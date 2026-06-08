# dotfiles

Reproducible configuration for an Arch/CachyOS + Hyprland laptop. Managed with
[GNU Stow](https://www.gnu.org/software/stow/). This repo is the **living source
of truth**: configs, the package lists, and (encrypted) secrets. The companion
[`postInstall`](https://github.com/Stars-Hiker/postInstall) repo is the
bootstrapper that consumes it on a fresh machine.

> 📖 **New here or rebuilding a machine?** Read **[GUIDE.md](GUIDE.md)** — a
> plain-language explanation of how the whole backup/recovery system works.

## Layout

| Path | What |
|------|------|
| `bash/ btop/ git/ hypr/ kitty/ nvim/ paru/ rofi/ waybar/ zsh/` | Stow packages (mirror their place under `$HOME`) |
| `pkglists/pkgs-native.txt` | Explicit repo packages (`pacman -Qqen`) — **source of truth** |
| `pkglists/pkgs-aur.txt` | Explicit AUR/foreign packages (`pacman -Qqem`) |
| `secrets/secrets.tar.age` | SSH keys etc., encrypted with `age` (safe to commit) |
| `secrets/recipient.txt` | Public age key (safe to commit) |
| `bin/` | `install.sh` helpers: snapshot / sync / seal / unseal |
| `install.sh` | Deploys all stow packages into `$HOME` |

---

## 🔁 Restore on a fresh machine

After a base Arch/CachyOS install, as your normal user (not root):

```sh
git clone https://github.com/Stars-Hiker/postInstall ~/postInstall
cd ~/postInstall
./ArchHyprPostInstall.sh
```

This installs the base toolchain + paru, clones this repo, **stows** the configs,
installs every package from `pkglists/`, and then **restores your secrets** —
*if* your age key is present (see below). Finally it sets up services, firewall,
and Hyprland.

### Restoring secrets

Your encrypted secrets can only be opened with your **private age key**, which is
**not** in git. Before (or after) the script runs:

```sh
mkdir -p ~/.config/age
# paste the key you saved in Bitwarden / on USB:
$EDITOR ~/.config/age/keys.txt          # contains the "AGE-SECRET-KEY-..." line
~/.dotfiles/bin/secrets-unseal.sh       # restores ~/.ssh with correct perms
```

> ⚠️ Without that key the secrets are unrecoverable. Keep it in Bitwarden **and**
> on a USB stick. Never commit it.

---

## 💾 Save your current state (ongoing)

```sh
dotsync        # = ~/.dotfiles/bin/sync.sh : refresh pkg lists, commit, push
```

Package lists also refresh **automatically** after every `pacman`/`paru`
operation via the hook installed by `postInstall`
(`/etc/pacman.d/hooks/95-pkglist-snapshot.hook`) — so you usually just need to
`dotsync` to commit + push.

When you change which secrets are tracked (or rotate keys), edit the `ITEMS` list
in `bin/secrets-seal.sh`, then:

```sh
~/.dotfiles/bin/secrets-seal.sh && dotsync
```

### Aliases

| Alias | Action |
|-------|--------|
| `dotsync` | snapshot pkg lists, commit, push |
| `pkgsnap` | regenerate package lists only |
| `dots` | `cd ~/.dotfiles` + `git status` |

---

## 🔐 First-time secrets setup (one-off)

```sh
sudo pacman -S age
age-keygen -o ~/.config/age/keys.txt          # prints "Public key: age1..."
# put the PUBLIC key in the repo (safe to commit):
grep 'public key' ~/.config/age/keys.txt | awk '{print $NF}' > ~/.dotfiles/secrets/recipient.txt
~/.dotfiles/bin/secrets-seal.sh               # creates secrets/secrets.tar.age
dotsync
```

Then save `~/.config/age/keys.txt` to Bitwarden and a USB stick.
