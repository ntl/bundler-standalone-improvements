#!/usr/bin/env bash

set -eEuo pipefail

trap 'printf "\n\e[31mError: Exit Status %s (%s)\e[m\n" $? "$(basename "$0")"' ERR

cd "$(dirname "$0")"

echo
echo "Start ($(basename "$0"))"

run-cmd() {
  cmd="$1"
  echo "+ $cmd"
  eval "$cmd"
}

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

run-cmd "rm -rvf .bundle/"

if [ "$reinstall_gems" != "none" ]; then
  echo
  echo "Removing Lock File"
  echo "- - -"

  run-cmd "rm -vf Gemfile.lock"

  if [ "$reinstall_gems" != "outdated" ]; then
    echo
    echo "Removing Previously Installed Gems"
    echo "- - -"

    run-cmd "rm -rf $gems_dir"
  fi
fi

echo
echo "Configuring Bundler"
echo "- - -"

run-cmd "bundle config set --local path $gems_dir"

if [ "$posture" = "operational" ]; then
  run-cmd "bundle config set --local without development:test"
fi

echo
echo "Installing Bundle"
echo "- - -"

run-cmd "bundle add rubygems-runtime --skip-install"

run-cmd "bundle install --standalone"

run-cmd "bundle binstubs --all --path=$gems_dir/exec --standalone"

echo
echo "Generating $gems_dir/lib/"
echo "- - -"

rubygems_runtime_dir="$(bundle show rubygems-runtime)"

run-cmd "rm -rf $gems_dir/lib && mkdir -p $gems_dir/lib/bundler"

run-cmd "cp -r $rubygems_runtime_dir/* $gems_dir"

run-cmd "$(cat <<'SH'
sed -n \
  -e '1i\
lib_dir = File.expand_path("..", __dir__)\
$:.unshift(lib_dir) unless $:.include?(lib_dir)\
require "rubygems/runtime"\

' -e 's|\.\./|../../|' \
  -e '/$rubygems_runtime_dir/d' \
  -e '/RUBY_ENGINE/ s/^\$:.unshift/$:.push/p' \
  -e '/^\$:.unshift/p' \
  $gems_dir/bundler/setup.rb > $gems_dir/lib/bundler/setup.rb
SH
)"

run-cmd "rm -rf $gems_dir/bundler"

run-cmd "bundle remove rubygems-runtime"

echo
echo "Gem installation is complete. Verify the standalone bundle:"
echo
echo "    ruby --disable-rubyopt --disable-gems -I./gems/lib -rbundler/setup -e 'require \"some_installed_gem\"'"

echo
echo "Done ($(basename "$0"))"
