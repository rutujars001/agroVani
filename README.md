# 🌾 AgroVani — Voice-First Farming Assistant

AgroVani is a **Marathi-language voice assistant** built for farmers. It provides crop advice, mandi prices, weather updates, government schemes, and fertilizer calculations — all through a conversational voice interface powered by **Flutter**, **Flask**, and **Amazon Polly**.

---

## 📱 Features

| Screen | Description |
|---|---|
| 🏠 Home | Voice-based query interface with Dialogflow-style intent detection |
| 🌾 पीक माहिती | Crop info grid — tap or speak a crop to hear रोग, खत, पाणी advice |
| 🩺 कृषी डॉक्टर | Guided 3-step flow: select crop → select symptom → get spoken advice |
| 🌤️ हवामान | Live weather with contextual answers (पाऊस पडेल का? / तापमान किती?) |
| 📋 शासकीय योजना | 6 government schemes with voice search and auto-speak |
| 📊 बाजारभाव | Live mandi prices for 15 Solapur crops, voice-filtered |
| 🧪 खत गणक | Fertilizer calculator — supports full Marathi sentences + number words |

---

## 🏗️ Tech Stack

### Frontend
- **Flutter** 3.43.0+ (Dart)
- **speech_to_text** — Marathi (`mr_IN`) voice recognition
- **audioplayers** — plays Amazon Polly MP3 audio
- **http** — REST API calls to Flask backend

### Backend
- **Python 3.x** + **Flask** — REST API server
- **Amazon Polly** (Aditi, hi-IN) — Text-to-Speech
- **boto3** — AWS SDK for Python
- **python-dotenv** — environment variable management
- **OpenWeatherMap API** — live weather data

---

## 📁 Project Structure

```
agrovani_backend/
├── app.py                  # Flask server — all API routes
├── crop_info.txt           # 15 crops × 3 topics (रोग/खत/पाणी) in Marathi
├── mandi_data.json         # Solapur mandi prices for 15 crops
├── run_server.bat          # Start Flask server (Windows)
├── .env                    # AWS credentials (not committed)
├── pubspec.yaml            # Flutter dependencies
└── lib/
    ├── main.dart
    ├── screens/
    │   ├── home_screen.dart
    │   ├── crops_screen.dart
    │   ├── krushi_doctor.dart
    │   ├── weather_screen.dart
    │   ├── yojana_screen.dart
    │   ├── mandi_price.dart
    │   ├── calculator_screen.dart
    │   └── splash_screen.dart
    ├── widgets/
    │   └── voice_mic_bar.dart   # Shared mic widget with auditory confirmation
    └── utils/
        └── polly_tts.dart       # Amazon Polly TTS helper
```

---

## ⚙️ Setup & Installation

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) 3.13+
- Python 3.8+
- AWS Account with **AmazonPollyReadOnlyAccess** IAM policy
- [OpenWeatherMap API key](https://openweathermap.org/api) (free tier)

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

**Set your OpenWeatherMap API key** in `app.py`:
```python
WEATHER_API_KEY = 'your_openweathermap_api_key'
```

**Start the Flask server:**
```bash
# Windows
run_server.bat

# Mac / Linux
python app.py
```
Server runs on `http://127.0.0.1:5000`

---

### 3. Flutter Setup

**Install dependencies:**
```bash
flutter pub get
```

**Set the backend URL** — open `lib/utils/polly_tts.dart` and all screen files, replace the IP with your machine's local IP (for physical device testing):
```dart
// For web browser testing
'http://127.0.0.1:5000'

// For physical Android device (replace with your PC's IP)
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

---

## 🔑 AWS Polly Setup

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Create a new user with **AmazonPollyReadOnlyAccess** policy
3. Generate Access Key + Secret Key
4. Add them to your `.env` file

> **Voice used:** Aditi (Hindi/hi-IN, standard engine) — reads Marathi Devanagari text

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Health check |
| POST | `/speak` | Text → MP3 via Amazon Polly |
| POST | `/query` | Intent detection + Marathi response |
| GET | `/mandi-prices` | Solapur mandi prices |

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

---

## 📦 Flutter Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  speech_to_text: ^6.6.1
  flutter_tts: ^3.8.5
  audioplayers: ^6.0.0
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

- **Auditory Confirmation** — app repeats what it heard before acting
- **Full sentence understanding** — "सोलापूर मध्ये पाऊस पडेल का?" works, not just keywords
- **Marathi number words** — "पाच एकर" parsed as 5 acres in calculator
- **Auto-speak results** — every screen speaks the answer automatically after confirmation

---

## 📝 Notes

- `.env` file is **gitignored** — never commit your AWS credentials
- Backend URL is hardcoded — update it to your local IP for physical device testing
- Amazon Polly **Aditi** voice reads Marathi in Devanagari script (Hindi engine)
- App tested on Flutter Web (Chrome) and Android 14

---

## 👨‍💻 Built By

**Rutuj** — Built entirely from scratch as a voice-first agricultural assistant for Marathi-speaking farmers in Maharashtra.
