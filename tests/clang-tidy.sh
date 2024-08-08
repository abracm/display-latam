#!/bin/sh
set -eu

. tools/lib.sh

FILE="$1"
{
	printf '%s: linting of C files...' "$(yellow "$0")"
	clang-tidy "$FILE" -- -DTEST
	printf ' %s\n' "$(green 'OK')"
} >&2
