# Google Sign-In Configuratie voor YessFish Flutter App

## ⚠️ BELANGRIJK: Google Cloud Console Setup Vereist

De Google Sign-In werkt pas na het toevoegen van de Android app in Google Cloud Console.

## 📋 Stappen in Google Cloud Console

### 1. Ga naar Google Cloud Console
https://console.cloud.google.com/apis/credentials?project=yessfish-443511

### 2. Klik op "Create Credentials" → "OAuth client ID"

### 3. Selecteer "Android"

### 4. Vul de gegevens in:
- **Package name**: `nl.sbuilder.yessfish_flutter_app`
- **SHA-1 certificate fingerprint**: `DE:1E:81:07:66:4F:53:18:E5:B8:D7:79:A2:98:F9:B1:E2:60:CC:AB`

### 5. Klik op "Create"

## ✅ Verificatie

Na het aanmaken krijg je een Android Client ID zoals:
```
123456789-xxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

De app zal nu automatisch werken met Google Sign-In!

## 📱 Keystore Informatie

- **Keystore**: `/android/app/yessfish-release.jks`
- **Alias**: `yessfish`
- **Password**: `YessFish2025!`
- **SHA-1**: `DE:1E:81:07:66:4F:53:18:E5:B8:D7:79:A2:98:F9:B1:E2:60:CC:AB`
- **SHA-256**: `42:3A:32:28:66:A7:E0:20:E6:5B:7C:11:88:91:95:3A:41:36:DC:81:96:BB:93:92:C3:8E:1F:09:4B:C8:2D:DD`

## 🔐 Bestaande OAuth Clients

**Web Client ID** (al geconfigureerd):
- Zie `.env` bestand op production server
- Of check Google Cloud Console

**Client Secret**:
- Zie `.env` bestand op production server

## 🚀 Na Setup

1. Download de nieuwe versie van de app
2. Test Google Sign-In
3. Je zou succesvol moeten kunnen inloggen!

---
Gegenereerd: 2025-10-17
# Build 20251017-195456
