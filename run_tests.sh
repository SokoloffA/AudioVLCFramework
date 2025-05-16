#!/bin/bash

set -euo pipefail

OUT_DIR=.build/tests
cmake -B${OUT_DIR} tests
make -C${OUT_DIR}
install -l s ../../AudioVLC.xcframework ${OUT_DIR}/AudioVLC.xcframework

passed=0
failed=0
n=0

function test() {
    n=$(($n+1))

    if ${OUT_DIR}/AudioVLC_Test $@; then
        passed=$(($passed+1))
    else
        failed=$(($failed+1))
    fi
}

########################

test http://sc2.radiocaroline.net:8040/
test http://www.rcgoldserver.com:8253
test http://stream.radioparadise.com/flac
test http://sc3.radiocaroline.net:8030
test https://mediaserviceslive.akamaized.net/hls/live/2038308/triplejnsw/index.m3u8 --skip-metadata

echo ""
echo "*********************************"
echo "Totals: ${passed} passed, ${failed} failed"
echo "*********************************"
exit $failed