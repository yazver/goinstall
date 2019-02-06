#!/bin/bash

version="1.11.5"

os="linux"
case `uname -s` in
    linux|Linux) os="linux" ;;
    darwin|Darwin) os="darvin" ;;
    freebsd|FreeBSD) os="freebsd" ;;
esac

arch="amd64"
case `uname -m` in 
    i?86|x86) arch="386" ;;
    x86_64) arch="amd64" ;;
    armv6l) arch="armv6l" ;;
    *arm64) arch="arm64" ;;
esac

filename="go$version.$os-$arch.tar.gz"
echo "Will be installed \"$filename\""

dest="/usr/local"
goroot="$dest/go"
gopath="$HOME/dev/go"
profile="$HOME/.bashrc"
if [[ -n "$SHELL" ]] && [[ $(basename "$SHELL") == "zsh" ]]; then
    profile="$HOME/.zshrc"
fi

if [ "$1" == "--remove" ]; then
    rm -rf "$goroot"
    sed -i '/export GOROOT/d' "$profile"
    sed -i "/:$goroot/d" "$profile"
    sed -i '/export GOPATH/d' "$profile}"
    sed -i "/:$gopath/d" "$profile"
    echo "Go removed."
    exit 0
fi

if [ ! -w "$dest" ]; then
    echo "Not enough rights to write to the directory: $dest"
    exit 1
fi
if [ -d "$goroot" ]; then
 read -p "Directory $goroot exist. Remove it and continue (y/n)?" -n 1 -r
 if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
 fi
fi
rm -rf $goroot
 
echo "Download archive ..."
wget https://dl.google.com/go/$filename -O /tmp/$filename
if [ $? -ne 0 ]; then
    echo "Download failed! Exiting."
    exit 1
fi

echo "Extract files from /tmp/$filename to /usr/local"
tar -C /usr/local -xzf "/tmp/$filename" --totals
rm -f /tmp/$filename

echo "Set envirinment:"
add_path() {
    if [ -s "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        echo "  Add \"$1\" to PATH"  
        echo 'export PATH="$PATH:'$1'"' >> "$profile"
    fi
}

add_path "$goroot/bin"
add_path "$gopath/bin"

add_env() {
    local env_var_name=$1
    local local_var_name=${env_var_name,,}
    echo "  Add environment variable ${env_var_name}=${!local_var_name}"
    if [[ -z ${!env_var_name} ]] || [[ ${!env_var_name} != ${!local_var_name} ]]; then
        sed -i "/export ${env_var_name}/d" "$profile"
        echo "export ${env_var_name}=\"${!local_var_name}\"" >> "$profile" 
    fi
}
add_env "GOROOT"
add_env "GOPATH"

if [ -d "$gopath" ]; then
    echo "Create $gopath"
    mkdir -p "$gopath"
fi

source "$profile"
