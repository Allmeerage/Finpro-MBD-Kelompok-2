# PinPulse Pinball Game

**Kelompok 2**
| Nama | NPM |
|------|-----|
| Fahreza Dwi Cahyo Purnomo | 2406426965 |
| Haitsam Ahmad Fakhri | 2406357740 |
| Putu Arkana Satriakusuma | 2406486983 |
| Soraya Azzizah Pahlevi | 2406487001 |

---
 
## 📌 Pendahuluan
 
Game arcade klasik seperti mesin pinball menuntut respons sistem yang real-time dan sinkronisasi waktu yang presisi antara input fisik pemain dengan aksi mekanis di permainan. Input lag sekecil beberapa milidetik saja sudah cukup untuk merusak pengalaman bermain secara keseluruhan.
 
**PinPulse** hadir untuk menjawab tantangan tersebut dengan membangun sistem kendali mesin pinball yang mengoptimalkan seluruh potensi arsitektur mikrokontroler **ATmega328P** secara langsung melalui **bahasa pemrograman AVR Assembly**. Pendekatan low-level ini memberikan kendali penuh atas manipulasi register, manajemen memori SRAM, dan ketepatan clock cycle — menghasilkan sistem permainan yang responsif dan bebas lag tanpa bergantung pada library tingkat tinggi maupun prosesor berdaya besar.
 
---

## 🔧 Desain & Implementasi Hardware
 
### Komponen yang Digunakan
- **Arduino UNO** (mikrokontroler ATmega328P)
- **LCD 1602** dengan modul I2C PCF8574
- **2× Servo SG90** (flipper kiri dan kanan)
- **2× Push Button** (kontrol flipper)
- **Sensor Infrared TCRT5000** (pendeteksi bola)
- **Breadboard & Kabel Jumper**
- **Impraboard** (rangka bodi fisik)
> 💡 Total biaya pembuatan sekitar **Rp250.000** menggunakan komponen yang mudah didapatkan di toko online mana saja.
 
### Arsitektur Hardware
- **Flipper kiri** digerakkan oleh servo SG90 pada Pin 9 (OCR1A), dipicu tombol di pin D2 (INT0).
- **Flipper kanan** digerakkan oleh servo SG90 pada Pin 10 (OCR1B), dipicu tombol di pin D3 (INT1).
- **Sensor IR (TCRT5000)** terhubung ke pin D7 untuk mendeteksi bola yang jatuh melewati batas bawah dan memicu kondisi Game Over.
- **LCD 1602** berkomunikasi via I2C melalui modul PCF8574 pada PORTC4 (SDA) dan PORTC5 (SCL).
 
---

## 💻 Implementasi Software
 
Seluruh logika sistem ditulis menggunakan **AVR Assembly**, distrukturisasi menggunakan arsitektur **Finite State Machine (FSM)** dengan tiga kondisi utama:
 
| State | Deskripsi |
|-------|-----------|
| **High Score** | Menampilkan skor tertinggi saat ini |
| **Gameplay** | Loop permainan aktif dengan kontrol flipper dan perhitungan skor |
| **Game Over** | Dipicu saat bola terdeteksi melewati sensor IR |
 
### Modul-Modul Utama
 
**Register & Memori (AVR Assembly)**
- Menggunakan `#include <avr/io.h>` untuk memetakan alamat register hardware ATmega328P secara langsung.
- Instruksi `LDI`, `OUT`, `STS`, `LDS` menangani inisialisasi pin I/O dan penyimpanan skor di SRAM.
**Aritmatika & Perhitungan Skor**
- `ADD` menambah poin pemain secara dinamis.
- `INC` / `DEC` mengendalikan pencacah waktu dan looping delay.
- `CP`, `CPI`, `SUBI` digunakan untuk perbandingan high score dan konversi nilai ke kode ASCII sebelum ditampilkan ke LCD.
**Timer (Timer/Counter1 — 16-bit)**
- Dikonfigurasi melalui `TCCR1A` dan `TCCR1B` dengan prescaler 8.
- Nilai ICR1 diatur ke **40.000** untuk menghasilkan **frekuensi dasar 50Hz** yang dibutuhkan motor servo.
- Interupsi overflow periodik berfungsi sebagai clock engine internal permainan.
**Interupsi Eksternal**
- `INT0` (pin D2) → flipper kiri; `INT1` (pin D3) → flipper kanan.
- `EICRA` dikonfigurasi untuk pemicuan pada **setiap perubahan logika**; `EIMSK` mengaktifkan pin masking interupsi.
- Rutinitas ISR (`__vector_1` dan `__vector_2`) menggerakkan posisi flipper secara real-time tanpa proses polling.
**PWM — Kontrol Servo**
- **Fast PWM Mode 14** pada OCR1A (Pin 9) dan OCR1B (Pin 10).
- Duty cycle dimodifikasi secara dinamis di dalam ISR untuk berpindah antara posisi *istirahat (down)* dan posisi *pukul (up)*.
- Posisi servo dicerminkan secara simetris untuk mengompensasi orientasi fisik flipper yang saling berhadapan.
**Komunikasi I2C & Sensor Interfacing**
- I2C diimplementasikan secara manual menggunakan teknik **bit-banging** pada PORTC4 (SDA) dan PORTC5 (SCL).
- Sensor IR dibaca secara kontinu via polling pada pin D7 menggunakan instruksi `sbic`.
- Deteksi bola memicu transisi state FSM ke kondisi Game Over.

---

## 🧪 Hasil Pengujian & Evaluasi
 
Proyek berhasil diselesaikan dan diuji pada **Minggu, 17 Mei 2026**.
 
| Tujuan | Status |
|--------|--------|
| Sistem penggerak responsif menggunakan AVR Assembly | ✅ Tercapai |
| Penyimpanan high score melalui EEPROM | ✅ Tercapai |
| Komunikasi LCD melalui protokol I2C | ✅ Tercapai |
| Pemahaman AVR Assembly yang lebih mendalam | ✅ Tercapai |
 
**Temuan Utama:**
- Input lag sangat minimal, menghasilkan pengalaman bermain yang lancar dan responsif.
- Seluruh integrasi register hardware, penanganan interupsi, dan logika FSM berjalan secara sinkron dan stabil.
- Sistem berjalan bebas lag selama pengujian, memvalidasi pendekatan desain berbasis assembly.

---

## 📝 Kesimpulan & Pengembangan ke Depan
 
PinPulse berhasil membuktikan bahwa game arcade yang fungsional dan responsif dapat diimplementasikan pada mikrokontroler berbiaya rendah hanya menggunakan AVR Assembly. Dengan bekerja langsung di level hardware — mengelola register, timer, interupsi, dan PWM secara manual — sistem mencapai performa real-time yang sulit dijamin oleh abstraksi tingkat tinggi.
 
**Potensi pengembangan ke depan:**
- Menambahkan **buzzer/speaker** untuk efek suara menggunakan channel PWM tambahan.
- Mengimplementasikan **beberapa level kesulitan** yang meningkatkan kecepatan bola secara bertahap.
- Memperluas area permainan dengan **bumper tambahan** menggunakan lebih banyak sensor.
- Mengganti display skor ke **seven-segment display** untuk visibilitas lebih tinggi.
- Menambahkan **upload skor secara nirkabel** via UART + modul Bluetooth.

---

Link Wokwi: https://wokwi.com/projects/464203052628442113 

<img width="1715" height="501" alt="image" src="https://github.com/user-attachments/assets/1846e4dd-8ef9-4310-a8a6-903394763913" />

| Left | Top | Right |
| -------- | -------- | -------- |
| <img width="1200" height="1600" alt="image" src="https://github.com/user-attachments/assets/fecc0c56-be26-42b9-b671-374bb3bd1678" />| <img width="1200" height="1600" alt="image" src="https://github.com/user-attachments/assets/0d40d3f8-8031-4076-923f-e9b801888f26" />| <img width="1200" height="1600" alt="image" src="https://github.com/user-attachments/assets/023f5542-785c-454a-b81f-29f0cb695c21" />|
