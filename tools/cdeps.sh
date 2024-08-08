#!/bin/sh
set -eu

. tools/lib.sh

usage() {
	cat <<-'EOF'
		Usage:
		  tools/cdeps.sh FILE...
		  tools/cdeps.sh -h
	EOF
}

help() {
	cat <<-'EOF'


		Options:
		  -h, --help    show this message

		  FILE          toplevel entrypoint file


		Given a list of C FILEs, generate the Makefile dependencies
		between them.

		We have 3 types of object files:
		- .o: plain object files;
		- .lo: object files compiled as relocatable so it can be
		  included in a shared library;
		- .to: compiled with -DTEST so it can expose its embedded unit
		  tests;

		We also have 1 aggregate file:
		- .ea: an **e**xecutable **a**rchive, made with ar(1), that
		  includes all the .o dependencies required for linking, so that
		  one can have only the archive as the linker input, i.e.
		  `cc -o example.bin example.ea`.  This way we don't need
		  separate targets for each executable, and we can instead deal
		  separately with dependencies and linking, but without specific
		  file listing for each case.  We use an ar-chive to exploit the
		  fact that a) it can replace existing files with the same name
		  and b) the $? macro in make(1) gives us all the out-of-date
		  dependencies, so our rule in the Makefile is usually a simple
		  `$(AR) $(ARFLAGS) $@ $?`.  This way each .ea file lists its
		  dependency separately, and the building of the .ea file is
		  taken care of, in the same way that the linkage into an
		  executable is also taken care of.  For running unit tests, we
		  include as a dependency of "$NAME.ea" the "$NAME.to" file,
		  which is the object code of "$NAME.c" compiled with the -DTEST
		  flag.  This exposes a main() function for running unit tests.

		Also in order to run the unit tests without having to relink
		them on each run, we have:
		- .bin-check: a dedicated virtual target that does nothing but
		  execute the tests.  In order to assert the binaries exist,
		  each "$NAME.bin-check" virtual target depends on the
		  equivalent "$NAME.check" physical target.

		There are 2 types of dependencies that are generated:
		1. self dependencies;
		2. inter dependencies.

		The self dependencies are the ones across different
		manifestations of the same file so all derived assets are
		correctly kept up-to-date:
		- $NAME.o $NAME.lo $NAME.to: $NAME.h

		  As the .SUFFIXES rule already covers the dependency to the
		  orinal $NAME.c file, all we do is say that whenever the public
		  interface of these binaries change, they need to be
		  recompiled;

		- $NAME.ea: $NAME.to

		  We make sure to include in each executable archive (.ea) file
		  its own binary with unit tests.  We include the "depN.o"
		  dependencies later;

		- $NAME.bin-check: $NAME.bin

		  Enforce that the binary exists before we run them.

		After we establish the self dependencies, we scrub each file's
		content looking for `#include "..."` lines that denote
		dependency to other C file.  Once we do that we'll have:
		- $NAME.o $NAME.lo $NAME.to: dep1.h dep2.h ... depN.h

		  We'll recompile our file when its public header changes.  When
		  only the body of the code changes we don't recompile, only
		  later relink;

		- $NAME.ea: dep1.o dep2.o ... depN.o

		  Make sure to include all required dependencies in the
		  $NAME.bin binary so that the later linking works properly.

		So if we have file1.c, file2.c and file3.c with their respective
		headers, where file2.c and file3.c depend of file1.c, i.e. they
		have `#include "file.h"` in their code, and file3.c depend of
		file2.c, the expected output is:

		  file1.o file1.lo file1.to: file1.h
		  file2.o file2.lo file2.to: file2.h
		  file3.o file3.lo file3.to: file3.h

		  file1.ea: file1.to
		  file2.ea: file2.to
		  file3.ea: file3.to

		  file1.bin-check: file1.bin
		  file2.bin-check: file2.bin
		  file3.bin-check: file3.bin


		  file1.o file1.lo file1.to:
		  file2.o file2.lo file2.to: file1.h
		  file3.o file3.lo file3.to: file1.h file2.h

		  file1.ea:
		  file2.ea: file1.o
		  file3.ea: file1.o file2.o

		This ensures that only the minimal amount of files need to get
		recompiled, but no less.


		Examples:

		  Get deps for all files in 'src/' but 'src/main.c':

		    $ sh tools/cdeps.sh `find src/*.c -not -name 'main.c'`


		  Emit dependencies for all C files in a Git repository:

		    $ sh tools/cdeps.sh `git ls-files | grep '\.c$'`
	EOF
}


for flag in "$@"; do
	case "$flag" in
		(--)
			break
			;;
		(--help)
			usage
			help
			exit
			;;
		(*)
			;;
	esac
done

while getopts 'h' flag; do
	case "$flag" in
		(h)
			usage
			help
			exit
			;;
		(*)
			usage >&2
			exit 2
			;;
	esac
done
shift $((OPTIND - 1))

FILE="${1:-}"
eval "$(assert_arg "$FILE" 'FILE')"



each_f() {
	fn="$1"
	shift
	for file in "$@"; do
		f="${file%.c}"
		"$fn" "$f"
	done
	printf '\n'
}

self_header_deps() {
	printf '%s.o\t%s.lo\t%s.to:\t%s.h\n' "$1" "$1" "$1" "$1"
}

self_ea_deps() {
	printf '%s.ea:\t%s.to\n' "$1" "$1"
}

self_bincheck_deps() {
	printf '%s.bin-check:\t%s.bin\n' "$1" "$1"
}

deps_for() {
	ext="$2"
	for file in $(awk -F'"' '/^#include "/ { print $2 }' "$1.c"); do
		if [ "$file" = 'config.h' ]; then
			continue
		fi
		if [ "$(basename "$file")" = 'tests-lib.h' ]; then
			continue
		fi
		f="$(dirname "$1")/$file"
		if [ "$f" = "$1.h" ]; then
			continue
		fi
		printf '%s\n' "${f%.h}$2"
	done
}

rebuild_deps() {
	printf '\n'
	printf '%s.o\t%s.lo\t%s.to:' "$1" "$1" "$1"
	printf ' %s' $(deps_for "$1" .h) | sed 's| *$||'
}

archive_deps() {
	printf '\n'
	printf '%s.ea:' "$1"
	printf ' %s' $(deps_for "$1" .o) | sed 's| *$||'
}


each_f self_header_deps "$@"
each_f self_ea_deps     "$@"
each_f self_bincheck_deps   "$@"

each_f rebuild_deps     "$@"
each_f archive_deps     "$@"
