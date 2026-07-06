#!/bin/bash
# Downloads the prebuilt dls2_msgs release asset from GitHub and installs it.
# Runs inside the dls2-dev container as part of the build preparation step.
# Requires: CICD_PAT or GITHUB_TOKEN env var for authentication.
set -euo pipefail

DOWNLOAD_DIR="/tmp/dls2-msgs-release"
REPO="iit-DLSLab/dls2_msgs"

echo "--- Installing dls2_msgs prebuilt artifacts ---"

# Install gh CLI if not present in the container
if ! command -v gh &>/dev/null; then
    echo "gh CLI not found, installing..."
    apt-get update -qq
    apt-get install -y gh
fi

TOKEN="${CICD_PAT:-${GITHUB_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
    echo "::error::No GitHub token found (CICD_PAT or GITHUB_TOKEN). Cannot download release."
    exit 1
fi
echo "CICD_PAT: ${CICD_PAT}"
echo "GITHUB_TOKEN: ${GITHUB_TOKEN}"

export GH_TOKEN="$TOKEN"
echo "GH_TOKEN: ${GH_TOKEN}"

# Resolve the dls2_msgs submodule commit SHA pinned in this repo
SHA="$(git ls-tree HEAD dls2_msgs | awk '{print $3}')"
echo "dls2_msgs submodule is pinned to commit: $SHA"

# Find the release tag that points to that commit
TAG="$(
    git ls-remote --tags "https://x-access-token:${TOKEN}@github.com/${REPO}.git" |
    awk -v sha="$SHA" '
        $1 == sha {
            ref = $2
            sub("^refs/tags/", "", ref)
            sub("\\^\\{\\}$", "", ref)
            print ref
            exit
        }
    '
)"

if [ -z "$TAG" ]; then
    echo "::error::No release tag found in ${REPO} for commit ${SHA}"
    exit 1
fi
echo "Found release tag: $TAG"

# Download the dev .deb package from that release
mkdir -p "$DOWNLOAD_DIR"
gh release download "$TAG" \
    --repo "$REPO" \
    --pattern "dls-messages-dev.deb" \
    --dir "$DOWNLOAD_DIR" \
    --clobber

echo "Downloaded assets:"
ls -lR "$DOWNLOAD_DIR"

# Install the .deb package (apt-get handles dependencies automatically)
echo "Installing dls-messages-dev .deb..."
sudo dpkg -i "$DOWNLOAD_DIR"/dls-messages-dev.deb
echo "dls2_msgs installed successfully."