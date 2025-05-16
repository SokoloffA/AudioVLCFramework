#!/bin/bash

set -euo pipefail

CONFIGURE_FLAGS+=" --prefix=${ROOT_DIR}"

CONFIGURE_FLAGS+=" --no-system-libs"
CONFIGURE_FLAGS+=" --datadir=${ROOT_DIR}/share/cmake"
CONFIGURE_FLAGS+=" --docdir=${ROOT_DIR}/share/doc/cmake"
CONFIGURE_FLAGS+=" --mandir=${ROOT_DIR}/share/man"
CONFIGURE_FLAGS+=" --system-zlib"
CONFIGURE_FLAGS+=" --system-bzip2"
CONFIGURE_FLAGS+=" --system-curl"

which cmake >/dev/null && exit

./bootstrap ${CONFIGURE_FLAGS} -- -DCMake_BUILD_LTO=ON
make -j ${PROC_NUM}
make install
