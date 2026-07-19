#!/usr/bin/env bash

set -o pipefail
export LC_ALL=C

REPO_OWNER="Puchaczov"
REPO_NAME="Musoq.CLI"
INSTALL_DIR="/opt/Musoq"
MUSOQ_EXE="$INSTALL_DIR/Musoq"
INSTALLER_URL="https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/bash/install.sh"
SUPPORTED_CHANNELS=(stable alpha beta rc)
SEMVER_PATTERN='(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?'

VERSION=""
CHANNEL=""
DEBUG=0

usage() {
  cat <<'EOF'
Usage: install.sh [--debug|-d] [--version|-v <semver> | --channel|-c <channel>]

Channels: stable, alpha, beta, rc. The default channel is stable.
EOF
}

fail() {
  echo "Error: $*" >&2
  return 1
}

parse_arguments() {
  VERSION=""
  CHANNEL=""
  DEBUG=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--debug)
        DEBUG=1
        shift
        ;;
      -v|--version)
        [[ $# -ge 2 ]] || { fail "$1 requires a version."; return 2; }
        VERSION="$2"
        shift 2
        ;;
      --version=*)
        VERSION="${1#*=}"
        shift
        ;;
      -c|--channel)
        [[ $# -ge 2 ]] || { fail "$1 requires a channel."; return 2; }
        CHANNEL="${2,,}"
        shift 2
        ;;
      --channel=*)
        CHANNEL="${1#*=}"
        CHANNEL="${CHANNEL,,}"
        shift
        ;;
      -h|--help)
        usage
        return 64
        ;;
      --)
        shift
        [[ $# -eq 0 ]] || { fail "Unexpected arguments: $*"; return 2; }
        ;;
      *)
        fail "Unknown option '$1'."
        usage >&2
        return 2
        ;;
    esac
  done

  if [[ -n "$VERSION" && -n "$CHANNEL" ]]; then
    fail "--version and --channel are mutually exclusive."
    return 2
  fi

  if [[ -z "$VERSION" ]]; then
    CHANNEL="${CHANNEL:-stable}"
    is_supported_channel "$CHANNEL" || {
      fail "Unsupported channel '$CHANNEL'. Expected stable, alpha, beta, or rc."
      return 2
    }
  fi
}

is_supported_channel() {
  local candidate="${1,,}"
  local channel
  for channel in "${SUPPORTED_CHANNELS[@]}"; do
    [[ "$candidate" == "$channel" ]] && return 0
  done
  return 1
}

normalize_semver() {
  local version="${1#v}"
  validate_semver "$version" || return 1
  printf '%s\n' "$version"
}

validate_semver() {
  local version="$1"
  local regex="^${SEMVER_PATTERN}$"
  [[ "$version" =~ $regex ]] || return 1

  local without_build="${version%%+*}"
  if [[ "$without_build" == *-* ]]; then
    local prerelease="${without_build#*-}"
    local identifier
    IFS='.' read -r -a identifiers <<< "$prerelease"
    for identifier in "${identifiers[@]}"; do
      if [[ "$identifier" =~ ^[0-9]+$ && ${#identifier} -gt 1 && "$identifier" == 0* ]]; then
        return 1
      fi
    done
  fi
}

semver_channel() {
  local version
  version=$(normalize_semver "$1") || return 1
  local without_build="${version%%+*}"
  if [[ "$without_build" != *-* ]]; then
    printf 'stable\n'
    return
  fi

  local prerelease="${without_build#*-}"
  printf '%s\n' "${prerelease%%.*}"
}

compare_numeric_identifiers() {
  local left="$1"
  local right="$2"
  if (( ${#left} < ${#right} )); then echo -1; return; fi
  if (( ${#left} > ${#right} )); then echo 1; return; fi
  if [[ "$left" < "$right" ]]; then echo -1
  elif [[ "$left" > "$right" ]]; then echo 1
  else echo 0
  fi
}

semver_compare() {
  local left right
  left=$(normalize_semver "$1") || return 1
  right=$(normalize_semver "$2") || return 1
  left="${left%%+*}"
  right="${right%%+*}"

  local left_core="${left%%-*}" right_core="${right%%-*}"
  local left_pre="" right_pre=""
  [[ "$left" == *-* ]] && left_pre="${left#*-}"
  [[ "$right" == *-* ]] && right_pre="${right#*-}"

  local -a left_parts right_parts
  IFS='.' read -r -a left_parts <<< "$left_core"
  IFS='.' read -r -a right_parts <<< "$right_core"
  local index comparison
  for index in 0 1 2; do
    comparison=$(compare_numeric_identifiers "${left_parts[$index]}" "${right_parts[$index]}")
    [[ "$comparison" != 0 ]] && { echo "$comparison"; return; }
  done

  [[ -z "$left_pre" && -z "$right_pre" ]] && { echo 0; return; }
  [[ -z "$left_pre" ]] && { echo 1; return; }
  [[ -z "$right_pre" ]] && { echo -1; return; }

  local -a left_ids right_ids
  IFS='.' read -r -a left_ids <<< "$left_pre"
  IFS='.' read -r -a right_ids <<< "$right_pre"
  local count=${#left_ids[@]}
  (( ${#right_ids[@]} > count )) && count=${#right_ids[@]}

  for ((index=0; index<count; index++)); do
    [[ $index -ge ${#left_ids[@]} ]] && { echo -1; return; }
    [[ $index -ge ${#right_ids[@]} ]] && { echo 1; return; }

    local left_id="${left_ids[$index]}" right_id="${right_ids[$index]}"
    [[ "$left_id" == "$right_id" ]] && continue
    if [[ "$left_id" =~ ^[0-9]+$ && "$right_id" =~ ^[0-9]+$ ]]; then
      compare_numeric_identifiers "$left_id" "$right_id"
      return
    fi
    [[ "$left_id" =~ ^[0-9]+$ ]] && { echo -1; return; }
    [[ "$right_id" =~ ^[0-9]+$ ]] && { echo 1; return; }
    [[ "$left_id" < "$right_id" ]] && echo -1 || echo 1
    return
  done
  echo 0
}

validate_release_metadata() {
  local release_json="$1"
  local expected_version="${2:-}"
  local expected_channel="${3:-}"
  local tag version channel prerelease
  tag=$(jq -r '.tag_name // empty' <<< "$release_json")
  [[ -n "$tag" ]] || { fail "GitHub returned a release without a tag."; return 1; }
  version=$(normalize_semver "$tag") || { fail "Release tag '$tag' is not valid SemVer."; return 1; }
  channel=$(semver_channel "$version") || return 1
  prerelease=$(jq -r '.prerelease // false' <<< "$release_json")

  if [[ "$channel" == stable && "$prerelease" != false ]]; then
    fail "Release '$tag' is marked prerelease but has a stable tag."
    return 1
  fi
  if [[ "$channel" != stable && "$prerelease" != true ]]; then
    fail "Release '$tag' has a prerelease tag but is not marked as a GitHub prerelease."
    return 1
  fi
  if [[ -n "$expected_version" && "$version" != "$expected_version" ]]; then
    fail "GitHub returned '$tag' while '$expected_version' was requested."
    return 1
  fi
  if [[ -n "$expected_channel" && "$channel" != "$expected_channel" ]]; then
    fail "Release '$tag' belongs to channel '$channel', not '$expected_channel'."
    return 1
  fi

  printf '%s\n' "$version"
}

select_release_for_channel() {
  local releases_json="$1"
  local requested_channel="${2,,}"
  is_supported_channel "$requested_channel" || return 1

  local selected="" selected_version="" release tag version channel prerelease comparison
  while IFS= read -r release; do
    tag=$(jq -r '.tag_name // empty' <<< "$release")
    version=$(normalize_semver "$tag" 2>/dev/null) || continue
    channel=$(semver_channel "$version") || continue
    prerelease=$(jq -r '.prerelease // false' <<< "$release")
    [[ "$channel" == "$requested_channel" ]] || continue
    if [[ "$channel" == stable ]]; then
      [[ "$prerelease" == false ]] || continue
    else
      [[ "$prerelease" == true ]] || continue
    fi

    if [[ -z "$selected" ]]; then
      selected="$release"
      selected_version="$version"
      continue
    fi
    comparison=$(semver_compare "$version" "$selected_version") || continue
    if (( comparison > 0 )); then
      selected="$release"
      selected_version="$version"
    fi
  done < <(jq -c '.[] | select(.draft != true)' <<< "$releases_json")

  [[ -n "$selected" ]] || {
    fail "No published release is available for channel '$requested_channel'."
    return 1
  }
  printf '%s\n' "$selected"
}

github_get() {
  curl -fsSL -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' "$1"
}

fetch_release_by_version() {
  local version encoded release
  version=$(normalize_semver "$1") || { fail "Invalid SemVer '$1'."; return 1; }
  encoded=$(printf '%s' "$version" | jq -sRr @uri)
  release=$(github_get "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/tags/$encoded") || {
    fail "Release version '$version' was not found on GitHub."
    return 1
  }
  validate_release_metadata "$release" "$version" >/dev/null || return 1
  printf '%s\n' "$release"
}

fetch_release_for_channel() {
  local requested_channel="${1,,}"
  if [[ "$requested_channel" == stable ]]; then
    local release
    release=$(github_get "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest") || {
      fail "No latest stable release was found on GitHub."
      return 1
    }
    validate_release_metadata "$release" "" stable >/dev/null || return 1
    printf '%s\n' "$release"
    return
  fi

  local page=1 page_json page_count all_releases='[]'
  while :; do
    page_json=$(github_get "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases?per_page=100&page=$page") || {
      fail "Failed to fetch release page $page from GitHub."
      return 1
    }
    page_count=$(jq 'length' <<< "$page_json")
    all_releases=$(jq -cn --argjson existing "$all_releases" --argjson page "$page_json" '$existing + $page')
    (( page_count < 100 )) && break
    ((page++))
  done
  select_release_for_channel "$all_releases" "$requested_channel"
}

extract_installed_version() {
  local output="$1" candidate
  while IFS= read -r candidate; do
    candidate="${candidate#v}"
    if validate_semver "$candidate"; then
      printf '%s\n' "$candidate"
      return
    fi
  done < <(grep -Eo "v?${SEMVER_PATTERN}" <<< "$output" || true)
  return 1
}

get_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo x64 ;;
    aarch64|arm64) echo arm64 ;;
    *) echo unsupported ;;
  esac
}

get_os() {
  if [[ "$(uname -s)" == Darwin ]]; then echo osx
  elif [[ -f /etc/alpine-release ]]; then echo alpine
  else echo linux
  fi
}

get_platform_asset_name() {
  local os="${1:-$(get_os)}"
  local arch="${2:-$(get_arch)}"
  case "$os-$arch" in
    linux-x64) echo Musoq-linux-x64.zip ;;
    linux-arm64) echo Musoq-linux-arm64.zip ;;
    alpine-x64) echo Musoq-alpine-x64.zip ;;
    osx-x64) echo Musoq-osx-x64.zip ;;
    *) fail "Unsupported platform '$os-$arch'."; return 1 ;;
  esac
}

select_asset() {
  local release_json="$1"
  local expected_name="$2"
  local count asset size
  count=$(jq --arg name "$expected_name" '[.assets[]? | select(.name == $name)] | length' <<< "$release_json")
  [[ "$count" == 1 ]] || {
    fail "Expected exactly one '$expected_name' asset, found $count."
    return 1
  }
  asset=$(jq -c --arg name "$expected_name" '.assets[] | select(.name == $name)' <<< "$release_json")
  size=$(jq -r '.size // 0' <<< "$asset")
  (( size > 0 )) || { fail "Asset '$expected_name' is empty."; return 1; }
  printf '%s\n' "$asset"
}

calculate_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print tolower($1)}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print tolower($1)}'
  else
    fail "Neither sha256sum nor shasum is available."
    return 1
  fi
}

verify_asset_digest() {
  local file="$1"
  local digest="${2:-}"
  if [[ -z "$digest" || "$digest" == null ]]; then
    echo "Warning: release asset has no GitHub digest; continuing for legacy compatibility." >&2
    return 0
  fi
  [[ "$digest" == sha256:* ]] || { fail "Unsupported asset digest '$digest'."; return 1; }
  local expected="${digest#sha256:}" actual
  actual=$(calculate_sha256 "$file") || return 1
  [[ "${actual,,}" == "${expected,,}" ]] || {
    fail "SHA-256 mismatch for '$(basename "$file")'."
    return 1
  }
}

check_dependencies() {
  local command
  for command in curl jq unzip uname; do
    command -v "$command" >/dev/null 2>&1 || { fail "Missing dependency: $command"; return 1; }
  done

  [[ "$(uname -s)" == Darwin ]] && return 0
  if [[ -f /etc/alpine-release ]]; then
    apk add --no-cache libstdc++ libgcc icu-libs
  elif [[ -f /etc/debian_version ]]; then
    apt-get update && apt-get install -y libicu-dev
  elif [[ -f /etc/redhat-release ]]; then
    if command -v dnf >/dev/null 2>&1; then dnf install -y libicu
    elif command -v yum >/dev/null 2>&1; then yum install -y libicu
    else fail "Neither dnf nor yum is available."; return 1
    fi
  elif [[ -f /etc/arch-release ]]; then
    pacman -Sy --noconfirm icu
  fi
}

stop_musoq() {
  echo "Stopping running Musoq instance if it exists..."
  pkill -f Musoq 2>/dev/null || true
  sleep 5
}

install_release() (
  local release_json="$1"
  local release_tag="$2"
  local asset_name asset asset_url asset_digest
  asset_name=$(get_platform_asset_name) || return 1
  asset=$(select_asset "$release_json" "$asset_name") || return 1
  asset_url=$(jq -r '.browser_download_url' <<< "$asset")
  asset_digest=$(jq -r '.digest // empty' <<< "$asset")
  [[ -n "$asset_url" ]] || { fail "Asset '$asset_name' has no download URL."; return 1; }

  local cache_dir="${TMPDIR:-/tmp}/MusoqCache"
  local cache_file="$cache_dir/$asset_name"
  local temp_extract_dir
  mkdir -p "$cache_dir"
  echo "Downloading $asset_url..."
  curl -fL "$asset_url" -o "$cache_file" || { fail "Download failed."; return 1; }
  verify_asset_digest "$cache_file" "$asset_digest" || { rm -f "$cache_file"; return 1; }

  temp_extract_dir=$(mktemp -d "${TMPDIR:-/tmp}/MusoqTemp.XXXXXX") || return 1
  trap 'rm -rf "$temp_extract_dir"; rm -f "$cache_file"' EXIT
  unzip -q "$cache_file" -d "$temp_extract_dir" || { fail "Archive extraction failed."; return 1; }
  [[ -f "$temp_extract_dir/Musoq" ]] || { fail "Archive does not contain the Musoq binary."; return 1; }

  if [[ -x "$MUSOQ_EXE" ]]; then stop_musoq; fi
  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  cp -R "$temp_extract_dir/"* "$INSTALL_DIR/"
  chmod +x "$INSTALL_DIR/Musoq"

  [[ -d "$INSTALL_DIR/DataSources" ]] && chmod -R 777 "$INSTALL_DIR/DataSources"
  chmod -R 777 "$INSTALL_DIR"

  local user_data_dir="/usr/share/Musoq"
  mkdir -p "$user_data_dir"
  chmod 777 "$user_data_dir"

  local agent_local_dir="${TMPDIR:-/tmp}/AgentLocal"
  rm -rf "$agent_local_dir"
  mkdir -p "$agent_local_dir/DataSources"
  chmod -R 777 "$agent_local_dir"

  [[ -L /usr/local/bin/Musoq ]] || ln -s "$INSTALL_DIR/Musoq" /usr/local/bin/Musoq
  [[ -L /usr/local/bin/musoq ]] || ln -s "$INSTALL_DIR/Musoq" /usr/local/bin/musoq
  printf 'export PATH="%s:$PATH"\n' "$INSTALL_DIR" > /etc/profile.d/musoq.sh
  chmod +x /etc/profile.d/musoq.sh

  echo "Musoq.CLI version $release_tag was installed and is available in PATH."
)

main() {
  parse_arguments "$@"
  local parse_result=$?
  [[ $parse_result -eq 64 ]] && return 0
  [[ $parse_result -eq 0 ]] || return "$parse_result"
  (( DEBUG == 1 )) && set -x

  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { fail "Please run this script as root (for piped installs, use sudo bash)."; return 1; }
  [[ -n "${BASH_VERSION:-}" ]] || { fail "Please run this script with bash."; return 1; }
  check_dependencies || return 1

  local release release_tag selected_version installed_output installed_version=""
  if [[ -n "$VERSION" ]]; then
    VERSION=$(normalize_semver "$VERSION") || { fail "Invalid SemVer '$VERSION'."; return 2; }
    release=$(fetch_release_by_version "$VERSION") || return 1
  else
    release=$(fetch_release_for_channel "$CHANNEL") || return 1
  fi
  release_tag=$(jq -r '.tag_name' <<< "$release")
  selected_version=$(normalize_semver "$release_tag") || return 1
  echo "Selected release: $release_tag (${CHANNEL:-exact} selection)"

  if [[ -x "$MUSOQ_EXE" ]]; then
    installed_output=$($MUSOQ_EXE --version 2>/dev/null || true)
    installed_version=$(extract_installed_version "$installed_output" || true)
    if [[ -n "$installed_version" ]]; then
      echo "Installed version: $installed_version"
      if [[ "$installed_version" == "$selected_version" ]]; then
        echo "Musoq $selected_version is already installed."
        return 0
      fi
      echo "Switching Musoq from $installed_version to $selected_version."
    fi
  fi

  install_release "$release" "$release_tag"
}

if [[ "${MUSOQ_INSTALLER_SOURCE_ONLY:-0}" != 1 ]]; then
  main "$@"
fi
