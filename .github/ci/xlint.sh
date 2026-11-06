#!/bin/bash
#
# xlint.sh

EXITCODE=0
read base tip < /tmp/revisions

ci_dir="${GITHUB_WORKSPACE:-$PWD}/.github/ci"

/bin/echo -e "\x1b[34mLinting commits...\x1b[0m"
if [ -f "$ci_dir/lint-commits" ]; then
	"$ci_dir/lint-commits" $base $tip || EXITCODE=$?
fi

if [ -s /tmp/templates ]; then
	for t in $(awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates); do
		if [ ! -f "$t" ]; then
			t="${GITHUB_WORKSPACE:-$PWD}/$(basename $(dirname $t))/template"
		fi
		[ -f "$t" ] || continue
		/bin/echo -e "\x1b[34mLinting $t...\x1b[0m"
		xlint "$t" > /tmp/xlint_out || EXITCODE=$?
		if [ -f "$ci_dir/lint-version-change" ]; then
			"$ci_dir/lint-version-change" "$t" $base $tip > /tmp/vlint_out 2>/dev/null || EXITCODE=$?
		fi
		if [ -f "$ci_dir/lint2annotations.awk" ]; then
			awk -f "$ci_dir/lint2annotations.awk" /tmp/xlint_out /tmp/vlint_out 2>/dev/null || cat /tmp/xlint_out
		else
			cat /tmp/xlint_out
		fi
	done
fi
exit $EXITCODE
