#!/usr/bin/env bash

set -eEuo pipefail

trap 'printf "\n\e[31mError: Exit Status %s (%s)\e[m\n" $? "$(basename "$0")"' ERR

cd "$(dirname "$0")"

echo
echo "Start ($(basename "$0"))"

echo
echo "Install Gems"
echo "= = ="

if [ -z "${POSTURE:-}${REINSTALL_GEMS:-}" ]; then
  echo
fi

if [ -z "${POSTURE:-}" ]; then
  echo "POSTURE is not set. Using \"$POSTURE\" by default."
  posture="operational"
else
  posture="$POSTURE"
fi

if [ -z ${REINSTALL_GEMS:-} ]; then
  echo "REINSTALL_GEMS is not set. Using \"all\" by default; other values are \"outdated\" and \"none\""
  reinstall_gems="all"
else
  reinstall_gems="$REINSTALL_GEMS"
fi

gems_dir="gems"

echo
echo "Posture: $posture"
echo "Reinstall Gems: $reinstall_gems"
echo "Gems Directory: $gems_dir"

echo
echo "Removing Bundler Configuration"
echo "- - -"

cmd="rm -rvf .bundle/"
echo "$cmd"
eval "$cmd"

if [ "$reinstall_gems" != "none" ]; then
  echo
  echo "Removing Lock File"
  echo "- - -"

  cmd="rm -vf Gemfile.lock"
  echo "$cmd"
  eval "$cmd"

  if [ "$reinstall_gems" != "outdated" ]; then
    echo
    echo "Removing Previously Installed Gems"
    echo "- - -"

    cmd="rm -rf $gems_dir"
    echo "$cmd"
    eval "$cmd"
  fi
fi

echo
echo "Configuring Bundler"
echo "- - -"

cmd="bundle config set --local path $gems_dir"
echo "$cmd"
eval "$cmd"

if [ "$posture" = "operational" ]; then
  cmd="bundle config set --local without development:test"
  echo "$cmd"
  eval "$cmd"
fi

echo
echo "Installing Bundle"
echo "- - -"

cmd="bundle add rubygems-runtime --skip-install"
echo "$cmd"
eval "$cmd"

cmd="bundle install --standalone"
echo "$cmd"
eval "$cmd"

cmd="bundle binstubs --all --path=$gems_dir/exec --standalone"
echo "$cmd"
eval "$cmd"

echo
echo "Generating $gems_dir/lib Directory"
echo "- - -"

rubygems_runtime_dir="$(bundle show rubygems-runtime)"

cmd="rm -rf $gems_dir/lib && mkdir -p $gems_dir/lib/bundler"
echo "$cmd"
eval "$cmd"

cmd="cp -r $rubygems_runtime_dir/* $gems_dir"
echo "$cmd"
eval "$cmd"

cmd="$(cat <<'SH'
sed -n \
  -e '1i\
require "rubygems/runtime"
' -e 's|\.\./|../../|' \
  -e '/$rubygems_runtime_dir/d' \
  -e '/RUBY_ENGINE/ s/^\$:.unshift/$:.push/p' \
  -e '/^\$:.unshift/p' \
  $gems_dir/bundler/setup.rb > $gems_dir/lib/bundler/setup.rb
SH
)"
echo "$cmd"
eval "$cmd"

cmd="rm -rf $gems_dir/bundler"
echo "$cmd"
eval "$cmd"

cmd="bundle remove rubygems-runtime"
echo "$cmd"
eval "$cmd"

echo
echo "Done ($(basename "$0"))"
