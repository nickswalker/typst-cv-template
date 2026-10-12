#!/bin/sh
# Build the CV: ./build.sh [compile|watch] [extra typst arguments]
# Rebuilds on every change to the template or cv.json when watching.
cd "$(dirname "$0")" || exit 1
command="${1:-compile}"
[ $# -gt 0 ] && shift
output=cv.pdf
set -- "$command" --font-path fonts --ignore-system-fonts --pdf-standard ua-1 "$@" cv.typ "$output"
# Watched output skips the fix below, so wrapped links misbehave in Preview until the next compile
[ "$command" = compile ] || exec typst "$@"
typst "$@" || exit 1
# Typst writes each link quad as bottom-left, bottom-right, top-right, top-left (the order the
# PDF spec gives). Preview and Safari read quads the way Acrobat writes them (top-left, top-right,
# bottom-left, bottom-right), so only slivers of a wrapped link are clickable. The numbers are
# only reordered, so the file's length and its cross-reference table stay valid.
perl -0pi -e 's{/QuadPoints\[([^\]]*)\]}{my @n = split " ", $1; my @o; push @o, @n[$_+6, $_+7, $_+4, $_+5, $_, $_+1, $_+2, $_+3] for grep { $_ % 8 == 0 } 0..$#n; "/QuadPoints[@o]"}ge' "$output"
