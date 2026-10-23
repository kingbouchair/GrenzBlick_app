import os
import re
import json
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone

SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://ymddwehqifawycwlmtza.supabase.co').rstrip('/')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', '')

headers_supabase = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

headers_web = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "de-DE,de;q=0.9"
}

# Zu überwachende Tankstellen im Pilotgebiet Hochrhein
TARGET_STATIONS = [
    {"id": "ch_oil_laufenburg", "brand": "OIL! tank & go", "keywords": ["oil", "laufenburg"], "plz": "5080", "street": "Baslerstrasse 17", "place": "5080 Laufenburg (CH)"},
    {"id": "ch_agrola_kaisten", "brand": "Agrola", "keywords": ["agrola", "kaisten"], "plz": "5082", "street": "Dorfstrasse 15", "place": "5082 Kaisten (CH)"},
    {"id": "ch_socar_laufenburg", "brand": "SOCAR", "keywords": ["socar", "laufenburg"], "plz": "5080", "street": "Baslerstrasse 11", "place": "5080 Laufenburg (CH)"},
    {"id": "ch_coop_laufenburg", "brand": "Coop Pronto", "keywords": ["coop", "laufenburg"], "plz": "5080", "street": "Laufenburgerstrasse 1", "place": "5080 Laufenburg (CH)"},
    {"id": "ch_schraner_sulz", "brand": "Tankstelle Schraner", "keywords": ["schraner", "sulz"], "plz": "5085", "street": "Hauptstrasse 32", "place": "5085 Sulz (CH)"},
    {"id": "ch_bp_sisseln", "brand": "BP", "keywords": ["bp", "sisseln"], "plz": "4334", "street": "Sisslerstrasse 1", "place": "4334 Sisseln (CH)"},
    {"id": "ch_tamoil_kaisten", "brand": "Tamoil", "keywords": ["tamoil", "kaisten"], "plz": "5082", "street": "Kaisterfeld 2", "place": "5082 Kaisten (CH)"},
    {"id": "ch_avia_laufenburg", "brand": "AVIA", "keywords": ["avia", "laufenburg"], "plz": "5080", "street": "Laufenburgerstrasse 30", "place": "5080 Laufenburg (CH)"}
]

def get_existing_supabase_data():
    """Lädt den aktuellen Datenbestand aus Supabase als Fallback-Sicherung."""
    try:
        url = f"{SUPABASE_URL}/rest/v1/swiss_stations?select=*"
        res = requests.get(url, headers=headers_supabase, timeout=10)
        if res.status_code == 200:
            return {item['id']: item for item in res.json()}
    except Exception as e:
        print(f"Hinweis: Konnte bestehende Supabase-Daten nicht abrufen: {e}")
    return {}

def scrape_tcs_prices(plz):
    """Scrapt tagesaktuelle Live-Preise für eine PLZ direkt von benzin.tcs.ch."""
    results = {}
    try:
        url = f"https://benzin.tcs.ch/de/suche?location={plz}"
        res = requests.get(url, headers=headers_web, timeout=12)
        if res.status_code != 200:
            return results

        html = res.text

        # 1. Versuch: Next.js JSON-Schnittstelle parsen
        next_data = re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', html, re.DOTALL)
        if next_data:
            try:
                data = json.loads(next_data.group(1))
                page_props = data.get('props', {}).get('pageProps', {})
                stations = page_props.get('stations', []) or page_props.get('initialStations', [])
                
                for st in stations:
                    name = str(st.get('name', '') or st.get('brand', '')).lower()
                    prices = st.get('prices', {}) or st.get('fuelPrices', {})
                    e5 = prices.get('bleifrei95') or prices.get('e5') or prices.get('95')
                    diesel = prices.get('diesel')
                    
                    if e5 or diesel:
                        results[name] = {
                            "e5": float(e5) if e5 else None,
                            "diesel": float(diesel) if diesel else None
                        }
            except Exception as e:
                print(f"JSON-Parse Hinweis PLZ {plz}: {e}")

        # 2. Versuch: HTML-Kartenstruktur auslesen
        if not results:
            soup = BeautifulSoup(html, 'html.parser')
            for card in soup.find_all(['div', 'article', 'section']):
                text = card.get_text().lower()
                e5_m = re.search(r'(?:bleifrei|95).*?(\d\.\d{2})', text)
                diesel_m = re.search(r'diesel.*?(\d\.\d{2})', text)
                
                if e5_m or diesel_m:
                    for st in TARGET_STATIONS:
                        if all(kw in text for kw in st['keywords']):
                            results[st['brand'].lower()] = {
                                "e5": float(e5_m.group(1)) if e5_m else None,
                                "diesel": float(diesel_m.group(1)) if diesel_m else None
                            }
    except Exception as e:
        print(f"TCS Scraper Fehler bei PLZ {plz}: {e}")

    return results

def sync_live():
    now_iso = datetime.now(timezone.utc).isoformat()
    existing_db = get_existing_supabase_data()
    
    # 1. Scrape alle benötigten PLZ-Gebiete bei TCS
    plz_list = list(set(st["plz"] for st in TARGET_STATIONS))
    scraped_data = {}
    for plz in plz_list:
        print(f"Hole Live-Preise von TCS für PLZ {plz}...")
        scraped_data.update(scrape_tcs_prices(plz))

    url = f"{SUPABASE_URL}/rest/v1/swiss_stations"

    # 2. Zuordnung und Sync nach Supabase
    for st in TARGET_STATIONS:
        st_id = st["id"]
        brand_key = st["brand"].lower()

        # Zuordnung aus TCS-Scraper
        scraped = None
        for key, val in scraped_data.items():
            if brand_key in key or all(kw in key for kw in st['keywords']):
                scraped = val
                break

        # Fallback auf bestehende Datenbankwerte, falls TCS für diese Tankstelle stumm bleibt
        prev = existing_db.get(st_id, {})
        e5_val = scraped.get('e5') if (scraped and scraped.get('e5')) else prev.get('e5_chf', 2.12)
        diesel_val = scraped.get('diesel') if (scraped and scraped.get('diesel')) else prev.get('diesel_chf', 2.40)

        payload = {
            "id": st_id,
            "brand": st["brand"],
            "street": st["street"],
            "place": st["place"],
            "is_open": True,
            "has_shop": True if st["brand"] in ["Coop Pronto", "SOCAR", "BP", "AVIA"] else False,
            "e5_chf": round(float(e5_val), 2),
            "diesel_chf": round(float(diesel_val), 2),
            "updated_at": now_iso
        }

        res = requests.post(url, json=payload, headers=headers_supabase)
        if res.status_code in [200, 201]:
            print(f"✓ {st['brand']} ({st['place']}): Bleifrei 95 = {payload['e5_chf']} CHF | Diesel = {payload['diesel_chf']} CHF")
        else:
            print(f"❌ Fehler bei {st['brand']}: Status {res.status_code} - {res.text}")
            res.raise_for_status()

if __name__ == "__main__":
    sync_live()