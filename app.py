import os
from dotenv import load_dotenv
load_dotenv()
import requests
import json
import base64
from datetime import date
from flask import Flask, request, jsonify
import boto3
import xml.etree.ElementTree as ET

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
_POLLY_VOICE  = 'Kajal'   # Neural Hindi voice — reads Marathi Devanagari naturally
_POLLY_ENGINE = 'neural'  # Kajal requires neural engine
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
    state = request.args.get('state', 'Maharashtra')
    try:
        url = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'
        params = {
            'api-key': '579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b',
            'format':  'json',
            'limit':   100,
            'filters[state]': state,
        }
        res     = requests.get(url, params=params, timeout=8).json()
        records = res.get('records', [])

        if not records:
            raise ValueError('No records')

        today = date.today().strftime("%d-%m-%Y")
        rows  = []
        seen  = set()
        # Normalize commodity names to match Flutter crop keys
        _commodity_normalize = {
            'jowar': 'Jowar', 'sorghum': 'Jowar',
            'wheat': 'Wheat',
            'tur': 'Tur', 'arhar': 'Tur', 'pigeonpea': 'Tur',
            'onion': 'Onion',
            'soybean': 'Soybean', 'soya': 'Soybean',
            'sunflower': 'Sunflower',
            'groundnut': 'Groundnut',
            'cotton': 'Cotton',
            'gram': 'Gram', 'chickpea': 'Gram', 'harbhara': 'Gram',
            'maize': 'Maize', 'corn': 'Maize',
            'bajra': 'Bajra', 'pearlmillet': 'Bajra',
            'sugarcane': 'Sugarcane',
            'tomato': 'Tomato',
            'pomegranate': 'Pomegranate',
            'grape': 'Grape',
        }
        for r in records:
            raw = r.get('commodity', '').strip().lower()
            # Match against normalize map using substring
            normalized = None
            for key, val in _commodity_normalize.items():
                if key in raw:
                    normalized = val
                    break
            if not normalized:
                normalized = r.get('commodity', '').strip().title()
            if normalized in seen:
                continue
            seen.add(normalized)
            rows.append({
                'market_name':       r.get('market', state),
                'variety':           normalized,
                'price_per_quintal': r.get('modal_price', 0),
                'min':               r.get('min_price',   0),
                'max':               r.get('max_price',   0),
                'date':              r.get('arrival_date', today),
            })

        return jsonify({'success': True, 'count': len(rows), 'data': rows})

    except Exception as e:
        print(f"data.gov.in mandi-prices failed: {e} — falling back to local")
        # Fallback to local JSON
        with open('mandi_data.json', 'r') as f:
            data = json.load(f)
        market_data = data.get('Solapur', {})
        today = date.today().strftime("%d-%m-%Y")
        rows = []
        for variety, price_obj in market_data.items():
            rows.append({
                'market_name':       'Solapur',
                'variety':           variety,
                'price_per_quintal': price_obj.get('avg', 0),
                'min':               price_obj.get('min', 0),
                'max':               price_obj.get('max', 0),
                'date':              today,
            })
        return jsonify({'success': True, 'count': len(rows), 'data': rows})

def fetch_weather(city="Solapur", query_text=""):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric"
    try:
        response = requests.get(url).json()
        if response.get("cod") != 200:
            return "क्षमस्व, हवामान माहिती मिळाली नाही."

        temp      = response['main']['temp']
        humidity  = response['main']['humidity']
        condition = response['weather'][0]['main'].lower()
        desc      = response['weather'][0]['description']
        wind      = response['wind']['speed']
        clouds    = response['clouds']['all']

        text = query_text.lower()

        # Rain question
        if any(w in text for w in ['paus', 'rain', 'varsha', 'padel', 'pavas', 'पाऊस', 'पाउस', 'वर्षा', 'पडेल']):
            if 'rain' in condition or 'drizzle' in condition or 'thunderstorm' in condition:
                return f"{city} मध्ये आज पाऊस पडण्याची शक्यता आहे. सध्या {desc} आहे, आर्द्रता {humidity}% आणि ढग {clouds}% आहेत."
            elif clouds > 60 or humidity > 75:
                return f"{city} मध्ये आज पाऊस पडण्याची थोडी शक्यता आहे. ढग {clouds}% आणि आर्द्रता {humidity}% आहे. सावध राहा."
            else:
                return f"{city} मध्ये आज पाऊस पडण्याची शक्यता कमी आहे. आकाश {desc} आहे, तापमान {temp}°C आहे."

        # Wind question
        if any(w in text for w in ['vara', 'wind', 'वारा', 'वादळ', 'storm']):
            return f"{city} मध्ये वाऱ्याचा वेग {wind} मीटर प्रति सेकंद आहे. {'वादळाची शक्यता आहे, काळजी घ्या.' if wind > 10 else 'वारा सामान्य आहे.'}"

        # Humidity question
        if any(w in text for w in ['humidity', 'aardrata', 'आर्द्रता', 'दमट']):
            return f"{city} मध्ये सध्या आर्द्रता {humidity}% आहे. {'हवा खूप दमट आहे, बुरशीजन्य रोगांसाठी फवारणी करा.' if humidity > 80 else 'आर्द्रता सामान्य आहे.'}"

        # Temperature question
        if any(w in text for w in ['tapman', 'temp', 'तापमान', 'उष्णता', 'थंडी']):
            return f"{city} मध्ये आज तापमान {temp}°C आहे. {'खूप उष्ण आहे, पिकांना पाणी द्या.' if temp > 35 else 'थंडीचे वातावरण आहे, पिकांचे संरक्षण करा.' if temp < 15 else 'तापमान सामान्य आहे.'}"

        # General weather
        return f"{city} मध्ये आज तापमान {temp}°C, आर्द्रता {humidity}%, वाऱ्याचा वेग {wind} m/s आहे. आकाश {desc} आहे."

    except:
        return "सर्व्हर एरर. कृपया नंतर प्रयत्न करा."

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

def fetch_live_mandi(commodity="Jowar", state="Maharashtra"):
    """
    Fetch live mandi prices from data.gov.in official API.
    Falls back to mandi_data.json on failure.
    """
    try:
        url = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'
        params = {
            'api-key': '579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b',
            'format':  'json',
            'limit':   5,
            'filters[state]':     state,
            'filters[commodity]': commodity,
        }
        res  = requests.get(url, params=params, timeout=8).json()
        records = res.get('records', [])

        if not records:
            raise ValueError('No records found')

        r           = records[0]
        market      = r.get('market',   'सोलापूर')
        min_price   = r.get('min_price', '-')
        max_price   = r.get('max_price', '-')
        modal_price = r.get('modal_price', '-')
        arrival_date= r.get('arrival_date', '')
        marathi_name = _marathi_crop_names.get(commodity, commodity)

        return (
            f"Agmarknet अधिकृत भाव ({arrival_date}): "
            f"{marathi_name} — {market} मंडईत सरासरी ₹{modal_price}, "
            f"किमान ₹{min_price}, कमाल ₹{max_price} प्रति क्विंटल."
        )

    except Exception as e:
        print(f"data.gov.in API failed: {e} — falling back to local data")
        return fetch_mandi_price(commodity)


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

# ── shared lookup tables ──────────────────────────────────────────────────────
_CROP_MAP = {
    "jowar": "Jowar", "jwari": "Jowar", "jwair": "Jowar", "ज्वारी": "Jowar",
    "wheat": "Wheat", "gahu": "Wheat", "गहू": "Wheat",
    "toor": "Tur", "तूर": "Tur",
    "onion": "Onion", "kanda": "Onion", "कांदा": "Onion",
    "soybean": "Soybean", "soyabean": "Soybean", "soya": "Soybean", "सोयाबीन": "Soybean",
    "sunflower": "Sunflower", "suryafool": "Sunflower", "सूर्यफूल": "Sunflower",
    "groundnut": "Groundnut", "shengdana": "Groundnut", "शेंगदाणा": "Groundnut",
    "cotton": "Cotton", "kapus": "Cotton", "कापूस": "Cotton",
    "harbhara": "Gram", "chana": "Gram", "हरभरा": "Gram",
    "maize": "Maize", "makka": "Maize", "corn": "Maize", "मका": "Maize",
    "bajra": "Bajra", "bajri": "Bajra", "बाजरी": "Bajra",
    "sugarcane": "Sugarcane", "oos": "Sugarcane", "ऊस": "Sugarcane",
    "tomato": "Tomato", "tamatar": "Tomato", "tometo": "Tomato", "टोमॅटो": "Tomato",
    "pomegranate": "Pomegranate", "dalimb": "Pomegranate", "डाळिंब": "Pomegranate",
    "grape": "Grape", "draksha": "Grape", "द्राक्षे": "Grape",
    # short keys last to avoid false matches
    "jowar": "Jowar", "tur": "Tur", "gram": "Gram",
}

_TOPIC_KEYWORDS = [
    "rog", "kida", "kidi", "disease", "pest", "रोग", "किडी",
    "khat", "khad", "fertilizer", "खत",
    "pani", "sinchan", "water", "पाणी", "सिंचन",
]

_WEATHER_KEYWORDS = [
    "havaman", "weather", "tapman", "hava", "paus", "varsha",
    "हवामान", "तापमान", "पाऊस", "वर्षा", "ऊन", "थंडी",
]

_MANDI_KEYWORDS = [
    "bhav", "mandi", "bajar", "rate", "kimat", "mol",
    "भाव", "बाजार", "मंडई", "किंमत", "दर",
]

def _contains(text, keywords):
    """Return True if any keyword appears as a substring in text."""
    return any(kw in text for kw in keywords)

def _extract_crop(text):
    """Return the first matching crop key found anywhere in the sentence."""
    for key, val in _CROP_MAP.items():
        if key in text:
            return val
    return None

def _extract_topic(text):
    return next((kw for kw in _TOPIC_KEYWORDS if kw in text), "")

def _detect_intent_from_text(query_text):
    import re
    text = (query_text or "").strip().lower()
    if not text:
        return "fallback", None

    if _contains(text, ["namaskar", "hello", "hi ", "नमस्कार"]):
        return "Default Welcome Intent", None

    if _contains(text, _WEATHER_KEYWORDS):
        return "get_weather", None

    # Farm doctor — topic keyword anywhere in sentence
    if _contains(text, _TOPIC_KEYWORDS):
        crop  = _extract_crop(text)
        topic = _extract_topic(text)
        return "get_farm_doctor", (crop, topic)

    # Mandi price — crop name OR price keyword anywhere in sentence
    crop = _extract_crop(text)
    if crop:
        return "get_mandi_price", crop

    if _contains(text, _MANDI_KEYWORDS):
        return "get_mandi_price", None

    return "fallback", None

def _build_reply(intent, param, query_text=""):
    if intent == "Default Welcome Intent":
        return "नमस्कार! AgroVani मध्ये आपले स्वागत आहे."
    if intent == "get_weather":
        return fetch_weather("Solapur", query_text)
    if intent == "get_mandi_price":
        if param:
            return fetch_live_mandi(param, "Maharashtra")
        return "कोणत्या पिकाचा बाजारभाव हवा आहे? (ज्वारी, गहू, कांदा, तूर...)"
    if intent == "get_farm_doctor":
        crop, topic = param if isinstance(param, tuple) else (param, "")
        if not crop:
            return "कोणत्या पिकाबद्दल माहिती हवी आहे? आणि रोग, खत, की पाणी?"
        return get_crop_advice(crop, topic or "")
    return "क्षमस्व, मला समजले नाही. कृपया पुन्हा सांगा."

# ── Crop recommendation logic ─────────────────────────────────────────────────
_SOIL_CROP_MAP = {
    'black':  {'high_humidity': 'कापूस', 'low_humidity': 'ज्वारी', 'rainy': 'सोयाबीन'},
    'red':    {'high_humidity': 'भुईमूग', 'low_humidity': 'बाजरी', 'rainy': 'तूर'},
    'alluvial':{'high_humidity': 'गहू',  'low_humidity': 'मका',   'rainy': 'ऊस'},
    'sandy':  {'high_humidity': 'शेंगदाणा','low_humidity': 'बाजरी','rainy': 'मका'},
    'loamy':  {'high_humidity': 'गहू',   'low_humidity': 'हरभरा', 'rainy': 'सोयाबीन'},
}

_SOIL_MARATHI = {
    'black': 'काळी माती', 'red': 'लाल माती',
    'alluvial': 'गाळाची माती', 'sandy': 'वालुकामय माती', 'loamy': 'चिकणमाती',
}

@app.route('/agri-news', methods=['GET'])
def agri_news():
    try:
        url = 'https://newsapi.org/v2/everything'
        params = {
            'q': 'agriculture India farming crops mandi',
            'language': 'en',
            'sortBy': 'publishedAt',
            'pageSize': 3,
            'apiKey': '0fabec243c9e4edebe93e06efef0005d',
        }
        res  = requests.get(url, params=params, timeout=6).json()
        articles = res.get('articles', [])
        news = []
        for a in articles[:3]:
            news.append({
                'title':  a.get('title', '').split(' - ')[0].strip(),
                'source': a.get('source', {}).get('name', 'Trusted News'),
                'link':   a.get('url', ''),
                'date':   (a.get('publishedAt') or '')[:10],
            })
        if news:
            return jsonify({'success': True, 'news': news})
        raise ValueError('No articles')
    except Exception as e:
        print(f'NewsAPI error: {e}')
        # Fallback static headlines
        return jsonify({'success': True, 'news': [
            {'title': 'खरीप हंगामात सोयाबीन लागवडीसाठी शेतकर्यांनी तयारी करावी', 'source': 'Krishi Jagran', 'link': '', 'date': ''},
            {'title': 'पीक विमा योजनेत नोंदणीसाठी अंतिम तारीख जवळ येत आहे', 'source': 'ET Agriculture', 'link': '', 'date': ''},
            {'title': 'सोलापूर जिल्ह्यात कांदा उत्पादनात वाढ, भाव स्थिर', 'source': 'Krishi Jagran', 'link': '', 'date': ''},
        ]})


def recommend_crop():
    data      = request.get_json(silent=True, force=True) or {}
    soil_type = (data.get('soil_type') or 'black').lower().strip()
    city      = data.get('city', 'Solapur')

    # Get live weather
    try:
        url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric"
        w         = requests.get(url, timeout=5).json()
        humidity  = w['main']['humidity']
        condition = w['weather'][0]['main'].lower()
        temp      = w['main']['temp']
    except:
        humidity, condition, temp = 60, 'clear', 28

    # Determine weather condition bucket
    if 'rain' in condition or 'thunder' in condition or 'drizzle' in condition:
        bucket = 'rainy'
    elif humidity > 70:
        bucket = 'high_humidity'
    else:
        bucket = 'low_humidity'

    soil_key  = soil_type if soil_type in _SOIL_CROP_MAP else 'black'
    crop      = _SOIL_CROP_MAP[soil_key][bucket]
    soil_mr   = _SOIL_MARATHI.get(soil_key, soil_key)

    # Build contextual reason
    if bucket == 'rainy':
        reason = f"सध्या पाऊस आहे आणि {soil_mr} आहे"
    elif bucket == 'high_humidity':
        reason = f"आर्द्रता {humidity}% जास्त आहे आणि {soil_mr} आहे"
    else:
        reason = f"तापमान {temp}°C आहे आणि {soil_mr} आहे"

    message = (
        f"🌱 स्मार्ट सूचना: {reason}, त्यामुळे "
        f"**{crop}** लागवड केल्यास जास्त उत्पादन मिळेल. "
        f"सध्याचे हवामान या पिकासाठी अनुकूल आहे."
    )

    return jsonify({
        'success':    True,
        'crop':       crop,
        'soil':       soil_mr,
        'humidity':   humidity,
        'condition':  condition,
        'temp':       temp,
        'message':    message,
    })


def query():
    data = request.get_json(silent=True, force=True) or {}
    query_text = data.get('query', '')
    intent, param = _detect_intent_from_text(query_text)
    reply = _build_reply(intent, param, query_text)
    return jsonify({
        "success": True,
        "intent": intent,
        "query": query_text,
        "fulfillmentText": reply
    })

@app.route('/query', methods=['POST'])
def query():
    data = request.get_json(silent=True, force=True) or {}
    query_text = data.get('query', '')
    intent, param = _detect_intent_from_text(query_text)
    reply = _build_reply(intent, param, query_text)
    return jsonify({
        'success': True,
        'intent': intent,
        'query': query_text,
        'fulfillmentText': reply
    })

@app.route('/recommend', methods=['POST'])
def recommend_crop():
    data      = request.get_json(silent=True, force=True) or {}
    soil_type = (data.get('soil_type') or 'black').lower().strip()
    city      = data.get('city', 'Solapur')
    try:
        url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric"
        w         = requests.get(url, timeout=5).json()
        humidity  = w['main']['humidity']
        condition = w['weather'][0]['main'].lower()
        temp      = w['main']['temp']
    except:
        humidity, condition, temp = 60, 'clear', 28
    if 'rain' in condition or 'thunder' in condition or 'drizzle' in condition:
        bucket = 'rainy'
    elif humidity > 70:
        bucket = 'high_humidity'
    else:
        bucket = 'low_humidity'
    soil_key  = soil_type if soil_type in _SOIL_CROP_MAP else 'black'
    crop      = _SOIL_CROP_MAP[soil_key][bucket]
    soil_mr   = _SOIL_MARATHI.get(soil_key, soil_key)
    if bucket == 'rainy':
        reason = f"सध्या पाऊस आहे आणि {soil_mr} आहे"
    elif bucket == 'high_humidity':
        reason = f"आर्द्रता {humidity}% जास्त आहे आणि {soil_mr} आहे"
    else:
        reason = f"तापमान {temp}°C आहे आणि {soil_mr} आहे"
    message = f"🌱 स्मार्ट सूचना: {reason}, त्यामुळे {crop} लागवड केल्यास जास्त उत्पादन मिळेल. सध्याचे हवामान या पिकासाठी अनुकूल आहे."
    return jsonify({'success': True, 'crop': crop, 'soil': soil_mr, 'humidity': humidity, 'condition': condition, 'temp': temp, 'message': message})


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
    app.run(host='0.0.0.0', port=5000, debug=True)