#!/bin/sh
set -eu

awk '
BEGIN {
	rc = 0
	msg = "function not on the start of the line:"
}

/^[a-zA-Z0-9_]+ [^=]+\(/ {
	if (rc == 0) {
		print msg
	}
	printf "%s:%s:%s\n", FILENAME, FNR, $0
	rc = 1
}

END {
	exit rc
}
' "$@"


awk '
BEGIN {
	rc = 0
	static = 1
	msg = "non-static function is not declared in a header:"
}

/^[a-zA-Z0-9_]+\(.*$/ && static == 0 {
	split($0, line, /\(/)
	fn_name = line[1]
	if (fn_name != "main" && fn_name != "LLVMFuzzerTestOneInput") {
		header = substr(FILENAME, 0, length(FILENAME) - 2)  ".h"
		if (system("grep -q ^\"" fn_name "\" \"" header "\"")) {
			if (rc == 0) {
				print msg
			}
			printf "%s:%s:%s\n", FILENAME, FNR, $0
			rc = 1
		}
	}
}

/^static / {
	static = 1
}

!/^static / {
	static = 0
}

END {
	exit rc
}
' "$@"


RE='[a-z]+\(\) {'
if grep -Eq "$RE" "$@"; then
	echo 'Functions with no argument without explicit "void" parameter:' >&2
	grep -En "$RE" "$@"
	exit 1
fi

awk '
BEGIN {
	rc = 0
	tags[""] = 0
}

$0 == "/**" {
	docs = 1
	for (k in tags) {
		delete tags[k]
	}
}

$0 == "*/" && docs = 1 {
	docs = 0
}

docs == 1 && $1 == "*" && $2 == "@tags" {
	for (i = 3; i <= NF; i++) {
		tags[$(i)] = 1
	}
}

/^[a-zA-Z0-9_]+\(.*$/ {
	for (k in tags) {
		delete tags[k]
	}
}

{ prev = $0 }

END {
	exit rc
}
' "$@"
