#!/bin/sh

# clone and retarget a project name
#
# Typical use:
#   cpname source_dir dest_dir
#
# Behavior:
# - Copies source_dir -> dest_dir
# - Retargets project name inside dest_dir using mvname
# - Prunes template history/artifacts by default

usage() {
	cat <<'EOF'
usage: cpname [-R] [--prune|--no-prune|--keep-history] source_dir dest_dir

Clone source_dir to dest_dir, then retarget the KiCad project name to
match dest_dir's basename.

Options:
  -R              Accepted for compatibility (no effect)
  --prune         Prune clone history/artifacts for KiCad projects (default)
  --no-prune      Keep copied history/artifacts
  --keep-history  Alias for --no-prune
  -h, --help      Show help
EOF
}

die() {
	printf '%s\n' "$*" >&2
	exit 1
}

prune=1

while [ $# -gt 0 ]; do
	case "$1" in
	-R)
		shift
		;;
	--prune)
		prune=1
		shift
		;;
	--no-prune|--keep-history)
		prune=0
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

src="$1"
dst="$2"
src=${src%/}
dst=${dst%/}

[ -d "$src" ] || die "source directory does not exist: $src"
[ ! -e "$dst" ] || die "destination already exists: $dst"

src_base=${src##*/}
dst_base=${dst##*/}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -x "${script_dir}/mvname.sh" ]; then
	mvname_cmd="${script_dir}/mvname.sh"
elif command -v mvname >/dev/null 2>&1; then
	mvname_cmd=`command -v mvname`
else
	die "mvname command not found"
fi

detect_project_name() {
	src_default="$1"
	set -- ./*.kicad_pro
	if [ "$1" = "./*.kicad_pro" ]; then
		printf '%s\n' "$src_default"
		return 0
	fi

	if [ $# -eq 1 ]; then
		base=${1##*/}
		printf '%s\n' "${base%.kicad_pro}"
		return 0
	fi

	for f in "$@"; do
		base=${f##*/}
		name=${base%.kicad_pro}
		if [ "$name" = "$src_default" ]; then
			printf '%s\n' "$name"
			return 0
		fi
	done

	die "multiple .kicad_pro files found; cannot infer source project name"
}

is_kicad_project() {
	set -- ./*.kicad_pro
	[ "$1" != "./*.kicad_pro" ]
}

prune_clone_artifacts() {
	new_project="$1"

	rm -rf ./.history ./.mvname-backups

	find . -mindepth 1 -maxdepth 1 -type d -name '*-backups' -print | while IFS= read -r d; do
		rm -rf "$d"
	done
	mkdir -p "./${new_project}-backups"

	rm -rf ./production
	mkdir -p ./production/backups

	for f in ./*.zip ./*_missing3Dmodels.txt ./*_log_missing3Dmodels.txt; do
		[ -e "$f" ] || continue
		rm -f "$f"
	done
}

cp -R "$src" "$dst" || die "copy failed"

(
	cd "$dst" || exit 1
	new_project="$dst_base"
	if is_kicad_project; then
		old_project=`detect_project_name "$src_base"` || exit 1
		"$mvname_cmd" -R --no-backup "$old_project" "$new_project" || exit 1

		if [ "$prune" -ne 0 ]; then
			prune_clone_artifacts "$new_project" || exit 1
		fi
	else
		"$mvname_cmd" -R "$src_base" "$new_project" || exit 1
		if [ "$prune" -ne 0 ]; then
			printf 'cpname: destination is not a KiCad project; skipping prune/history cleanup.\n' >&2
		fi
	fi
)
