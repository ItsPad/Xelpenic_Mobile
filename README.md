# 🎬 XELPENIC - Internal Developer Documentation

**XELPENIC** คือแอปพลิเคชันจัดการโรงภาพยนตร์แบบครบวงจร (Comprehensive Movie Theater Application) ที่ออกแบบมาเพื่อยกระดับประสบการณ์ของผู้ใช้งาน ตั้งแต่การค้นหาสาขาใกล้เคียง, การตรวจสอบรอบฉาย, การซื้อตั๋วภาพยนตร์, ไปจนถึงระบบสมาชิกและการแลกคะแนนสะสม (Points Redemption)

---

## 📑 Table of Contents (สารบัญ)
1. [Tech Stack & Architecture](#1-tech-stack--architecture)
2. [Prerequisites & Installation](#2-prerequisites--installation)
3. [Project Directory Structure](#3-project-directory-structure)
4. [Database Schema & Data Dictionary](#4-database-schema--data-dictionary)
5. [Security & Row Level Security (RLS)](#5-security--row-level-security-rls)
6. [Build & Release Guide](#6-build--release-guide)
7. [Testing Strategy (SDLC)](#7-testing-strategy-sdlc)
8. [Troubleshooting & Known Issues](#8-troubleshooting--known-issues)

---

## 🛠 1. Tech Stack & Architecture
* **Frontend Framework:** Flutter (Dart)
* **Backend Platform:** Supabase (BaaS)
* **Database:** PostgreSQL (via Supabase)
* **Authentication:** Supabase Auth (Email / Password)
* **Key Packages (Dependencies):**
  * `supabase_flutter`: เชื่อมต่อระบบ Backend และ Auth
  * `geolocator`: ตรวจจับพิกัด GPS ปัจจุบันของผู้ใช้งาน
  * `flutter_map` & `latlong2`: แสดงผลแผนที่ OpenStreetMap แบบ Custom Marker

---

## 🚀 2. Prerequisites & Installation

### System Requirements
* Flutter SDK (Latest Stable Version)
* Android Studio (สำหรับ Emulator) หรือ Physical Android Device (Android 7.0+)
* VS Code พร้อมติดตั้ง Extension: Flutter, Dart

### Setup Steps
1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd xelpenic
