#!/usr/bin/env bash

# This script deploys the contents of the 'build' folder
# via rsync to the web server.

set -euo pipefail

# Ensures that the script runs from its own folder.
if ! cd "$(dirname "$0")"; then exit 1; fi

# Gets the current operating system.
os=$(uname -s)

# Sets the build folder.
build_folder="build"

# Checks the build folder.
if [[ ! -d "$build_folder" ]]; then
  echo "Error: Build folder '$build_folder' does not exist. Run the build script first."
  exit 1
fi

# Checks that the build folder is not empty.
# An empty folder would cause rsync --delete to wipe the remote site.
if [[ -z "$(find "$build_folder" -mindepth 1 -print -quit)" ]]; then
  echo "Error: Build folder '$build_folder' is empty. Run the build script first."
  exit 1
fi

# Sets the host and target folder.
host="ilux150"
target_folder="~/upload_git-docs-collab"
git_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$git_branch" == "next" ]]; then
  target_folder="${target_folder}_next"
fi

# Uploads the content of the build folder to the web server.
echo "Upload to server:"
if [[ "$os" == "Darwin" ]]; then
  rsync --delete -avze ssh "$build_folder/" "$host:$target_folder/" --exclude=".*" --exclude="files/*" --exclude="images/videos/*" --chmod=Du+rwx,Dgo+x,Fu+rw,Fgo+r #macOS
else
  rsync --delete -avze ssh "$build_folder/" "$host:$target_folder/" --exclude=".*" --exclude="files/*" --exclude="images/videos/*" --chmod=D0711,F0644 #Linux
fi
