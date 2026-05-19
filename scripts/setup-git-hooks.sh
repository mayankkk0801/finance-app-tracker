#!/bin/sh
set -e
cd "$(dirname "$0")/.."

chmod +x .githooks/commit-msg .githooks/prepare-commit-msg .githooks/strip-coauthor-trailers.sh
git config core.hooksPath .githooks

echo "Git hooks enabled. Agent co-author trailers will be stripped from commits."
