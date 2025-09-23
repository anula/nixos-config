# anula's NixOS configuration (`anula/nix-config`)

Full config for my personal NixOS installation, managed with Flakes and Home Manager.

## Structure

* **`flake.nix`**: The main entry point. It defines dependencies and lists all system configurations.

* **`hosts/`**: Contains system-level configurations.

  * `common.nix`: Base settings shared by all hosts.

  * `<hostname>/`: A directory for the `<hostname>` host (hosts are distinguished by their hostnames).

    * `default.nix`: The main configuration for the host.

    * `hardware.nix`: The machine-specific hardware configuration the host.

* **`users/`**: Contains user-level configurations.

  * `<username>`: A directory for user `<username>`

    * `default.nix`: The main home manager config for the user.

    * `res/`: Directory with additional resources (eg. raw dotfiles) for the user.

## How to Deploy on a New Machine

This procedure will take over a fresh NixOS installation and apply the configuration for a *new* host.

1. **Install NixOS**: Perform a standard installation. This will generate a `/etc/nixos/hardware-configuration.nix`.

2. **Clone This Repository**: Log in to the new system and clone this repository:

   ```
   nix shell nixpkgs#jujutsu
   jj git clone git@github.com:anula/nixos-config.git ~/.nixos-config
   ```

3. **Add the New Host**:
   a. Create a new directory for your host (e.g., `hosts/new-machine`).
   b. **Copy the generated hardware configuration** into your repo:

   ```
   cp /etc/nixos/hardware-configuration.nix ~/nix-config/hosts/new-machine/hardware-configuration.nix
   ```

   c. Create a `default.nix` for the new host, (see `hosts/kawerna/default.nix` for example).
   d. Add the new host to your `flake.nix` under `nixosConfigurations`.

4. **Run the Build**: From the root of the repository, run the build command for the new host:

   ```
   sudo nixos-rebuild switch --flake ~/.nix-config#new-machine
   ```

5. **Commit the Changes**
