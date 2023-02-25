#!/bin/sh

## Arch Linux Bootstrap Script
## Author: Arsany Samuel <arsanysamuel.as@gmail.com>
## Repository: https://github.com/arsanysamuel/arch-bootstrapper
## License: GNU GPLv3

# TODO: 
#   - Change script verbosity (substitute /dev/null and 2>&1 with STDOUT)
#   - Configuration for laptop
#   - Startup systemd msgs
#   - use reflector to update mirror list
#   - Change name to ABBAS
#   - NeoMutt wizard


### Global Variables ###
device=0  # 1:PC , 2:Laptop
requirements=(sudo base-devel git openssh ntp)
conflicts=(mimi)  # Packages we want to install but causing conflicts
dotfilesrepo="https://github.com/arsanysamuel/dotfiles.git"
suckless=(dwm dmenu st)
cocplugins=(html css json pyright lua vimtex sh tsserver json snippets markdownlint htmldjango)


# Error handler function
error() {
    printf "\n$1\n" >&2
    exit 1
}

# Welcome message
welcome() {
    printf "\nStarting Arch Linux Bootstrapping Script...\nBy: Arsany Samuel.\n"
    printf "\nThe script will do the following:\n\t1- Add a new user account (or modify if existing).\n\t2- Install AUR helper.\n\t3- Install packages.\n\t4- Configure packages and deploy dotfiles.\n\n"
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
    while ! [ -n "$pass" ]; do
        printf "\nThe password is empty, try again.\n"
        printf "Password: "
        read -s pass
    done
    printf "\nRetype password: "
    read -s repass

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
    printf "\n\nRefreshing keys and upgrading...\n"
    pacman -Syy --noconfirm archlinux-keyring > /dev/null 2>&1
    pacman -Su --noconfirm --needed > /dev/null 2>&1
    pacman-key --populate archlinux > /dev/null 2>&1

    printf "\nInstalling requirements:\n"
    for pkg in ${requirements[@]}; do
        printf "\t$pkg\n"
        pacman -S --noconfirm --needed $pkg > /dev/null 2>&1
    done

    printf "\nConfiguring time using NTP...\n"
    ntpd -g -q > /dev/null 2>&1
}

# Add or modify user
adduser() {
    printf "\n\nAdding/Modifying user $username.\n"
    export homedir="/home/$username"
    useradd -m -g wheel "$username" > /dev/null 2>&1 || usermod -a -G wheel -m -d "$homedir" "$username"
    echo "$username:$pass" | chpasswd > /dev/null 2>&1 && printf "\tNew password set.\n" || printf "\tPassword unchanged.\n"

    printf "\tConfiguring for auto login on tty1...\n"
    mkdir -p "/etc/systemd/system/getty@tty1.service.d/"
    echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --autologin $username %I $TERM" > /etc/systemd/system/getty@tty1.service.d/autologin.conf
    printf "[Service]\nTTYVTDisallocate=no" > /etc/systemd/system/getty@tty1.service.d/noclear.conf  # Prevents systemd from clearing screen

    printf "\tConfiguring sudoers...\n"
    sed -i "/wheel.*NOPASSWD/s/#\ //" /etc/sudoers || return 1  # Could do with awk

    printf "\tCreating home directory folders...\n"
    chown "$username":wheel $homedir > /dev/null 2>&1
    sudo -u $username mkdir -p $homedir/dls/ $homedir/docs/ $homedir/unsorted $homedir/torrents/incomplete
}

# Pacman edit configuration
pacmanconfig() {
    printf "\nConfiguring pacman by editing /etc/pacman.conf\n"

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
    printf "\nInstalling PIKAUR...\n"
    [ -d "$homedir/pikaur" ] && rm -rf "$homedir/pikaur"
    sudo -u $username git -C "$homedir" clone -q --depth 1 --no-tags https://aur.archlinux.org/pikaur.git || { printf "Couldn't clone the repo\n"; return 1; }
    cd $homedir/pikaur
    sudo -u $username makepkg -fsricC --noconfirm --needed > /dev/null 2>&1 || { printf "PIKAUR failed to compile and install\n"; return 1; }
    rm -rf $homedir/pikaur

    # Adding TOR browser pgp key (will resolve later)
    sudo -u $username gpg --keyserver keys.openpgp.org --recv-keys E53D989A9E2D47BF > /dev/null 2>&1
}

# Configure git globally
configgit() {
    sudo -u $username git config --global merge.tool nvimdiff
    sudo -u $username git config --global merge.conflictstyle diff3
    sudo -u $username git config --global mergetool.prompt false
    sudo -u $username git config --global color.ui auto
}

# Deploy Dotfiles
deploydotfiles() {
    printf "\nDeploying dotfiles:\n"

    printf "\tConfiguring SSH...\n"
    cd $homedir
    yes | sudo -u $username ssh-keygen -q -N "" -C "" -t rsa -f $homedir/.ssh/id_rsa > /dev/null 2>&1
    yes | sudo -u $username ssh-keygen -q -N "" -C "" -t ed25519 -f $homedir/.ssh/id_ed25519 > /dev/null 2>&1
    sudo -u $username ssh-keyscan github.com >> $homedir/.ssh/known_hosts 2> /dev/null

    printf "\tDeploying dotfiles...\n"
    ! [ -d "$homedir/.dotfiles" ] || rm -rf "$homedir/.dotfiles"
    sudo -u $username git -C "$homedir" clone -q --bare $dotfilesrepo $homedir/.dotfiles
    sudo -u $username git -C "$homedir" --work-tree=$homedir --git-dir=$homedir/.dotfiles/ checkout -f
    rm -f LICENSE README.md
    sudo -u $username git -C "$homedir" --work-tree=$homedir --git-dir=$homedir/.dotfiles/ update-index --skip-worktree -q LICENSE README.md
    sudo -u $username git -C "$homedir" --work-tree=$homedir --git-dir=$homedir/.dotfiles/ config --local status.showUntrackedFiles no
}

# Install packages from pkglist.txt
installpkglist() {
    pkglist_all=(cat "$homedir/.config/pkglist.txt")

    printf "\nCategorizing packages...\n"  # Will replace with better method
    pkglist_main=($(pacman -Slq | comm -12 <(sort $homedir/.config/pkglist.txt) <(sort -)))
    pkglist_aur=($(pacman -Slq | comm -32 <(sort $homedir/.config/pkglist.txt) <(sort -)))

    printf "\nResolving conflicts...\n"
    for pkg in ${conflicts[@]}; do
        printf "\tInstalling $pkg... "
        yes p | sudo -u $username pikaur -S --noconfirm --needed $pkg > /dev/null 2>&1 || return 1
        printf "done.\n"
    done

    printf "\nInstalling main packages:\n"
    for pkg in ${pkglist_main[@]}; do
        printf "\t$pkg... "
        pacman -S --noconfirm --needed $pkg > /dev/null 2>&1 || return 1
        printf "done.\n"
    done

    printf "\nInstalling AUR packages:\n"
    for pkg in ${pkglist_aur[@]}; do
        printf "\t$pkg... "
        yes p | sudo -u $username pikaur -S --noconfirm --needed $pkg > /dev/null 2>&1 || return 1
        printf "done.\n"
    done

    printf "\nDone installing all packages.\n"
}

# Configure every package in the list according to its arch wiki page
configpkgs() {
    printf "\nConfiguring packages:\n"

    printf "\tInstalling GRUB Theme...\n"
    [ -d "$homedir/grub2-theme-vimix" ] && rm -rf "$homedir/grub2-theme-vimix"
    sudo -u $username git -C "$homedir" clone -q https://github.com/Se7endAY/grub2-theme-vimix.git
    mkdir -p /boot/grub/themes/ || return 1
    cp -r grub2-theme-vimix/Vimix/ /boot/grub/themes/
    rm -rf $homedir/grub2-theme-vimix
    printf "\n# User added config\nGRUB_DISABLE_OS_PROBER=false  # detect all OSes\n#GRUB_GFXMODE=1024x768x32  # setting grub resolution\n#GRUB_BACKGROUND='/path/to/wallpaper'\nGRUB_THEME='/boot/grub/themes/Vimix/theme.txt'\nGRUB_COLOR_NORMAL='light-blue/black'\nGRUB_COLOR_HIGHLIGHT='light-cyan/blue'" >> /etc/default/grub
    sed -i "s/^GRUB_TERMINAL_OUTPUT/#GRUB_TERMINAL_OUTPUT/" /etc/default/grub 
    grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1 || return 1

    printf "\tEnabling NetworkManager...\n"
    systemctl enable NetworkManager.service > /dev/null 2>&1

    printf "\tEnabling CUPS socket for printing...\n"
    systemctl disable cups.service > /dev/null 2>&1
    systemctl enable cups.socket > /dev/null 2>&1

    printf "\tConfiguring MPD...\n"
    sudo -u $username mkdir -p "$homedir/.config/mpd/playlists"
    sudo -u $username systemctl --user enable mpd.service > /dev/null 2>&1  # might try mpd.socket later

    printf "\tCreating NeoMutt directory...\n"
    sudo -u $username mkdir -p "$homedir/dls/email_attachments"

    printf "\tEnabling and configuring Transmission...\n"
    mkdir -p /etc/systemd/system/transmission.service.d/
    printf "[Service]\nUser=$username" > /etc/systemd/system/transmission.service.d/username.conf
    systemctl enable transmission.service > /dev/null 2>&1

    printf "\nPackage configuration done.\n"
}

# Configuring NeoVim
configneovim() {
    printf "\nDeploying NeoVim configuration:\n"

    printf "\tInstalling Language Providers...\n"
    sudo -u $username pip --no-input install -U pynvim > /dev/null 2>&1
    sudo -u $username npm install -g neovim > /dev/null 2>&1

    printf "\tInstalling VimPlug...\n"
    sudo -u $username sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' > /dev/null 2>&1

    printf "\tInstalling Plugins...\n"
    sudo -u $username nvim -c "messages clear|PlugInstall|UpdateRemotePlugins|PlugUpdate|qall"

    printf "\tInstalling CocPlugins...\n"
    for plg in ${cocplugins[@]}; do
        printf "\t\tInstalling coc-$plug...\n"
        sudo -u $username nvim +"messages clear" +"CocInstall -sync coc-$plg" +"qall"
    done
}

# Compile and install from source (used for suckless utilities)
makeinstallsource() {
    printf "\t$1...\n"
    repo="https://github.com/arsanysamuel/$1.git"
    sudo -u $username git -C "$homedir/.config" clone -q --depth 1 --single-branch --no-tags $repo
    cd $homedir/.config/$1
    sudo -u $username make > /dev/null 2>&1 || return 1
    make clean install > /dev/null 2>&1 || return 1
}

# Finalize installation
finalize() {
    printf "\nBootstrapping script has completed successfully, provided there were no hidden errors.\nAll packages have been installed and configured, please reboot the system to complete the installation.\n\nDo you want to reboot now [Y/n]? "
    read -r
    ! [[ -z "$REPLY" || "$REPLY" == "y" || "$REPLY" == "Y" ]] || reboot
}


### Main Script ###
welcome || error "User exited."

getuserinfo || error "User exited."

printf "\nThe script will proceed to bootstrap the system fully automated without any more input required from you, this may take some time.\n\nPress any key to continue..."
read -s -n 1

installrequirements
adduser || error "Error has occurred while adding/modifying user."

# Use all CPU cores for compilation
sed -i "s/-j2/-j$(nproc)/;/#MAKEFLAGS/s/^#//" /etc/makepkg.conf

installaurhelper || error "Failed to install PIKAUR"
deploydotfiles || error "Failed to deploy .dotfiles"
installpkglist || error "Failed to install a package, check the logs and try again."
pacmanconfig

# Allow dmesg access for all users
printf "kernel.dmesg_restrict = 0" > /etc/sysctl.d/dmesg.conf

printf "\nBuilding and installing suckless tools:\n"
for t in ${suckless[@]}; do
    makeinstallsource $t || error "Failed to build and install $t"
done

configgit
configpkgs || error "Failed to configure this package."
configneovim || error "Failed to deploy neovim configuration."

printf "\nAdding StevenBlack list to /etc/hosts...\n"
curl -s http://sbc.io/hosts/alternates/fakenews-gambling-porn/hosts > /etc/hosts

finalize

