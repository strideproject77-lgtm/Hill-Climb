# Stride Open World — Development Handoff

Updated: 2026-11-14

## Project
- Repository: https://github.com/strideproject77-lgtm/Hill-Climb
- Active branch: `hill-climb-game`
- Engine: Godot 4.4.1
- Target: Android ARM64 APK via GitHub Actions
- Application ID: `com.strideproject.openworld`
- APK artifact: `stride-open-world-android-arm64`

## Product direction
Create an original, realistic 3D open-world driving/action game set in a faithful Sialkot city map. GTA V is a quality reference only; do not copy proprietary maps, assets, characters, logos, audio or code.

## Development rules
- One manageable phase per implementation batch.
- Visual quality, gameplay, world design, UI/UX, audio and optimization have equal priority.
- Do not present primitive placeholders or static mockups as finished systems.
- Do not claim a feature works until verified.
- APK is built by GitHub Actions; no local user build required.
- Update this file after meaningful progress.
- Prefer one consolidated validation pass per batch.

## Playable progress definition
Track the vertical playable slice separately from total planned content. Count only implemented and validated runtime features. Future plans and visual mockups do not count.

## Phase roadmap
1. **3D World Foundation — Source implemented; APK workflow #47 passed; device inspection pending**
2. **Vehicle & Driving Foundation — Source implemented; Android workflow #51 passed; device inspection pending**
   - Four-wheel VehicleBody, front steering/rear traction, suspension, throttle, brake, keyboard controls, generated sedan exterior, chase camera, mobile touch HUD, terrain and road collision.
3. **Sialkot Geospatial Base Map — Pilot pipeline implemented; full municipal coverage pending**
   - Municipal boundary, full road graph, building footprints, waterways, railway and POIs imported from OSM with attribution and source metadata.
4. **Sialkot Landmarks & Shopfronts — Planned**
   - Iqbal Manzil, Clock Tower/Saddar Bazaar, Holy Trinity Cathedral, Murray College, mapped markets and public businesses; varied ordinary shopfronts.
5. **City Streaming & Performance — Planned**
   - Tile streaming, LOD, culling, simplified collision and memory budgets.
6. **Player Character & Interaction — Planned**
   - Third-person character, animation, enter/exit vehicle and interactions.
7. **Traffic, Pedestrians & Police AI — Planned**
   - Traffic navigation, pedestrian routines, traffic rules and pursuit simulation.
8. **Missions & Progression — Planned**
   - Mission framework, objectives, checkpoints, save/load, economy and activities.
9. **World Simulation — Planned**
   - Day/night, weather, water, ambient/vehicle audio and world events.
10. **Premium UI/UX — Planned**
   - Main menu, pause, map, minimap, mission HUD, settings, garage and touch layouts.
11. **Optimization & Release Readiness — Planned**
   - LOD, occlusion, memory, compression, frame pacing, APK size and device profiling.

## Progress entry — 2026-11-14

### Phase 3 — Sialkot Geospatial Base Map — Pilot pipeline implemented; validation pending
- Added an Android-build data step that fetches a bounded central-Sialkot OpenStreetMap extract through public Overpass mirrors.
- Added coordinate conversion to local metres and preserved OSM IDs/tags, names, ODbL attribution, retrieval timestamp, coverage bounds and per-layer counts.
- Added batched runtime geometry for mapped roads, building footprints with basic height extrusion, railways and waterways.
- Added an in-game SIALKOT / OPENSTREETMAP PILOT label; the old procedural test landscape remains only as a fallback when map data is unavailable.
- Extra improvements: data refresh during APK builds, source metadata for later corrections, merged geometry to reduce scene-node overhead, and bounded feature counts for mobile memory.
- Limitation: this is a central-city pilot rectangle, not a verified municipal boundary or complete 1:1 Sialkot map. POIs are preserved in the data but bespoke storefronts are not implemented yet.
- Remaining: one consolidated Godot + APK validation; verify Overpass coverage and municipal boundary; add streaming/LOD and building collision; inspect on a real device. Phase 3 is not complete.

## Progress entry — 2026-11-14
### Phase 1 — 3D World Foundation
- Converted startup to a 3D Node3D scene.
- Added terrain, curved road, shader material, vegetation, distant ridges, sky and directional lighting.
- Added Android package identity and ARM64 artifact workflow.
- GitHub Actions run #47 passed on commit 67841104dc9d55b11bf87385eec3c2bb0c1a0e52.
- Physical device visual inspection remains pending.

### Phase 2 — Vehicle & Driving Foundation — Source implemented; Android workflow #51 passed; device inspection pending
- Added a four-wheel VehicleBody3D vehicle with front steering and rear-wheel traction.
- Added suspension tuning (with wheel spring/damping/grip values set from Godot's documented ranges), throttle, braking, steering response and keyboard driving.
- Built an original multi-section sedan silhouette with metallic paint, panoramic cabin glazing, roof, grille, lamps, bumpers, mirrors and alloy/rubber wheel assemblies.
- Added smoothed chase camera and mobile touch buttons for steering, brake and accelerator.
- Added speed HUD and static collision for terrain and road.
- Extra improvements: touch-first driving controls, camera smoothing and collision surfaces so the vehicle is not merely a visual prop.
- Consolidated Godot startup/script-parse and Android ARM64 export passed in workflow #51 (commit 6bc12c11f8e9d2f7dc3748c4dbab244f549ba7e1).
- Remaining: inspect wheel contact, steering, braking, touch controls and performance on a physical device; tune after actual results.
- Tests deferred to consolidated validation.

### Sialkot map — Research and data plan created; not imported yet
- Added docs/SIALKOT_MAP_PLAN.md with GIS accuracy policy, data source/attribution, major roads, landmarks and streaming requirements.
- Official references identify key radial roads and heritage landmarks.
- Remaining: acquire/import the municipal OSM geometry, verify city boundary and coverage, then build landmarks and shopfronts from public references.
- The current terrain test area is not Sialkot and must not be described as a 1:1 city map. Godot's built-in VehicleBody3D is a first drivable baseline; its documented limitations mean a custom suspension/tyre solver may be needed for higher-fidelity handling.
