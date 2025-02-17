#!/bin/bash

echo "####################
####################
######---##---######
######---##---######
######---##---######
######---##---######
######---##---######
###########---######
###########---######
####################
####################"

run_update_and_upgrade() {
    if [ -d "/data/data/com.termux" ]; then
    echo "RUNNING PKG UPDATE..."
        yes | pkg update -y
    else
    echo "RUNNING APT UPDATE..."
        sudo apt update -y
    fi

    if [ -d "/data/data/com.termux" ]; then
    echo "RUNNING PKG UPGRADE..."
        yes | pkg upgrade -y
    else
    echo "RUNNING APT UPGRADE..."
        sudo apt upgrade -y
    fi
}

install_packages() {
    echo "INSTALLING DEPENDENCIES..."
    if [ -d "/data/data/com.termux" ]; then
        yes | pkg install git jq wget nano -y
    else
        sudo apt install git jq wget nano -y
    fi
}

make_folder() {
    mkdir -p ~/qubic
}

download_latest_release() {
    echo "DOWNLOADING LATEST RQINER..."
    local repo_owner=$1
    local repo_name=$2
    local file_path=$3
    local download_location=$4

    if [ -e "$download_location" ]; then
        local filename=$(basename "$download_location")
        mv "$download_location" "$(dirname "$download_location")/old.${filename}"
        echo "Existing miner file '$filename' renamed to 'old.${filename}'"
    fi

    local releases=$(curl -s "https://api.github.com/repos/${repo_owner}/${repo_name}/releases?per_page=10")
    local binary_url=""

    for release in $(echo "$releases" | jq -r '.[] | @base64'); do
        local release_info=$(echo "$release" | base64 --decode)
        local release_name=$(echo "$release_info" | jq -r '.name')
        local release_tag=$(echo "$release_info" | jq -r '.tag_name')
        binary_url=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$file_path\") | .browser_download_url")
        if [ -n "$binary_url" ]; then
            break
        fi
    done

    if [ -z "$binary_url" ]; then
        echo "Binary file '$file_path' not found in the last 5 releases"
        exit 1
    fi

    curl -L -o "$download_location" "$binary_url"
    echo "Release: $release_name"
    echo "Release Tag: $release_tag"
    echo "Miner file '$file_path' downloaded to '$download_location'"

    chmod +x "$download_location"
    echo "Permissions of the downloaded binary changed to executable."
}

repo_owner="Qubic-Solutions"
repo_name="rqiner-builds"
if [ -d "/data/data/com.termux" ]; then
    file_path="rqiner-aarch64-android"
else
    file_path="rqiner-aarch64"
fi
download_location="$HOME/qubic/$file_path"

run_update_and_upgrade
install_packages
make_folder
download_latest_release "$repo_owner" "$repo_name" "$file_path" "$download_location"
