# Generator live image / rootfs dan installer **T4n OS**

## Ringkasan

Repositori ini berisi kumpulan utilitas untuk membangun **T4n OS**, sebuah sistem operasi
yang **berbasis Void Linux**, mencakup pembuatan live image, root filesystem, image
khusus platform, hingga proses rilis.

Utilitas yang tersedia:

* [*t4n-live.sh*](#t4n-live.sh) — Generator live image T4n OS untuk x86
* [*t4n-iso.sh*](#t4n-iso.sh) — Script pembungkus untuk menghasilkan live image
  **bootable dan installable** untuk i686, x86_64, dan aarch64
* [*t4n-rootfs.sh*](#t4n-rootfs.sh) — Generator ROOTFS T4n OS untuk semua platform
* [*t4n-platformfs.sh*](#t4n-platformfs.sh) — Tool filesystem untuk menghasilkan
  ROOTFS khusus platform
* [*t4n-image.sh*](#t4n-image.sh) — Generator image T4n OS untuk platform ARM
* [*t4n-net.sh*](#t4n-net.sh) — Script untuk membuat tarball netboot T4n OS
* *installer.sh* — Installer sederhana T4n OS untuk x86
* *release.sh* — Integrasi dengan GitHub CI untuk menghasilkan dan menandatangani
  image rilis

## Alur Kerja (Workflow)

### Membuat ISO live x86

Untuk menghasilkan ISO live T4n OS dengan fitur lengkap (installer dan utilitas
tambahan), gunakan [*t4n-iso.sh*](#t4n-iso).

Untuk ISO live yang lebih minimal dan ringan, gunakan
[*t4n-live.sh*](#t4n-live).

### Membuat tarball ROOTFS

Tarball ROOTFS berisi filesystem dasar T4n OS **tanpa kernel**.

Umumnya digunakan untuk:

* Instalasi berbasis **chroot**
* **Container**, VM, dan lingkungan terisolasi lainnya

Gunakan [*t4n-rootfs.sh*](#t4n-rootfs) untuk menghasilkan ROOTFS T4n OS.

### Membuat tarball khusus platform (PLATFORMFS)

PLATFORMFS adalah ROOTFS khusus platform yang **sudah menyertakan kernel**.

Biasanya digunakan untuk:

* Sistem ARM
* Perangkat embedded
* Platform yang membutuhkan kernel spesifik (misalnya Raspberry Pi)

Langkah pembuatan:

1. Buat ROOTFS sesuai arsitektur target
2. Gunakan [*t4n-platformfs.sh*](#t4n-platformfs) untuk menghasilkan PLATFORMFS

### Membuat image ARM

Image filesystem khusus platform berisi layout filesystem (`/` dan `/boot`)
yang **siap ditulis langsung ke media penyimpanan** menggunakan `dd`.

Image ini:

* **Bukan live image**
* **Tidak memerlukan proses instalasi**

Langkah:

1. Buat PLATFORMFS
2. Gunakan [*t4n-image.sh*](#t4n-image) untuk menghasilkan image akhir

## Dependensi

Toolchain T4n OS **tidak dijamin berjalan** di distro selain Void Linux atau
di dalam container.

Dependensi utama:

* Tipe kompresi initramfs (default: liblz4 untuk lz4, xz)
* xbps >= 0.45
* qemu-user-static (dibutuhkan untuk t4n-rootfs.sh)
* bash

## Parameter Kernel Command Line

Live image T4n OS mendukung parameter kernel berikut:

* `live.autologin`
  Melewati layar login awal di `tty1`

* `live.user`
  Mengubah nama user non-root dari default `anon`
  (password tetap `voidlinux`)

* `live.shell`
  Mengatur shell default user non-root

* `live.accessibility`
  Mengaktifkan fitur aksesibilitas seperti screen reader `espeakup`

* `console`
  Set ke `ttyS0`, `hvc0`, atau `hvsi0` untuk mengaktifkan `agetty`

* `locale.LANG`
  Mengatur bahasa sistem (default: `en_US.UTF-8`)

* `vconsole.keymap`
  Mengatur keymap console (default: `us`)

### Contoh penggunaan:

* `live.autologin live.user=foo live.shell=/bin/bash`
  Membuat user `foo`, menggunakan `/bin/bash`, dan login otomatis di `tty1`

* `live.shell=/bin/bash`
  Mengatur shell default user `anon` ke `/bin/bash`

* `console=ttyS0 vconsole.keymap=cf`
  Mengaktifkan `ttyS0` dengan keymap `cf`

* `locale.LANG=fr_CA.UTF-8`
  Mengatur bahasa sistem live ke `fr_CA.UTF-8`

---

## Penggunaan

### t4n-iso.sh

```
Penggunaan: t4n-iso.sh [opsi ...] [-- opsi t4n-live ...]

Script pembungkus t4n-live.sh untuk berbagai varian live image standar.
Menambahkan void-installer dan utilitas tambahan ke dalam image.

[+] Create by Gh0sT4n(https://github.com/gh0st4n)

OPSI
 -a <arch>     Menentukan arsitektur (atau platform)
 -b <variant>  base, base-x11, base-wayland, server, enlightenment
               xfce, xfce-wayland, kde, bspwm atau river (default: base)
 -d <date>     Date-stamp image (format YYYYMMDD)
 -t <arch-date-variant>
               Setara dengan pengaturan -a, -b, dan -d
 -r <repo>     Menggunakan repository XBPS tertentu (bisa lebih dari satu)
 -h            Tampilkan bantuan & keluar
 -V            Tampilkan versi & keluar

Opsi lain dapat diteruskan langsung ke t4n-live.sh setelah tanda --.
lihat t4n-live.sh -h untuk detail lainnya.
```

---

### t4n-live.sh

```
Penggunaan: t4n-live.sh [opsi]

Menghasilkan ISO live T4n OS dasar.
ISO dapat ditulis ke CD/DVD atau USB.

[!] Untuk Menghasil File ISO Lebih Lengkap, Gunakan t4n-iso.sh
[+] Create by Gh0sT4n(https://github.com/gh0st4n)

OPSI
 -a <arch>          Tentukan XBPS_ARCH dalam ISO image
 -b <system-pkg>    Tentukan paket dasar alternatif (default: base-system)
 -r <repo>          Menggunakan repository XBPS tertentu (bisa lebih dari satu)
 -c <cachedir>      Gunakan direktori cache XBPS ini (default: ./xbps-cachedir-<arch>)
 -H <host_cachedir> Gunakan direktori cache XBPS Host ini (default: ./xbps-cachedir-<host_arch>)
 -k <keymap>       Keymap default (default: us)
 -l <locale>        Locale default (default: en_US.UTF-8)
 -i <lz4|gzip|bzip2|xz>
                    Tipe kompresi untuk image initramfs (default: xz)
 -s <gzip|lzo|xz>   Tipe kompresi untuk image squashfs (default: xz)
 -o <file>          Nama file output image ISO (default: automatic)
 -p "<pkg> ..."     Menambahkan paket dalam image ISO
 -g "<pkg> ..."     Paket yang diabaikan saat proses build ISO
 -I <includedir>    Menyertakan struktur direktori di path tertentu ke dalam ROOTFS
 -S "<service> ..." mengaktifkan service di image ISO
 -e <shell>         Shell default pengguna root (harus berupa jalur absolut).
                    Atur argumen kernel live.shell untuk mengubah shell default menjadi anon.
 -C "<arg> ..."     Menambahkan argumen tambahan ke command line kernel
 -P "<platform> ..."
                    Coming Soon
 -T <title>         Ubah judul bootloader (default: T4n OS)
 -v linux<versi>    Instal versi Linux kustom pada citra ISO (default: linux metapaket).
                    Juga menerima metapaket linux (linux-mainline, linux-lts).
 -x <script>        Jalur ke skrip postsetup yang akan dijalankan sebelum menghasilkan initramfs
                            (menerima jalur ke ROOTFS sebagai argumen)
 -K                 Jangan hapus builddir
 -h                 Tampilkan Bantuan dan Keluar
 -V                 Tampilkan Versi dan Keluar
```

---

### t4n-rootfs.sh

#### Belum Di Kustom
```
Penggunaan: $PROGNAME [opsi] <arch>

Menghasilkan file tarball T4n OS ROOTFS untuk arsitektur yang ditentukan.

Arsitektur yang Di-Support:
 i686, i686-musl, x86_64, x86_64-musl,
 armv5tel, armv5tel-musl, armv6l, armv6l-musl, armv7l, armv7l-musl
 aarch64, aarch64-musl,
 mipsel, mipsel-musl,
 ppc, ppc-musl, ppc64le, ppc64le-musl, ppc64, ppc64-musl
 riscv64, riscv64-musl
[+] Create by Gh0sT4n(https://github.com/gh0st4n)

OPSI
 -b <system-pkg>  Menentukan paket sistem dasar alternatif (default: base-container-full)
 -c <cachedir>    Menentukan direktori cache XBPS (default: ./xbps-cachedir-<arch>)
 -C <file>        Jalur lengkap ke file konfigurasi XBPS
 -r <repo>        Menggunakan repository XBPS tertentu (bisa lebih dari satu)
 -o <file>        Nama file untuk menulis ROOTFS (default: otomatis)
 -x <num>         Jumlah thread yang digunakan untuk kompresi gambar (default: dinamis)
 -h               Tampilkan bantuan & keluar
 -V               Tampilkan versi & keluar
```

---

### t4n-platformfs.sh

#### Belum Di Kustom
```
Penggunaan: t4n-platformfs.sh [opsi] <platform> <rootfs-tarball>

Menghasilkan ROOTFS khusus platform.
[+] Create by Gh0sT4n(https://github.com/gh0st4n)

OPSI
 -b <system-pkg>  Paket base alternatif
 -c <cachedir>    Cache XBPS
 -C <file>        File konfigurasi XBPS
 -k <cmd>         Jalankan perintah setelah build
 -n               Tanpa kompresi
 -o <file>        Nama output
 -p "<pkg> ..."   Paket tambahan
 -r <repo>        Repository XBPS
 -x <num>         Jumlah thread kompresi
 -h               Bantuan
 -V               Versi
```

---

### mkimage.sh

#### Belum Di Kustom
```
Penggunaan: mkimage.sh [opsi] <platformfs-tarball>

Menghasilkan image filesystem siap tulis menggunakan dd.
[+] Create by Gh0sT4n(https://github.com/gh0st4n)

OPSI
 -b <fstype>    Tipe filesystem /boot
 -B <bsize>     Ukuran /boot
 -r <fstype>    Tipe filesystem /
 -s <totalsize> Ukuran total image
 -o <output>    Nama file output
 -x <num>       Thread kompresi
 -h             Bantuan
 -V             Versi
```

---

### t4n-net.sh

#### Belum Di Kustom
```
Penggunaan: t4n-net.sh [opsi] <rootfs-tarball>

Menghasilkan tarball netboot dari ROOTFS T4n OS.
[+] Create by Gh0sT4n(https://github.com/gh0st4n)

OPSI
 -r <repo>          Repository XBPS
 -c <cachedir>      Cache XBPS
 -i <lz4|gzip|bzip2|xz>
                    Kompresi initramfs
 -o <file>          Nama output
 -K linux<versi>    Kernel custom
 -k <keymap>        Keymap default
 -l <locale>        Locale default
 -C "<arg> ..."     Parameter kernel tambahan
 -T <title>         Judul bootloader
 -S <image>         Splash image
 -h                 Bantuan
 -V                 Versi
```

