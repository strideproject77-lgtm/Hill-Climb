#!/usr/bin/env python3
"""Download a bounded central-Sialkot OSM extract for the Android build."""
import json, math, pathlib, time, urllib.request
from datetime import datetime, timezone

SOUTH, WEST, NORTH, EAST = 32.455, 74.490, 32.535, 74.590
ORIGIN_LAT, ORIGIN_LON = 32.495, 74.540
OUT = pathlib.Path(__file__).resolve().parents[1] / "data" / "sialkot_city.json"
QUERY = f"""[out:json][timeout:180];(
way["highway"]({SOUTH},{WEST},{NORTH},{EAST});
way["building"]({SOUTH},{WEST},{NORTH},{EAST});
way["railway"]({SOUTH},{WEST},{NORTH},{EAST});
way["waterway"]({SOUTH},{WEST},{NORTH},{EAST});
node["shop"]({SOUTH},{WEST},{NORTH},{EAST});
node["amenity"]({SOUTH},{WEST},{NORTH},{EAST});
node["tourism"]({SOUTH},{WEST},{NORTH},{EAST});
);out body geom;"""

def xy(lat, lon):
    return [round((lon-ORIGIN_LON)*111320*math.cos(math.radians(ORIGIN_LAT)),2),
            round(-(lat-ORIGIN_LAT)*110540,2)]

def main():
    payload = QUERY.encode()
    data = None
    errors = []
    for endpoint in ("https://overpass-api.de/api/interpreter",
                     "https://overpass.kumi.systems/api/interpreter",
                     "https://overpass.private.coffee/api/interpreter"):
        try:
            req = urllib.request.Request(endpoint, data=payload,
                headers={"Content-Type":"application/x-www-form-urlencoded",
                         "User-Agent":"StrideOpenWorld/0.1 OSM data import"})
            with urllib.request.urlopen(req, timeout=210) as response:
                data = json.loads(response.read().decode("utf-8"))
            if isinstance(data.get("elements"), list):
                break
            data = None
        except Exception as exc:
            errors.append(str(exc))
            time.sleep(2)
    if data is None:
        raise RuntimeError("All Overpass mirrors failed: " + "; ".join(errors))
    roads, buildings, pois, railways, waterways = [], [], [], [], []
    for item in data["elements"]:
        tags, typ = item.get("tags", {}), item.get("type")
        geometry = item.get("geometry", [])
        if typ == "way" and len(geometry) >= 2:
            points = [xy(p["lat"], p["lon"]) for p in geometry]
            rec = {"id":item["id"],"name":tags.get("name",""),"tags":tags,"points":points}
            if "highway" in tags: roads.append(rec)
            elif "building" in tags and len(points) >= 4:
                try: rec["height"] = max(3.0,min(float(tags.get("height",float(tags.get("building:levels",2))*3.1)),90.0))
                except (ValueError,TypeError): rec["height"] = 6.2
                buildings.append(rec)
            elif "railway" in tags: railways.append(rec)
            elif "waterway" in tags: waterways.append(rec)
        elif typ == "node":
            pois.append({"id":item["id"],"name":tags.get("name",""),"tags":tags,
                         "position":xy(item["lat"],item["lon"])})
    roads, buildings, pois = roads[:9000], buildings[:18000], pois[:5000]
    railways, waterways = railways[:1000], waterways[:1000]
    result = {"schema":1,"source":"© OpenStreetMap contributors",
        "source_url":"https://www.openstreetmap.org/copyright","license":"ODbL-1.0",
        "retrieved_utc":datetime.now(timezone.utc).isoformat(),
        "coverage":{"south":SOUTH,"west":WEST,"north":NORTH,"east":EAST,
                    "status":"central-city pilot bbox; municipal boundary not verified"},
        "origin_wgs84":{"lat":ORIGIN_LAT,"lon":ORIGIN_LON},
        "counts":{"roads":len(roads),"buildings":len(buildings),"pois":len(pois),
                  "railways":len(railways),"waterways":len(waterways)},
        "roads":roads,"buildings":buildings,"pois":pois,"railways":railways,"waterways":waterways}
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(json.dumps(result,separators=(",",":"),ensure_ascii=False),encoding="utf-8")
    print("OSM pilot counts:",result["counts"],"bytes:",OUT.stat().st_size)

if __name__ == "__main__": main()
