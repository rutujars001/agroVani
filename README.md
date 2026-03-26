# 🌾 AgroVani — Voice-First Farming Assistant

## 🧭 About the Project

India has over 140 million farmers, the majority of whom speak regional languages and have limited access to smartphones or the internet in a meaningful way. Farmers in Maharashtra primarily speak **Marathi** — yet most agricultural apps are built in English or Hindi, creating a massive accessibility gap.

**AgroVani** bridges this gap by providing a **fully voice-driven agricultural assistant in Marathi**. A farmer doesn't need to type, read, or navigate complex menus. They simply **speak** — and the app understands, responds, and speaks back in Marathi.

### 🌱 The Problem It Solves

| Problem | AgroVani's Solution |
|---|---|
| Farmers can't read English apps | Fully Marathi UI + voice |
| Crop disease info is hard to find | कृषी डॉक्टर — guided diagnosis flow |
| Mandi prices require middlemen | Live Solapur mandi prices, voice-filtered |
| Weather apps are complex | Ask naturally — "पाऊस पडेल का?" |
| Government schemes are confusing | 6 schemes explained in simple Marathi |
| Fertilizer calculation needs expertise | Speak crop + area → get exact quantity |

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
