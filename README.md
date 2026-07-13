# Scripts

Personal command-line tool collection. Tools are used via symlinks from
`~/bin` (on PATH), following the pattern `~/bin/<name> -> ~/Dropbox/Scripts/<dir>/<name>`.

## Tools

- `git-tools/` — git workflow helpers
  - `post_merge_cleanup.py` — safe merged-branch cleanup using patch-equivalence
    (`git cherry`) checks; deletes local + remote branch only when fully merged.
    Symlinked as `git-cleanup-merged`, so it works as `git cleanup-merged`.
    Hardened against silent hangs (stdin detached, prompts disabled, network timeouts).
  - `git-done` — switch to main, pull, and clean up the just-merged feature branch
    (uses `git-cleanup-merged`, falling back to a repo-local `scripts/post_merge_cleanup.py`).
  - `git-rb` — rebase the current branch on the head of main.
  - `git-sb` — interactively select a branch to switch to.
- `mvname/` — bulk file rename/copy tools with KiCad-aware content rewriting
  (`mvname.sh`, `cpname.sh`).
- `myping/` — ping wrapper.
- `tar2zip/` — convert tarballs to zip archives.

## Tests

```sh
python3 -m pytest tests/
```
