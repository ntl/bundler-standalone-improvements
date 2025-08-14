#!/usr/bin/env bash

set -eEuo pipefail

trap 'printf "\n\e[31mError: Exit Status %s (%s)\e[m\n" $? "$(basename "$0")"' ERR

cd "$(dirname "$0")"

echo
echo "Start ($(basename "$0"))"

echo
echo "Setup"
echo "= = ="

examples=(
  "snap-ci/sample-rails-app-sqlite.git"
)

for example in "${examples[@]}"; do
  dir="$(basename "$example" ".git")"

  if [ ! -d examples/$dir ]; then
    git -C examples clone --depth 1 --single-branch --no-tags https://github.com/$example
  else
    git -C examples/$dir pull --verbose --rebase
  fi
done

echo
echo "Done ($(basename "$0"))"
