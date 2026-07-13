# mvname / cpname

## NAME
`mvname` - rename prefix-based file sets, with KiCad-aware project retargeting
`cpname` - clone a project directory and retarget its project name

## SYNOPSIS
`mvname [-R] [--no-backup] oldname newname`

`cpname [-R] [--prune|--no-prune|--keep-history] source_dir dest_dir`

## DESCRIPTION
This repository provides two shell tools for project name refactoring.

`mvname` supports:
- generic prefix renaming for file/directory basenames
- KiCad-aware rename mode when run in a directory containing `./oldname.kicad_pro`

`cpname` supports:
- copy + retarget workflow (`source_dir` -> `dest_dir`)
- destination project name derived from destination directory basename
- KiCad-specific prune cleanup by default for clone/template flows

## Mvname Modes
### Legacy mode
If `./oldname.kicad_pro` is **not** present, `mvname` renames basenames that start with `oldname`.

- Without `-R`: current directory only
- With `-R`: recursive directory traversal

### KiCad-aware mode
If `./oldname.kicad_pro` **is** present, `mvname` performs project-aware retargeting:

1. Creates pre-change safety backup under `.mvname-backups/` (unless `--no-backup`)
2. Renames matching project paths from `oldname*` to `newname*`
3. Rewrites embedded references in KiCad text files (`oldname` -> `newname`)
4. Removes `fp-info-cache` to avoid stale cache references

### KiCad-aware exclusions
During KiCad mode, these are intentionally preserved/skipped:
- `.git/`
- `.history/`
- `production/backups/`
- `oldname-backups/`
- `newname-backups/`
- `*.zip`

## Cpname Behavior
`cpname` runs:
1. `cp -R source_dir dest_dir`
2. `cd dest_dir`
3. If KiCad project detected (`*.kicad_pro`):
   - infer source project name
   - run `mvname -R --no-backup old_project new_project`
   - apply prune cleanup when enabled
4. If not KiCad:
   - run generic `mvname -R source_basename dest_basename`
   - skip KiCad prune/history cleanup

## OPTIONS
### mvname
- `-R`  
  Recursive rename traversal.
- `--no-backup`  
  Skip pre-change safety backup in KiCad-aware mode.
- `-h`, `--help`  
  Show usage.

### cpname
- `-R`  
  Accepted for compatibility (no behavioral effect).
- `--prune`  
  Enable KiCad clone cleanup (default).
- `--no-prune`  
  Disable prune cleanup.
- `--keep-history`  
  Alias for `--no-prune`.
- `-h`, `--help`  
  Show usage.

## PRUNE CONTENTS (KiCad mode only)
When prune is enabled for KiCad clones, `cpname`:
- removes `.history/`
- removes `.mvname-backups/`
- removes top-level `*-backups/`, then creates `${new_project}-backups/`
- resets `production/` to contain only `production/backups/`
- removes top-level `*.zip`, `*_missing3Dmodels.txt`, `*_log_missing3Dmodels.txt`

## EXAMPLES
Rename a project in place:

`mvname cpNode-ProMini TelephoneHeadsetTester`

Recursive generic rename:

`mvname -R foo bar`

Clone and retarget a KiCad template (with prune default):

`cpname variation1 TelephoneHeadsetTester`

Clone and retarget but keep history/backups:

`cpname --keep-history variation1 TelephoneHeadsetTester`

## EXIT STATUS
`0` on success, non-zero on error.

## NOTES
- `mvname` uses `perl` for in-file rewrite operations when available, with a `python3` fallback.
- For backups, `zip` is preferred; `tar.gz` is used as fallback.
- In KiCad mode, path overwrite conflicts abort with an error.
