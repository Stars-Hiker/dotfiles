# Recovery test — proving a rebuild actually works

The whole point of this setup is that I can rebuild the laptop from GitHub. The
**only** way to know that's true is to do it once, in a throwaway VM, *before* I
ever need it for real. This is that test.

Run it after any big change to `postInstall` or the package lists. It uses the
QEMU/KVM stack this machine already has (`virt-manager`).

---

## 0. Before you start

You need, from your existing machine:
- Your **private age key** — the `AGE-SECRET-KEY-...` line from Bitwarden / USB
  (you'll paste it into the VM). Without it the secrets step can't be tested.
- A **CachyOS ISO** (or Arch ISO) — download the latest.

> The VM has no access to your real disks or SSH agent. It's a clean room.

---

## 1. Create the VM

```sh
# GUI: virt-manager → Create a new VM → Local install media → pick the ISO.
#   - RAM: 4096 MB+   - CPUs: 2+   - Disk: 30 GB+
#   - Firmware: UEFI (matches this laptop's systemd-boot setup)
```

Boot the ISO and do a **minimal** base install (the CachyOS installer is fine):
- a normal user account (same username keeps paths identical, but any works),
- a network connection,
- **Btrfs root** if you want to also exercise the snapper step.

Reboot into the fresh install and log in as your normal user (**not** root).

---

## 2. Run the bootstrapper

```sh
git clone https://github.com/Stars-Hiker/postInstall ~/postInstall
cd ~/postInstall
./ArchHyprPostInstall.sh
```

Let it run to the end. Expect: pacman configured (multilib), paru built, dotfiles
cloned + stowed, the full package list installed (watch for the failure summary at
the end), services/firewall/Hyprland set up, TLP + snapper configured.

---

## 3. Restore secrets

```sh
mkdir -p ~/.config/age
$EDITOR ~/.config/age/keys.txt      # paste the AGE-SECRET-KEY... line
~/.dotfiles/bin/secrets-unseal.sh   # decrypts ~/.ssh, fixes perms
```

---

## 4. Reboot

```sh
sudo reboot
```

Needed for group membership (libvirt, kvm) and the zsh default shell.

---

## 5. Verification checklist

After the reboot, tick each item. Any unchecked box = a gap to fix in the repos.

- [ ] **Packages**: `comm -23 <(sort ~/.dotfiles/pkglists/pkgs-native.txt) <(pacman -Qqen | sort)`
      prints nothing (everything from the list is installed). If it lists names,
      they're the ones the resilient installer reported as failed — investigate.
- [ ] **Configs stowed**: `readlink ~/.config/hypr/hyprland.conf` points into
      `~/.dotfiles/...` (symlink, not a real file).
- [ ] **Shell**: `echo $SHELL` is zsh; tab-completion shows the **fzf-tab** picker
      (the bug this test exists to catch).
- [ ] **Hyprland starts**: log into the Hyprland session from SDDM and get a desktop.
- [ ] **Secrets**: `ls -l ~/.ssh` shows your keys with `600` perms; `ssh -T git@github.com`
      authenticates (if those keys are GitHub keys).
- [ ] **Power (laptop)**: `tlp-stat -s` shows TLP enabled; `systemctl is-enabled tlp` = enabled.
- [ ] **Snapshots (Btrfs)**: `sudo snapper list-configs` shows a `root` config;
      `sudo snapper -c root list` has entries; a `sudo pacman -S --needed bat` creates
      a pre/post pair.
- [ ] **Firewall**: `sudo ufw status` = active.

---

## 6. Tear down

Once everything's green: `virsh destroy <vm>` and `virsh undefine <vm> --remove-all-storage`,
or just delete the VM in virt-manager. Note anything that failed and fix it in the
repos so the next real recovery is clean.
