# How my laptop backup & recovery works

This is the plain-language guide to how my Arch/CachyOS + Hyprland laptop backs
itself up to GitHub and how to rebuild it from scratch if it ever dies, gets
stolen, or I do something regrettable with `rm -rf`.

If you read nothing else, read these three lines:

- **To save the current state:** run `dotsync`.
- **To rebuild a dead machine:** clone `postInstall`, run the script, paste in the age key.
- **The one thing that must never be lost:** `~/.config/age/keys.txt` (it's in Bitwarden + a USB stick).

---

## 1. The big idea

The goal is simple: **if anything bad happens to this laptop, I can get back to
exactly this setup from GitHub.**

To do that, three kinds of things need to be saved:

| What | Example | Where it's saved |
|------|---------|------------------|
| **Configs** (dotfiles) | Hyprland, kitty, nvim, zsh, waybar… | `dotfiles` repo (plain files) |
| **The list of installed programs** | firefox, neovim, qemu, paru packages… | `dotfiles` repo (`pkglists/`) |
| **Secrets** | SSH keys | `dotfiles` repo, but **encrypted** |

What is **not** saved: personal files (documents, photos, downloads). This system
rebuilds the *machine*, not my *data*. Those need a separate backup if I want them.

---

## 2. The two repositories

There are two GitHub repos that work as a team:

### `postInstall` — the builder
> https://github.com/Stars-Hiker/postInstall

A single big script, `ArchHyprPostInstall.sh`. Think of it as the **construction
crew**. On a fresh, empty machine it installs the basic tools, fetches the
`dotfiles` repo, installs every program from the saved lists, restores the
secrets, and sets up services, firewall, and Hyprland. I run it once, on a new
machine.

### `dotfiles` — the blueprint (this repo)
> https://github.com/Stars-Hiker/dotfiles

The **living source of truth**. It holds the actual config files, the package
lists, and the encrypted secrets. This is the repo I touch all the time — every
time I tweak my setup, the changes end up here and get pushed to GitHub.

**Mental model:** `dotfiles` is *what my machine should look like*. `postInstall`
is *the robot that reads the blueprint and builds it*.

---

## 3. What's inside this repo

```
~/.dotfiles/
├── bash/ btop/ git/ hypr/ kitty/ nvim/ paru/ rofi/ waybar/ zsh/  ← config files
│                                                    (one folder per "stow package")
├── pkglists/
│   ├── pkgs-native.txt   ← every official package I installed (pacman)
│   └── pkgs-aur.txt      ← every AUR package I installed (paru)
├── secrets/
│   ├── secrets.tar.age   ← my SSH keys, ENCRYPTED (safe to be public)
│   ├── recipient.txt     ← my public age key (safe to be public)
│   └── .gitignore        ← blocks any plaintext secret from ever being committed
├── bin/
│   ├── pkg-snapshot.sh   ← regenerates the two pkglists from the live system
│   ├── sync.sh           ← the `dotsync` command (snapshot + commit + push)
│   ├── secrets-seal.sh   ← encrypts my secrets into secrets.tar.age
│   └── secrets-unseal.sh ← decrypts them back (needs my private key)
├── install.sh            ← deploys all the configs into $HOME using stow
├── README.md             ← short runbook
└── GUIDE.md              ← this file
```

### What is "stow"?
The config folders (`hypr/`, `kitty/`, etc.) mirror where the files live in my
home directory. [GNU Stow](https://www.gnu.org/software/stow/) creates
**symlinks** from `$HOME` into this repo. So `~/.config/hypr/hyprland.conf` is
actually a link pointing at `~/.dotfiles/hypr/.config/hypr/hyprland.conf`.

Why this is great: I edit my config normally, and the change is *automatically*
inside the git repo — no copying. `install.sh` is what sets up all those links on
a fresh machine.

---

## 4. Saving my current state (daily use)

Whenever I change something I want to keep — installed a new program, tweaked a
config — I save it with one command:

```sh
dotsync
```

That's an alias (defined in `zsh/.zshrc`) for `~/.dotfiles/bin/sync.sh`, which:
1. Regenerates `pkglists/` so they match what's installed right now.
2. `git add` + `git commit` everything that changed.
3. `git push` to GitHub.

I don't have to think about the package lists staying current — a **pacman hook**
(`/etc/pacman.d/hooks/95-pkglist-snapshot.hook`, installed by `postInstall`)
automatically rewrites the lists after *every* install/remove/upgrade. So in
practice `dotsync` just commits and pushes what already updated itself.

### Handy aliases
| Command | What it does |
|---------|--------------|
| `dotsync` | snapshot package lists, commit, and push to GitHub |
| `pkgsnap` | only regenerate the package lists (no commit) |
| `dots` | jump to `~/.dotfiles` and show `git status` |

---

## 5. Secrets, explained simply

SSH keys can't sit in a normal GitHub repo — anyone could read them. But I still
want them backed up. The solution is **encryption with [age](https://age-encryption.org)**.

How it works, in everyday terms:

- I have a **key pair**: a *public* key (a padlock) and a *private* key (the only
  key that opens that padlock).
- The **public** key (`secrets/recipient.txt`) locks my secrets into
  `secrets/secrets.tar.age`. That encrypted file is safe to put on GitHub —
  **even if the repo were public**, nobody can open it.
- The **private** key (`~/.config/age/keys.txt`) is the *only* thing that can
  unlock it. It is **never** in git. It lives in **Bitwarden** and on a **USB
  stick**.

```
   ~/.ssh  ──[ lock with PUBLIC key ]──▶  secrets.tar.age  ──▶  GitHub  ✅ safe
   secrets.tar.age  ──[ unlock with PRIVATE key ]──▶  ~/.ssh           🔑 only me
```

### Saving / updating secrets
If I add or change something I want encrypted (the default is `~/.ssh`):
```sh
~/.dotfiles/bin/secrets-seal.sh   # re-encrypts into secrets/secrets.tar.age
dotsync                            # commit + push the encrypted blob
```
To change *which* files are sealed, edit the `ITEMS=(...)` list near the top of
`bin/secrets-seal.sh`.

### The golden rule
- `recipient.txt` (public) and `secrets.tar.age` (encrypted) → **go to GitHub** ✅
- `~/.config/age/keys.txt` (private) → **Bitwarden + USB only, never GitHub** ❌

The `.gitignore` files are set up so even if I accidentally drop a plaintext key
or a `keys.txt` into the repo, git will refuse to track it. But backing up the
private key is on me — that's the part that makes recovery actually possible.

---

## 6. 🚨 Rebuilding a dead/new machine (full recovery)

Starting point: a fresh Arch/CachyOS install with a working internet connection,
logged in as my normal user (**not** root).

### Step 1 — get the builder and run it
```sh
git clone https://github.com/Stars-Hiker/postInstall ~/postInstall
cd ~/postInstall
./ArchHyprPostInstall.sh
```
This installs the base tools + paru, clones this `dotfiles` repo, symlinks all my
configs with stow, installs **every** program from `pkglists/`, sets up services,
firewall, and Hyprland.

### Step 2 — restore my secrets (the SSH keys)
The script restores secrets automatically **if** my private age key is already in
place. So before (or after) running it:
```sh
mkdir -p ~/.config/age
$EDITOR ~/.config/age/keys.txt    # paste the AGE-SECRET-KEY... from Bitwarden/USB
~/.dotfiles/bin/secrets-unseal.sh # decrypts ~/.ssh and fixes permissions
```
If I run the big script *before* placing the key, it just prints a reminder and
keeps going — I can unseal manually afterward with the command above.

### Step 3 — reboot
Needed so group memberships (libvirt, kvm) and the zsh default shell take effect.

That's it. The machine should come back looking and behaving exactly like before.

---

## 7. The single most important thing

Everything above depends on **one file**: `~/.config/age/keys.txt` (specifically
the `AGE-SECRET-KEY-...` line inside it).

- It is the *only* thing that can decrypt my SSH keys.
- It is deliberately **not** on GitHub.
- So it must live in **at least two places that aren't this laptop**, because the
  laptop dying is the exact scenario I'm protecting against.

**Where it lives:**
1. **Bitwarden** — as a Secure Note titled e.g. *"age private key (dotfiles)"*.
2. **A USB stick** — an offline copy, in case Bitwarden is ever unreachable.

If I lose this key, the encrypted secrets become permanently unrecoverable
(everything else still rebuilds fine — I'd just have to generate new SSH keys).

---

## 8. Cheat sheet

```sh
# ── Everyday ──────────────────────────────────────────────
dotsync                              # save current state to GitHub
dots                                 # cd ~/.dotfiles + git status
make -C ~/.dotfiles help             # list all make targets
make -C ~/.dotfiles doctor           # health-check this machine (no sudo)

# ── Secrets ───────────────────────────────────────────────
~/.dotfiles/bin/secrets-seal.sh      # re-encrypt secrets, then: dotsync
~/.dotfiles/bin/secrets-unseal.sh    # restore secrets (needs private key)

# ── Fresh-machine recovery ────────────────────────────────
git clone https://github.com/Stars-Hiker/postInstall ~/postInstall
cd ~/postInstall && ./ArchHyprPostInstall.sh
# then place ~/.config/age/keys.txt and run secrets-unseal.sh

# ── First-time age setup (already done once) ──────────────
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/keys.txt
grep 'public key' ~/.config/age/keys.txt | awk '{print $NF}' \
    > ~/.dotfiles/secrets/recipient.txt
~/.dotfiles/bin/secrets-seal.sh && dotsync
# → then back up ~/.config/age/keys.txt to Bitwarden + USB
```

---

## 9. Quick troubleshooting

**"My new program didn't come back after recovery."**
It wasn't in the package lists. Run `dotsync` on the working machine *before* it
dies — that's what records installed programs.

**"secrets-unseal.sh says: no age identity."**
The private key isn't at `~/.config/age/keys.txt`. Restore it from Bitwarden/USB
first, or point to it: `AGE_IDENTITY=/path/to/keys.txt ~/.dotfiles/bin/secrets-unseal.sh`.

**"stow complains about conflicts on a fresh machine."**
`install.sh` backs up any pre-existing real files to
`~/.dotfiles-backup-<timestamp>/` before linking, so nothing is lost — check
there.

**"Is my setup actually recoverable right now?"**
The only true test is booting a fresh Arch/CachyOS VM (I have QEMU/KVM), running
the Step 1–3 recovery, and confirming everything comes back. There's a full
step-by-step runbook with a verification checklist in
**[RECOVERY-TEST.md](RECOVERY-TEST.md)** — worth doing once so I trust it before I
ever need it for real.
