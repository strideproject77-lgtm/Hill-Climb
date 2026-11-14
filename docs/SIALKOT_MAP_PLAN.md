# Sialkot 1:1 World Map — Data and Landmark Plan

Updated: 2026-11-14

## Accuracy policy
The long-term target is the real Sialkot municipal city area, not a fictional road grid with a Sialkot label. The **first playable map stage is main urban Sialkot only**; villages and distant outer settlements are explicitly deferred. Initial focus: Clock Tower / Saddar Bazaar, Cantonment-side streets, and the connected main-city corridor towards Mehrajke. Road geometry, intersections, rail corridors, building footprints, waterways, land use and named places must come from geospatial source data. Do not claim 1:1 coverage until imported geometry is compared with its source and inspected in-game.

## Initial playable boundary and street completeness
- Establish a documented urban coverage polygon around the agreed main-city scope before requesting/importing the final extract.
- Include the Clock Tower / Saddar Bazaar core, Cantonment side and connected city streets along the Mehrajke direction.
- Exclude villages and distant outer areas from this first playable stage; they may be considered as later world expansion.
- Inside the selected boundary, include main roads, neighbourhood streets, the smallest mapped residential galiyan, inner-market lanes, service roads, dead ends and connectors.
- Do not filter streets solely because they are narrow, low-class or unimportant to through traffic.
- Preserve road-node topology, intersections and tile-edge connectivity; report missing or uncertain coverage rather than silently dropping it.

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
1. Confirm and document the initial urban playable boundary; distinguish it from the wider municipal/district boundary.
2. Compare roads at city, neighbourhood and street zoom levels.
3. Check named radial roads and rail crossings.
4. Check landmark coordinates and building footprints.
5. Drive routes across multiple streamed tiles.
6. List unmapped/uncertain areas honestly; do not call the map complete while coverage is missing.

## Sources
- Sialkot Transport Sector Strategy and Action Plan (Urban Unit): https://urbanunit.gov.pk/download/publications/files/8/2021/sialkot%20transport%20sector%20action%20plan.pdf
- Government of Punjab, Sialkot — Important Places: https://sialkot.punjab.gov.pk/important_places
- Urban Unit, District Sialkot Report: https://urbanunit.gov.pk/Download/publications/Files/13/2021/Sialkot%20District%20Report%20-%20Water%20Supply%2C%20Sewerage%20%26%20Env%20Sector.pdf
