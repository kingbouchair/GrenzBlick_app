import os
import requests
from datetime import datetime, timezone

SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://ymddwehqifawycwlmtza.supabase.co').rstrip('/')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', '')

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

def get_swiss_prices():
    now_iso = datetime.now(timezone.utc).isoformat()
    return [
        {"id": "ch_socar_laufenburg", "brand": "SOCAR", "street": "Baslerstrasse 11", "place": "5080 Laufenburg (CH)", "is_open": True, "has_shop": True, "e5_chf": 1.74, "diesel_chf": 1.82, "updated_at": now_iso},
        {"id": "ch_oil_laufenburg", "brand": "OIL! tank & go", "street": "Baslerstrasse 17", "place": "5080 Laufenburg (CH)", "is_open": True, "has_shop": False, "e5_chf": 1.72, "diesel_chf": 1.80, "updated_at": now_iso},
        {"id": "ch_schraner_sulz", "brand": "Tankstelle Schraner", "street": "Hauptstrasse 32", "place": "5085 Sulz (CH)", "is_open": True, "has_shop": False, "e5_chf": 1.70, "diesel_chf": 1.78, "updated_at": now_iso},
        {"id": "ch_tamoil_kaisten", "brand": "Tamoil", "street": "Kaisterfeld 2", "place": "5082 Kaisten (CH)", "is_open": True, "has_shop": True, "e5_chf": 1.73, "diesel_chf": 1.81, "updated_at": now_iso},
        {"id": "ch_bp_sisseln", "brand": "BP", "street": "Sisslerstrasse 1", "place": "4334 Sisseln (CH)", "is_open": True, "has_shop": True, "e5_chf": 1.76, "diesel_chf": 1.84, "updated_at": now_iso},
        {"id": "ch_coop_laufenburg", "brand": "Coop Pronto", "street": "Laufenburgerstrasse 1", "place": "5080 Laufenburg (CH)", "is_open": True, "has_shop": True, "e5_chf": 1.74, "diesel_chf": 1.82, "updated_at": now_iso},
        {"id": "ch_avia_laufenburg", "brand": "AVIA", "street": "Laufenburgerstrasse 30", "place": "5080 Laufenburg (CH)", "is_open": True, "has_shop": True, "e5_chf": 1.75, "diesel_chf": 1.83, "updated_at": now_iso},
        {"id": "ch_agrola_kaisten", "brand": "Agrola", "street": "Dorfstrasse 15", "place": "5082 Kaisten (CH)", "is_open": True, "has_shop": False, "e5_chf": 1.72, "diesel_chf": 1.79, "updated_at": now_iso}
    ]

def fetch_and_update():
    print("Starte Preissynchronisation...")
    stations = get_swiss_prices()
    url = f"{SUPABASE_URL}/rest/v1/swiss_stations"

    for st in stations:
        res = requests.post(url, json=st, headers=headers)
        print(f"Update {st['brand']} ({st['id']}): Status {res.status_code}")
        if res.status_code not in [200, 201]:
            print(f"  --> FEHLER von Supabase: {res.text}")
            res.raise_for_status()

if __name__ == "__main__":
    fetch_and_update()