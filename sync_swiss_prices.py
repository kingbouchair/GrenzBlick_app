import os
import requests
from datetime import datetime, timezone
from bs4 import BeautifulSoup

SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://ymddwehqifawycwlmtza.supabase.co').rstrip('/')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', '')

headers_supabase = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

# Browser-Header für TCS-Abfrage
headers_web = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept-Language": "de-DE,de;q=0.9"
}

# Ziel-Tankstellen im Pilotgebiet Hochrhein (Laufenburg & Umgebung)
STATIONS_CONFIG = [
    {"id": "ch_socar_laufenburg", "brand": "SOCAR", "street": "Baslerstrasse 11", "place": "5080 Laufenburg (CH)", "plz": "5080"},
    {"id": "ch_oil_laufenburg", "brand": "OIL! tank & go", "street": "Baslerstrasse 17", "place": "5080 Laufenburg (CH)", "plz": "5080"},
    {"id": "ch_schraner_sulz", "brand": "Tankstelle Schraner", "street": "Hauptstrasse 32", "place": "5085 Sulz (CH)", "plz": "5085"},
    {"id": "ch_tamoil_kaisten", "brand": "Tamoil", "street": "Kaisterfeld 2", "place": "5082 Kaisten (CH)", "plz": "5082"},
    {"id": "ch_bp_sisseln", "brand": "BP", "street": "Sisslerstrasse 1", "place": "4334 Sisseln (CH)", "plz": "4334"},
    {"id": "ch_coop_laufenburg", "brand": "Coop Pronto", "street": "Laufenburgerstrasse 1", "place": "5080 Laufenburg (CH)", "plz": "5080"},
    {"id": "ch_avia_laufenburg", "brand": "AVIA", "street": "Laufenburgerstrasse 30", "place": "5080 Laufenburg (CH)", "plz": "5080"},
    {"id": "ch_agrola_kaisten", "brand": "Agrola", "street": "Dorfstrasse 15", "place": "5082 Kaisten (CH)", "plz": "5082"}
]

def fetch_live_tcs_price(plz, brand):
    """Holt den tagesaktuellen Preis vom TCS-Radar für eine PLZ & Marke."""
    try:
        url = f"https://benzin.tcs.ch/de/suche?location={plz}"
        response = requests.get(url, headers=headers_web, timeout=10)
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            # Extrahiere Preisangaben aus der TCS-Ergebnisseite
            items = soup.find_all('div', class_='station-card')
            for item in items:
                text = item.get_text().lower()
                if brand.lower() in text:
                    # Suche nach Zahlenmuster X.XX CHF
                    import re
                    prices = re.findall(r'(\d\.\d{2,3})', text)
                    if prices:
                        return float(prices[0])
    except Exception as e:
        print(f"Hinweis: Live-Abruf TCS für {brand} ({plz}) fehlgeschlagen: {e}")
    
    return None

def build_station_payload():
    now_iso = datetime.now(timezone.utc).isoformat()
    updated_stations = []

    # Standartsicht-Preise als Basiswerte
    base_prices = {
        "SOCAR": (1.74, 1.82),
        "OIL! tank & go": (1.72, 1.80),
        "Tankstelle Schraner": (1.70, 1.78),
        "Tamoil": (1.73, 1.81),
        "BP": (1.76, 1.84),
        "Coop Pronto": (1.74, 1.82),
        "AVIA": (1.75, 1.83),
        "Agrola": (1.72, 1.79),
    }

    print("Starte Live-Abruf der Schweizer Treibstoffpreise...")

    for config in STATIONS_CONFIG:
        brand = config["brand"]
        default_e5, default_diesel = base_prices.get(brand, (1.74, 1.82))

        # Versuche Live-Preis vom TCS zu laden
        live_price = fetch_live_tcs_price(config["plz"], brand)
        e5_price = live_price if live_price else default_e5
        diesel_price = round(e5_price + 0.08, 2)  # Schweizer Diesel-Aufschlag Richtwert

        station_data = {
            "id": config["id"],
            "brand": brand,
            "street": config["street"],
            "place": config["place"],
            "is_open": True,
            "has_shop": True if brand in ["Coop Pronto", "SOCAR", "BP", "AVIA"] else False,
            "e5_chf": e5_price,
            "diesel_chf": diesel_price,
            "updated_at": now_iso
        }
        updated_stations.append(station_data)

    return updated_stations

def sync_to_supabase():
    stations = build_station_payload()
    url = f"{SUPABASE_URL}/rest/v1/swiss_stations"

    print(f"Sende {len(stations)} Tankstellen-Datensätze an Supabase...")
    for st in stations:
        res = requests.post(url, json=st, headers=headers_supabase)
        if res.status_code in [200, 201]:
            print(f"✓ {st['brand']} ({st['place']}) aktualisiert: E5={st['e5_chf']} CHF | Diesel={st['diesel_chf']} CHF")
        else:
            print(f"❌ Fehler bei {st['brand']}: Status {res.status_code} - {res.text}")
            res.raise_for_status()

if __name__ == "__main__":
    sync_to_supabase()