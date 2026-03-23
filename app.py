import requests
import json
from flask import Flask, request, jsonify

app = Flask(__name__)
WEATHER_API_KEY = '482a3a616b59b6ad77409e8aed90da11'

@app.route('/')
def index():
    return "AgroVani Server is Live!"

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

def fetch_mandi_price(commodity="Jowar"):
    try:
        # If Dialogflow sends a list ["Jowar"], take the first item
        if isinstance(commodity, list):
            commodity = commodity[0]
            
        commodity = str(commodity).title() 
        
        with open('mandi_data.json', 'r') as f:
            data = json.load(f)
        
        prices = data["Solapur"].get(commodity)
        if prices:
            return f"Solapur mandit aaj {commodity} cha sarasari bhav {prices['avg']} rupaye prati quintal aahe."
        else:
            return f"Kshamasva, mala {commodity} baddal mahiti milali nahi."
    except Exception as e:
        print(f"Error: {e}")
        return "Market data load karanyat adthala yet aahe."

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.get_json(silent=True, force=True)
    intent = data.get('queryResult').get('intent').get('displayName')
    
    if intent == "Default Welcome Intent":
        reply = "Namaskar! AgroVani madhe tumche swagat aahe."
        
    elif intent == "get_weather":
        reply = fetch_weather("Solapur") 

    elif intent == "get_mandi_price":
        parameters = data.get('queryResult').get('parameters')
        selected_crop = parameters.get('crop')
        
        if selected_crop:
            reply = fetch_mandi_price(selected_crop)
        else:
            reply = "Konti pika baddal mahiti havi aahe? (Jwari, Gahu, ki Kanda?)"
        
    else:
        reply = "Kshamasva, mala samajle nahi. Krupaya punha sanga."

    return jsonify({"fulfillmentText": reply})

if __name__ == '__main__':
    app.run(port=5000, debug=True)