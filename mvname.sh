#!/bin/sh

# rename a set of files using a naming pattern
# used in eagle workspaces to rename a whole set of files (board, schematic, gerbers, etc)
# start with:
#     foo.sch, foo.brd, foo.parts.txt foo1234.txt
# mvname foo bar
#     bar.sch, bar.brd, bar.parts.txt bar1234.txt
#
# John Plocher residing at gmail

# set -x


# usage:  $0 oldname newname
recurse=0
oname="$1"; shift
if [ "$oname" = "-R" ]; then
	recurse=1
	oname="$1"; shift
fi
nname="$1"; shift


do_rename() {
	oname="$1"; shift
	nname="$1"; shift
	exts=`ls -1 --  "$oname"* | sed -e "s/^$oname//"`

	for ext in $exts; do
	    # (set -x;  mv -- "${oname}${ext}" "${nname}${ext}")
	    mv -- "${oname}${ext}" "${nname}${ext}"
	done
}

if [ "$recurse" -ne 0 ]; then
	find . -depth -type d -print | while IFS= read -r d; do
		(
		cd "$d" || exit
		do_rename "$oname" "$nname"
		)
	done
else
	do_rename "$oname" "$nname"
fi

