# arch-bootstrapper
Bootstrapping script for a fresh ArchLinux installation.

### Usage
1. Install Arch Linux by following the [installation guide](https://wiki.archlinux.org/title/Installation_guide).
2. Install and configure [GRUB](https://wiki.archlinux.org/title/GRUB) and install the microcode blob according to the CPU manufacturer.
3. Configure Network by following the [network configuration](https://wiki.archlinux.org/title/Network_configuration) wiki page, using `NetworkManager` is recommended.
4. Start the script as root user with the following command:
    ```
    curl -O https://raw.githubusercontent.com/arsanysamuel/arch-bootstrapper/main/bootstrap.sh &&
    ./bootstrap.sh
    ```
