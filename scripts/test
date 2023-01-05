#!/bin/sh -e
#
# Runs lua-language-server to lint the entire project.

tmp=`mktemp -d`
trap 'rm -rf -- "$tmp"' EXIT

lua-language-server --check="$PWD" --checklevel=Information --logpath="$tmp"

if [ -f "$tmp/check.json" ]; then
    cat >&2 -- "$tmp/check.json"
    exit 1
fi
