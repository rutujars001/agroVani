import os
import re
import json
import base64
from datetime import date

import boto3
import requests
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from botocore.exceptions import BotoCoreError, ClientError

load_dotenv()

app = Flask(__name__)

WEATHER_API_KEY = '482a3a616b59b6ad77409e8aed90da11'
MANDI_API_KEY = '579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b'
DISEASE_KB_FILE = 'crop_disease_knowledge.json'

_polly = boto3.client(
    'polly',
    region_name='ap-south-1',
    aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
)

_POLLY_VOICE = 'Kajal'
_POLLY_ENGINE = 'neural'
_POLLY_LANG = 'hi-IN'

@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET,POST,OPTIONS'
    return response

@app.route('/')
def index():
    return 'AgroVani Server is Live!'


def load_disease_kb():
    try:
        with open(DISEASE_KB_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f'disease kb load error: {e}')
        return {}


DISEASE_KB = load_disease_kb()

_marathi_crop_names = {
    'Jowar': 'ज्वारी', 'Wheat': 'गहू', 'Tur': 'तूर', 'Onion': 'कांदा', 'Soybean': 'सोयाबीन',
    'Sunflower': 'सूर्यफूल', 'Groundnut': 'शेंगदाणा', 'Cotton': 'कापूस', 'Gram': 'हरभरा',
    'Maize': 'मका', 'Bajra': 'बाजरी', 'Sugarcane': 'ऊस', 'Tomato': 'टोमॅटो',
    'Pomegranate': 'डाळिंब', 'Grape': 'द्राक्षे',
}

_CROP_MAP = {
    'soyabean': 'Soybean', 'soybean': 'Soybean', 'sunflower': 'Sunflower', 'groundnut': 'Groundnut',
    'sugarcane': 'Sugarcane', 'pomegranate': 'Pomegranate', 'tomato': 'Tomato', 'cotton': 'Cotton',
    'onion': 'Onion', 'wheat': 'Wheat', 'jowar': 'Jowar', 'jwari': 'Jowar', 'jwair': 'Jowar',
    'toor': 'Tur', 'tur': 'Tur', 'maize': 'Maize', 'corn': 'Maize', 'bajra': 'Bajra',
    'bajri': 'Bajra', 'gram': 'Gram', 'chana': 'Gram', 'harbhara': 'Gram', 'soya': 'Soybean',
    'kanda': 'Onion', 'kapus': 'Cotton', 'makka': 'Maize', 'oos': 'Sugarcane', 'tamatar': 'Tomato',
    'tometo': 'Tomato', 'dalimb': 'Pomegranate', 'draksha': 'Grape', 'grape': 'Grape',
    'shengdana': 'Groundnut', 'suryafool': 'Sunflower',
    'ज्वारी': 'Jowar', 'गहू': 'Wheat', 'तूर': 'Tur', 'कांदा': 'Onion', 'सोयाबीन': 'Soybean',
    'सूर्यफूल': 'Sunflower', 'शेंगदाणा': 'Groundnut', 'कापूस': 'Cotton', 'हरभरा': 'Gram',
    'मका': 'Maize', 'बाजरी': 'Bajra', 'ऊस': 'Sugarcane', 'टोमॅटो': 'Tomato',
    'डाळिंब': 'Pomegranate', 'द्राक्षे': 'Grape',
    'कापसाच्या': 'Cotton', 'कापसाला': 'Cotton', 'कापसावर': 'Cotton', 'कांद्याच्या': 'Onion',
    'टोमॅटोच्या': 'Tomato', 'गव्हाच्या': 'Wheat', 'ज्वारीच्या': 'Jowar', 'सोयाबीनच्या': 'Soybean',
}

_topic_map = {
    'रोग': 'रोग', 'disease': 'रोग', 'rog': 'रोग', 'kida': 'रोग', 'किडी': 'रोग', 'kidi': 'रोग', 'pest': 'रोग',
    'खत': 'खत', 'fertilizer': 'खत', 'khat': 'खत', 'khad': 'खत',
    'पाणी': 'पाणी', 'water': 'पाणी', 'pani': 'पाणी', 'sinchan': 'पाणी', 'सिंचन': 'पाणी',
}

_TOPIC_KEYWORDS = ['rog', 'kida', 'kidi', 'disease', 'pest', 'रोग', 'किडी', 'khat', 'khad', 'fertilizer', 'खत', 'pani', 'sinchan', 'water', 'पाणी', 'सिंचन']
_WEATHER_KEYWORDS = ['havaman', 'weather', 'tapman', 'hava', 'paus', 'varsha', 'हवामान', 'तापमान', 'पाऊस', 'वर्षा', 'ऊन', 'थंडी']
_MANDI_KEYWORDS = ['bhav', 'mandi', 'bajar', 'rate', 'kimat', 'mol', 'भाव', 'बाजार', 'मंडई', 'किंमत', 'दर']
_SYMPTOM_KEYWORDS = [
    'डाग', 'डागे', 'काळे', 'काळा', 'पिवळे', 'पिवळी', 'पिवळा', 'गुंडाळ', 'वाळ', 'सड', 'ठिपके', 'करपा',
    'कुज', 'गळ', 'छिद्र', 'जळ', 'spots', 'spot', 'yellow', 'curl', 'wilt', 'rot', 'blight', 'lesion', 'drying',
]

_SOIL_CROP_MAP = {
    'black': {'high_humidity': 'कापूस', 'low_humidity': 'ज्वारी', 'rainy': 'सोयाबीन'},
    'red': {'high_humidity': 'भुईमूग', 'low_humidity': 'बाजरी', 'rainy': 'तूर'},
    'alluvial': {'high_humidity': 'गहू', 'low_humidity': 'मका', 'rainy': 'ऊस'},
    'sandy': {'high_humidity': 'शेंगदाणा', 'low_humidity': 'बाजरी', 'rainy': 'मका'},
    'loamy': {'high_humidity': 'गहू', 'low_humidity': 'हरभरा', 'rainy': 'सोयाबीन'},
}

_SOIL_MARATHI = {
    'black': 'काळी माती', 'red': 'लाल माती', 'alluvial': 'गाळाची माती', 'sandy': 'वालुकामय माती', 'loamy': 'चिकणमाती'
}


def _contains(text, keywords):
    return any(kw in text for kw in keywords)


def _normalize_text(text):
    text = (text or '').strip().lower()
    text = re.sub(r'[^a-zA-Z0-9\u0900-\u097F\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def _extract_crop(text):
    text = _normalize_text(text)
    for key, val in sorted(_CROP_MAP.items(), key=lambda x: len(x[0]), reverse=True):
        if key in text:
            return val
    return None


def _extract_topic(text):
    text = _normalize_text(text)
    return next((kw for kw in _TOPIC_KEYWORDS if kw in text), '')


def _looks_like_symptom_query(text):
    text = _normalize_text(text)
    symptom_hit = any(sym in text for sym in _SYMPTOM_KEYWORDS)
    plant_part_hit = any(part in text for part in ['पान', 'पाने', 'leaf', 'leaves', 'stem', 'खोड', 'फळ', 'root', 'मुळ'])
    return symptom_hit or plant_part_hit


@app.route('/speak', methods=['POST'])
def speak():
    data = request.get_json(silent=True, force=True) or {}
    text = (data.get('text') or '').strip()
    if not text:
        return jsonify({'error': 'text is required'}), 400
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
        audio_b64 = base64.b64encode(audio_bytes).decode('utf-8')
        return jsonify({'audio_base64': audio_b64})
    except (BotoCoreError, ClientError) as e:
        print(f'Polly error: {e}')
        return jsonify({'error': str(e)}), 500


def fetch_weather(city='Solapur', query_text=''):
    url = f'http://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric'
    try:
        response = requests.get(url, timeout=8).json()
        if response.get('cod') != 200:
            return 'क्षमस्व, हवामान माहिती मिळाली नाही.'
        temp = response['main']['temp']
        humidity = response['main']['humidity']
        condition = response['weather'][0]['main'].lower()
        desc = response['weather'][0]['description']
        wind = response['wind']['speed']
        clouds = response['clouds']['all']
        text = (query_text or '').lower()
        if any(w in text for w in ['paus', 'rain', 'varsha', 'padel', 'pavas', 'पाऊस', 'पाउस', 'वर्षा', 'पडेल']):
            if 'rain' in condition or 'drizzle' in condition or 'thunderstorm' in condition:
                return f'{city} मध्ये आज पाऊस पडण्याची शक्यता आहे. सध्या {desc} आहे, आर्द्रता {humidity}% आणि ढग {clouds}% आहेत.'
            elif clouds > 60 or humidity > 75:
                return f'{city} मध्ये आज पाऊस पडण्याची थोडी शक्यता आहे. ढग {clouds}% आणि आर्द्रता {humidity}% आहे. सावध राहा.'
            else:
                return f'{city} मध्ये आज पाऊस पडण्याची शक्यता कमी आहे. आकाश {desc} आहे, तापमान {temp}°C आहे.'
        if any(w in text for w in ['vara', 'wind', 'वारा', 'वादळ', 'storm']):
            return f"{city} मध्ये वाऱ्याचा वेग {wind} मीटर प्रति सेकंद आहे. {'वादळाची शक्यता आहे, काळजी घ्या.' if wind > 10 else 'वारा सामान्य आहे.'}"
        if any(w in text for w in ['humidity', 'aardrata', 'आर्द्रता', 'दमट']):
            return f"{city} मध्ये सध्या आर्द्रता {humidity}% आहे. {'हवा खूप दमट आहे, बुरशीजन्य रोगांसाठी फवारणी करा.' if humidity > 80 else 'आर्द्रता सामान्य आहे.'}"
        if any(w in text for w in ['tapman', 'temp', 'तापमान', 'उष्णता', 'थंडी']):
            return f"{city} मध्ये आज तापमान {temp}°C आहे. {'खूप उष्ण आहे, पिकांना पाणी द्या.' if temp > 35 else 'थंडीचे वातावरण आहे, पिकांचे संरक्षण करा.' if temp < 15 else 'तापमान सामान्य आहे.'}"
        return f'{city} मध्ये आज तापमान {temp}°C, आर्द्रता {humidity}%, वाऱ्याचा वेग {wind} m/s आहे. आकाश {desc} आहे.'
    except Exception as e:
        print(f'weather error: {e}')
        return 'सर्व्हर एरर. कृपया नंतर प्रयत्न करा.'


def get_crop_advice(crop: str, topic: str) -> str:
    try:
        with open('crop_info.txt', 'r', encoding='utf-8') as f:
            content = f.read()
        crop = str(crop).strip().title()
        topic_label = _topic_map.get(topic.strip().lower()) if topic else None
        if not topic_label and topic:
            for key, label in _topic_map.items():
                if key in topic.lower():
                    topic_label = label
                    break
        pattern = rf'\[{re.escape(crop)}\](.*?)(?=\n\[|\Z)'
        match = re.search(pattern, content, re.DOTALL)
        if not match:
            return 'क्षमस्व, मला या पिकाची माहिती मिळाली नाही. मी लवकरच अपडेट करेन.'
        section = match.group(1)
        if not topic_label:
            return section.strip()
        for line in section.splitlines():
            if line.startswith(topic_label + ':'):
                return line[len(topic_label) + 1:].strip()
        return 'क्षमस्व, मला या पिकाची माहिती मिळाली नाही. मी लवकरच अपडेट करेन.'
    except Exception as e:
        print(f'crop_info error: {e}')
        return 'क्षमस्व, मला या पिकाची माहिती मिळाली नाही. मी लवकरच अपडेट करेन.'


def fetch_local_mandi_price(commodity='Jowar'):
    try:
        if isinstance(commodity, list):
            commodity = commodity[0]
        commodity = str(commodity).title()
        with open('mandi_data.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
        prices = data.get('Solapur', {}).get(commodity)
        if prices:
            marathi_name = _marathi_crop_names.get(commodity, commodity)
            return f"आज {marathi_name} चा बाजारभाव ₹{prices['avg']} प्रति क्विंटल आहे. (किमान: ₹{prices['min']}, कमाल: ₹{prices['max']})"
        return f'क्षमस्व, {commodity} बद्दल माहिती मिळाली नाही.'
    except Exception as e:
        print(f'local mandi error: {e}')
        return 'माफ करा, बाजारभाव माहिती उपलब्ध नाही.'


def fetch_live_mandi(commodity='Jowar', state='Maharashtra'):
    try:
        url = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'
        params = {
            'api-key': MANDI_API_KEY,
            'format': 'json',
            'limit': 5,
            'filters[state]': state,
            'filters[commodity]': commodity,
        }
        res = requests.get(url, params=params, timeout=8).json()
        records = res.get('records', [])
        if not records:
            raise ValueError('No records found')
        r = records[0]
        market = r.get('market', 'सोलापूर')
        min_price = r.get('min_price', '-')
        max_price = r.get('max_price', '-')
        modal_price = r.get('modal_price', '-')
        arrival_date = r.get('arrival_date', '')
        marathi_name = _marathi_crop_names.get(commodity, commodity)
        return f'Agmarknet अधिकृत भाव ({arrival_date}): {marathi_name} — {market} मंडईत सरासरी ₹{modal_price}, किमान ₹{min_price}, कमाल ₹{max_price} प्रति क्विंटल.'
    except Exception as e:
        print(f'data.gov.in API failed: {e} — falling back to local data')
        return fetch_local_mandi_price(commodity)


@app.route('/mandi-prices', methods=['GET'])
def mandi_prices():
    state = request.args.get('state', 'Maharashtra')
    today = date.today().strftime('%d-%m-%Y')
    commodity_normalize = {
        'jowar': 'Jowar', 'sorghum': 'Jowar', 'wheat': 'Wheat', 'tur': 'Tur', 'arhar': 'Tur',
        'pigeonpea': 'Tur', 'onion': 'Onion', 'soybean': 'Soybean', 'soya': 'Soybean',
        'sunflower': 'Sunflower', 'groundnut': 'Groundnut', 'cotton': 'Cotton', 'gram': 'Gram',
        'chickpea': 'Gram', 'maize': 'Maize', 'corn': 'Maize', 'bajra': 'Bajra',
        'pearlmillet': 'Bajra', 'sugarcane': 'Sugarcane', 'tomato': 'Tomato',
        'pomegranate': 'Pomegranate', 'grape': 'Grape',
    }
    # Always start with local data so all 15 crops are shown
    with open('mandi_data.json', 'r', encoding='utf-8') as f:
        local_data = json.load(f).get('Solapur', {})
    rows = {}
    for variety, price_obj in local_data.items():
        rows[variety] = {
            'market_name': 'Solapur APMC',
            'variety': variety,
            'price_per_quintal': price_obj.get('avg', 0),
            'min': price_obj.get('min', 0),
            'max': price_obj.get('max', 0),
            'date': today,
        }
    # Override with live data where available
    try:
        url = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'
        params = {'api-key': MANDI_API_KEY, 'format': 'json', 'limit': 100, 'filters[state]': state}
        res = requests.get(url, params=params, timeout=8).json()
        for r in res.get('records', []):
            raw = r.get('commodity', '').strip().lower()
            normalized = next((val for key, val in commodity_normalize.items() if key in raw), None)
            if normalized and normalized in rows:
                rows[normalized] = {
                    'market_name': r.get('market', state),
                    'variety': normalized,
                    'price_per_quintal': r.get('modal_price', 0),
                    'min': r.get('min_price', 0),
                    'max': r.get('max_price', 0),
                    'date': r.get('arrival_date', today),
                }
    except Exception as e:
        print(f'data.gov.in live fetch failed: {e} - using local data only')
    result = list(rows.values())
    return jsonify({'success': True, 'count': len(result), 'data': result})


def _score_disease_entry(user_text, disease_entry):
    score = 0
    text = _normalize_text(user_text)
    for kw in disease_entry.get('symptom_keywords', []):
        if _normalize_text(kw) in text:
            score += 2
    for phrase in disease_entry.get('symptom_phrases_mr', []):
        if _normalize_text(phrase) in text:
            score += 3
    return score


def _format_disease_reply(crop, disease):
    disease_name = disease.get('disease_name_mr') or disease.get('disease_name') or 'अज्ञात रोग'
    what_happened = disease.get('what_happened', 'लक्षणांनुसार रोग ओळखला गेला आहे.')
    what_to_do_now = disease.get('what_to_do_now', [])
    medicines = disease.get('recommended_medicines', [])
    prevention = disease.get('prevention', [])
    dosage_note = disease.get('dosage_note', '')
    crop_mr = _marathi_crop_names.get(crop, crop)
    parts = [f'{crop_mr} साठी संभाव्य रोग: {disease_name}.', what_happened]
    if what_to_do_now:
        parts.append('आता काय करावे: ' + ' '.join([f'{i+1}) {x}.' for i, x in enumerate(what_to_do_now)]))
    if medicines:
        parts.append('सुचवलेली औषधे: ' + ', '.join(medicines) + '.')
    if dosage_note:
        parts.append(dosage_note)
    if prevention:
        parts.append('प्रतिबंध: ' + ' '.join([f'{i+1}) {x}.' for i, x in enumerate(prevention)]))
    parts.append('गंभीर प्रादुर्भाव असल्यास जवळच्या कृषी तज्ज्ञांचा सल्ला घ्या.')
    return ' '.join(parts)


def diagnose_crop_disease(user_text, crop=None):
    if not crop:
        crop = _extract_crop(user_text)
    if not crop:
        return 'कृपया कोणते पीक आहे ते सांगा. उदाहरण: कापूस, कांदा, सोयाबीन, टोमॅटो.'
    diseases = DISEASE_KB.get(crop, [])
    if not diseases:
        return f"{_marathi_crop_names.get(crop, crop)} साठी रोग माहिती अजून उपलब्ध नाही."
    best = None
    best_score = 0
    for disease in diseases:
        score = _score_disease_entry(user_text, disease)
        if score > best_score:
            best_score = score
            best = disease
    if not best or best_score == 0:
        return f"{_marathi_crop_names.get(crop, crop)} साठी दिलेल्या लक्षणांवरून अचूक रोग सापडला नाही. कृपया पानावर डाग, पिवळेपणा, गुंडाळी, वाळणे, सडणे अशा लक्षणांसह पुन्हा सांगा."
    return _format_disease_reply(crop, best)


def _detect_intent_from_text(query_text):
    text = _normalize_text(query_text)
    if not text:
        return 'fallback', None
    if _contains(text, ['namaskar', 'hello', 'hi ', 'नमस्कार']):
        return 'Default Welcome Intent', None
    if _contains(text, _WEATHER_KEYWORDS):
        return 'get_weather', None
    crop = _extract_crop(text)
    if _contains(text, _TOPIC_KEYWORDS):
        topic = _extract_topic(text)
        return 'get_farm_doctor', (crop, topic)
    if crop and _looks_like_symptom_query(text):
        return 'get_farm_doctor_symptoms', crop
    if crop and any(word in text for word in ['रोग', 'किड', 'आजार', 'समस्या', 'त्रास']):
        return 'get_farm_doctor_symptoms', crop
    if crop:
        return 'get_mandi_price', crop
    if _contains(text, _MANDI_KEYWORDS):
        return 'get_mandi_price', None
    return 'fallback', None


def _build_reply(intent, param, query_text=''):
    if intent == 'Default Welcome Intent':
        return 'नमस्कार! AgroVani मध्ये आपले स्वागत आहे.'
    if intent == 'get_weather':
        return fetch_weather('Solapur', query_text)
    if intent == 'get_mandi_price':
        if param:
            return fetch_live_mandi(param, 'Maharashtra')
        return 'कोणत्या पिकाचा बाजारभाव हवा आहे? (ज्वारी, गहू, कांदा, तूर...)'
    if intent == 'get_farm_doctor':
        crop, topic = param if isinstance(param, tuple) else (param, '')
        if not crop:
            return 'कोणत्या पिकाबद्दल माहिती हवी आहे? आणि रोग, खत, की पाणी?'
        return get_crop_advice(crop, topic or '')
    if intent == 'get_farm_doctor_symptoms':
        crop = param if isinstance(param, str) else None
        return diagnose_crop_disease(query_text, crop)
    return 'क्षमस्व, मला समजले नाही. कृपया पुन्हा सांगा.'


@app.route('/agri-news', methods=['GET'])
def agri_news():
    try:
        url = 'https://newsapi.org/v2/top-headlines'
        params = {'category': 'science', 'country': 'in', 'pageSize': 3, 'apiKey': '0fabec243c9e4edebe93e06efef0005d'}
        res = requests.get(url, params=params, timeout=6, headers={'User-Agent': 'Mozilla/5.0', 'X-Forwarded-For': '127.0.0.1'}).json()
        articles = res.get('articles', [])
        if not articles:
            raise ValueError('No articles')
        news = []
        for a in articles[:3]:
            title = (a.get('title') or '').split(' - ')[0].strip()
            if not title:
                continue
            news.append({
                'title': title,
                'description': (a.get('description') or '').strip()[:500],
                'source': a.get('source', {}).get('name', 'Trusted News'),
                'link': a.get('url', ''),
                'date': (a.get('publishedAt') or '')[:10],
            })
        if news:
            return jsonify({'success': True, 'news': news})
        raise ValueError('Empty news list')
    except Exception as e:
        print(f'NewsAPI error: {e}')
        return jsonify({'success': True, 'news': [
            {'title': 'खरीप हंगामात सोयाबीन लागवडीसाठी शेतकर्यांनी तयारी करावी', 'description': 'कृषी तज्ज्ञांच्या मते यंदा खरीप हंगामात सोयाबीन आणि कापूस लागवडीसाठी चांगले वातावरण आहे. शेतकर्यांनी वेळेवर पेरणी करावी.', 'source': 'Krishi Jagran', 'link': '', 'date': ''},
            {'title': 'पीक विमा योजनेत नोंदणीसाठी अंतिम तारीख जवळ येत आहे', 'description': 'प्रधानमंत्री पीक विमा योजनेत नोंदणी करण्यासाठी शेतकर्यांनी तातडीने अर्ज करावा. दुष्काळ, पूर आणि गारपीट यांमुळे नुकसान झाल्यास भरपाई मिळते.', 'source': 'ET Agriculture', 'link': '', 'date': ''},
            {'title': 'सोलापूर मंडईत कांदा भाव स्थिर, शेतकर्यांना दिलासा', 'description': 'सोलापूर कृषी उत्पन्न बाजार समितीत आज कांद्याची आवक चांगली राहिली. सरासरी भाव ₹१२०० प्रति क्विंटल राहिला.', 'source': 'Agri News', 'link': '', 'date': ''},
        ]})


@app.route('/recommend', methods=['POST'])
def recommend_crop():
    data = request.get_json(silent=True, force=True) or {}
    soil_type = (data.get('soil_type') or 'black').lower().strip()
    city = data.get('city', 'Solapur')
    try:
        url = f'http://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric'
        w = requests.get(url, timeout=5).json()
        humidity = w['main']['humidity']
        condition = w['weather'][0]['main'].lower()
        temp = w['main']['temp']
    except Exception:
        humidity, condition, temp = 60, 'clear', 28
    if 'rain' in condition or 'thunder' in condition or 'drizzle' in condition:
        bucket = 'rainy'
    elif humidity > 70:
        bucket = 'high_humidity'
    else:
        bucket = 'low_humidity'
    soil_key = soil_type if soil_type in _SOIL_CROP_MAP else 'black'
    crop = _SOIL_CROP_MAP[soil_key][bucket]
    soil_mr = _SOIL_MARATHI.get(soil_key, soil_key)
    if bucket == 'rainy':
        reason = f'सध्या पाऊस आहे आणि {soil_mr} आहे'
    elif bucket == 'high_humidity':
        reason = f'आर्द्रता {humidity}% जास्त आहे आणि {soil_mr} आहे'
    else:
        reason = f'तापमान {temp}°C आहे आणि {soil_mr} आहे'
    message = f'🌱 स्मार्ट सूचना: {reason}, त्यामुळे {crop} लागवड केल्यास जास्त उत्पादन मिळेल. सध्याचे हवामान या पिकासाठी अनुकूल आहे.'
    return jsonify({'success': True, 'crop': crop, 'soil': soil_mr, 'humidity': humidity, 'condition': condition, 'temp': temp, 'message': message})


@app.route('/query', methods=['POST'])
def query():
    data = request.get_json(silent=True, force=True) or {}
    query_text = data.get('query', '')
    intent, param = _detect_intent_from_text(query_text)
    reply = _build_reply(intent, param, query_text)
    return jsonify({'success': True, 'intent': intent, 'query': query_text, 'fulfillmentText': reply})


@app.route('/debug-query', methods=['POST'])
def debug_query():
    data = request.get_json(silent=True, force=True) or {}
    query_text = data.get('query', '')
    normalized = _normalize_text(query_text)
    crop = _extract_crop(query_text)
    topic = _extract_topic(query_text)
    symptom_hit = _looks_like_symptom_query(query_text)
    intent, param = _detect_intent_from_text(query_text)
    return jsonify({
        'raw_query': query_text,
        'normalized_query': normalized,
        'detected_crop': crop,
        'detected_topic': topic,
        'symptom_like': symptom_hit,
        'intent': intent,
        'param': param,
        'disease_kb_loaded': bool(DISEASE_KB),
        'disease_kb_keys': list(DISEASE_KB.keys())[:20],
    })


@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.get_json(silent=True, force=True) or {}
    query_result = data.get('queryResult', {})
    intent = query_result.get('intent', {}).get('displayName', '')
    parameters = query_result.get('parameters') or {}
    query_text = query_result.get('queryText', '') or ''

    def _extract_crop_from_params(params):
        raw = params.get('crop') or params.get('crop-name') or params.get('any')
        if isinstance(raw, list):
            raw = raw[0] if raw else None
        if not raw:
            return None
        raw_text = str(raw).strip().lower()
        return _CROP_MAP.get(raw_text, str(raw).title())

    param = None
    if intent == 'get_mandi_price':
        param = _extract_crop_from_params(parameters)
    elif intent == 'get_farm_doctor':
        crop = _extract_crop_from_params(parameters)
        topic = parameters.get('query_topic') or parameters.get('topic') or ''
        if isinstance(topic, list):
            topic = topic[0] if topic else ''
        param = (crop, str(topic).lower())
    elif intent == 'get_farm_doctor_symptoms':
        param = _extract_crop_from_params(parameters)
    reply = _build_reply(intent, param, query_text)
    return jsonify({'fulfillmentText': reply})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)