#!/bin/sh
set -eu

if [ ! -e .git ]; then
	echo "Not in a Git repository, skipping \"$0\"" >&2
	exit
fi


. tools/lib.sh

R="$(mkdtemp)"
trap 'rm -rf "$R"' EXIT

cp -LpR ./ "$R"
cd "$R"


DIRTY=false
UNTRACKED=false

if [ -n "$(git status -s)" ]; then
	DIRTY=true
fi

if [ -n "$(git clean -nffdx)" ]; then
	UNTRACKED=true
fi

{
	make -s clean

	printf '%s: "clean" target deletes all derived assets...' \
		"$(yellow "$0")"

	if [ "$DIRTY" = false ] && [ -n "$(git status -s)" ]; then
		printf ' %s.\n' "$(red 'ERR')"
		echo 'Repository left dirty:'
		git status
		exit 1
	fi

	if [ "$UNTRACKED" = false ] && [ -n "$(git clean -nffdx)" ]; then
		printf ' %s.\n' "$(red 'ERR')"
		echo 'Untracked files left:'
		git clean -ffdx --dry-run
		exit 1
	fi

	printf ' %s\n' "$(green 'OK')"
} >&2
