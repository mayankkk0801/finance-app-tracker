#!/bin/sh
set -e
cd "$(dirname "$0")/.."

PATTERN='^co-authored-by:.*(cursor|cursoragent|cursor\.com|openai|anthropic|github-copilot)'

if git log --format=%B --all | grep -qiE "$PATTERN"; then
  echo "error: Found blocked Co-authored-by trailer in commit history." >&2
  exit 1
fi

if git log --format=%B --all | grep -qiE 'cursor-related|cursoragent'; then
  echo "error: Found blocked text in a commit message." >&2
  exit 1
fi

if git grep -i cursor HEAD -- ':!.gitignore' ':!.githooks' ':!scripts' 2>/dev/null; then
  echo "error: Found blocked agent reference in app source files." >&2
  exit 1
fi

echo "Commit history and tracked files look clean."
