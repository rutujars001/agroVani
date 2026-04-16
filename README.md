# AgroVani — Voice-First Farming Assistant

## About the Project

India has over 140 million farmers, the majority of whom speak regional languages and have limited access to smartphones or the internet in a meaningful way. Farmers in Maharashtra primarily speak **Marathi** — yet most agricultural apps are built in English or Hindi, creating a massive accessibility gap.

**AgroVani** bridges this gap by providing a **fully voice-driven agricultural assistant in Marathi**. A farmer doesn't need to type, read, or navigate complex menus. They simply **speak** — and the app understands, responds, and speaks back in Marathi.

### The Problem It Solves

| Problem | AgroVani's Solution |
|---|---|
| Farmers can't read English apps | Fully Marathi UI + voice |
| Crop disease info is hard to find | Krushi Doctor — guided 3-step diagnosis flow |
| Mandi prices require middlemen | Live Solapur mandi prices via data.gov.in API |
| Weather apps are complex | Ask naturally in Marathi |
| Government schemes are confusing | 6 schemes explained in simple Marathi |
| Fertilizer calculation needs expertise | Speak crop + area, get exact quantity |
| No personalisation | Firebase Auth — farmer profile with crops, soil, location |
| Crop selection is guesswork | Smart crop suggestion based on soil + live weather |

### Who Is It For?

- Marathi-speaking farmers in Maharashtra, primarily Solapur district
- Farmers with low digital literacy who prefer voice over text
- Agricultural extension workers who assist farmers

### How It Works

1. Farmer opens the app and speaks a query in Marathi
2. **Auditory confirmation** — app repeats what it heard and shows confirm/retry buttons
3. After confirmation, the app processes the query and speaks the answer back
4. Every response is spoken aloud using **Amazon Polly** TTS
5. No typing required at any step

### Intelligence Without an LLM

AgroVani does **not** use a large language model (LLM) or Dialogflow. Instead, it uses a custom **intent detection engine** built in Python that:
- Scans the full spoken sentence for crop names, topics, and intent keywords
- Understands natural Marathi sentences
- Parses Marathi number words for the fertilizer calculator
- Maps voice input to structured data entirely offline — no API cost per query

---

AgroVani is a **Marathi-language voice assistant** built for farmers. It provides crop advice, mandi prices, weather updates, government schemes, fertilizer calculations, agri news, and smart crop suggestions — all through a conversational voice interface powered by **Flutter**, **Flask**, **Firebase**, and **Amazon Polly**.

---

## Features

| Screen | Description |
|---|---|
| Home | Plantix-style UI — weather card, smart crop suggestion, my crops, service grid, Marathi agri news |
| Pik Mahiti | Crop info grid — tap or speak a crop to hear disease, fertilizer, water advice |
| Krushi Doctor | Guided 3-step flow: select crop, select symptom, confirm, auto-speak result |
| Havaman | Live weather with contextual answers |
| Shaskaiy Yojana | 6 government schemes with voice search, keyword matching, and auto-speak |
| Bazarbhav | Live mandi prices via data.gov.in API, fallback to local JSON, always 15 crops |
| Khat Gaanak | Fertilizer calculator — supports full Marathi sentences + number words |
| Smart Suchana | Crop recommendation based on soil type + live weather via /recommend |
| Krushi Batmya | Marathi agri news on home screen with detail view and voice playback |
| Profile | Farmer profile — name, village, crops, soil type, gender avatar, edit support |

---

## Tech Stack

### Frontend
- **Flutter** 3.43.0+ (Dart)
- **speech_to_text** — Marathi (mr_IN) voice recognition
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

## Project Structure

```
agrovani_backend/
├── app.py                  # Flask server — all API routes
├── crop_info.txt           # 15 crops x 3 topics (disease/fertilizer/water) in Marathi
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
    │   ├── splash_screen.dart           # Animated splash with auth routing
    │   ├── welcome_screen.dart          # Landing screen
    │   └── auth/
    │       ├── login_screen.dart        # Email/password login
    │       ├── register_screen.dart     # Full registration form
    │       └── otp_screen.dart          # OTP verify -> create Firebase account
    ├── widgets/
    │   └── voice_mic_bar.dart           # Shared mic widget with auditory confirmation
    └── utils/
        ├── polly_tts.dart               # Amazon Polly TTS helper
        ├── app_config.dart              # Single backend URL constant (kBaseUrl)
        └── api_client.dart              # Shared HTTP client with ngrok header
```

---

## Setup & Installation

### Prerequisites
- Flutter 3.13+
- Python 3.8+
- AWS Account with **AmazonPollyReadOnlyAccess** IAM policy
- OpenWeatherMap API key (free tier)
- Firebase project with **Email/Password** and **Phone** auth enabled

---

### 1. Clone the repository
```bash
git clone https://github.com/rutujars001/agroVani.git
cd agrovani_backend
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
Server runs on `http://0.0.0.0:5000`

---

### 3. Firebase Setup

1. Create a Firebase project at console.firebase.google.com
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

**Set the backend URL** in `lib/utils/app_config.dart`:
```dart
// For Chrome testing (same machine)
const String kBaseUrl = 'http://127.0.0.1:5000';

// For physical Android device via ngrok
const String kBaseUrl = 'https://xxxx.ngrok-free.app';
```

> All API calls automatically include `ngrok-skip-browser-warning: true` header via `lib/utils/api_client.dart`

**Run on Chrome (disable CORS for local testing):**
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**Run on Android device:**
```bash
flutter devices          # find your device ID
flutter run -d YOUR_DEVICE_ID
```

**Wireless ADB:**
```bash
adb tcpip 5555
adb connect PHONE_IP:5555
```

---

## AWS Polly Setup

1. Go to AWS IAM Console
2. Create a new user with **AmazonPollyReadOnlyAccess** policy
3. Generate Access Key + Secret Key
4. Add them to your `.env` file

> **Voice used:** Kajal (Hindi/hi-IN, neural engine) — reads Marathi Devanagari text with natural intonation

---

## Authentication Flow

- **Web**: Email/Password only (Phone OTP blocked by reCAPTCHA on web)
- **Android**: Full registration form -> Phone OTP verification -> Firebase account created after OTP -> Firestore profile saved
- Firebase Auth account is created **after** OTP verification to prevent orphaned accounts
- "Number change" button on OTP screen goes back to register with all form data prefilled

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Health check |
| POST | `/speak` | Text -> MP3 via Amazon Polly |
| POST | `/query` | Intent detection + Marathi response |
| GET | `/mandi-prices` | Live mandi prices (data.gov.in + JSON fallback, always 15 crops) |
| GET | `/agri-news` | Marathi agri news (static fallback) |
| POST | `/recommend` | Smart crop suggestion based on soil + live weather |
| POST | `/webhook` | Dialogflow-compatible webhook |
| POST | `/debug-query` | Debug intent detection (dev only) |

### `/query` request body:
```json
{ "query": "kapus rog" }
```
### `/query` response:
```json
{
  "success": true,
  "intent": "get_farm_doctor",
  "fulfillmentText": "..."
}
```

### `/recommend` request body:
```json
{ "soil_type": "black", "city": "Solapur" }
```

---

## Flutter Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  speech_to_text: ^7.0.0
  audioplayers: ^6.0.0
  flutter_tts: ^3.8.5
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  pin_code_fields: ^8.0.1
```

---

## Python Dependencies

```
flask
requests
boto3
python-dotenv
```

---

## Voice Features

- **Auditory Confirmation** — app repeats what it heard, shows confirm/retry buttons before acting
- **Full sentence understanding** — natural Marathi sentences work, not just keywords
- **Marathi number words** — spoken numbers parsed as digits in the fertilizer calculator
- **Contextual weather answers** — rain / wind / humidity / temperature questions answered differently
- **Yojana voice search** — keyword matching across all 6 schemes, auto-expands and speaks on match
- **Auto-speak results** — every screen speaks the answer automatically after confirmation

---

## Notes

- `.env` file is **gitignored** — never commit your AWS credentials
- Backend URL is configured in one place: `lib/utils/app_config.dart`
- All HTTP calls go through `lib/utils/api_client.dart` which adds `ngrok-skip-browser-warning` header automatically
- For Chrome use `http://127.0.0.1:5000`, for phone use ngrok URL
- Amazon Polly **Kajal** (neural) voice reads Marathi in Devanagari script via the Hindi engine
- OTP auth works on Android only; web uses email/password
- Mandi prices always show all 15 crops — live data from data.gov.in overrides local fallback where available
- Gender avatar uses face_3_rounded for female, face_rounded otherwise
- App tested on Flutter Web (Chrome) and Android 14 (CPH2401)

---

## Built By

**Rutuj** — Built entirely from scratch as a voice-first agricultural assistant for Marathi-speaking farmers in Maharashtra.
