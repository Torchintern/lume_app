# LUME – Smart Campus Payments App

LUME is a Flutter-based fintech application designed for students to make secure, fast, and seamless payments in on and off campus ecosystem. It supports UPI-based payments, QR scanning, wallet balance management, and KYC-driven access — all with a clean, modern UI.

---

## 🚀 Features

- 🔐 OTP-based Login & Registration  
- 🆔 Aadhaar & PAN KYC verification  
- 💼 In-app Wallet with real-time balance  
- 📷 QR Code Scanner (Camera + Gallery)  
- 💳 Tap & Pay using UPI IDs or QR codes  
- 🧮 Secure amount entry & validation  
- 🎯 KYC-based feature unlocking  
- 🎨 Consistent UI across Login, Register & Dashboard  

---

## 📱 App Flow

1. User registers & logs in using OTP  
2. Completes KYC (Aadhaar / PAN)  
3. Wallet gets activated  
4. User can:  
   - Scan QR codes  
   - Enter UPI ID manually  
   - Enter payment amount  
   - Pay using LUME Wallet  

---

## 🛠️ Tech Stack

### Frontend
- Flutter  
- Dart  
- Material UI  

### Backend
- Python (Flask)  
- MySQL  
- REST APIs  

### Tools & Libraries
- Mobile Scanner (QR scanning)  
- Image Picker (Gallery QR scan)  
- Git & GitHub  

---

## 🔐 Security

- OTP-based authentication  
- Server-side KYC validation  
- Wallet activation only after Aadhaar verification  
- Secure API communication  

---

## 📂 Project Structure
lib/
├── screens/
│ ├── login_screen.dart
│ ├── register_screen.dart
│ ├── dashboard_screen.dart
│ ├── qr_scanner_screen.dart
│ └── payment_amount_screen.dart
├── services/
│ └── api_service.dart
└── main.dart

## ▶️ Getting Started

### Prerequisites
- Flutter SDK  
- Android Studio / VS Code  
- Android Emulator or Physical Device  

### Run the App
```bash
### Backend (Flask)
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python app.py

### Frontend (Flutter)
cd lume_app
flutter pub get
flutter run


