# Worktree workflow — parallel Claude Code sessions, one branch + draft PR per worktree.
# Source from ~/.zshrc.

# --- helpers --------------------------------------------------------------

# Returns the main worktree path of the current git repo (the first entry in `git worktree list`).
_wt_main_path() {
  git worktree list --porcelain 2>/dev/null | awk '/^worktree / { print $2; exit }'
}

# Encodes a cwd path the same way Claude Code does for `~/.claude/projects/`:
# leading slash dropped, every non-alphanumeric replaced with `-`.
_wt_encode_path() {
  print -r -- "-$(print -r -- "$1" | sed 's#^/##; s#[^A-Za-z0-9]#-#g')"
}

# mtime of the most recently modified JSONL session file for a worktree path.
# Output: epoch seconds, or empty if no session yet.
_wt_last_activity() {
  setopt local_options nullglob
  local worktree_path="$1"
  local encoded
  encoded="$(_wt_encode_path "$worktree_path")"
  local dir="$HOME/.claude/projects/$encoded"
  [ -d "$dir" ] || return 0
  local files=("$dir"/*.jsonl)
  (( ${#files[@]} )) || return 0
  stat -f %m "${files[@]}" 2>/dev/null | sort -nr | head -1
}

# Pretty-print a relative age from an epoch.
_wt_relative_age() {
  local then="$1"
  [ -z "$then" ] && { print -r -- "—"; return; }
  local now=$(date +%s)
  local diff=$((now - then))
  if   [ $diff -lt 60 ];     then print -r -- "${diff}s ago"
  elif [ $diff -lt 3600 ];   then print -r -- "$((diff/60))m ago"
  elif [ $diff -lt 86400 ];  then print -r -- "$((diff/3600))h ago"
  else                            print -r -- "$((diff/86400))d ago"
  fi
}

# --- main commands --------------------------------------------------------

# wt <name>  — spawn a new Claude session in a worktree under .claude/worktrees/<name>/
wt() {
  if [ -z "${1:-}" ]; then
    print -u2 -- "usage: wt <name>"
    return 1
  fi
  local main
  main="$(_wt_main_path)"
  if [ -z "$main" ]; then
    print -u2 -- "wt: not inside a git repo"
    return 1
  fi
  (cd "$main" && claude -w "$1")
}

# wt-resume <name>  — re-attach to the last Claude session in an existing worktree
wt-resume() {
  if [ -z "${1:-}" ]; then
    print -u2 -- "usage: wt-resume <name>"
    return 1
  fi
  local main
  main="$(_wt_main_path)"
  local target="$main/.claude/worktrees/$1"
  if [ ! -d "$target" ]; then
    print -u2 -- "wt-resume: no worktree at $target"
    return 1
  fi
  (cd "$target" && claude --continue)
}

# wt-jump  — fzf picker over existing worktrees; cd into the chosen one
wt-jump() {
  command -v fzf >/dev/null || { print -u2 -- "wt-jump: fzf required"; return 1; }
  local choice
  choice="$(git worktree list --porcelain 2>/dev/null \
    | awk '/^worktree / { wp=$2 } /^branch / { print wp "\t" substr($2, length("refs/heads/")+1) } /^detached/ { print wp "\t(detached)" }' \
    | fzf --with-nth=2.. --delimiter=$'\t' \
        --preview 'git -C {1} -c color.status=always status -sb 2>/dev/null; echo; git -C {1} log --oneline -5 2>/dev/null' \
        --preview-window=right:60%)"
  [ -z "$choice" ] && return 0
  local dir
  dir="$(print -r -- "$choice" | awk -F'\t' '{ print $1 }')"
  cd "$dir"
}

# wt-pr [name]  — push current (or named) worktree branch and create a draft PR
wt-pr() {
  local main target branch
  main="$(_wt_main_path)"
  if [ -n "${1:-}" ]; then
    target="$main/.claude/worktrees/$1"
    [ -d "$target" ] || { print -u2 -- "wt-pr: no worktree at $target"; return 1; }
  else
    target="$PWD"
  fi
  branch="$(git -C "$target" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  [ -z "$branch" ] && { print -u2 -- "wt-pr: detached HEAD"; return 1; }
  git -C "$target" push -u origin "$branch" || return $?
  if gh -R "$(git -C "$target" config --get remote.origin.url)" pr view "$branch" --json number >/dev/null 2>&1; then
    print -- "wt-pr: PR already exists for $branch"
    (cd "$target" && gh pr view --web)
  else
    (cd "$target" && gh pr create --draft --fill)
  fi
}

# wt-rm [name]  — remove a worktree + its branch (fzf if no arg)
wt-rm() {
  local main name target branch
  main="$(_wt_main_path)"
  if [ -n "${1:-}" ]; then
    name="$1"
  else
    command -v fzf >/dev/null || { print -u2 -- "wt-rm: fzf required when no arg"; return 1; }
    name="$(ls "$main/.claude/worktrees/" 2>/dev/null | fzf --prompt='remove worktree> ')"
    [ -z "$name" ] && return 0
  fi
  target="$main/.claude/worktrees/$name"
  [ -d "$target" ] || { print -u2 -- "wt-rm: no worktree at $target"; return 1; }
  branch="$(git -C "$target" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  print -- "About to remove:"
  print -- "  worktree: $target"
  print -- "  branch:   $branch"
  print -n -- "Proceed? [y/N] "
  read -r answer
  [ "$answer" = "y" ] || [ "$answer" = "Y" ] || return 0
  git -C "$main" worktree remove --force "$target"
  if [ -n "$branch" ]; then
    git -C "$main" branch -D "$branch" 2>/dev/null || true
  fi
  git -C "$main" worktree prune
}

# wt-status  — table of all worktrees with branch, dirty, last claude activity, PR state
wt-status() {
  local main
  main="$(_wt_main_path)"
  [ -z "$main" ] && { print -u2 -- "wt-status: not inside a git repo"; return 1; }
  local remote_slug
  remote_slug="$(git -C "$main" config --get remote.origin.url 2>/dev/null \
    | sed -E 's#.*github.com[:/]([^/]+/[^/.]+)(\.git)?#\1#')"
  printf "%-24s %-32s %-7s %-14s %s\n" "NAME" "BRANCH" "DIRTY" "LAST CLAUDE" "PR"
  printf "%-24s %-32s %-7s %-14s %s\n" "----" "------" "-----" "-----------" "--"
  local wp branch dirty age pr_state name
  git worktree list --porcelain 2>/dev/null | awk '
    /^worktree / { wp=$2 }
    /^branch / { print wp "\t" substr($2, length("refs/heads/")+1) }
    /^detached/ { print wp "\t-" }
  ' | while IFS=$'\t' read -r wp branch; do
    [ -z "$wp" ] && continue
    if [ "$wp" = "$main" ]; then
      name="(main)"
    else
      name="${wp##*/}"
    fi
    if [ -n "$(git -C "$wp" status --porcelain 2>/dev/null)" ]; then
      dirty="*"
    else
      dirty="-"
    fi
    age="$(_wt_relative_age "$(_wt_last_activity "$wp")")"
    pr_state="—"
    if [ -n "$remote_slug" ] && [ "$branch" != "-" ]; then
      pr_state="$(gh -R "$remote_slug" pr list --head "$branch" --json number,state,isDraft --limit 1 2>/dev/null \
        | python3 -c 'import json,sys
data=json.load(sys.stdin)
if not data:
    print("—")
else:
    pr=data[0]
    suffix=" (draft)" if pr.get("isDraft") else ""
    print(f"#{pr[\"number\"]} {pr[\"state\"]}{suffix}")' 2>/dev/null)"
      [ -z "$pr_state" ] && pr_state="—"
    fi
    printf "%-24s %-32s %-7s %-14s %s\n" "$name" "$branch" "$dirty" "$age" "$pr_state"
  done
}

# wt-init  — one-time setup on the main repo: disable gc.auto, ensure .worktreeinclude
wt-init() {
  local main
  main="$(_wt_main_path)"
  [ -z "$main" ] && { print -u2 -- "wt-init: not inside a git repo"; return 1; }
  git -C "$main" config gc.auto 0
  git -C "$main" config maintenance.auto false
  if [ ! -f "$main/.worktreeinclude" ]; then
    print -u2 -- "wt-init: .worktreeinclude missing — create it at repo root"
  fi
  print -- "wt-init: configured ${main}"
  print -- "  gc.auto = $(git -C "$main" config --get gc.auto)"
  print -- "  maintenance.auto = $(git -C "$main" config --get maintenance.auto)"
  print -- "  .worktreeinclude = $([ -f "$main/.worktreeinclude" ] && echo present || echo MISSING)"
}

# wt-prune  — drop worktree dirs marked prunable + delete already-merged worktree-* branches
wt-prune() {
  local main
  main="$(_wt_main_path)"
  [ -z "$main" ] && { print -u2 -- "wt-prune: not inside a git repo"; return 1; }
  git -C "$main" worktree prune --verbose
  git -C "$main" branch --merged origin/master 2>/dev/null \
    | grep -E '^\s+worktree-' \
    | xargs -I{} git -C "$main" branch -d {} 2>/dev/null || true
}
