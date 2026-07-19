#!/usr/bin/env bash

set -o pipefail
export LC_ALL=C

INSTALL_DIR="/opt/Musoq"
MUSOQ_EXE="$INSTALL_DIR/Musoq"
LEGACY_PROFILE_PATH="/etc/profile.d/musoq.sh"
LEGACY_DATA_DIRECTORY="/usr/share/Musoq"
PURGE=0
DEBUG=0

usage() {
  cat <<'EOF'
Usage: remove.sh [--debug|-d] [--purge|-p]

--purge removes the invoking user's Musoq configuration and plugins.
EOF
}

fail() {
  echo "Error: $*" >&2
  return 1
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--debug) DEBUG=1; shift ;;
      -p|--purge) PURGE=1; shift ;;
      -h|--help) usage; return 64 ;;
      *) fail "Unknown option '$1'."; usage >&2; return 2 ;;
    esac
  done
}

musoq_is_running() {
  local operating_system pid executable
  operating_system=$(uname -s)
  if [[ "$operating_system" == Linux ]]; then
    while IFS= read -r pid; do
      [[ -L "/proc/$pid/exe" ]] || continue
      executable=$(readlink -f "/proc/$pid/exe") || continue
      [[ "$executable" == "$MUSOQ_EXE" ]] && return 0
    done < <(pgrep -x Musoq 2>/dev/null || true)
    return 1
  fi

  pgrep -f "^${MUSOQ_EXE}([[:space:]]|$)" >/dev/null 2>&1
}

stop_musoq() {
  [[ -x "$MUSOQ_EXE" ]] || return 0

  echo "Stopping running Musoq instance if it exists..."
  "$MUSOQ_EXE" quit >/dev/null 2>&1 || true

  local deadline=$((SECONDS + 20))
  while musoq_is_running; do
    if (( SECONDS >= deadline )); then
      fail "Musoq did not stop within 20 seconds."
      return 1
    fi
    sleep 1
  done
}

remove_managed_symlink() {
  local link="$1" target
  if [[ -L "$link" ]]; then
    target=$(readlink "$link") || return 1
    if [[ "$target" == "$MUSOQ_EXE" ]]; then
      rm -- "$link" || return 1
      echo "Removed managed symlink $link"
    else
      echo "Leaving unmanaged symlink $link"
    fi
  elif [[ -e "$link" ]]; then
    echo "Leaving non-symlink path $link"
  fi
}

remove_legacy_profile() {
  [[ -f "$LEGACY_PROFILE_PATH" ]] || return 0
  # shellcheck disable=SC2016 # The legacy profile must contain a literal $PATH reference.
  if grep -Fxq 'export PATH="/opt/Musoq:$PATH"' "$LEGACY_PROFILE_PATH"; then
    rm -- "$LEGACY_PROFILE_PATH" || return 1
    echo "Removed legacy profile script $LEGACY_PROFILE_PATH"
  else
    echo "Leaving unmanaged profile script $LEGACY_PROFILE_PATH"
  fi
}

get_invoking_home() {
  local user="${SUDO_USER:-}" home=""
  if [[ -n "$user" && "$user" != root ]]; then
    if command -v getent >/dev/null 2>&1; then
      home=$(getent passwd "$user" | awk -F: '{print $6}')
    elif [[ "$(uname -s)" == Darwin ]]; then
      home=$(dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    fi
  fi
  printf '%s\n' "${home:-$HOME}"
}

purge_user_data() {
  local user_home="$1" path
  [[ -n "$user_home" && "$user_home" != / ]] || {
    fail 'Unable to determine a safe invoking-user home directory.'
    return 1
  }

  for path in "$user_home/.musoq" "$user_home/.config/musoq"; do
    if [[ -e "$path" || -L "$path" ]]; then
      rm -rf -- "$path" || return 1
      echo "Removed user data $path"
    fi
  done

  if [[ "$(uname -s)" == Linux && ( -e "$LEGACY_DATA_DIRECTORY" || -L "$LEGACY_DATA_DIRECTORY" ) ]]; then
    rm -rf -- "$LEGACY_DATA_DIRECTORY" || return 1
    echo "Removed legacy data $LEGACY_DATA_DIRECTORY"
  fi
}

remove_installation() {
  if [[ -e "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
    stop_musoq || return 1
    rm -rf -- "$INSTALL_DIR" || return 1
    echo "Removed installation directory $INSTALL_DIR"
  else
    echo "Installation directory $INSTALL_DIR does not exist."
  fi

  remove_managed_symlink /usr/local/bin/Musoq || return 1
  remove_managed_symlink /usr/local/bin/musoq || return 1
  remove_legacy_profile || return 1
}

main() {
  parse_arguments "$@"
  local parse_result=$?
  [[ $parse_result -eq 64 ]] && return 0
  [[ $parse_result -eq 0 ]] || return "$parse_result"

  [[ -n "${BASH_VERSION:-}" ]] || { fail "Please run this script with bash instead of sh."; return 1; }
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { fail "Please run as root."; return 1; }
  (( DEBUG == 1 )) && set -x

  remove_installation || return 1
  if (( PURGE == 1 )); then
    purge_user_data "$(get_invoking_home)" || return 1
  fi
  echo "Musoq removal completed."
}

if [[ "${MUSOQ_REMOVER_SOURCE_ONLY:-0}" != 1 ]]; then
  main "$@"
fi
