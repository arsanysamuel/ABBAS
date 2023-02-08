#!/bin/sh

## Arch Linux Bootstrap Script
## Author: Arsany Samuel <arsanysamuel.as@gmail.com>
## Repository: https://github.com/arsanysamuel/arch-bootstrapper
## License: GNU GPLv3


### Global Variables ###
dotfiles="git@github.com:arsanysamuel/dotfiles.git"


# Error handler function
error() {
    printf "\n$1\n" >&2
    exit 1
}

# Welcome message
welcome() {
    printf "\nStarting Arch Linux Bootstrapping Script...\nBy: Arsany Samuel.\n"
    printf "\nThe script will do the following:\n\t1- Add a new user account.\n\t2- Install AUR helper.\n\t3- Install packages and configure them.\n\n"
    read -p "Do you wish to continue [Y/n]? "
    [[ -z "$REPLY" || "$REPLY" == "y" || "$REPLY" == "Y" ]] || return 1
}

# Create user
createuser() {

}


### Main Script ###
welcome || error "User exited."
createuser || error "User exited."

