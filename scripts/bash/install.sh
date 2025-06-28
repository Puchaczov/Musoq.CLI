#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

if [ -z "$BASH_VERSION" ]; then
  echo "Please run this script with bash instead of sh."
  exit 1
fi

DEBUG=0
VERSION=""

# Parse options: -d for debug, -v for version
while getopts "dv:" opt; do
  case $opt in
    d)
      DEBUG=1
      ;;
    v)
      VERSION="$OPTARG"
      ;;
    *)
      echo "Usage: $0 [-d] [-v version]"
      exit 1
      ;;
  esac
done

[ $DEBUG -eq 1 ] && set -x

get_os() {
  if [ -f /etc/alpine-release ]; then
    echo "alpine"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ]; then
    echo "redhat"
  elif [ -f /etc/arch-release ]; then
    echo "arch"
  else
    echo "linux"
  fi
}

check_dependencies() {
  # Check for universal command-line tools
  for cmd in curl jq unzip uname tar; do
    if ! command -v $cmd >/dev/null 2>&1; then
      echo "Missing dependency: $cmd. Please install it and retry."
      exit 1
    fi
  done

  # Check for and install OS-specific dependencies
  local os=$(get_os)
  echo "Detected OS: $os"
  
  case $os in
    alpine)
      echo "Installing dependencies for Alpine Linux..."
      apk add --no-cache libstdc++ libgcc icu-libs || {
        echo "Failed to install dependencies on Alpine Linux."
        exit 1
      }
      ;;
    debian)
      echo "Installing dependencies for Debian/Ubuntu..."
      apt-get update && apt-get install -y libicu-dev || {
        echo "Failed to install dependencies on Debian/Ubuntu."
        exit 1
      }
      ;;
    redhat)
      echo "Installing dependencies for Red Hat/CentOS/Fedora..."
      if command -v dnf >/dev/null 2>&1; then
        dnf install -y libicu || { echo "Failed to install dependencies using dnf."; exit 1; }
      elif command -v yum >/dev/null 2>&1; then
        yum install -y libicu || { echo "Failed to install dependencies using yum."; exit 1; }
      else
        echo "Neither dnf nor yum package manager found."; exit 1
      fi
      ;;
    arch)
      echo "Installing dependencies for Arch Linux..."
      pacman -Sy --noconfirm icu || {
        echo "Failed to install dependencies on Arch Linux."; exit 1
      }
      ;;
    *)
      echo "Unknown OS: $os. You may need to manually install ICU libraries."
      ;;
  esac
}

check_dependencies

# Get system architecture
get_arch() {
  local arch=$(uname -m)
  case $arch in
    x86_64|amd64) echo "x64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unsupported" ;;
  esac
}

ARCH=$(get_arch)
if [ "$ARCH" = "unsupported" ]; then
  echo "Unsupported architecture: $(uname -m)"
  exit 1
fi
echo "Detected architecture: $ARCH"

OS=$(get_os)

# Functions
normalize_version() {
  local version=$1
  IFS='.' read -ra parts <<< "$version"
  # Ensure 4 parts
  for ((i=${#parts[@]}; i<4; i++)); do
    parts[i]=0
  done
  # By default, return full four parts; for GitHub comparisons, join only first three
  if [ "$2" == "github" ]; then
    echo "${parts[0]}.${parts[1]}.${parts[2]}"
  else
    echo "${parts[0]}.${parts[1]}.${parts[2]}.${parts[3]}"
  fi
}

stop_musoq() {
  echo "Stopping running Musoq instance if exists..."
  pkill -f Musoq 2>/dev/null || true
  sleep 5
}

download_asset() {
  local url=$1
  local dest=$2
  if [ ! -f "$dest" ]; then
    echo "Downloading $url..."
    if ! curl -L "$url" -o "$dest"; then
      echo "Download failed"
      exit 1
    fi
  else
    echo "Using cached file: $dest"
  fi
}

INSTALL_DIR="/opt/Musoq"
MUSOQ_EXE="$INSTALL_DIR/Musoq"

# If Musoq is already installed, check version
if [ -x "$MUSOQ_EXE" ]; then
  installedOutput=$("$MUSOQ_EXE" --version 2>/dev/null)
  if [[ $installedOutput =~ Musoq[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    installedVersion="${BASH_REMATCH[1]}.0"
    installedVersionTriple="${BASH_REMATCH[1]}"
    echo "Installed version: $installedVersion"
    if [ -n "$VERSION" ]; then
      normInstalled=$(normalize_version $installedVersion)
      normRequested=$(normalize_version $VERSION)
      if [[ $normInstalled == $normRequested* ]]; then
        echo "Musoq version $normRequested is already installed ($installedVersion)."
        exit 0
      fi
    fi
  else
    echo "Could not parse installed version."
    exit 0
  fi
fi

repoOwner="Puchaczov"
repoName="Musoq.CLI"
apiUrl="https://api.github.com/repos/$repoOwner/$repoName/releases"

echo "Fetching releases from $apiUrl..."
releases=$(curl -sL "$apiUrl") || { echo "Failed to fetch releases."; exit 1; }
if [ -z "$releases" ]; then
  echo "No releases found."
  exit 1
fi

# Determine release: if a version is provided, filter for it; else, use the latest proper release.
if [ -n "$VERSION" ]; then
  normVersion=$(normalize_version $VERSION github)
  release=$(echo "$releases" | jq -r --arg ver "$normVersion" 'map(select(.tag_name | ltrimstr("v") == $ver)) | .[0]')
  if [ "$release" == "null" ] || [ -z "$release" ]; then
    echo "Release version $normVersion not found on GitHub."
    exit 1
  fi
else
  # Modified jq query to properly sort semantic versions
  release=$(echo "$releases" | jq -r '
    map(select(.tag_name|test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
    | sort_by(
        .tag_name | split(".")
        | map(tonumber)
        | .[0] * 1000000 + .[1] * 1000 + .[2]
    )
    | reverse | .[0]
  ')
fi

releaseTag=$(echo "$release" | jq -r '.tag_name')
echo "Selected release: $releaseTag"

# If no specific version was requested, compare installed vs latest
if [ -z "$VERSION" ] && [ -n "$installedVersionTriple" ]; then
  latestVersion=$(echo "$releaseTag" | sed 's/^v//')
  # Use normalize_version to ensure proper comparison
  normInstalled=$(normalize_version "$installedVersionTriple")
  normLatest=$(normalize_version "$latestVersion")
  if dpkg --compare-versions "$normInstalled" ge "$normLatest"; then
    echo "No installation needed. Installed version ($installedVersionTriple) is up to date."
    exit 0
  else
    echo "Update available: $installedVersionTriple -> $latestVersion"
  fi
fi

# Select asset: looking for appropriate Linux version
# Map OS to asset naming convention
case $OS in
  alpine)
    ASSET_OS="alpine"
    ;;
  *)
    ASSET_OS="linux"
    ;;
esac

assetUrl=$(echo "$release" | jq -r --arg arch "$ARCH" --arg os "$ASSET_OS" '.assets[] | select(.name | test($os + "-" + $arch)) | .browser_download_url' | head -n 1)
if [ -z "$assetUrl" ]; then
  echo "No $ASSET_OS $ARCH asset found in the selected release."
  exit 1
fi
echo "Selected asset URL: $assetUrl"

# Prepare download cache and temporary extraction directory
cacheDir="/tmp/MusoqCache"
mkdir -p "$cacheDir"
assetName=$(basename "$assetUrl")
cacheFile="$cacheDir/$assetName"

download_asset "$assetUrl" "$cacheFile"

tempExtractDir=$(mktemp -d /tmp/MusoqTemp.XXXXXX)
trap 'rm -rf "$tempExtractDir"; rm -f "$cacheFile"' EXIT

echo "Extracting contents to temporary location: $tempExtractDir"
if [[ "$assetName" == *.zip ]]; then
  unzip -q "$cacheFile" -d "$tempExtractDir" || { echo "Extraction failed"; exit 1; }
elif [[ "$assetName" == *.tar.gz ]]; then
  tar -xzf "$cacheFile" -C "$tempExtractDir" || { echo "Extraction failed"; exit 1; }
else
  echo "Unsupported archive format: $assetName"
  exit 1
fi

if [ ! -f "$tempExtractDir/Musoq" ]; then
  echo "Invalid archive contents: Musoq binary not found."
  exit 1
fi

# Stop any running instance if exists
if [ -x "$MUSOQ_EXE" ]; then
  stop_musoq
fi

# Install new version
if [ -d "$INSTALL_DIR" ]; then
  echo "Removing existing installation..."
  rm -rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"
cp -r "$tempExtractDir/"* "$INSTALL_DIR/"

# Ensure executable permission
chmod +x "$INSTALL_DIR/Musoq"

# Maintain proper privileges on existing DataSources folder
if [ -d "$INSTALL_DIR/DataSources" ]; then
  chmod -R 777 "$INSTALL_DIR/DataSources"
else
  echo "Warning: DataSources folder not found in $INSTALL_DIR."
fi

# Create symlink in /usr/local/bin if not exists
if [ ! -L "/usr/local/bin/Musoq" ]; then
  ln -s "$INSTALL_DIR/Musoq" /usr/local/bin/Musoq
fi

# Create lowercase symlink in /usr/local/bin if not exists
if [ ! -L "/usr/local/bin/musoq" ]; then
  ln -s "$INSTALL_DIR/Musoq" /usr/local/bin/musoq
fi

# Set full permissions on installation directory
chmod -R 777 "$INSTALL_DIR"

# Create /usr/share/Musoq directory for user data and set permissions
USER_DATA_DIR="/usr/share/Musoq"
if [ ! -d "$USER_DATA_DIR" ]; then
  echo "Creating user data directory: $USER_DATA_DIR"
  mkdir -p "$USER_DATA_DIR"
fi
# Set directory permissions: 755 (rwxr-xr-x) - users can read/access, owner can write
chmod 755 "$USER_DATA_DIR"
# Make it writable by all users for data files
chmod g+w,o+w "$USER_DATA_DIR"

# Create /tmp/AgentLocal directory for temporary data and set permissions
AGENT_LOCAL_DIR="/tmp/AgentLocal"
if [ ! -d "$AGENT_LOCAL_DIR" ]; then
  echo "Creating agent local directory: $AGENT_LOCAL_DIR"
  mkdir -p "$AGENT_LOCAL_DIR"
fi
# Set full permissions for AgentLocal (needs to store and execute .dll files)
chmod 777 "$AGENT_LOCAL_DIR"

# Create /tmp/AgentLocal/DataSources directory for data sources and set permissions
DATASOURCES_DIR="/tmp/AgentLocal/DataSources"
if [ ! -d "$DATASOURCES_DIR" ]; then
  echo "Creating data sources directory: $DATASOURCES_DIR"
  mkdir -p "$DATASOURCES_DIR"
fi
# Set full permissions for DataSources (needs to store and execute .dll files)
chmod 777 "$DATASOURCES_DIR"

echo "Musoq installation completed successfully."
echo "Musoq.CLI version $releaseTag was installed and is available in PATH."

# Update current terminal PATH to include the installation folder if not already present.
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    export PATH="$INSTALL_DIR:$PATH"
    hash -r
    echo "Updated PATH in the current session."
fi

# Create /etc/profile.d/musoq.sh to add the installation folder to PATH for future sessions.
echo "export PATH=\"$INSTALL_DIR:\$PATH\"" > /etc/profile.d/musoq.sh
chmod +x /etc/profile.d/musoq.sh
