#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
export MUSOQ_REMOVER_SOURCE_ONLY=1
# shellcheck source=../../scripts/bash/remove.sh
source "$repo_root/scripts/bash/remove.sh"
tests=0

assert_equal() {
  local expected="$1" actual="$2" message="$3"
  ((tests+=1))
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $message (expected '$expected', got '$actual')" >&2
    exit 1
  fi
}

assert_succeeds() {
  local message="$1"
  shift
  ((tests+=1))
  if ! "$@" >/dev/null 2>&1; then
    echo "FAIL: $message" >&2
    exit 1
  fi
}

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

parse_arguments --purge
assert_equal 1 "$PURGE" "purge option is parsed"

INSTALL_DIR="$test_root/install"
MUSOQ_EXE="$INSTALL_DIR/Musoq"
LEGACY_PROFILE_PATH="$test_root/musoq.sh"
LEGACY_DATA_DIRECTORY="$test_root/legacy-data"
mkdir -p "$test_root/bin" "$test_root/regular" "$INSTALL_DIR"
printf 'binary' > "$MUSOQ_EXE"
ln -s "$MUSOQ_EXE" "$test_root/bin/Musoq"
printf 'external' > "$test_root/regular/musoq"
assert_succeeds "managed symlink is removed" remove_managed_symlink "$test_root/bin/Musoq"
assert_equal false "$([[ -L "$test_root/bin/Musoq" ]] && echo true || echo false)" "managed symlink no longer exists"
assert_succeeds "regular file is left alone" remove_managed_symlink "$test_root/regular/musoq"
assert_equal external "$(<"$test_root/regular/musoq")" "non-symlink collision is preserved"

printf 'export PATH="/opt/Musoq:$PATH"\n' > "$LEGACY_PROFILE_PATH"
assert_succeeds "managed legacy profile is removed" remove_legacy_profile
assert_equal false "$([[ -e "$LEGACY_PROFILE_PATH" ]] && echo true || echo false)" "managed profile no longer exists"
printf 'custom profile\n' > "$LEGACY_PROFILE_PATH"
assert_succeeds "custom profile is preserved" remove_legacy_profile
assert_equal custom\ profile "$(<"$LEGACY_PROFILE_PATH")" "custom profile content remains"

user_home="$test_root/user"
mkdir -p "$user_home/.musoq" "$user_home/.config/musoq" "$LEGACY_DATA_DIRECTORY"
printf 'plugin' > "$user_home/.musoq/plugin.txt"
printf 'config' > "$user_home/.config/musoq/appsettings.json"
assert_succeeds "purge removes documented user data" purge_user_data "$user_home"
assert_equal false "$([[ -e "$user_home/.musoq" ]] && echo true || echo false)" "plugin data is purged"
assert_equal false "$([[ -e "$user_home/.config/musoq" ]] && echo true || echo false)" "configuration data is purged"
if [[ "$(uname -s)" == Linux ]]; then
  assert_equal false "$([[ -e "$LEGACY_DATA_DIRECTORY" ]] && echo true || echo false)" "legacy Linux data is purged"
else
  assert_equal true "$([[ -e "$LEGACY_DATA_DIRECTORY" ]] && echo true || echo false)" "legacy Linux data is not touched on macOS"
fi

echo "PASS: $tests Bash remover assertions"
