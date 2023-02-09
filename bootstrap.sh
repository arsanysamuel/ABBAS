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
    printf "\nThe script will do the following:\n\t1- Add a new user account (if not existing).\n\t2- Install AUR helper.\n\t3- Install packages.\n\t4- Configure packages and deploy dotfiles.\n\n"
    read -p "Do you wish to continue [Y/n]? "
    [[ -z "$REPLY" || "$REPLY" == "y" || "$REPLY" == "Y" ]] || return 1
}

# Prompt for user
getuserinfo() {
    printf "\nCreating New user.\n"

    # Getting usrname
    read -p "New user name: " username
    while ! echo "$username" | grep -q "^[a-z_][a-z0-9_-]*$"; do
        printf "Invalid user name, try again.\n"
        read -p "New user name: " username
    done

    # Getting password
    printf "Password: "
    read -s pass
    printf "\nRetype password: "
    read -s repass
    #while ! [ -n $pass ] && [ -n $repass ] || [ "$pass" == "$repass" ]; do  # TODO
    while ! [ "$pass" == "$repass" ]; do
        printf "\nPasswords don't match, try again.\n"
        printf "Password: "
        read -s pass
        printf "\nRetype password: "
        read -s repass
    done
    unset repass

    # Check if user exists
    id -u $username > /dev/null 2>&1 && {
        printf "\n\nThis user already exists, the script will continue running and will overwrite any current config files, also will set the new password to the current user.\n"
        read -p "Do you wish to continue [Y/n]? "
        [[ -z "$REPLY" || "$REPLY" == "y" || "$REPLY" == "Y" ]] || return 1
    }
    echo  # Resolves a bug for some reason
}


### Main Script ###
welcome || error "User exited."
getuserinfo || error "User exited."

printf "\nThe script will proceed to bootstrap the system fully automated without any more input required from you, this may take some time.\n\nPress any key to continue..."
read -s -n 1

printf "\nFinished\n"

