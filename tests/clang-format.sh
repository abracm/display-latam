#!/bin/sh
set -eu

. tools/lib.sh

FILE="$1"
{
	printf '%s: formatting of C files...' "$(yellow "$0")"
	clang-format --Werror --dry-run "$FILE"
	printf ' %s\n' "$(green 'OK')"
} >&2
