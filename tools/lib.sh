#!/bin/sh

assert_arg() {
	if [ -z "$1" ]; then
		printf 'Missing %s.\n\n' "$2" >&2
		cat <<-'EOF'
			usage >&2
			exit 2
		EOF
	fi
}

uuid() {
        od -xN20 /dev/urandom |
                head -n1 |
                awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
}

tmpname() {
        echo "${TMPDIR:-/tmp}/uuid-tmpname with spaces.$(uuid)"
}

mkstemp() {
	name="$(tmpname)"
	touch "$name"
	echo "$name"
}

mkdtemp() {
        name="$(tmpname)"
	mkdir "$name"
        echo "$name"
}

END="\033[0m"
yellow() {
	YELLOW="\033[0;33m"
	printf "${YELLOW}${1}${END}"
}

green() {
	GREEN="\033[0;32m"
	printf "${GREEN}${1}${END}"
}

red() {
	RED="\033[0;31m"
	printf "${RED}${1}${END}"
}
