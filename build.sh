#!/bin/bash

set -euo pipefail


FRAMEWORK_NAME=AudioVLC
XCFRAMEWORK_DIR="./${FRAMEWORK_NAME}.xcframework"
CERT_IDENTITY="Developer ID Application: Alex Sokolov (635H9TYSZJ)"

#######################################

SCRIPT_DIR=`pwd`
OUT_DIR="${SCRIPT_DIR}/.build/AudioVLC.framework"
PROC_NUM=`nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2`
ARCHITECTURES="arm64 x86_64"
ORIG_PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

export PROC_NUM=${PROC_NUM}
export MAKEFLAGS="--jobs=${PROC_NUM} ${MAKEFLAGS:-}"


function lazy_configure() {
    local re="$@"
    if grep -q -- "$re" "config.log"; then
        echo "Skip ./configure"
    else
        ./configure "$@"
    fi
}

export -f lazy_configure

function extaract_sources() {
    local project=$1

    if [ -d "${project}/sources" ]; then
        echo "Syncing sources ........................."
        local in_dir="${project}/sources"
        local out_dir="${BUILD_DIR}/sources"
        rsync -ra "${in_dir}/" "${out_dir}/"
        echo "Sources successfully synced ............."
        return 0
    fi

    if [ ! -d "${BUILD_DIR}/sources" ]; then
        echo "Extractiong sources ....................."
        tar=`find ${project} -type file -name "*.tar.gz" -or -name "*.tar.xz" -or -name "*.tar.bz2"`
        mkdir -p "${BUILD_DIR}/sources"
        tar -xf "${tar}" --strip-components=1 -C "${BUILD_DIR}/sources"
        echo "Sources successfully extracted .........."
        return 0
    fi
}


function build() {
    local project=$1

    for arch in ${ARCHITECTURES}; do
        export BUILD_DIR="${SCRIPT_DIR}/.build/${project}/${arch}"
        export ARCH=${arch}
        export ROOT_DIR="${SCRIPT_DIR}/.build/${arch}"
        export PATH="${ROOT_DIR}/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin"
        export PKG_CONFIG_PATH="${ROOT_DIR}/lib/pkgconfig:${ORIG_PKG_CONFIG_PATH}"
        export CONF_DIR="${SCRIPT_DIR}/${project}"

        echo "*****************************************"
        echo "** ${project}"

        extaract_sources "${project}"

        pushd "${BUILD_DIR}/sources" 2>&1> /dev/null
        echo "Building for ${arch} ........................"
        arch -${ARCH} /bin/bash "${SCRIPT_DIR}/${project}/build.sh" 2>&1 | tee ${BUILD_DIR}/build.log
        echo "Successfully built for ${arch} .............."

        popd 2>&1> /dev/null
    done
}


function in_modules_list() {
    local file=${1#"${FRAMEWORK_NAME}.framework/plugins/"}

    line=`grep "$file" ${SCRIPT_DIR}/vlc_modules.conf` || { echo "Unknown module $file"; exit 1; }
    [[ $line == "ON "* ]] && return 0
    return 1
}


function name_tool() {
    install_name_tool $@ 2>&1 \
        | grep --quiet -v "warning: changes being made to the file will invalidate the code signature in" || true
}


function build_universal_framework() {
    local arm_dir="arm64"
    local x86_dir="x86_64"
    local out_dir="${FRAMEWORK_NAME}.framework"

    rm -rf "${out_dir}"
    mkdir -p "${out_dir}"

    mkdir -p "${out_dir}/Headers/vlc"
    cp -a "${arm_dir}/include/vlc/"*.h "${out_dir}/Headers/vlc"
    rm -rf "${out_dir}/Headers/vlc/vlc.h"
    rm -rf "${out_dir}/Headers/vlc/deprecated.h"

    echo "Creating AudioVLC.h ......................."
    cp -a "${SCRIPT_DIR}/vlc/AudioVLC.h" "${out_dir}/Headers/AudioVLC.h"

    echo "Creating module.modulemap ................."
    mkdir -p ${out_dir}/Modules
    echo "framework module ${FRAMEWORK_NAME} {" > "${out_dir}/Modules/module.modulemap"
    echo '    umbrella header "AudioVLC.h"' >> "${out_dir}/Modules/module.modulemap"
    echo ''                                 >> "${out_dir}/Modules/module.modulemap"
    echo '    export *'                     >> "${out_dir}/Modules/module.modulemap"
    echo '    module * { export * }'        >> "${out_dir}/Modules/module.modulemap"
    echo '}'                                >> "${out_dir}/Modules/module.modulemap"

    echo "Processing libraries ......................"
    for f in `find "${arm_dir}/lib" -type file -maxdepth 1 -name '*.dylib'`; do
        f=${f#"$arm_dir/lib/"}
        lipo "${arm_dir}/lib/$f" "${x86_dir}/lib/$f" -create -output "${out_dir}/$f"
    done

    for f in `find "${arm_dir}/lib" -type link -maxdepth 1 -name '*.dylib'`; do
        f=${f#"$arm_dir/lib/"}
        cp -a "${arm_dir}/lib/$f" "${out_dir}/$f"
    done
    cat "${out_dir}/libvlc.dylib" > "${out_dir}/${FRAMEWORK_NAME}"

    echo "Processing plugins ........................"
    for f in `find "${arm_dir}/lib/vlc/plugins" -type file -name '*.dylib'`; do
        f=${f#"$arm_dir/lib/vlc/plugins"}
        arm_file="${arm_dir}/lib/vlc/plugins$f"
        x86_file="${x86_dir}/lib/vlc/plugins$f"
        out_file="${out_dir}/plugins$f"
        dir=$(dirname ${out_file})

        if in_modules_list "${out_file}"; then
            mkdir -p "${dir}"
            lipo "${arm_file}" "${x86_file}" -create -output "${out_file}"
        else
            echo " * skip ${out_file}"
        fi
    done


    echo "Fixing @rpath ............................."
    local rpath=@rpath/${FRAMEWORK_NAME}.framework

    name_tool -id "${rpath}/${FRAMEWORK_NAME}" "${out_dir}/${FRAMEWORK_NAME}"
    name_tool -change "@rpath/libvlccore.dylib" "${rpath}/libvlccore.dylib" "${out_dir}/${FRAMEWORK_NAME}"

    for f in `find "${out_dir}" -type file -name '*.dylib'`; do
        name=${f#"$out_dir/"}
        name_tool -id "${rpath}/${name}" "${f}"
        name_tool -change @rpath/libvlccore.dylib ${rpath}/libvlccore.dylib "$f"

        IFS=$'\n'
        for old in `otool -L "${f}" | grep -o "${SCRIPT_DIR}/.build/\S*"`; do
            new="${rpath}/"`echo $old | sed 's|.*/lib/||'`
            name_tool -change "${old}" "${new}" "${f}"
            name_tool -change "@rpath/libvlccore.dylib" "${rpath}/libvlccore.dylib" "${f}"
        done
    done
}


# ***************************
build cmake
build pkgconf
build libogg
build flac
build mpg123
build faad
build libdvbpsi
build vlc

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin
echo "*****************************************"
echo "* Building for universal framework..."
pushd "${SCRIPT_DIR}/.build" 2>&1> /dev/null
build_universal_framework
popd 2>&1> /dev/null

echo "*****************************************"
echo "* Building xcframework"
rm -rf "${XCFRAMEWORK_DIR}"
xcodebuild \
    -create-xcframework \
    -framework "${SCRIPT_DIR}/.build/${FRAMEWORK_NAME}.framework" \
    -output "${XCFRAMEWORK_DIR}"


echo "*****************************************"
echo "* Signing .dylib files"
find "${XCFRAMEWORK_DIR}" -type file -name '*.dylib' -print0 | \
    xargs -0 -I % -P ${PROC_NUM} \
        codesign --force --sign "${CERT_IDENTITY}" %


echo "*****************************************"
echo "* Signing framework"
codesign --force --sign "${CERT_IDENTITY}" --deep "${XCFRAMEWORK_DIR}"


echo "*****************************************"
echo "* Verifining signinature"
codesign --all-architectures -v --strict --deep --verbose=1 "${XCFRAMEWORK_DIR}"
echo "Signinature is OK"


echo "*****************************************"
echo "* ZIP xcframework"
zip --quiet -r "${XCFRAMEWORK_DIR}.zip" "${XCFRAMEWORK_DIR}"