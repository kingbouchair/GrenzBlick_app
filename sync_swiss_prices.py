import os
import requests
from bs4 import BeautifulSoup

SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://ymddwehqifawycwlmtza.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'DEIN_SUPABASE_KEY')

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

def fetch_and_update():
    print("Starte automatischen Live-Sync für Schweizer Tankstellen...")
    
    # 1. Live-Daten von einer Schweizer Preisquelle abrufen (Beispiel-Live-Abfrage)
    # Hier liest das Skript automatisiert die aktuellen TCS / Benzinpreis-Daten aus
    try:
        # Beispielhafte Abfrage der Live-Daten
        # In der Praxis holt requests.get() die Daten direkt von der Schweizer Preis-API/Webseite
        response = requests.get("https://ich-tanke.ch/api/stations/laufenburg", timeout=10)
        live_data = response.json()
    except Exception as e:
        print(f"Fehler beim Live-Abruf der Preise: {e}")
        return

    # 2. Automatisch extrahierte Daten verarbeiten und an Supabase senden
    for station in live_data:
        station_payload = {
            "id": station.get("id"),
            "brand": station.get("brand"),
            "street": station.get("street"),
            "place": station.get("place"),
            "is_open": True,
            "has_shop": station.get("has_shop", False),
            "e5_chf": float(station.get("e5_chf", 0.0)),
            "diesel_chf": float(station.get("diesel_chf", 0.0))
        }
        
        res = requests.post(f"{SUPABASE_URL}/rest/v1/swiss_stations", json=station_payload, headers=headers)
        print(f"Station {station.get('brand')} aktualisiert: Status {res.status_code}")

if __name__ == "__main__":
    fetch_and_update()