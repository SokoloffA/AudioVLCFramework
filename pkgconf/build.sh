#!/bin/bash

set -euo pipefail

[ -f ${ROOT_DIR}/bin/pkgconf ] && exit

CONFIGURE_FLAGS+=" --prefix=${ROOT_DIR}"
CONFIGURE_FLAGS+=" --quiet"
CONFIGURE_FLAGS+=" --disable-shared" #  build shared libraries [default=yes]
CONFIGURE_FLAGS+=" --disable-static" #  build static libraries [default=yes]

lazy_configure ${CONFIGURE_FLAGS}
make -j ${PROC_NUM}
make install

install -l s ./pkgconf ${ROOT_DIR}/bin/pkg-config
rm -rf "${ROOT_DIR}/lib/libpkgconf"*

