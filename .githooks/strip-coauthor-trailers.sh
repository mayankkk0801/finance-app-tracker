#!/bin/sh
# Removes Co-authored-by trailers for automated agents from commit messages.

MSG_FILE=$1

if [ -z "$MSG_FILE" ] || [ ! -f "$MSG_FILE" ]; then
  exit 0
fi

if ! grep -qiE '^co-authored-by:.*(cursor|cursoragent|cursor\.com|openai|anthropic|github-copilot)' "$MSG_FILE"; then
  exit 0
fi

tmp=$(mktemp)
grep -viE '^co-authored-by:.*(cursor|cursoragent|cursor\.com|openai|anthropic|github-copilot)' "$MSG_FILE" >"$tmp" || true
cat "$tmp" >"$MSG_FILE"
rm -f "$tmp"
