#!/usr/bin/env bash

set -euo pipefail

: "${PACKAGES:=--all}"
: "${TARGET_BRANCH:=master}"

git checkout "$TARGET_BRANCH"
nix develop --command forge-update "$PACKAGES" --commit 2>&1 | tee /tmp/update-all.log

# Save commit-list of updated packages
git log --reverse origin/"$TARGET_BRANCH"..HEAD --format="%H %s" \
  | grep "recipes(" \
  > /tmp/commits.txt || true
