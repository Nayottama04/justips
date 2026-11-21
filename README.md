# Justips - Aplikasi Jasa Titip (Jastip)

Flutter + Firebase, berdasarkan PRD v1.2 (Escrow, Pencegahan Penipuan, Floating Navbar)
dan desain Figma. Tampilan: kartu glassmorphism / liquid glass, floating navbar kapsul,
mode terang & gelap (ikuti sistem, atau pilih manual di Profil / tombol di header).

## Cara menjalankan (Android Studio)

1. Buka folder ini di Android Studio (File > Open).
2. Di terminal Android Studio, jalankan satu kali:

       dart run tool/setup.dart

   Script ini membuat folder `android/` (via `flutter create`), mengatur `minSdk 23`
   (syarat Firebase), menambah izin INTERNET, lalu `flutter pub get`.
3. Pilih emulator/HP, tekan **Run**.

Tanpa konfigurasi Firebase, aplikasi otomatis berjalan di **mode demo** (data lokal di memori).
Akun demo (kata sandi `123456`): `alex@demo.id` (pembeli) dan `rina@demo.id` (penjastip, KYC lolos).
Kode OTP / PIN simulasi: `123456`.

## Menyambungkan Firebase

1. Buat project di console.firebase.google.com, tambahkan app Android (package: `com.justips.justips`).
2. Aktifkan **Authentication > Email/Password** dan **Cloud Firestore**. Firebase Storage TIDAK dipakai.
3. Pasang konfigurasi, salah satu cara:
   - `dart pub global activate flutterfire_cli` lalu `flutterfire configure`, atau
   - unduh `google-services.json` ke `android/app/` dan tambahkan plugin
     `com.google.gms.google-services` pada Gradle.
4. Salin isi `firestore.rules` ke tab Rules Firestore di console lalu Publish.
5. Jalankan ulang aplikasi - mode demo akan hilang dan data tersimpan di Firestore.

Koleksi Firestore: `users, orders, rooms, messages, notifications, ledger, withdrawals, kyc, images` (foto disimpan base64 di `images`, maks. ~900 KB per foto setelah dikompres).
Login di mode Firebase memakai email (login via username butuh Cloud Function).

## Fitur yang tercakup

Pengunjung tanpa login, login/registrasi + validasi, Home Pembeli & Home Penjastip (kartu order,
Chat, Ambil Order dengan konfirmasi + penguncian atomik), buat/edit/batal order, rincian biaya,
pembayaran escrow (simulasi), bukti pembelian/pengiriman wajib, konfirmasi diterima + konfirmasi otomatis 3x24 jam,
komplain + jendela 2x24 jam, saldo tertahan/tersedia, rekening (nama harus sama dengan KYC),
pencairan dengan PIN/OTP, KYC (OTP, KTP, swafoto), sistem level 1-4, chat real time (centang terkirim/dibaca,
kirim gambar, peringatan transaksi di luar aplikasi), notifikasi in-app + badge, pencarian, profil/edit profil,
floating navbar (menyusut saat scroll, sembunyi saat keyboard terbuka, aman untuk gesture bar).

## Batasan yang perlu diketahui

- Push notification (FCM) membutuhkan Cloud Functions/server; yang tersedia: notifikasi in-app real time.
- Lokasi memakai pencarian kota/alamat + catatan teks. Peta interaktif butuh API key Google Maps.
- Panel Admin (web) di luar aplikasi mobile; keputusan komplain disimulasikan lewat tombol di mode demo.
- Logika uang (escrow, saldo, pencairan) berjalan di klien karena ini mock tugas kuliah dengan pembayaran sandbox.
  Untuk produksi gunakan Cloud Functions + payment gateway berizin (Midtrans/Xendit).
- Foto produk pada desain Figma adalah data dinamis (dari order), jadi kartu memakai ikon placeholder bila belum ada gambar.
