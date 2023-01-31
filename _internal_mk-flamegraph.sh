#!/bin/bash

set -eux

# Check that two arguments are passed
if [ $# -ne 2 ]; then
  echo "Usage: perf-to-svg <perf_data> <output_svg>"
  exit 1
fi

perf_data=$1
output_svg=$2

cp "/data/$perf_data" /tmp/perf.data
cd /tmp
perf script > out.perf
/FlameGraph/stackcollapse-perf.pl out.perf > out.folded
/FlameGraph/flamegraph.pl out.folded > out.svg
cp out.svg "/data/$output_svg"
