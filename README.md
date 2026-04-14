# 🌾 AgroVani — Voice-First Farming Assistant

## 🧭 About the Project

India has over 140 million farmers, the majority of whom speak regional languages and have limited access to smartphones or the internet in a meaningful way. Farmers in Maharashtra primarily speak **Marathi** — yet most agricultural apps are built in English or Hindi, creating a massive accessibility gap.

**AgroVani** bridges this gap by providing a **fully voice-driven agricultural assistant in Marathi**. A farmer doesn't need to type, read, or navigate complex menus. They simply **speak** — and the app understands, responds, and speaks back in Marathi.

### 🌱 The Problem It Solves

| Problem | AgroVani's Solution |
|---|---|
| Farmers can't read English apps | Fully Marathi UI + voice |
| Crop disease info is hard to find | कृषी डॉक्टर — guided 3-step diagnosis flow |
| Mandi prices require middlemen | Live Solapur mandi prices via data.gov.in API |
| Weather apps are complex | Ask naturally — "पाऊस पडेल का?" |
| Government schemes are confusing | 6 schemes explained in simple Marathi |
| Fertilizer calculation needs expertise | Speak crop + area → get exact quantity |
| No personalisation | Firebase Auth — farmer profile with crops, soil, location |
| Crop selection is guesswork | Smart crop suggestion based on soil + live weather |

### 🎯 Who Is It For?

- Marathi-speaking farmers in Maharashtra, primarily Solapur district
- Farmers with low digital literacy who prefer voice over text
- Agricultural extension workers who assist farmers

### 💡 How It Works

1. Farmer opens the app and speaks a query in Marathi
2. **Auditory confirmation** — app repeats what it heard and asks for confirmation
3. After confirmation, the app processes the query and speaks the answer back
4. Every response is spoken aloud using **Amazon Polly** TTS
5. No typing required at any step

### 🔬 Intelligence Without an LLM

AgroVani does **not** use a large language model (LLM) or Dialogflow. Instead, it uses a custom **intent detection engine** built in Python that:
- Scans the full spoken sentence for crop names, topics, and intent keywords
- Understands natural Marathi sentences like "सोलापूर मध्ये आज पाऊस पडेल का?"
- Parses Marathi number words (पाच, तीन, दहा) for the fertilizer calculator
- Maps voice input to structured data entirely offline — no API cost per query

---

AgroVani is a **Marathi-language voice assistant** built for farmers. It provides crop advice, mandi prices, weather updates, government schemes, fertilizer calculations, agri news, and smart crop suggestions — all through a conversational voice interface powered by **Flutter**, **Flask**, **Firebase**, and **Amazon Polly**.

---

## 📱 Features

| Screen | Description |
|---|---|
| 🏠 Home | Plantix-style UI — weather card, smart crop suggestion, my crops, service grid, Marathi agri news |
| 🌾 पीक माहिती | Crop info grid — tap or speak a crop to hear रोग, खत, पाणी advice |
| 🩺 कृषी डॉक्टर | Guided 3-step flow: select crop → select symptom → confirm → auto-speak result |
| 🌤️ हवामान | Live weather with contextual answers (पाऊस पडेल का? / तापमान किती? / वारा किती?) |
| 📋 शासकीय योजना | 6 government schemes with voice search, keyword matching, and auto-speak |
| 📊 बाजारभाव | Live mandi prices via data.gov.in API, fallback to local JSON, voice-filtered |
| 🧪 खत गणक | Fertilizer calculator — supports full Marathi sentences + number words |
| 🌱 स्मार्ट सूचना | Crop recommendation based on soil type + live weather via `/recommend` |
| 📰 कृषी बातम्या | Marathi agri news on home screen with detail view and voice playback |
| 👤 प्रोफाइल | Farmer profile — name, village, crops, soil type, gender avatar, edit support |

---

## 🏗️ Tech Stack

### Frontend
- **Flutter** 3.43.0+ (Dart)
- **speech_to_text** — Marathi (`mr_IN`) voice recognition
- **audioplayers** — plays Amazon Polly MP3 audio
- **http** — REST API calls to Flask backend
- **firebase_core / firebase_auth / cloud_firestore** — authentication and farmer profiles
- **pin_code_fields** — OTP input UI

### Backend
- **Python 3.x** + **Flask** — REST API server
- **Amazon Polly** (Kajal, neural, hi-IN) — Text-to-Speech
- **boto3** — AWS SDK for Python
- **python-dotenv** — environment variable management
- **OpenWeatherMap API** — live weather data
- **data.gov.in API** — live Solapur mandi prices

### Auth & Database
- **Firebase Authentication** — Phone OTP (Android) + Email/Password (Web)
- **Cloud Firestore** — farmer profile storage (name, village, crops, soil, gender, etc.)

---

## 📁 Project Structure

```
agrovani_backend/
├── app.py                  # Flask server — all API routes
├── crop_info.txt           # 15 crops × 3 topics (रोग/खत/पाणी) in Marathi
├── mandi_data.json         # Solapur mandi prices fallback for 15 crops
├── run_server.bat          # Start Flask server (Windows) — runs python app.py
├── .env                    # AWS credentials (not committed)
├── pubspec.yaml            # Flutter dependencies
└── lib/
    ├── main.dart                        # Firebase init, auth routing
    ├── firebase_options.dart            # FlutterFire CLI generated config
    ├── screens/
    │   ├── main_navigation.dart         # 5-tab bottom nav (IndexedStack)
    │   ├── home_screen.dart             # Plantix-style home with news + suggestion
    │   ├── crops_screen.dart            # Crop info with initialCrop support
    │   ├── krushi_doctor.dart           # 3-step guided diagnosis flow
    │   ├── weather_screen.dart          # Live weather + contextual voice answers
    │   ├── yojana_screen.dart           # Government schemes with voice search
    │   ├── mandi_price.dart             # Live mandi prices
    │   ├── calculator_screen.dart       # Fertilizer calculator + Marathi numbers
    │   ├── profile_screen.dart          # Farmer profile from Firestore
    │   ├── news_detail_screen.dart      # News article detail with voice playback
    │   ├── welcome_screen.dart          # Landing screen
    │   └── auth/
    │       ├── login_screen.dart        # Email/password login
    │       ├── register_screen.dart     # Full registration form
    │       └── otp_screen.dart          # OTP verify → create Firebase account
    ├── widgets/
    │   └── voice_mic_bar.dart           # Shared mic widget with auditory confirmation
    └── utils/
        └── polly_tts.dart               # Amazon Polly TTS helper
```

---

## ⚙️ Setup & Installation

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) 3.13+
- Python 3.8+
- AWS Account with **AmazonPollyReadOnlyAccess** IAM policy
- [OpenWeatherMap API key](https://openweathermap.org/api) (free tier)
- Firebase project with **Email/Password** and **Phone** auth enabled

---

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/agrovani.git
cd agrovani
```

---

### 2. Backend Setup

**Install Python dependencies:**
```bash
pip install flask requests boto3 python-dotenv
```

**Create `.env` file** in the root folder:
```
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
```

**Set your API keys** in `app.py`:
```python
WEATHER_API_KEY = 'your_openweathermap_api_key'
MANDI_API_KEY   = 'your_data_gov_in_api_key'
```

**Start the Flask server:**
```bash
# Windows
run_server.bat

# Mac / Linux
python app.py
```
Server runs on `http://0.0.0.0:5000` (accessible from phone on same network)

---

### 3. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Enable **Email/Password** and **Phone** authentication
3. Create a **Firestore** database (test mode is fine for development)
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`
5. Download `google-services.json` and place it in `android/app/`

---

### 4. Flutter Setup

**Install dependencies:**
```bash
flutter pub get
```

**Set the backend URL** in `lib/utils/polly_tts.dart` and all screen files:
```dart
// For web browser testing
'http://127.0.0.1:5000'

// For physical Android device (replace with your PC's local IP)
'http://192.168.x.x:5000'
```

**Run on Chrome (web):**
```bash
flutter run -d chrome
```

**Run on Android device:**
```bash
flutter devices          # find your device ID
flutter run -d YOUR_DEVICE_ID
```

**Wireless ADB (optional):**
```bash
adb tcpip 5555
adb connect PHONE_IP:5555
```

---

## 🔑 AWS Polly Setup

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Create a new user with **AmazonPollyReadOnlyAccess** policy
3. Generate Access Key + Secret Key
4. Add them to your `.env` file

> **Voice used:** Kajal (Hindi/hi-IN, neural engine) — reads Marathi Devanagari text with natural intonation

---

## 🔐 Authentication Flow

- **Web**: Email/Password only (Phone OTP blocked by reCAPTCHA on web)
- **Android**: Full registration form → Phone OTP verification → Firebase account created after OTP → Firestore profile saved
- Firebase Auth account is created **after** OTP verification to prevent orphaned accounts
- "नंबर बदला" on OTP screen goes back to register with all form data prefilled

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Health check |
| POST | `/speak` | Text → MP3 via Amazon Polly |
| POST | `/query` | Intent detection + Marathi response |
| GET | `/mandi-prices` | Live Solapur mandi prices (data.gov.in + JSON fallback) |
| GET | `/agri-news` | Marathi agri news (static fallback) |
| POST | `/recommend` | Smart crop suggestion based on soil + live weather |
| POST | `/webhook` | Dialogflow-compatible webhook |

### `/query` request body:
```json
{ "query": "कापूस रोग" }
```
### `/query` response:
```json
{
  "success": true,
  "intent": "get_farm_doctor",
  "fulfillmentText": "कापसावरील प्रमुख रोग..."
}
```

### `/recommend` request body:
```json
{ "soil": "काळी माती", "district": "सोलापूर" }
```

---

## 📦 Flutter Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  speech_to_text: ^7.0.0
  audioplayers: ^6.0.0
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  pin_code_fields: ^8.0.1
```

---

## 🐍 Python Dependencies

```
flask
requests
boto3
python-dotenv
```

---

## 🎤 Voice Features

- **Auditory Confirmation** — app repeats what it heard, shows "होय, बरोबर आहे" / "पुन्हा बोला" before acting
- **Full sentence understanding** — "सोलापूर मध्ये पाऊस पडेल का?" works, not just keywords
- **Marathi number words** — "पाच एकर" parsed as 5 acres in the fertilizer calculator
- **Contextual weather answers** — rain / wind / humidity / temperature questions answered differently
- **Yojana voice search** — keyword matching across all 6 schemes, auto-expands and speaks on match
- **Auto-speak results** — every screen speaks the answer automatically after confirmation

---

## 📝 Notes

- `.env` file is **gitignored** — never commit your AWS credentials
- Backend URL is hardcoded — update it to your local IP for physical device testing
- Amazon Polly **Kajal** (neural) voice reads Marathi in Devanagari script via the Hindi engine
- OTP auth works on Android only; web uses email/password
- data.gov.in mandi API may have delays — app falls back to `mandi_data.json` automatically
- Gender avatar: `Icons.face_3_rounded` for महिला (detected via `codeUnitAt(0) == 2350`), `Icons.face_rounded` otherwise
- App tested on Flutter Web (Chrome) and Android 14 (CPH2401)

---

## 👨‍💻 Built By

**Rutuj** — Built entirely from scratch as a voice-first agricultural assistant for Marathi-speaking farmers in Maharashtra.
