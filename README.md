# garden

This repository manages my dotfiles and system configuration state using [Chezmoi](https://www.chezmoi.io/).
It features a self-healing architecture that automatically backs up installed packages and enabled services, ensuring my system is always reproducible.

[Download Wallpaper Here](https://www.dropbox.com/s/vl49u8dypw99y51/disco_elysium_high_res.jpg?dl=0).

## Profiles & specs

The configuration adapts based on the `profile` defined in `~/.config/chezmoi/chezmoi.toml`.

| Profile | Type | Hardware Spec |
| :--- | :--- | :--- |
| **`butterfly`** | Laptop | High-DPI (1.25x scale), Touchpad gestures, single monitor focus. |
| **`garden`** | Desktop | Dual monitor (HDMI + Vertical DP), Standard kb/mouse. |

**Data Locations:**
*   **Hardware DB**: `.chezmoidata/hardware.toml` (Monitor configs per profile).
*   **Package Lists**: `packages/<profile>.txt` (List of parabolic/pacman packages).
*   **Service Lists**: `services/<profile>.txt` (List of enabled user systemd services).
*   **Keyrings**: `~/.local/share/keyrings/` (Encrypted with `age` via chezmoi).

---

## Security & Secrets

Sensitive files like GNOME Keyrings are managed using chezmoi's built-in encryption.

*   **Encryption**: [age](https://github.com/FiloSottile/age)
*   **Key Location**: `~/.config/chezmoi/key.txt` (Not tracked in git)
*   **Managed Secrets**:
    *   `Default_keyring.keyring`
    *   `user.keystore`
    *   `default` (symlink target)

To add new secrets:
```bash
chezmoi add --encrypt <path-to-secret>
```

---

## Scripts

These scripts are installed to `~/.local/bin/`.


### `scrape-machine.sh`
*   **Location**: `~/.local/bin/scrape-machine.sh`
*   **Purpose**: Generates a TOML configuration snippet for the current machine's hardware.
*   **Usage**: Run it to see the detected Monitors (Niri), CPU, and GPU capabilities (CUDA/ROCm/XPU - only WIP).
    ```bash
    scrape-machine.sh
    ```
*   **Workflow**: Use the output to update `.chezmoidata/hardware.toml` when setting up a new machine or changing hardware.

### `update-packages`
*   **Purpose**: Backs up current system packages to `packages/<profile>.txt`.
*   **Logic**: Runs `paru -Qttq`, sorts the output, and writes to the source file. It effectively "snapshots" the current state.

### `update-services`
*   **Purpose**: Backs up currently enabled user services to `services/<profile>.txt`.
*   **Logic**: query `systemctl --user`, filters out noise, and saves the list.

### **Automation (Systemd Watchers)**
Instead of running these manually, **Systemd Path Units** watch for changes and trigger them automatically:
*   `chezmoi-watch-packages.path` -> Watches `/var/lib/pacman/local` -> Triggers `update-packages`.
*   `chezmoi-watch-services.path` -> Watches `~/.config/systemd/user` -> Triggers `update-services`.

---

## Run Scripts

These scripts run automatically during `chezmoi apply` to enforce the "Restore/Sync" side of the loop.

### `run_onchange_before_00-packages.sh.tmpl`
*   **Trigger**: Runs whenever `packages/<profile>.txt` changes (hash based).
*   **Action**:
    1.  **Installs** missing packages using `paru`.
    2.  Checks for "extra" packages (installed but not in list).
    3.  **Prompts** the user to remove these extras (Self-healing).

### `run_onchange_after_01-services.sh.tmpl`
*   **Trigger**: Runs whenever `services/<profile>.txt` changes.
*   **Action**:
    1.  **Enables** missing services using `systemctl --user`.
    2.  Checks for "extra" enabled services.
    3.  **Prompts** the user to disable these extras.

### `run_once_after_99-enable-watcher.sh`
*   **Trigger**: Runs once (or when script changes).
*   **Action**: Installs, enables, and starts the systemd watchers mentioned above, ensuring the automation loop is active.
