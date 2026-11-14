# Sialkot 1:1 World Map — Data and Landmark Plan

Updated: 2026-11-14

## Accuracy policy
The long-term inspiration is real Sialkot, but the first playable map follows a **GTA-style adaptation rule**: recognizable local anchors and city character, not strict 1:1 geography. Initial focus: Clock Tower / Saddar Bazaar, Cantonment side and a connected corridor towards Mehrajke. Compress distances, simplify blocks and adjust street connections where gameplay benefits. Villages and distant outer areas are excluded for now.

## Initial playable layout rules
- Build a compact Sialkot-inspired city layout anchored by Clock Tower / Saddar Bazaar, Cantonment side and the Mehrajke-direction corridor.
- Use real maps/references as inspiration for the street hierarchy, landmarks and local character, but allow deliberate gameplay-driven compression, simplification and repositioning.
- Do not label the result as a 1:1 map or exact GIS recreation.
- Keep enough secondary streets and lanes to make navigation feel like a believable city; prioritize playability and readable route choices over exhaustive street-by-street reproduction.
- Exclude villages and distant outer areas from the initial playable world; consider expansion later.
- Maintain internal road connectivity and clear navigation loops even when the layout is adapted.

## Primary map data
- OpenStreetMap is the preferred initial source for routable road geometry, building footprints and points of interest.
- Preserve OpenStreetMap attribution and comply with its ODbL database licence.
- Import the municipal boundary and available roads, buildings, waterways, railways and POIs.
- Preserve source IDs/tags so individual roads and buildings can be corrected independently.
- Use tagged widths where available; otherwise use clearly marked road-class estimates.
- Record source date and allow data refreshes.

## City structure and major corridors
The Sialkot Transport Sector Strategy and Action Plan identifies these radial corridors:
- Wazirabad / Kashmir Road
- Jammu Road
- Zafarwal Road
- Pasrur Road
- Aimanabad Road
- Daska Road
- Shahab Pura Road

Its primary internal/connecting roads include:
- Khadim Ali Road
- Khawaja Safdar Road
- Circular Road
- Church Road
- Defence Road
- Cantonment links and railway crossings

These names guide validation; they do not replace the actual source geometry.

## Initial high-detail landmark set
The Government of Punjab's Sialkot important-places page identifies:
- Iqbal Manzil
- Sialkot Clock Tower / Saddar Bazaar
- Holy Trinity Cathedral Church
- Government Murray College

Other mapped POIs will be included from the source data. Hero buildings should be authored from lawful public references; ordinary buildings should retain mapped footprints and use locally appropriate facade variations.

## Shops and ordinary buildings
- Use public business names and coordinates when present in the map data.
- Give major mapped markets and identifiable public shops bespoke storefront treatment where reliable references exist.
- Use modular but varied storefronts for ordinary unnamed shops, preserving their actual footprints and street positions.
- Never invent a precise logo or facade when no trustworthy reference exists; flag it for later verification.

## Coordinate system and streaming
- Keep source geometry in WGS84 at import.
- Convert to local East/North metres around a documented city-centre origin.
- Split the city into streamed tiles while preserving road-node connectivity across tile edges.
- Keep map data independent of rendering scenes so it can be refreshed without changing driving code.

## Validation gates
1. Define and document the compact playable layout and its real-world anchor references; clearly distinguish it from a 1:1 municipal map.
2. Compare roads at city, neighbourhood and street zoom levels.
3. Check named radial roads and rail crossings.
4. Check landmark coordinates and building footprints.
5. Drive routes across multiple streamed tiles.
6. List unmapped/uncertain areas honestly; do not call the map complete while coverage is missing.

## Sources
- Sialkot Transport Sector Strategy and Action Plan (Urban Unit): https://urbanunit.gov.pk/download/publications/files/8/2021/sialkot%20transport%20sector%20action%20plan.pdf
- Government of Punjab, Sialkot — Important Places: https://sialkot.punjab.gov.pk/important_places
- Urban Unit, District Sialkot Report: https://urbanunit.gov.pk/Download/publications/Files/13/2021/Sialkot%20District%20Report%20-%20Water%20Supply%2C%20Sewerage%20%26%20Env%20Sector.pdf
