# ABBAS

<b>A</b>rch <b>B</b>ootstrapper <b>B</b>y <b>A</b>rsany <b>S</b>amuel

Bootstrapping script for a fresh Arch Linux installation.

### Usage
1. Install Arch Linux by following the [installation guide](https://wiki.archlinux.org/title/Installation_guide).
2. Install and configure [GRUB](https://wiki.archlinux.org/title/GRUB) and install the microcode blob according to the CPU manufacturer.
3. Configure Network by following the [network configuration](https://wiki.archlinux.org/title/Network_configuration) wiki page, using `NetworkManager` is recommended.
4. Start the script as root user with the following command:
    ```
    curl -LO https://raw.githubusercontent.com/arsanysamuel/arch-bootstrapper/main/bootstrap.sh &&
    sh bootstrap.sh
    ```
5. (Optional) Add configuration for your laptop (if running on a laptop) using this [wiki page](https://wiki.archlinux.org/title/Laptop).


### Resources
- [archlinux wiki](https://wiki.archlinux.org/)
- [pikaur](https://github.com/actionless/pikaur)
- [dwm](https://github.com/arsanysamuel/dwm)
- [st](https://github.com/arsanysamuel/st)
- [dmenu](https://github.com/arsanysamuel/dmenu)
- [dotfiles](https://github.com/arsanysamuel/dotfiles)
- [LARBS](https://larbs.xyz/)


***Disclaimer:*** This script was intended for my personal use to install my package list, deploy my configuration files and builds, if you're looking for more general usage try using [LARBS](https://larbs.xyz/) as it supports bootstrapping with different package list and dotfiles repo.
