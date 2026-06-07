# Configuration Réseau — Orange Pi Zero 2W

> Mise en place d'un accès USB OTG + Wi-Fi sous NetworkManager  
> OS : Armbian 26.2.x trixie (Debian 13)

---

## Résultat final

```
wlan0   192.168.1.69   ← Wi-Fi (accès confortable)
usb0    192.168.7.2    ← USB OTG (accès de secours, sans réseau)
```

---

## Partie 1 — Accès USB OTG (sans Wi-Fi ni écran)

### 1.1 Matériel requis

- Câble USB-C **avec fils data** (pas un câble charge seule)
- Port **USB-C OTG** de la board (le second port, pas celui d'alimentation)

```
┌──────────────────────────┐
│  [USB-C POWER]           │  ← alimentation uniquement
│  [USB-C OTG]  ←──────────── câble vers votre PC
└──────────────────────────┘
```

---

### 1.2 Préparer la carte SD (une seule fois)

Insérer la SD dans votre PC. Monter la partition `armbi_root` (ext4).

#### Activer les modules gadget USB

```bash
echo "g_ether" | sudo tee -a /run/media/$USER/armbi_root/etc/modules
```

Vérifier que ces lignes sont présentes dans `/etc/modules` :

```
libcomposite
dwc3
g_ether
```

#### Créer le service de configuration réseau USB

```bash
sudo nano /run/media/$USER/armbi_root/etc/systemd/system/usb-gadget-eth.service
```

```ini
[Unit]
Description=USB Ethernet Gadget (g_ether)
After=systemd-modules-load.service
Requires=systemd-modules-load.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 2
ExecStart=/sbin/ip addr add 192.168.7.2/24 dev usb0
ExecStart=/sbin/ip link set usb0 up
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

#### Activer le service au démarrage

```bash
sudo mkdir -p /run/media/$USER/armbi_root/etc/systemd/system/multi-user.target.wants

sudo ln -s /etc/systemd/system/usb-gadget-eth.service \
  /run/media/$USER/armbi_root/etc/systemd/system/multi-user.target.wants/usb-gadget-eth.service
```

> ⚠️ Le lien symbolique pointe vers `/etc/...` sans le préfixe du point de montage —
> ce chemin sera résolu par la board au démarrage, pas par votre PC.

#### Démonter proprement

```bash
sync && sudo umount /run/media/$USER/armbi_root
```

---

### 1.3 Premier démarrage

1. Insérer la SD dans la board
2. Brancher l'alimentation sur le port **USB-C POWER**
3. Brancher le câble data sur le port **USB-C OTG** → votre PC
4. Attendre ~30 secondes le boot complet

---

### 1.4 Configurer l'interface réseau sur votre PC

```bash
# Repérer la nouvelle interface (enp4s0f3u3iX ou usb0)
ip link show

# Lui assigner une IP
sudo ip addr add 192.168.7.1/24 dev enp4s0f3u3i1   # adapter le nom
sudo ip link set enp4s0f3u3i1 up
```

#### Rendre la config permanente

```bash
sudo nmcli connection add \
  type ethernet \
  ifname enp4s0f3u3i1 \
  con-name "orangepi-usb" \
  ipv4.method manual \
  ipv4.addresses "192.168.7.1/24"
```

---

### 1.5 Connexion SSH

```bash
ping 192.168.7.2
ssh root@192.168.7.2
```

> ⚠️ Premier boot Armbian : mot de passe par défaut `1234`
> L'assistant force immédiatement le changement de mot de passe root
> et la création d'un utilisateur standard — c'est obligatoire.

L'assistant propose aussi de se connecter au Wi-Fi — répondre `Y` et suivre les instructions.

---

## Partie 2 — Migration vers NetworkManager

Armbian trixie utilise par défaut **Netplan + systemd-networkd + wpa_supplicant**.
Migration vers NetworkManager pour utiliser `nmtui`.

### 2.1 Installer NetworkManager

```bash
sudo apt install network-manager
```

### 2.2 Désactiver l'ancienne stack réseau

```bash
sudo systemctl disable --now systemd-networkd
sudo systemctl disable --now systemd-networkd.socket
sudo systemctl disable --now wpa_supplicant
```

### 2.3 Activer NetworkManager

```bash
sudo systemctl enable --now NetworkManager
```

### 2.4 Corriger NetworkManager.conf

Par défaut Armbian met `managed=false` ce qui empêche NM de gérer les interfaces :

```bash
sudo sed -i 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf
```

### 2.5 Nettoyer les fichiers Netplan

Armbian crée plusieurs fichiers Netplan en conflit. On les supprime et on repart propre :

```bash
# Lister les fichiers existants
ls /etc/netplan/
# Typiquement : 01-network.yaml  10-dhcp-all-interfaces.yaml  30-wifis-dhcp.yaml

# Supprimer les fichiers Armbian
sudo rm /etc/netplan/10-dhcp-all-interfaces.yaml
sudo rm /etc/netplan/30-wifis-dhcp.yaml

# Réécrire 01-network.yaml proprement
sudo nano /etc/netplan/01-network.yaml
```

```yaml
network:
  version: 2
  renderer: NetworkManager
  wifis:
    wlan0:
      dhcp4: yes
      access-points:
        "NOM_DU_RESEAU":
          password: "MOT_DE_PASSE"
  ethernets:
    all-eth:
      match:
        name: "e*"
      dhcp4: yes
```

```bash
# Corriger les permissions (obligatoire pour Netplan)
sudo chmod 600 /etc/netplan/01-network.yaml

# Appliquer
sudo netplan apply
sudo systemctl restart NetworkManager
```

### 2.6 Gérer usb0 avec NetworkManager

```bash
sudo nmcli device set usb0 managed yes

sudo nmcli connection add \
  type ethernet \
  ifname usb0 \
  con-name "usb-gadget" \
  ipv4.method manual \
  ipv4.addresses "192.168.7.2/24"

sudo nmcli connection up usb-gadget
```

### 2.7 Vérification finale

```bash
nmcli device status
```

```
DEVICE         TYPE      STATE      CONNECTION
wlan0          wifi      connected  wifi-home
usb0           ethernet  connected  usb-gadget
lo             loopback  connected  lo
```

---

## Partie 3 — Finalisation

### IP statique sur le Wi-Fi

```bash
sudo nmcli connection modify wifi-home \
  ipv4.method manual \
  ipv4.addresses "192.168.1.69/24" \
  ipv4.gateway "192.168.1.1" \
  ipv4.dns "1.1.1.1,8.8.8.8"

sudo nmcli connection up wifi-home
```

### Mise à jour du système

```bash
sudo apt update && sudo apt upgrade -y
```

### Config SSH sur votre PC

Ajouter dans `~/.ssh/config` sur votre machine de dev :

```ini
Host orangepi
    HostName 192.168.1.69
    User votre_user
    IdentityFile ~/.ssh/id_ed25519

Host orangepi-usb
    HostName 192.168.7.2
    User votre_user
    IdentityFile ~/.ssh/id_ed25519
```

```bash
ssh orangepi      # via Wi-Fi
ssh orangepi-usb  # via USB (toujours disponible sans réseau)
```

---

## Dépannage

### L'interface USB n'apparaît pas sur le PC

```bash
lsusb
dmesg | tail -20
```

Causes fréquentes :
- Mauvais port USB-C (utiliser OTG, pas POWER)
- Câble sans fils data (tester avec un câble de téléphone Android)
- Boot incomplet — attendre 30 secondes de plus

### wlan0 en état `unmanaged`

```bash
sudo nmcli device set wlan0 managed yes
sudo systemctl restart NetworkManager
```

### wlan0 en état `unavailable`

```bash
rfkill list
rfkill unblock wifi
sudo systemctl restart NetworkManager
```

### Erreurs de permissions Netplan

```bash
sudo chmod 600 /etc/netplan/*.yaml
sudo netplan apply
```

### Erreurs filesystem sur la SD

Si `dmesg` affiche des erreurs `Buffer I/O` ou `ext4 error` :

```bash
# SD démontée — réparer depuis le PC
sudo fsck -f /dev/sdc2    # partition rootfs
sudo fsck -f /dev/sdc1    # partition boot
```

---

*Orange Pi Zero 2W — Armbian 26.2.x trixie — Avril 2026*
