# GDM & Session Crash Fix Log - April 14, 2026

This document summarizes the investigation and fixes applied to resolve the GDM ("gmd") and session crashes on this NVIDIA PRIME system.

---

## Attempt 1: Initial Stabilization (Previous Session)
- **Symptom:** GDM failing to start or looping.
- **Changes:** Disabled Wayland for GDM, added GNOME portal, set global NVIDIA environment variables.
- **Result:** **Failed.** GDM stopped loading entirely due to missing session files in X11 mode.

---

## Attempt 2: Session Registration Fix (Previous Attempt)
- **Symptom:** GDM core-dumps immediately on startup with `no session desktop files installed`.
- **Root Cause:** Forcing GDM to X11 mode without correct session files, and global NVIDIA variables crashing the Intel-driven greeter.
- **Changes:** Removed global NVIDIA variables, re-enabled GDM Wayland, explicitly enabled GNOME sessions using both old and new style options.
- **Result:** **Failed.** GDM greeter loads, but user session (GNOME/Hyprland) fails to register after password entry.

---

## Attempt 3: NVIDIA Driver & GSP Stabilization (Previous Attempt)
- **Symptom:** `GdmDisplay: Session never registered, failing` after login.
- **Kernel Logs:** `NVRM: _kgspProcessRpcEvent: Attempted to process RPC event from GPU0 ... during bootup without API lock`.
- **Changes:** Switched to the proprietary NVIDIA driver (`open = false`), disabled GSP firmware (`nvidia.NVreg_EnableGpuFirmware=0`), and integrated `nixos-facter`.
- **Result:** **Waiting for Reboot Verification.** (Simultaneous investigation into UWSM and stateVersion below).

---

## Attempt 4: UWSM & stateVersion Alignment (Current)

### 1. Investigation & Diagnostics
- **Symptom:** Continued "Session never registered" failures and a persistent warning that `stateVersion` is missing or defaulting to `26.05`.
- **Root Cause:**
    - **UWSM Integration:** Using `withUWSM = true` with GDM can cause race conditions or hand-off failures where GDM kills the session before it registers.
    - **Version Mismatch:** The nixpkgs `unstable` branch is targeting `26.05`, and setting an older version (`25.05`) in an unstable context was likely causing the "not found" or "defaulting" warning.

### 2. Changes Applied

#### A. Disable UWSM for Hyprland (`desktop-environment/hyprland.nix`)
- **Action:** Set `programs.hyprland.withUWSM = false;`.
- **Reason:** To simplify the session launch chain and ensure GDM can correctly register the Hyprland session.

#### B. Align stateVersion to 26.05 (`configuration.nix` & `home.nix`)
- **Action:** Set `system.stateVersion = "26.05";` and `home.stateVersion = "26.05";`.
- **Reason:** To match the target version of your current NixOS channel and eliminate the evaluation warnings.

### 3. Next Steps
1. **Full Reboot:** Crucial to load the proprietary driver and the new `stateVersion` context.
2. **Login Test (GNOME):** Confirm basic session registration works.
3. **Login Test (Hyprland):** Test Hyprland without the UWSM wrapper.
