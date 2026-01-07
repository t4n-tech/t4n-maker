# Generator Live Image / RootFS dan Installer T4n OS

## Ringkasan

Repositori resmi ini berisi kumpulan utilitas untuk membangun **live image**, **root filesystem (ROOTFS)**, **platform filesystem (PLATFORMFS)**, hingga **installer** berbasis Void Linux dan untuk T4n OS.

### Utilitas Utama

* *`mklive.sh`*
  Generator live image Void Linux / T4n OS untuk arsitektur x86.

* *`mkiso.sh`*
  Wrapper script untuk menghasilkan live ISO yang **bootable dan installable** untuk arsitektur:
  `i686`, `x86_64`, dan `aarch64`.

* *`mkrootfs.sh`*
  Generator ROOTFS Void Linux / T4n OS untuk semua arsitektur.

* *`mkplatformfs.sh`*
  Generator filesystem khusus platform (PLATFORMFS) berbasis ROOTFS.

* *`mkimage.sh`*
  Generator image sistem untuk platform ARM.

* **`mknet.sh`*
  Generator tarball netboot Void Linux / T4n OS.

* **`installer.sh`**
  Installer Void Linux versi ringan untuk arsitektur x86.

* **`release.sh`**
  Digunakan untuk berinteraksi dengan GitHub CI dalam proses build dan penandatanganan image rilis.

### Utilitas Khusus T4n OS

* **[`t4n.sh`](#t4n-script)**
  Script wrapper khusus untuk menghasilkan image T4n OS.

## Alur Kerja (Workflow)

### Generate Live ISO x86

* Gunakan **`mkiso.sh`** untuk menghasilkan ISO live lengkap seperti rilis resmi.
* Gunakan **`mklive.sh`** untuk menghasilkan ISO live minimal (tanpa `void-installer` dan utilitas tambahan).

### Menghasilkan Tarball ROOTFS

ROOTFS adalah filesystem dasar Void Linux **tanpa kernel**. Biasanya digunakan untuk:

* Instalasi via **chroot**
* Lingkungan **container**
* Bootstrap sistem

Gunakan:

```
mkrootfs.sh
```

### Menghasilkan Tarball Khusus Platform (PLATFORMFS)

PLATFORMFS adalah ROOTFS **dengan kernel**, disesuaikan untuk platform tertentu seperti:

* ARM
* Raspberry Pi
* Platform dengan kebutuhan kernel khusus

Langkah:

1. Buat ROOTFS dengan `mkrootfs.sh`
2. Konversi menjadi PLATFORMFS menggunakan `mkplatformfs.sh`

### Menghasilkan Image ARM

Image ARM berisi:

* Partisi `/boot`
* Partisi `/`

Image ini **siap ditulis langsung** ke storage target menggunakan `dd`
(bukan live image seperti x86).

Langkah:

1. Buat PLATFORMFS
2. Generate image dengan `mkimage.sh`

## Dependensi

> ⚠️ **Catatan:** void-mklive **tidak dijamin berjalan** di distro selain Void Linux atau di dalam container.

Dependensi yang dibutuhkan:

* xbps ≥ 0.45
* bash
* qemu-user-static (untuk mkrootfs lintas arsitektur)
* Tipe kompresi initramfs: `lz4`, `xz`, dll

## Parameter Kernel (Live Image)

Live image mendukung beberapa parameter kernel untuk mengubah perilaku sistem saat boot:

* `live.autologin`
  Login otomatis ke `tty1`

* `live.user=<nama>`
  Mengubah username non-root (default: `anon`)

* `live.shell=<path>`
  Mengubah shell default user non-root

* `live.accessibility`
  Mengaktifkan fitur aksesibilitas (misalnya `espeakup`)

* `console=ttyS0|hvc0|hvsi0`
  Mengaktifkan konsol serial

* `locale.LANG=<locale>`
  Mengatur bahasa sistem (default: `en_US.UTF-8`)

* `vconsole.keymap=<keymap>`
  Mengatur keymap konsol (default: `us`)



### Contoh

* Login otomatis dengan user dan shell khusus:

  ```
  live.autologin live.user=foo live.shell=/bin/bash
  ```
Akan membuat pengguna `foo` dengan shell default `/bin/bash` saat booting, dan masuk secara otomatis pada `tty1`


* Mengubah shell user default:

  ```
  live.shell=/bin/bash
  ```
Akan mengatur shell default untuk user `anon` untuk `/bin/bash`


* Konsol serial dan keymap:

  ```
  console=ttyS0 vconsole.keymap=cf
  ```

Akan memungkinkan `ttyS0` dan atur keymap di konsol untuk `cf`

* Bahasa sistem:

  ```
  locale.LANG=fr_CA.UTF-8
  ```
Akan mengatur bahasa sistem langsung menjadi `fr_CA.UTF-8`

## Kebutuhan Sistem

* RAM: minimal **2 GB**
* CPU: **Dual Core**
* Storage Recommended:
  * 10 GB (Base)
  * 20 GB (Window Manager)
  * 30 GB (Desktop Environment)

## Informasi Login

| User | Password  |
| ---- | --------- |
| anon | voidlinux |
| root | voidlinux |

## Penggunaan Script

> Bagian **Usage** untuk `mkiso.sh`, `mklive.sh`, `mkrootfs.sh`, `mkplatformfs.sh`, `mkimage.sh`, dan `mknet.sh` **tetap sama** seperti [dokumentasi asli](https://github.com/void-linux/void-mklive).

## T4n Script
### t4n-script
```
Usage: t4n.sh [architecture] [Variant]

Wrapper script around mklive.sh for several standard flavors of live images.
Adds void-installer and other helpful utilities to the generated images.

Supported architectures:
 x86_64, x86_64-musl

OPTIONS
 -a <architecture>          Set Architecture
 -b <variant>               base(CLI Only), xfce(DE),bspwm(WM), KDE(DE), river(WM).
                            (Default: base).
 -o <file name>             Output file name for the ISO image (default: automatic)
 -p "<pkg1> <pkg2> <etc>"   Install additional packages in the ISO image
 -r <repository>            Use this XBPS repository. May be specified multiple times
 -h                         Show this help and exit
 -V                         Show version and exit

Example:
./t4n.sh -a x86_64
./t4n.sh -a x86_64 -b bspwm
./t4n.sh -a x86_64 -b base -p NetworkManager dbus
./t4n.sh -a x86_64 -b bspwm -o T4n-OS_Base.iso
./t4n.sh -a x86_64 -b bspwm -p "neovim vivaldi tree bat btop" -r https://repo-fi.voidlinux.org/ -o 
T4n-OS_BSPWM.ISO
./t4n.sh -a x86_64-musl
./t4n.sh -a x86_64-musl -b bspwm
./t4n.sh -a x86_64-musl -b base -p NetworkManager dbus
./t4n.sh -a x86_64-musl -b bspwm -o T4n-OS_Base.iso
./t4n.sh -a x86_64-musl -b bspwm -p "neovim vivaldi tree bat btop" -r https://repo-fi.voidlinux.org/ -o T4n-OS-musl_BSPWM.ISO
```

### t4n-base
##### x86_64 glibc
```
./t4n.sh -a x86_64
```
atau
```
./t4n.sh -a x86_64 -b base
```

##### x86_64 musl
```
./t4n.sh -a x86_64-musl
```
atau
```
./t4n.sh -a x86_64-musl -b base
```

### t4n-xfce4
##### x86_64 glibc
```
./t4n.sh -a x86_64 -b xfce
```

##### x86_64 musl
```
./t4n.sh -a x86_64-musl -b xfce
```

### t4n-bspwm
##### x86_64 glibc
```
./t4n.sh -a x86_64 -b bspwm
```

##### x86_64 musl
```
./t4n.sh -a x86_64-musl -b bspwm
```

### t4n-kde
##### x86_64 glibc
```
./t4n.sh -a x86_64 -b kde
```

##### x86_64 musl
```
./t4n.sh -a x86_64 -b kde
```

### t4n-river
##### x86_64 glibc
```
./t4n.sh -a x86_64 -b river
```

##### x86_64 musl
```
./t4n.sh -a x86_64-musl -b river
```

##### All images

```
./release.sh
```

---

## Referensi & Kredit

* [Void Linux & Contributors](https://github.com/void-linux/void-mklive)
* [Langit Ketujuh (L7 OS)](https://github.com/langitketujuh/l7-os)
* [d77void - dani-77](https://github.com/dani-77/d77void)


