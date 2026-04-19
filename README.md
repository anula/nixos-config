# anula's NixOS configuration (`anula/nix-config`)

Full config for my personal NixOS installation, managed with Flakes and Home Manager.
Designed for portability across different hosts (bare-metal and WSL).

## Structure

* **`flake.nix`**: The main entry point. It defines dependencies and lists all system configurations.

* **`hosts/`**: Contains system-level configurations.
  * **`common/`**: Shared modules (base, desktop, audio, bare-metal).
  * **`<hostname>/`**: Specific configuration for a machine.
    * `default.nix`: Imports required common modules and host-specific settings.
    * `hardware-configuration.nix`: Machine-specific hardware settings (generated during install).

* **`users/`**: Contains user-level Home Manager configurations.
  * **`<username>/`**:
    * `core.nix`: Essential CLI tools and shell config (portable everywhere).
    * `dev.nix`: Base developer tools.
    * `desktop.nix`: GUI applications and desktop settings.
    * `ai.nix`: AI agent sandboxes.
    * `kubernetes.nix`: K8s specific toolset.
    * `res/`: Raw dotfiles (vimrc, tmux.conf).

## How to Deploy on a New Machine

### For Bare-Metal NixOS
1. **Install NixOS**: Perform a standard installation to generate `/etc/nixos/hardware-configuration.nix`.
2. **Clone This Repository**:
   ```bash
   nix shell nixpkgs#jujutsu
   jj git clone git@github.com:anula/nixos-config.git ~/.nixos-config
   ```
3. **Add the New Host**:
   - Create `hosts/<hostname>/`.
   - Copy `/etc/nixos/hardware-configuration.nix` into it.
   - Create `default.nix` importing required modules from `../common/`.
   - Add to `flake.nix` under `nixosConfigurations`.
4. **Switch**: `sudo nixos-rebuild switch --flake .#<hostname>`

### For WSL
1. Ensure `nixos-wsl` input is in `flake.nix`.
2. Create a host entry using `nixos-wsl.nixosModules.default` (see `hosts/lufcik`).
3. Import `hosts/common/base.nix` and relevant user modules.
