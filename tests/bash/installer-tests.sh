#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
export MUSOQ_INSTALLER_SOURCE_ONLY=1
# shellcheck source=../../scripts/bash/install.sh
source "$repo_root/scripts/bash/install.sh"
fixtures=$(<"$repo_root/tests/fixtures/releases.json")
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

file_mode() {
  if stat -c '%a' "$1" >/dev/null 2>&1; then
    stat -c '%a' "$1"
  else
    stat -f '%Lp' "$1"
  fi
}

assert_fails() {
  local message="$1"
  shift
  ((tests+=1))
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $message" >&2
    exit 1
  fi
}

assert_equal "0.40.0-alpha.1" "$(normalize_semver v0.40.0-alpha.1)" "leading v is normalized"
assert_equal "alpha" "$(semver_channel 0.40.0-alpha.1)" "alpha channel is parsed"
assert_equal "stable" "$(semver_channel 0.40.0)" "stable channel is parsed"
assert_fails "leading-zero prerelease is invalid" validate_semver 1.0.0-alpha.01
assert_equal "1" "$(semver_compare 1.3.0-alpha.10 1.3.0-alpha.2)" "numeric prerelease precedence"
assert_equal "-1" "$(semver_compare 1.3.0-alpha.10 1.3.0-beta.1)" "identifier precedence"
assert_equal "1" "$(semver_compare 1.3.0 1.3.0-rc.1)" "stable outranks prerelease"

alpha=$(select_release_for_channel "$fixtures" alpha)
assert_equal "1.3.0-alpha.10" "$(jq -r .tag_name <<< "$alpha")" "highest exact alpha is selected"
assert_equal "1.3.0-beta.3" "$(jq -r .tag_name <<< "$(select_release_for_channel "$fixtures" beta)")" "beta remains isolated"
assert_equal "1.3.0-rc.1" "$(jq -r .tag_name <<< "$(select_release_for_channel "$fixtures" rc)")" "rc remains isolated"
assert_equal "1.2.0" "$(jq -r .tag_name <<< "$(select_release_for_channel "$fixtures" stable)")" "stable remains isolated"
assert_fails "custom channel is rejected" is_supported_channel preview
assert_fails "version and channel conflict" parse_arguments --version 1.2.0 --channel alpha

parse_arguments --channel ALPHA
assert_equal "alpha" "$CHANNEL" "channel input is case-insensitive"
parse_arguments --version v1.3.0-preview.3
assert_equal "v1.3.0-preview.3" "$VERSION" "custom exact input is preserved until normalization"

assert_equal "Musoq-linux-x64.zip" "$(get_platform_asset_name linux x64)" "linux x64 asset mapping"
assert_equal "Musoq-linux-arm64.zip" "$(get_platform_asset_name linux arm64)" "linux arm64 asset mapping"
assert_equal "Musoq-alpine-x64.zip" "$(get_platform_asset_name alpine x64)" "alpine asset mapping"
assert_equal "Musoq-osx-x64.zip" "$(get_platform_asset_name osx x64)" "macOS asset mapping"
assert_fails "unsupported platform is rejected" get_platform_asset_name alpine arm64

asset=$(select_asset "$alpha" Musoq-linux-x64.zip)
assert_equal "Musoq-linux-x64.zip" "$(jq -r .name <<< "$asset")" "asset selection is exact"
assert_fails "AgentLocal name is not accepted as Musoq" select_asset "$alpha" Musoq.Cloud.AgentLocal.Api-linux-arm64.zip

temp_file=$(mktemp)
test_root=$(mktemp -d)
trap 'rm -f "$temp_file"; rm -rf "$test_root"' EXIT
printf 'musoq-test' > "$temp_file"
digest="sha256:$(calculate_sha256 "$temp_file")"
assert_succeeds "valid digest passes" verify_asset_digest "$temp_file" "$digest"
assert_fails "invalid digest fails" verify_asset_digest "$temp_file" "sha256:0000"
assert_fails "missing digest is rejected" verify_asset_digest "$temp_file" ""

staging_directory=$(create_staging_directory "$test_root")
assert_equal "700" "$(file_mode "$staging_directory")" "staging directory is private"
mkdir -p "$staging_directory/payload/DataSources"
printf '#!/bin/sh\n' > "$staging_directory/payload/Musoq"
printf 'data' > "$staging_directory/payload/DataSources/asset.txt"
set_install_modes "$staging_directory/payload"
assert_equal "755" "$(file_mode "$staging_directory/payload")" "install directory mode is immutable"
assert_equal "755" "$(file_mode "$staging_directory/payload/Musoq")" "executable mode is preserved"
assert_equal "644" "$(file_mode "$staging_directory/payload/DataSources/asset.txt")" "data files are not world writable"

managed_symlink_paths() { printf '%s\n' "$test_root/bin/Musoq" "$test_root/bin/musoq"; }
mkdir -p "$test_root/bin" "$test_root/install"
MUSOQ_EXE="$test_root/install/Musoq"
touch "$MUSOQ_EXE" "$test_root/bin/Musoq"
assert_fails "regular symlink collision is rejected" preflight_managed_symlinks
rm "$test_root/bin/Musoq"
assert_succeeds "managed symlinks are created" install_managed_symlinks
assert_succeeds "managed symlinks pass preflight" preflight_managed_symlinks

INSTALL_DIR="$test_root/transaction/Musoq"
MUSOQ_EXE="$INSTALL_DIR/Musoq"
managed_symlink_paths() { printf '%s\n' "$test_root/transaction-bin/Musoq" "$test_root/transaction-bin/musoq"; }
mkdir -p "$INSTALL_DIR" "$test_root/transaction-bin" "$test_root/prepared-success"
printf 'old' > "$INSTALL_DIR/Musoq"
printf 'new' > "$test_root/prepared-success/Musoq"
assert_succeeds "prepared install replaces existing tree" replace_installation "$test_root/prepared-success"
assert_equal "new" "$(<"$INSTALL_DIR/Musoq")" "replacement activates the prepared tree"

mkdir -p "$test_root/prepared-failure"
printf 'old-again' > "$INSTALL_DIR/Musoq"
printf 'new-but-failing' > "$test_root/prepared-failure/Musoq"
install_managed_symlinks() { return 1; }
assert_fails "failed post-swap action restores previous tree" replace_installation "$test_root/prepared-failure"
assert_equal "old-again" "$(<"$INSTALL_DIR/Musoq")" "failed replacement restores previous tree"

github_get() {
  case "$1" in
    */releases/latest) jq -c 'map(select(.tag_name == "1.2.0"))[0]' <<< "$fixtures" ;;
    */releases/tags/1.3.0-alpha.10) jq -c 'map(select(.tag_name == "1.3.0-alpha.10"))[0]' <<< "$fixtures" ;;
    *releases\?*) printf '%s\n' "$fixtures" ;;
    *) return 1 ;;
  esac
}
assert_equal "1.2.0" "$(jq -r .tag_name <<< "$(fetch_release_for_channel stable)")" "stable API resolution"
assert_equal "1.3.0-alpha.10" "$(jq -r .tag_name <<< "$(fetch_release_for_channel alpha)")" "paginated channel resolution"
assert_equal "1.3.0-alpha.10" "$(jq -r .tag_name <<< "$(fetch_release_by_version 1.3.0-alpha.10)")" "exact tag resolution"

assert_equal "0.40.0-alpha.1" "$(extract_installed_version 'Musoq 0.40.0-alpha.1')" "complete installed version is parsed"

echo "PASS: $tests Bash installer assertions"
