# GEMINI.md - Context for AI Agents

This file provides high-level context, architectural guidelines, and conventions for AI agents working on this NixOS configuration repository.

## Project Overview

This is a personal NixOS configuration repository managed using **Nix Flakes** and **Home Manager**. It is designed for portability across different hosts, including bare-metal workstations and WSL2 instances.

## Architecture

The project follows a layered, modular structure to ensure configuration can be reused across different hardware environments.

*   **Entry Point**: `flake.nix` is the source of truth, defining inputs (dependencies) and outputs (`nixosConfigurations`).
*   **System Configuration (`hosts/`)**:
    *   **`common/`**: Contains shared system modules (e.g., `base.nix`, `desktop.nix`, `audio.nix`, `bare-metal.nix`).
    *   **`<hostname>/`**: Specific configuration for a machine.
        *   `default.nix`: Imports required common modules and defines host-specific settings.
*   **User Configuration (`users/`)**:
    *   **`<username>/`**: Segmented Home Manager modules.
        *   `core.nix`: Essential CLI tools, shell, and editor config.
        *   `dev.nix`: Base developer toolset.
        *   `desktop.nix`: GUI apps and desktop services.
        *   `ai.nix`, `kubernetes.nix`: Specialized toolsets.
        *   `res/`: Stores raw dotfiles referenced by the Nix config.

## Key Technologies

*   **NixOS & Nix Flakes**: System management and dependency tracking.
*   **Home Manager**: User-level environment and dotfile management.
*   **NixOS-WSL**: Support for running NixOS under WSL2.
*   **Jujutsu (jj)**: Version control system (Git backend).

## Development Conventions & Rules

**Strict Adherence Required:**

1.  **Line Length Limit**: **MAXIMUM 80 COLUMNS per line.**
2.  **Modularity**: Avoid monolithic files. Split functionality into logical modules and import them where needed.
3.  **Portability**: When adding new configurations, consider if they are host-specific or should be part of a shared module.
4.  **Reproducibility**: Ensure all new dependencies are added to `flake.nix` or relevant Nix modules.

## Operational Tasks

### Adding a New Host
1.  Create `hosts/<hostname>/`.
2.  Add `hardware-configuration.nix` (if applicable).
3.  Create `hosts/<hostname>/default.nix`, importing necessary modules from `hosts/common/`.
4.  Register the new host in `flake.nix`.

### Adding a New User Component
1.  Create a new `.nix` file in `users/<username>/`.
2.  Import this new component in the relevant host-level Home Manager configurations.

## Version Control
*   Use `jj` commands for version control operations.
*   Ensure atomic commits that describe the *intent* of the change.
