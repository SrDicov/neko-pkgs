#!/bin/bash
#
# changed_templates.sh

set -e

repo_dir="${GITHUB_WORKSPACE:-$PWD}"
cd "$repo_dir"

tip="$(git rev-list -1 --parents HEAD 2>/dev/null | head -1)"
case "$tip" in
	*" "*" "*) tip="${tip##* }" ;;
	*)         tip="${tip%% *}" ;;
esac

base=""
for ref in origin/main origin/master origin/HEAD HEAD~1; do
	if git rev-parse --verify "$ref" >/dev/null 2>&1; then
		mb="$(git merge-base "$ref" "$tip" 2>/dev/null || true)"
		if [ -n "$mb" ] && [ "$mb" != "$tip" ]; then
			base="$mb"
			break
		fi
	fi
done

if [ -z "$base" ]; then
	base="$(git rev-parse HEAD~1 2>/dev/null || git rev-parse HEAD)"
fi

echo "$base $tip" > /tmp/revisions

/bin/echo -e '\x1b[32mChanged packages:\x1b[0m'

if [ "$base" = "$tip" ]; then
	: > /tmp/templates
else
	# Soporta tanto */template (neko-pkgs) como srcpkgs/*/template
	git diff-tree -r --no-renames --name-only --diff-filter=AM "$base" "$tip" |
		grep -E '(^|/)template$' |
		grep -v '^\.github' |
		sed -E 's|^srcpkgs/||; s|/template$||' |
		sort -u > /tmp/templates_raw || true

	xbps_src_bin=""
	if [ -x ./xbps-src ]; then
		xbps_src_bin="./xbps-src"
	elif [ -x /void-packages/xbps-src ]; then
		xbps_src_bin="/void-packages/xbps-src"
	fi

	if [ -s /tmp/templates_raw ]; then
		if [ -n "$xbps_src_bin" ]; then
			xargs "$xbps_src_bin" sort-dependencies < /tmp/templates_raw > /tmp/templates 2>/dev/null || cp /tmp/templates_raw /tmp/templates
		else
			cp /tmp/templates_raw /tmp/templates
		fi
	else
		: > /tmp/templates
	fi
fi

cat /tmp/templates | sed "s/^/  /" >&2
