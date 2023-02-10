#!/bin/sh

## Arch Linux Bootstrap Script
## Author: Arsany Samuel <arsanysamuel.as@gmail.com>
## Repository: https://github.com/arsanysamuel/arch-bootstrapper
## License: GNU GPLv3

# TODO: 
#   1- Change script verbosity (substitute /dev/null and 2>&1 with a variable)
#   2- Check if passwords are empty
#   3- Resolve PIKAUR pgp key failures (pacman-key might solve it)
#   4- Configuration for laptop


### Global Variables ###
device=0  # 1:PC , 2:Laptop
requirements=(sudo base-devel git ntp)
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

    while ! [ $device -eq 1 -o $device -eq 2 ] 2> /dev/null
    do
        printf "\nYou are using this script on:\n\t1- PC\n\t2- Laptop\nChoose: "
        read -r device
    done

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

# Update the system and install requirements
installrequirements() {
    printf "\nRefreshing keys and upgrading...\n"
    pacman -Syy --noconfirm archlinux-keyring > /dev/null 2>&1
    pacman -Su --noconfirm --needed > /dev/null 2>&1
    pacman-key --populate archlinux > /dev/null 2>&1

    printf "\nInstalling requirements:\n"
    for pkg in ${requirements[@]}; do
        printf "\t$pkg\n"
        pacman -S --noconfirm --needed $pkg > /dev/null 2>&1
    done

    ntpd -g -q > /dev/null 2>&1
}

# Add or modify user
adduser() {
    printf "\n\nAdding/Modifying user $username.\n"
    export homedir="/home/$username"
    useradd -m -g wheel "$username" > /dev/null 2>&1 || usermod -a -G wheel -m -d "$homedir" "$username"
    echo "$username:$pass" | chpasswd

    printf "Configuring for auto login on tty1.\n"
    mkdir -p "/etc/systemd/system/getty@tty1.service.d/"
    printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $username %I $TERM" > /etc/systemd/system/getty@tty1.service.d/autologin.conf
    printf "[Service]\nTTYVTDisallocate=no" > /etc/systemd/system/getty@tty1.service.d/noclear.conf  # Prevents systemd from clearing screen

    printf "Configuring sudoers\n"
    sed -i "/wheel.*NOPASSWD/s/#\ //" /etc/sudoers || return 1  # Could do with awk

    printf "\nUser configured successfully\n"
}

# Pacman edit configuration
pacmanconfig() {
    printf"\nConfiguring pacman by editing /etc/pacman.conf\n"

    # Editing config file
    sed -i "/Color/s/#//" /etc/pacman.conf
    sed -i "/CheckSpace/s/#//" /etc/pacman.conf
    sed -i "/VerbosePkgLists/s/#//" /etc/pacman.conf
    sed -i "/ParallelDownloads/s/#//" /etc/pacman.conf

    # Enabling cache weekly cleaning service
    systemctl enable paccache.timer
}

# Install AUR helper (PIKAUR)
installaurhelper() {
    printf "\nInstalling PIKAUR\n"
    sudo -u $username git clone https://aur.archlinux.org/pikaur.git || printf "Couldn't clone the repo\n"; return 1
    cd pikaur
    sudo -u $username makepkg -fsri > /dev/null 2>&1 || printf "PIKAUR failed to compile and install\n"; return 1
    cd ..
    rm -rf pikaur

    # Adding TOR browser pgp key (will resolve later)
    sudo -u $username gpg --keyserver keys.openpgp.org --recv-keys E53D989A9E2D47BF > /dev/null 2>&1
}

# Deploy Dotfiles
deploydotfiles() {
    printf "\nDeploying dotfiles...\n"
    sudo -u $username git clone --bare git@github.com:arsanysamuel/dotfiles.git $HOME/.dotfiles
    sudo -u $username git --work-tree=$HOME --git-dir=$HOME/.dotfiles/ checkout -f
    rm -f LICENSE README.md
    sudo -u $username git --work-tree=$HOME --git-dir=$HOME/.dotfiles/ update-index --skip-worktree LICENSE README.md
    sudo -u $username git --work-tree=$HOME --git-dir=$HOME/.dotfiles/ config --local status.showUntrackedFiles no
}

# Install packages from pkglist.txt
installpkglist() {
    printf "\nInstalling packages:\n"

    pkglist=$(cat "$homedir/.config/pkglist.txt")
    for pkg in $pkglist; do
        printf "$pkg... "
        sudo -u $username pikaur -S --noconfirm --needed $pkg > /dev/null 2>&1 || return 1
        printf "done.\n"
    done

    printf "Done installing all packages.\n"
}

# Configure every package in the list according to its arch wiki page
configpkgs() {
    printf "\nConfiguring packages. (Check wiki.archlinux.org for every package configuration)\n"

    # GRUB Theme
}


### Main Script ###
welcome || error "User exited."
getuserinfo || error "User exited."

printf "\nThe script will proceed to bootstrap the system fully automated without any more input required from you, this may take some time.\n\nPress any key to continue..."
read -s -n 1

installrequirements
adduser || error "Error has occurred while adding/modifying user."
pacmanconfig
installaurhelper || error "Failed to install PIKAUR"
deploydotfiles || error "Failed to deploy .dotfiles"
installpkglist || error "Failed to install a package, check the logs and try again."

printf "\nFinished\n"

