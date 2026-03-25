import os
from dotenv import load_dotenv
load_dotenv()
import requests
import json
import base64
from datetime import date
from flask import Flask, request, jsonify
import boto3
from botocore.exceptions import BotoCoreError, ClientError

app = Flask(__name__)
WEATHER_API_KEY = '482a3a616b59b6ad77409e8aed90da11'

# ── Amazon Polly client ───────────────────────────────────────────────────────
# Aditi  → standard engine, hi-IN (best available for Marathi on Polly)
# Kajal  → neural  engine, hi-IN (switch voice_id + engine below to use Kajal)
_polly = boto3.client(
    'polly',
    region_name='ap-south-1',          # Mumbai — lowest latency from India
    aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
)
_POLLY_VOICE  = 'Aditi'    # swap to 'Kajal' for Neural
_POLLY_ENGINE = 'standard' # swap to 'neural' when using Kajal
_POLLY_LANG   = 'hi-IN'

@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET,POST,OPTIONS"
    return response

@app.route('/')
def index():
    return "AgroVani Server is Live!"


@app.route('/speak', methods=['POST'])
def speak():
    """
    Body: { "text": "<Marathi string>" }
    Returns: { "audio_base64": "<mp3 bytes as base64>" }
    Flutter plays it with audioplayers from bytes.
    """
    data = request.get_json(silent=True, force=True) or {}
    text = (data.get('text') or '').strip()
    if not text:
        return jsonify({'error': 'text is required'}), 400

    # Polly accepts max 3000 billed characters; truncate gracefully
    text = text[:2900]

    try:
        response = _polly.synthesize_speech(
            Text=text,
            OutputFormat='mp3',
            VoiceId=_POLLY_VOICE,
            Engine=_POLLY_ENGINE,
            LanguageCode=_POLLY_LANG,
        )
        audio_bytes = response['AudioStream'].read()
        audio_b64   = base64.b64encode(audio_bytes).decode('utf-8')
        return jsonify({'audio_base64': audio_b64})

    except (BotoCoreError, ClientError) as e:
        print(f'Polly error: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/mandi-prices', methods=['GET'])
def mandi_prices():
    market_name = request.args.get('market', 'Solapur')
    try:
        with open('mandi_data.json', 'r') as f:
            data = json.load(f)

        market_data = data.get(market_name, {})
        today = date.today().strftime("%d-%m-%Y")
        rows = []
        for variety, price_obj in market_data.items():
            rows.append({
                "market_name": market_name,
                "variety": variety,
                "price_per_quintal": price_obj.get("avg", 0),
                "min": price_obj.get("min", 0),
                "max": price_obj.get("max", 0),
                "date": today
            })

        return jsonify({
            "success": True,
            "count": len(rows),
            "data": rows
        })
    except Exception as e:
        print(f"Error loading mandi prices: {e}")
        return jsonify({
            "success": False,
            "message": "Unable to load mandi prices",
            "data": []
        }), 500

def fetch_weather(city="Solapur"):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric"
    try:
        response = requests.get(url).json()
        if response.get("cod") == 200:
            temp = response['main']['temp']
            return f"{city} madhe aaj tapman {temp}°C aahe."
        else:
            return "Kshamasva, mala havamanacha andaj gheta yet nahiye."
    except:
        return "Server error. Krupaya nantar prayatna kara."

_marathi_crop_names = {
    "Jowar": "ज्वारी", "Wheat": "गहू", "Tur": "तूर", "Onion": "कांदा",
    "Soybean": "सोयाबीन", "Sunflower": "सूर्यफूल", "Groundnut": "शेंगदाणा",
    "Cotton": "कापूस", "Gram": "हरभरा", "Maize": "मका", "Bajra": "बाजरी",
    "Sugarcane": "ऊस", "Tomato": "टोमॅटो", "Pomegranate": "डाळिंब", "Grape": "द्राक्षे",
}

# Topic keyword → label used in crop_info.txt
_topic_map = {
    "रोग":       "रोग", "disease":   "रोग", "rog":      "रोग", "kida":     "रोग",
    "किडी":      "रोग", "kidi":      "रोग", "pest":     "रोग",
    "खत":        "खत",  "fertilizer":"खत",  "khat":     "खत",  "khad":     "खत",
    "पाणी":      "पाणी","water":     "पाणी","pani":     "पाणी","sinchan":  "पाणी",
    "सिंचन":     "पाणी",
}

def get_crop_advice(crop: str, topic: str) -> str:
    """Read crop_info.txt and return the Marathi advice paragraph for (crop, topic)."""
    try:
        with open('crop_info.txt', 'r', encoding='utf-8') as f:
            content = f.read()

        # Normalise crop key — title-case English name
        crop = str(crop).strip().title()

        # Resolve topic label (रोग / खत / पाणी)
        topic_label = _topic_map.get(topic.strip().lower())
        if not topic_label:
            # Try partial match
            for key, label in _topic_map.items():
                if key in topic.lower():
                    topic_label = label
                    break

        # Find the [CropName] section
        import re
        pattern = rf'\[{re.escape(crop)}\](.*?)(?=\n\[|\Z)'
        match = re.search(pattern, content, re.DOTALL)
        if not match:
            return 'क्षमस्व, मला या पिकाची माहिती मिळाली नाही. मी लवकरच अपडेट करेन.'

        section = match.group(1)

        if not topic_label:
            # No topic detected — return full section
            return section.strip()

        # Find the specific topic line inside the section
        for line in section.splitlines():
            if line.startswith(topic_label + ':'):
                return line[len(topic_label) + 1:].strip()

        return 'क्षमस्व, मला या पिकाची माहिती मिळाली नाही. मी लवकरच अपडेट करेन.'
    except Exception as e:
        print(f"crop_info error: {e}")
        return 'क्षमस्व, मला या पिकाची माहिती मिळाली नाही. मी लवकरच अपडेट करेन.'

def fetch_mandi_price(commodity="Jowar"):
    try:
        if isinstance(commodity, list):
            commodity = commodity[0]
        commodity = str(commodity).title()

        with open('mandi_data.json', 'r') as f:
            data = json.load(f)

        prices = data["Solapur"].get(commodity)
        if prices:
            marathi_name = _marathi_crop_names.get(commodity, commodity)
            return f"आज {marathi_name} चा बाजारभाव ₹{prices['avg']} प्रति क्विंटल आहे. (किमान: ₹{prices['min']}, कमाल: ₹{prices['max']})"
        else:
            return f"क्षमस्व, {commodity} बद्दल माहिती मिळाली नाही."
    except Exception as e:
        print(f"Error: {e}")
        return "माफ करा, बाजारभाव माहिती उपलब्ध नाही."

def _detect_intent_from_text(query_text):
    text = (query_text or "").strip().lower()
    if not text:
        return "fallback", None

    if any(word in text for word in ["namaskar", "hello", "hi", "नमस्कार"]):
        return "Default Welcome Intent", None

    if any(word in text for word in ["havaman", "weather", "tapman", "हवामान", "तापमान"]):
        return "get_weather", None

    # Farm doctor keywords — check before mandi price
    farm_doctor_topics = [
        "rog", "kida", "kidi", "disease", "pest",
        "khat", "khad", "fertilizer",
        "pani", "sinchan", "water",
        "रोग", "किडी", "खत", "पाणी", "सिंचन",
    ]
    if any(word in text for word in farm_doctor_topics):
        # Try to detect crop from same text
        detected_crop = None
        farm_crop_map = {
            "jowar": "Jowar", "jwari": "Jowar", "ज्वारी": "Jowar",
            "wheat": "Wheat", "gahu": "Wheat", "गहू": "Wheat",
            "tur": "Tur", "toor": "Tur", "तूर": "Tur",
            "onion": "Onion", "kanda": "Onion", "कांदा": "Onion",
            "soybean": "Soybean", "soya": "Soybean", "सोयाबीन": "Soybean",
            "sunflower": "Sunflower", "suryafool": "Sunflower", "सूर्यफूल": "Sunflower",
            "groundnut": "Groundnut", "shengdana": "Groundnut", "शेंगदाणा": "Groundnut",
            "cotton": "Cotton", "kapus": "Cotton", "कापूस": "Cotton",
            "gram": "Gram", "harbhara": "Gram", "हरभरा": "Gram",
            "maize": "Maize", "makka": "Maize", "मका": "Maize",
            "bajra": "Bajra", "bajri": "Bajra", "बाजरी": "Bajra",
            "sugarcane": "Sugarcane", "oos": "Sugarcane", "ऊस": "Sugarcane",
            "tomato": "Tomato", "tamatar": "Tomato", "टोमॅटो": "Tomato",
            "pomegranate": "Pomegranate", "dalimb": "Pomegranate", "डाळिंब": "Pomegranate",
            "grape": "Grape", "draksha": "Grape", "द्राक्षे": "Grape",
        }
        for key, val in farm_crop_map.items():
            if key in text:
                detected_crop = val
                break
        detected_topic = next((w for w in farm_doctor_topics if w in text), "")
        return "get_farm_doctor", (detected_crop, detected_topic)

    crop_map = {
        "jowar": "Jowar", "jwari": "Jowar", "jwair": "Jowar", "ज्वारी": "Jowar",
        "wheat": "Wheat", "gahu": "Wheat", "गहू": "Wheat",
        "tur": "Tur", "toor": "Tur", "तूर": "Tur",
        "onion": "Onion", "kanda": "Onion", "कांदा": "Onion",
        "soybean": "Soybean", "soya": "Soybean", "soyabean": "Soybean", "सोयाबीन": "Soybean",
        "sunflower": "Sunflower", "suryafool": "Sunflower", "सूर्यफूल": "Sunflower",
        "groundnut": "Groundnut", "shengdana": "Groundnut", "शेंगदाणा": "Groundnut",
        "cotton": "Cotton", "kapus": "Cotton", "कापूस": "Cotton",
        "gram": "Gram", "chana": "Gram", "harbhara": "Gram", "हरभरा": "Gram",
        "maize": "Maize", "makka": "Maize", "corn": "Maize", "मका": "Maize",
        "bajra": "Bajra", "bajri": "Bajra", "बाजरी": "Bajra",
        "sugarcane": "Sugarcane", "oos": "Sugarcane", "ऊस": "Sugarcane",
        "tomato": "Tomato", "tamatar": "Tomato", "tometo": "Tomato", "टोमॅटो": "Tomato",
        "pomegranate": "Pomegranate", "dalimb": "Pomegranate", "डाळिंब": "Pomegranate",
        "grape": "Grape", "draksha": "Grape", "द्राक्षे": "Grape",
    }
    for key, value in crop_map.items():
        if key in text:
            return "get_mandi_price", value

    if any(word in text for word in ["bhav", "mandi", "bajar", "भाव", "बाजार"]):
        return "get_mandi_price", None

    return "fallback", None

def _build_reply(intent, param):
    if intent == "Default Welcome Intent":
        return "नमस्कार! AgroVani मध्ये आपले स्वागत आहे."
    if intent == "get_weather":
        return fetch_weather("Solapur")
    if intent == "get_mandi_price":
        if param:
            return fetch_mandi_price(param)
        return "कोणत्या पिकाचा बाजारभाव हवा आहे? (ज्वारी, गहू, कांदा, तूर...)"
    if intent == "get_farm_doctor":
        crop, topic = param if isinstance(param, tuple) else (param, "")
        if not crop:
            return "कोणत्या पिकाबद्दल माहिती हवी आहे? आणि रोग, खत, की पाणी?"
        return get_crop_advice(crop, topic or "")
    return "क्षमस्व, मला समजले नाही. कृपया पुन्हा सांगा."

@app.route('/query', methods=['POST'])
def query():
    data = request.get_json(silent=True, force=True) or {}
    query_text = data.get('query', '')
    intent, param = _detect_intent_from_text(query_text)
    reply = _build_reply(intent, param)
    return jsonify({
        "success": True,
        "intent": intent,
        "query": query_text,
        "fulfillmentText": reply
    })

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.get_json(silent=True, force=True)
    query_result = data.get('queryResult', {})
    intent = query_result.get('intent', {}).get('displayName', '')
    parameters = query_result.get('parameters') or {}

    def _extract_crop(params):
        raw = params.get('crop') or params.get('crop-name') or params.get('any')
        if isinstance(raw, list):
            raw = raw[0] if raw else None
        return str(raw).title() if raw else None

    param = None
    if intent == "get_mandi_price":
        param = _extract_crop(parameters)
    elif intent == "get_farm_doctor":
        crop  = _extract_crop(parameters)
        topic = parameters.get('query_topic') or parameters.get('topic') or ''
        if isinstance(topic, list):
            topic = topic[0] if topic else ''
        param = (crop, str(topic).lower())

    reply = _build_reply(intent, param)
    return jsonify({"fulfillmentText": reply})

if __name__ == '__main__':
    app.run(port=5000, debug=True)