#!/bin/bash

set -euo pipefail

CONFIGURE_FLAGS+=" --prefix=${ROOT_DIR}"
CONFIGURE_FLAGS+=" --quiet"

CONFIGURE_FLAGS+=" --disable-programs"
CONFIGURE_FLAGS+=" --disable-cpplibs"
CONFIGURE_FLAGS+=" --disable-examples"
CONFIGURE_FLAGS+=" --disable-doxygen-docs"

CONFIGURE_FLAGS+=" --enable-static"
CONFIGURE_FLAGS+=" --disable-shared"

lazy_configure ${CONFIGURE_FLAGS}
make -j ${PROC_NUM}
make install
