# Connexion USB OTG — Orange Pi Zero 2W

> Accès SSH direct via câble USB-C, sans Wi-Fi ni écran.

---

## Matériel requis

- Câble USB-C **avec fils data** (pas un câble charge seule)
- Port **USB-C OTG** de la board (le second port, pas celui d'alimentation)

```
┌─────────────────────────┐
│  [USB-C POWER]          │  ← alimentation uniquement
│  [USB-C OTG]  ←──────────── câble vers votre PC
└─────────────────────────┘
```

---

## Étape 1 — Préparer la carte SD (une seule fois)

Insérer la SD dans votre PC. Monter la partition `armbi_root` (ext4).

### Activer le module gadget USB

```bash
echo "g_ether" | sudo tee -a /run/media/$USER/armbi_root/etc/modules
```

Vérifier que ces modules sont bien présents :

```bash
cat /run/media/$USER/armbi_root/etc/modules
# Doit contenir : libcomposite, dwc3, g_ether
```

### Créer le service de configuration réseau

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

### Activer le service au démarrage

```bash
sudo mkdir -p /run/media/$USER/armbi_root/etc/systemd/system/multi-user.target.wants

sudo ln -s /etc/systemd/system/usb-gadget-eth.service \
  /run/media/$USER/armbi_root/etc/systemd/system/multi-user.target.wants/usb-gadget-eth.service
```

### Démonter proprement

```bash
sync && sudo umount /run/media/$USER/armbi_root
```

---

## Étape 2 — Démarrer la board

1. Insérer la SD dans la board
2. Brancher l'alimentation sur le port **USB-C POWER**
3. Brancher le câble data sur le port **USB-C OTG** → votre PC
4. Attendre ~30 secondes le boot complet

---

## Étape 3 — Configurer l'interface réseau sur votre PC

### Repérer la nouvelle interface

```bash
ip link show
# Une nouvelle interface apparaît : enp4s0f3u3X ou usb0
```

### Lui assigner une IP

```bash
sudo ip addr add 192.168.7.1/24 dev enp4s0f3u3i1  # adapter le nom
sudo ip link set enp4s0f3u3i1 up
```

### Rendre la config permanente (NetworkManager)

```bash
sudo nmcli connection add \
  type ethernet \
  ifname enp4s0f3u3i1 \
  con-name "orangepi-usb" \
  ipv4.method manual \
  ipv4.addresses "192.168.7.1/24"
```

---

## Étape 4 — Connexion SSH

```bash
ping 192.168.7.2          # Vérifier que la board répond
ssh root@192.168.7.2      # Premier boot : mot de passe 1234
```

> ⚠️ Au premier boot Armbian impose un changement de mot de passe root
> et la création d'un utilisateur standard. C'est obligatoire.

Connexions suivantes :

```bash
ssh monuser@192.168.7.2
```

---

## Dépannage

### L'interface n'apparaît pas

```bash
# Vérifier que le PC voit la board en USB
lsusb
dmesg | tail -20
```

Causes fréquentes :
- Mauvais port USB-C (utiliser OTG, pas POWER)
- Câble sans fils data (tester avec un câble de téléphone Android)
- Boot incomplet — attendre 30 secondes de plus

### L'interface apparaît mais ping échoue

La board a peut-être une IP APIPA (169.254.x.x). Scanner le réseau :

```bash
sudo ip addr add 169.254.1.1/16 dev enp4s0f3u3i1
arp-scan --interface=enp4s0f3u3i1 --localnet
```

### Erreurs filesystem sur la SD

Si le dmesg affiche des erreurs `Buffer I/O` ou `ext4 error` :

```bash
# SD démontée — réparer
sudo fsck -f /dev/sdc2    # partition rootfs
sudo fsck -f /dev/sdc1    # partition boot
```

---

*Orange Pi Zero 2W — Armbian 26.2.x trixie — Avril 2026*
