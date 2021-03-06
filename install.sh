#!/usr/bin/env bash

# https://gist.github.com/P7h/91e14096374075f5316e

# Steps to build and install tmux from source on Ubuntu.
# Takes < 25 seconds on EC2 env [even on a low-end config instance].
#function IsPackageInstalled() {
    #dpkg -s "$1" > /dev/null 2>&1
#}
#packages="tmux"

ARG_1=$1
if [ -z "$ARG_1" ]; then
    echo "ARG_1 = empty; no install tmux"
else
    echo "remove tmux";
    sudo apt-get -y remove tmux

    VERSION=3.1
    sudo apt -y install gcc wget tar make
    sudo apt install -f -y
    sudo apt -y install wget tar 
    sudo apt -y install libevent-dev
    sudo apt -y install libncurses-dev

    wget https://invisible-mirror.net/archives/ncurses/ncurses-6.2.tar.gz
    tar -xzf ncurses-6.2.tar.gz
    cd ncurses-6.2
    ./configure
    make -j$(nproc)
    sudo make install

    wget https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz
    tar xf tmux-${VERSION}.tar.gz
    rm -f tmux-${VERSION}.tar.gz
    cd tmux-${VERSION}
    ./configure
    make -j$(nproc)
    sudo make install
    cd -
    sudo rm -rf /usr/local/src/tmux-*
    sudo mv tmux-${VERSION} /usr/local/src

    tmux kill-server
fi



## Logout and login to the shell again and run.
## tmux -V

set -e
set -u
set -o pipefail

is_app_installed() {
    type "$1" &>/dev/null
}

REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
cd "$REPODIR";

if ! is_app_installed tmux; then
    printf "WARNING: \"tmux\" command is not found. \
        Install it first\n"
    exit 1
fi

if [ ! -e "$HOME/.tmux/plugins/tpm" ]; then
    printf "WARNING: Cannot found TPM (Tmux Plugin Manager) \
        at default location: \$HOME/.tmux/plugins/tpm.\n"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [ -e "$HOME/.tmux.conf" ]; then
    printf "Found existing .tmux.conf in your \$HOME directory. Will create a backup at $HOME/.tmux.conf.bak\n"
fi

cp -f "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak" 2>/dev/null || true
cp -a ./tmux/. "$HOME"/.tmux/
ln -sf .tmux/tmux.conf "$HOME"/.tmux.conf;

# Install TPM plugins.
# TPM requires running tmux server, as soon as `tmux start-server` does not work
# create dump __noop session in detached mode, and kill it when plugins are installed
printf "Install TPM plugins\n"
tmux new -d -s __noop >/dev/null 2>&1 || true
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins"
"$HOME"/.tmux/plugins/tpm/bin/install_plugins || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

printf "OK: Completed\n"
