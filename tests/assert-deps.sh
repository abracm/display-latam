#!/bin/sh
set -eu

. tools/lib.sh

{
	printf '%s: all deps.mk is up-to-date...' "$(yellow "$0")"
	sh mkdeps.sh | diff -U10 deps.mk -
	printf ' %s\n' "$(green 'OK')"
} >&2
