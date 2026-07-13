#!/bin/sh

# rename a set of files using a naming pattern
# used in eagle workspaces to rename a whole set of files (board, schematic, gerbers, etc)
# start with:
#     foo.sch, foo.brd, foo.parts.txt foo1234.txt
# mvname foo bar
#     bar.sch, bar.brd, bar.parts.txt bar1234.txt
#
# Extended behavior for KiCad projects:
# - when run from a project root that contains OLDNAME.kicad_pro, this script
#   updates both filenames and in-file project references.
# - creates a pre-change safety backup in .mvname-backups/
# - preserves historical artifacts in OLDNAME-backups and production/backups
#
# John Plocher residing at gmail

usage() {
	cat <<'EOF'
usage: mvname [-R] [--no-backup] oldname newname

Legacy mode:
  Renames files/directories whose basename starts with oldname.
  -R traverses directories recursively.

KiCad-aware mode:
  If ./oldname.kicad_pro exists, mvname performs a project-aware rename:
  - creates a pre-change safety backup in .mvname-backups/
  - renames project file paths and project libraries
  - rewrites in-file references from oldname -> newname
  - preserves old historical artifacts in oldname-backups and production/backups
EOF
}

die() {
	printf '%s\n' "$*" >&2
	exit 1
}

recurse=0
create_backup=1

while [ $# -gt 0 ]; do
	case "$1" in
	-R)
		recurse=1
		shift
		;;
	--no-backup)
		create_backup=0
		shift
		;;
	-h|--help)
		usage
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		die "unknown option: $1"
		;;
	*)
		break
		;;
	esac
done

[ $# -eq 2 ] || {
	usage >&2
	exit 1
}

oname="$1"
nname="$2"

[ -n "$oname" ] || die "oldname must not be empty"
[ -n "$nname" ] || die "newname must not be empty"

if [ "$oname" = "$nname" ]; then
	printf 'mvname: oldname and newname are identical; nothing to do.\n' >&2
	exit 0
fi

do_rename_current_dir() {
	old="$1"
	new="$2"
	find . -mindepth 1 -maxdepth 1 -name "${old}*" -print | while IFS= read -r src; do
		base=${src##*/}
		suffix=${base#"$old"}
		dst="./${new}${suffix}"
		[ "$src" = "$dst" ] && continue
		mv -- "$src" "$dst" || exit 1
	done
}

legacy_rename() {
	if [ "$recurse" -ne 0 ]; then
		find . -depth -type d -print | while IFS= read -r d; do
			(
				cd "$d" || exit
				do_rename_current_dir "$oname" "$nname"
			)
		done
	else
		do_rename_current_dir "$oname" "$nname"
	fi
}

create_kicad_backup() {
	stamp=`date "+%Y-%m-%d_%H-%M-%S"`
	backup_dir=".mvname-backups"
	mkdir -p "$backup_dir" || return 1

	if command -v zip >/dev/null 2>&1; then
		archive="${backup_dir}/pre-rename-${oname}-to-${nname}-${stamp}.zip"
		zip -rq "$archive" . -x "./${backup_dir}/*" || return 1
	else
		archive="${backup_dir}/pre-rename-${oname}-to-${nname}-${stamp}.tar.gz"
		tar -czf "$archive" --exclude "./${backup_dir}" . || return 1
	fi

	printf '%s\n' "$archive"
}

is_excluded_kicad_path() {
	p="$1"

	case "$p" in
		./.git|./.git/*)
			return 0
			;;
		./.history|./.history/*)
			return 0
			;;
		./production/backups|./production/backups/*)
			return 0
			;;
		"./${oname}-backups"| "./${oname}-backups"/*)
			return 0
			;;
		"./${nname}-backups"| "./${nname}-backups"/*)
			return 0
			;;
		*.zip)
			return 0
			;;
	esac

	return 1
}

detect_rewrite_backend() {
	if command -v perl >/dev/null 2>&1; then
		rewrite_backend="perl"
	elif command -v python3 >/dev/null 2>&1; then
		rewrite_backend="python3"
	else
		die "KiCad content rewrite requires perl or python3"
	fi
}

rewrite_file_content() {
	f="$1"

	case "$rewrite_backend" in
		perl)
			ONAME="$oname" NNAME="$nname" perl -i -pe 's/\Q$ENV{ONAME}\E/$ENV{NNAME}/g' "$f" || return 1
			;;
		python3)
			ONAME="$oname" NNAME="$nname" python3 - "$f" <<'PY' || return 1
import os
import sys

path = sys.argv[1]
old = os.environ["ONAME"].encode("utf-8")
new = os.environ["NNAME"].encode("utf-8")

with open(path, "rb") as fh:
    data = fh.read()

with open(path, "wb") as fh:
    fh.write(data.replace(old, new))
PY
			;;
		*)
			return 1
			;;
	esac
}

rename_kicad_paths() {
	find . -depth -name "${oname}*" -print | while IFS= read -r src; do
		is_excluded_kicad_path "$src" && continue

		dir=${src%/*}
		base=${src##*/}
		[ "$dir" = "$src" ] && dir="."

		suffix=${base#"$oname"}
		dst="${dir}/${nname}${suffix}"

		[ "$src" = "$dst" ] && continue
		if [ -e "$dst" ]; then
			die "refusing to overwrite existing path: $dst"
		fi

		mv -- "$src" "$dst" || exit 1
	done
}

rewrite_kicad_content() {
	find . -type f \
		\( \
			-name "*.kicad_pro" -o \
			-name "*.kicad_prl" -o \
			-name "*.kicad_sch" -o \
			-name "*.kicad_pcb" -o \
			-name "*.kicad_sym" -o \
			-name "fp-lib-table" -o \
			-name "sym-lib-table" -o \
			-name "fp-info-cache" \
		\) -print | while IFS= read -r f; do
		is_excluded_kicad_path "$f" && continue
			rewrite_file_content "$f" || exit 1
	done
}

kicad_rename() {
	if [ "$create_backup" -ne 0 ]; then
		backup_path=`create_kicad_backup` || die "failed creating pre-rename safety backup"
		printf 'mvname: created safety backup %s\n' "$backup_path" >&2
	fi
	detect_rewrite_backend || die "failed selecting rewrite backend"
	rename_kicad_paths || die "failed renaming KiCad project paths"
	rewrite_kicad_content || die "failed rewriting KiCad project content"

	# Safe to regenerate; deleting avoids stale cache references.
	rm -f ./fp-info-cache
}

if [ -f "./${oname}.kicad_pro" ]; then
	kicad_rename
else
	legacy_rename
fi

