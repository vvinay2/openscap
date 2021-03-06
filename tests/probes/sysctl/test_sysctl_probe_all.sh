#!/bin/bash

. $srcdir/../../test_common.sh

set -e -o pipefail

probecheck "sysctl" || return 255

name=$(basename $0 .sh)

result=$(mktemp ${name}.res.out.XXXXXX)
stderr=$(mktemp ${name}.err.out.XXXXXX)
ourNames=$(mktemp ${name}.our.out.XXXXXX)
sysctlNames=$(mktemp ${name}.sysctl.out.XXXXXX)

echo "Result file: $result"
echo "Our names file: $ourNames"
echo "Sysctl names file: $sysctlNames"
echo "Errors file: $stderr"

$OSCAP oval eval --results $result $srcdir/test_sysctl_probe_all.oval.xml > /dev/null 2>$stderr

# sysctl has duplicities in output
# hide permission errors like: "sysctl: permission denied on key 'fs.protected_hardlinks'"
sysctl -aN --deprecated 2> /dev/null | sort -u > "$sysctlNames"

grep unix-sys:name "$result" | sed -E 's;.*>(.*)<.*;\1;g' | sort > "$ourNames"

diff "$sysctlNames" "$ourNames"

[ ! -s $stderr ]

rm $stderr $result $ourNames $sysctlNames


