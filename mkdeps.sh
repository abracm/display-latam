#!/bin/sh
set -eu

varlist() {
	printf '%s = \\\n' "$1"
	sed 's|^\(.*\)$|\t\1 \\|'
	printf '\n'
}

export LANG=POSIX.UTF-8
find src/*.c        | sort | varlist 'sources.c'
find src/*.mjs      | sort | varlist 'sources.mjs'
find tests/js/*.mjs | sort | varlist 'tests.mjs'

sh tools/cdeps.sh `find src/*.c | sort`

printf '\n'
find tests/js/*.mjs | sort | sed 's|^\(.*\)$|\1-t: \1|'
