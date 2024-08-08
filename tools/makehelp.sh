#!/bin/sh
set -eu

. tools/lib.sh


usage() {
	cat <<-'EOF'
		Usage:
		  makehelp.sh < MAKEFILE
		  makehelp.sh -h
	EOF
}

help() {
	cat <<-'EOF'


		Options:
		  -h, --help    show this message


		Generate a help message from the given Makefile.

		Any target or variable commented with two "#" characters gets
		picked up.  Multi-line comments are supported:

		  VAR1 = 1
		  # a comment
		  VAR2 = 2
		  ## another comment -> this one is included in the docs
		  VAR3 = 3

		  ## with a big
		  ## comment, which is also included
		  a-target:


		Examples:

		  Generate help messages from "Makefile":

		    $ aux/makehelp.sh < Makefile


		  Generate help messages for all targets:

		    $ cat Makefile dev.mk | aux/makehelp.sh
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


TARGETS="$(mkstemp)"
VARIABLES="$(mkstemp)"
trap 'rm -f "$TARGETS" "$VARIABLES"' EXIT

awk -vCOLUMN=15 -vTARGETS="$TARGETS" -vVARIABLES="$VARIABLES" '
function indent(n, where) {
	for (INDENT = 0; INDENT < n; INDENT++) {
		printf " " > where
	}
}

/^## / { doc[len++] = substr($0, 4) }

/^[-_a-zA-Z]+:/ && len {
	printf "\033[36m%s\033[0m", substr($1, 1, length($1) - 1) > TARGETS
	for (i = 0; i < len; i++) {
		n = COLUMN - (i == 0 ? length($1) - 1 : 0)
		indent(n, TARGETS)
		printf "%s\n", doc[i] > TARGETS
	}
	len = 0
}

/^.++=/ && len {
	printf "\033[36m%s\033[0m", $1 > VARIABLES
	for (i = 0; i < len; i++) {
		n = COLUMN - (i == 0 ? length($1) : 0)
		indent(n, VARIABLES)
		printf "%s\n", doc[i] > VARIABLES
	}
	len = 0
}'



indent() {
	sed 's|^|  |'
}

cat <<-EOF
	Usage:

	  make [VARIABLE=value...] [target...]


	Targets:

	$(indent < "$TARGETS")


	Variables:

	$(indent < "$VARIABLES")


	Examples:

	  Build "all", the default target:

	    $ make


	  Test and install, with \$(DESTDIR) set to "tmp/":

	    $ make DESTDIR=tmp check install
EOF
