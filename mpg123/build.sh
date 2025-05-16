#!/bin/bash

set -euo pipefail

CONFIGURE_FLAGS+=" --prefix=${ROOT_DIR}"
CONFIGURE_FLAGS+=" --quiet"

CONFIGURE_FLAGS+=" --disable-components"
CONFIGURE_FLAGS+=" --enable-libmpg123"
CONFIGURE_FLAGS+=" --with-default-audio=coreaudio"
CONFIGURE_FLAGS+=" --disable-network"
CONFIGURE_FLAGS+=" --disable-shared"
CONFIGURE_FLAGS+=" --enable-static"

if [[ ${ARCH} = "arm64" ]]; then
    CONFIGURE_FLAGS+=" --with-cpu=aarch64"
else
    CONFIGURE_FLAGS+=" --with-cpu=x86-64"
fi

lazy_configure ${CONFIGURE_FLAGS}
make -j ${PROC_NUM}
make install
