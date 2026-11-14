# INFINITE HORIZONS — Master Handover & Development Mission

Updated: 2026-11-14  
Project codename: Infinite Horizons  
Repository: https://github.com/strideproject77-lgtm/Hill-Climb  
Active development branch: `hill-climb-game`  
Engine: Godot 4.4.1  
Primary target: Android ARM64 APK  
Runtime compatibility target: Husk on supported iOS devices (must be verified on-device; never assume compatibility from packaging alone)

> This document is the source of truth for the game's identity, mission, quality bar, architecture direction, roadmap, current status and next development work. Read it before making changes. Keep it updated after every meaningful implementation batch.

---

## 1. Official identity

**INFINITE HORIZONS**

The title represents a complete world of possibilities, not a driving-only or racing-only game. Driving is one major activity among many.

Working tagline: **Your world. Your choices. Infinite possibilities.**

The name is selected as the project's working official title. Before public release, perform a proper game-title, store-listing and trademark availability check. Do not claim legal or worldwide name exclusivity until checked.

---

## 2. The mission

Build a highly immersive, realistic, large-scale 3D open-world game set in a faithfully recreated Sialkot, Pakistan.

The player should feel that they are living inside a connected city rather than selecting isolated driving tracks or entering a small collection of disconnected levels. The city must have recognizable geography, believable streets, varied architecture, local identity, active public spaces and systems that make the world feel alive.

The long-term ambition is a premium, console-inspired open-world experience on mobile. GTA V may be used only as a broad quality and freedom reference. **Do not copy its maps, missions, characters, brands, logos, models, textures, audio, code or other protected content.** Infinite Horizons must have its own world, story, characters, art direction and identity.

### Core player promise

- Explore a coherent, recognizable Sialkot rather than a generic city with a Sialkot label.
- Drive different types of believable vehicles across connected streets and districts.
- Leave vehicles, walk around, interact with people and places, and enter appropriate interiors.
- Discover missions, side activities, businesses, landmarks and emergent city events.
- Make meaningful choices and progress through an original story and open-world activities.
- Experience a city that changes through time, weather, traffic, pedestrians and world events.
- Enjoy polished controls, clear feedback, attractive menus and consistent performance on supported mobile hardware.

---

## 3. What the game is — and is not

### It is
- A third-person 3D open-world city/life/action adventure.
- A driving experience with multiple vehicle classes, handling styles, traffic and exploration.
- A mission-based game with an original story, side missions and optional activities.
- A living-world simulation with pedestrians, traffic, day/night, weather and ambient activity.
- A Sialkot-focused world with local landmarks, markets, roads and architecture.
- A mobile-first product with touch controls, scalable quality and performance-aware rendering.

### It is not
- A driving-only simulator, racing-only game or collection of tracks.
- A static map showcase with no meaningful gameplay.
- A fake demo where imported or selected content is replaced by a built-in test scene.
- A low-poly/blocky placeholder presented as final realistic art.
- A claim of full 1:1 city coverage before source coverage and in-game geometry have been validated.
- A claim of Husk compatibility before an actual supported-device launch and gameplay test.

---

## 4. Equal-priority quality pillars

Every development batch must consider all pillars. Do not spend the entire project only fixing backend bugs while leaving the visible game, UI and gameplay behind.

| Pillar | Required direction |
|---|---|
| World & visuals | Realistic materials, coherent scale, recognizable Sialkot, detailed landmarks, varied buildings, convincing lighting and atmosphere |
| Gameplay | Driving, walking, interaction, missions, exploration, activities and progression |
| UI/UX | Premium menus, readable HUD, intuitive touch controls, map, mission guidance, settings and accessibility |
| Simulation | Traffic, pedestrians, time, weather, audio, world events and believable reactions |
| Technical quality | Stable architecture, memory control, loading, save data, crash diagnostics and efficient rendering |
| Performance | Mobile frame pacing, scalable quality, streaming, LOD, culling and thermal/memory awareness |
| Compatibility | ARM64 packaging, Godot export correctness and real Husk/device validation |

### Batch rule

One phase equals one manageable implementation batch and should be delivered as a coherent set of changes. For each batch:
1. Implement the main phase scope.
2. Add at least one useful extra improvement when it fits without destabilizing the batch.
3. Include relevant UI/UX and visual polish alongside gameplay/technical work.
4. Fix related defects discovered during implementation.
5. Update this handover with completed work, remaining work, risks and honest progress.
6. Avoid repeatedly running tests during editing. Run one consolidated validation pass at the end of the batch unless a blocker makes a targeted check essential.
7. Never mark a phase Completed while any required scope or validation gate remains outstanding.

Do not claim that a feature is complete merely because a script, placeholder, mockup or workflow step exists.

---

## 5. World design — Sialkot

### Geographic accuracy
The long-term geographic target is the real Sialkot municipal city area. **The initial playable-world scope is narrower: main/urban Sialkot only, not the surrounding villages or distant outer areas.** The first coverage focus is the Clock Tower / Saddar Bazaar area, the Cantonment side, and the main-city corridor/connected streets in the direction of Mehrajke. Use source geometry and documented references for roads, intersections, buildings, railway corridors, waterways, land use and points of interest.

OpenStreetMap is the initial geospatial source. Preserve required attribution and comply with its ODbL obligations. Keep source IDs, tags, retrieval date, coverage bounds and layer counts so data can be audited and refreshed.

The current imported area is only a **bounded central-city pilot**. It is not a verified municipal boundary and must not be described as the complete city. For the first playable map, define and document an urban-Sialkot coverage boundary that includes the Clock Tower / Saddar Bazaar, Cantonment-side city streets and the connected main-city corridor towards Mehrajke, while excluding villages and distant outer settlements from the initial playable scope. This is a staged scope decision, not permission to omit small streets inside the chosen boundary.

### Important roads and corridors
Use actual source geometry and validate the named corridors, including:
- Wazirabad / Kashmir Road
- Jammu Road
- Zafarwal Road
- Pasrur Road
- Aimanabad Road
- Daska Road
- Shahab Pura Road
- Khadim Ali Road
- Khawaja Safdar Road
- Circular Road
- Church Road
- Defence Road
- Cantonment links and railway crossings

### Landmark and district targets
Initial high-detail landmark targets:
- Iqbal Manzil
- Sialkot Clock Tower and Saddar Bazaar
- Holy Trinity Cathedral Church
- Government Murray College
- Recognizable markets, public spaces and mapped commercial areas

Landmarks must be built from lawful public references. Use bespoke hero assets for recognizable locations and varied modular assets for ordinary buildings. Do not fabricate exact details when references are unavailable; mark uncertain assets for later verification.

### World streaming
The full city must not be loaded as one unbounded high-detail scene. Design for:
- Connected world tiles with stable road links at tile boundaries.
- Distance-based LOD and visibility culling.
- Simplified collision away from the player.
- Asynchronous tile/asset loading where supported.
- Prioritized loading around the player and active mission.
- Memory budgets and graceful fallback for lower-end devices.
- Persistent world state only where gameplay requires it.

---

## 6. Gameplay systems — complete vision

### Player
- Third-person player controller with responsive movement.
- Walk, run, jump where appropriate, camera control and contextual interaction.
- Enter and exit supported vehicles smoothly.
- Animation states, transitions and interaction prompts.
- Character identity and customization can be expanded after the core controller is stable.

### Vehicles and driving
- Multiple vehicle categories: everyday cars, sedans, SUVs, vans, bikes and suitable service vehicles.
- Distinct acceleration, braking, steering, suspension, traction and weight behavior.
- Camera options, speed feedback and mobile-first control layouts.
- Vehicle selection, garage, customization and upgrade progression.
- Damage presentation and repair flow, implemented with non-graphic visual effects.
- Traffic-aware driving and reliable vehicle enter/exit handoff.
- Avoid one generic vehicle setup being reused unchanged for every vehicle class.

### Missions and story
- Original story set in Sialkot with memorable characters and locally grounded locations.
- Main missions, side missions, optional challenges and free-roam activities.
- Reusable mission framework: prerequisites, objectives, markers, checkpoints, fail/retry, rewards and completion state.
- Mission scripting must be data-driven where practical, not hard-coded into one giant scene script.
- Clear mission briefings, objective tracking, waypoint guidance and post-mission feedback.
- No borrowed GTA missions, dialogue, characters or story material.

### City life and activities
- Pedestrians with believable routes and simple daily routines.
- Traffic with lanes, intersections, traffic lights/signals where mapped, yielding and basic reactions.
- Public places, shops, service locations and selected interiors.
- Interactions with doors, counters, mission contacts and usable world objects.
- Side activities and optional discovery content that make free roam rewarding.
- Business/economy mechanics can include purchases, upgrades, services and progression, introduced in balanced stages.

### Police and emergency simulation
- Rule-aware traffic/police simulation and escalating pursuit behavior as a gameplay system.
- Clear readable feedback and fair player response windows.
- Emergency/service vehicles and city response behaviors where feasible.
- Keep the system performant and avoid large numbers of expensive agents.

### World simulation
- Time-of-day cycle with consistent lighting transitions.
- Weather states and wet-surface/visibility changes where performance allows.
- Ambient city audio, traffic, footsteps, vehicle sounds and location-specific ambience.
- World events and mission-linked changes.
- Save/load for player progress, mission state, settings and relevant world state.

---

## 7. UI/UX and presentation direction

UI/UX is a first-class feature, not final-week decoration.

Required screens and components:
- Premium title screen and main menu using the **INFINITE HORIZONS** identity.
- Continue / New Game / Settings / Garage / Map / Activities / Exit flows as appropriate.
- In-game HUD with speed, vehicle state, mission objective, navigation and contextual prompts.
- Full map and minimap with player position, discovered locations, mission markers and route guidance.
- Pause menu, mission briefing, completion/failure feedback and save feedback.
- Garage and vehicle selection/customization UI.
- Settings for graphics quality, frame-rate target, audio, sensitivity, control layout and accessibility.
- Mobile touch controls that scale across aspect ratios and safe areas.
- Consistent typography, icon style, spacing, contrast, animation and sound feedback.

### Visual quality rules
- Avoid emoji as final UI icons.
- Avoid crude primitive shapes as final hero assets.
- Use coherent materials, lighting, shadows, reflections and environmental detail within mobile budgets.
- Use original or properly licensed assets only.
- Maintain visual consistency across menu, HUD, map, garage and gameplay.
- Provide scalable graphics settings rather than forcing maximum settings on every device.

---

## 8. Technical architecture direction

Keep systems modular and testable. Avoid a single monolithic script for the entire game.

Suggested high-level modules:
- **WorldData:** map source data, coordinates, tiles, POIs and metadata.
- **WorldStreamer:** tile loading/unloading, LOD, culling and memory budgets.
- **WorldRenderer:** terrain, roads, buildings, vegetation, landmarks and lighting.
- **VehicleSystem:** vehicle definitions, physics, input, camera, damage and garage.
- **PlayerSystem:** movement, animation, interaction and vehicle transitions.
- **TrafficSystem:** road graph, traffic agents and signals.
- **PedestrianSystem:** pedestrian navigation, routines and interactions.
- **MissionSystem:** mission definitions, objectives, checkpoints, rewards and state.
- **EconomySystem:** currency, purchases, upgrades and services.
- **WorldSimulation:** clock, weather, events and ambient state.
- **UIManager:** screens, HUD, map, navigation, settings and accessibility.
- **SaveSystem:** versioned persistent data and recovery.
- **AudioManager:** buses, ambience, vehicle and UI audio.
- **Diagnostics:** startup errors, performance snapshots, session logs and crash context.

Use resource/data-driven definitions for vehicles, missions, POIs and settings where practical. Keep coordinate conversion and source map data independent from rendering code.

---

## 9. Mobile performance and compatibility targets

Primary build target is Android ARM64. The project currently uses Godot 4.4.1 with the GL Compatibility renderer. Preserve this mobile-oriented baseline unless profiling demonstrates a better supported configuration.

Performance work must include:
- Tile streaming, LOD, culling and batching.
- Texture/audio compression and sensible asset budgets.
- Efficient collision and physics update ranges.
- Bounded NPC/traffic simulation around the player.
- Loading screens/progress feedback for expensive transitions.
- Memory-pressure handling and safe cleanup.
- Frame-time profiling, not only average FPS.
- Device-quality presets and adjustable visual effects.

**Husk is a compatibility target, not a verified result.** The Android package must use 64-bit ARM native libraries where required. Godot 4 is among the engine families documented by Husk, but this does not guarantee that this specific game launches or performs correctly. Verify actual installation, startup, rendering, touch input, audio, save/load, long-session memory and performance on a supported device before marking Husk compatibility as passed.

Do not build, sign or export an IPA. This project deliverable is an Android APK through the repository workflow unless the owner explicitly authorizes a different deliverable.

---

## 10. Current repository baseline (2026-11-14)

### Confirmed project configuration
- Repository: `strideproject77-lgtm/Hill-Climb`
- Active branch: `hill-climb-game`
- Engine: Godot 4.4.1
- Renderer: GL Compatibility
- Android target: ARM64 APK
- Application ID currently configured: `com.strideproject.openworld`
- Existing project configuration still contains the former working title in its app name; update branding consistently in future UI/config batches.

### Phase status
| Phase | Scope | Current status |
|---|---|---|
| 1 | 3D world foundation | Source implemented; workflow #47 passed; physical-device visual inspection pending |
| 2 | Vehicle and driving foundation | Source implemented; workflow #51 passed; physical-device handling inspection pending |
| 3 | Sialkot geospatial base map | Central-city pilot pipeline implemented; full boundary, coverage validation, streaming and device inspection remain |
| 4 | Landmarks and shopfronts | Not started |
| 5 | City streaming and performance | Not started |
| 6 | Player character and interaction | Not started |
| 7 | Traffic, pedestrians and police AI | Not started |
| 8 | Missions and progression | Not started |
| 9 | World simulation | Not started |
| 10 | Premium UI/UX | Not started |
| 11 | Optimization and compatibility validation | Not started |

### Existing implementation details
- 3D startup scene with terrain, curved road, materials, vegetation, distant ridges, sky and directional lighting.
- Four-wheel `VehicleBody3D` baseline with steering, traction, suspension, throttle, braking and chase camera.
- Procedural sedan silhouette with body, cabin, roof, grille, lights, bumpers, mirrors and wheel assemblies.
- Mobile touch driving HUD and speed display.
- Terrain and road collision.
- OSM fetch tool at `game/tools/fetch_sialkot_osm.py`.
- Runtime Sialkot map geometry script at `game/scripts/sialkot_map.gd`.
- Map data integration and pilot label in `game/scripts/open_world.gd`.
- Generated map JSON is ignored by Git and fetched during the Android workflow.

### Honest progress snapshot
The previously reported estimate was:
- Playable progress: **12%** (rough project-level estimate, not a measured completion metric).
- Husk-verified playable progress: **0%** (no confirmed on-device compatibility test recorded).

These are estimates, not test results. Recalculate only when implementation and validation evidence justify a change. Keep overall content completion, playable-slice completion and Husk verification as separate metrics.

### Immediate unfinished work
1. Inspect the latest branch and recent GitHub Actions runs before editing.
2. Complete Phase 3 data coverage validation and define the initial urban playable boundary (Clock Tower / Saddar Bazaar, Cantonment side and the connected corridor towards Mehrajke); villages and distant outer areas are deferred.
3. Add streamed map tiles, LOD and safe building collision.
4. Render mapped POIs and begin high-quality landmark/shopfront production.
5. Improve the visual identity and gameplay HUD in parallel with world work.
6. Plan the next coherent batch; do not attempt every remaining system in one oversized commit.

---

## 11. Development roadmap — advanced target

Phases are ordered by dependency, not by a rule that visuals must wait until the end. Each phase should include appropriate UI, visual and performance work.

### Phase 1 — 3D world foundation
**Status:** Source implemented; workflow #47 passed; device inspection pending.  
**Remaining:** Inspect on device, improve terrain/world scale and lighting after visual review.

### Phase 2 — vehicle and driving foundation
**Status:** Source implemented; workflow #51 passed; device inspection pending.  
**Remaining:** Validate wheel contact, steering, braking, camera, touch response and handling on a physical device. Expand to data-driven vehicle classes after the base is stable.

### Phase 3 — Sialkot geospatial base map
**Status:** Pilot pipeline implemented; phase incomplete.  
**Initial playable scope:** Main urban Sialkot only — Clock Tower / Saddar Bazaar, Cantonment side and connected main-city streets towards Mehrajke. Exclude villages and distant outer areas for this first stage. Include every mapped minor street, residential gali, market lane, dead end and connector inside the agreed urban boundary.  
**Remaining:** Define the urban playable boundary precisely, measure layer coverage, validate roads and crossings, add connected tile streaming, LOD, collision strategy and on-device inspection.

### Phase 4 — landmarks, districts and shopfronts
Build signature Sialkot landmarks, commercial streets, market blocks, varied local storefronts and selected interiors. Add location discovery UI and map POI presentation.

### Phase 5 — world streaming and mobile rendering
Implement tile lifecycle, LOD, culling, batching, memory budgets, loading feedback and profiling. Maintain seamless road connectivity across tiles.

### Phase 6 — player character and interaction
Implement third-person movement, camera, animations, interaction prompts, doors and reliable vehicle enter/exit transitions.

### Phase 7 — living city simulation
Implement traffic graph/navigation, pedestrian routines, signals, basic law/response systems and performance-aware agent limits. Add debug overlays for navigation and agent state.

### Phase 8 — mission, story and progression
Create original narrative framework, mission data, objective/checkpoint system, rewards, side activities, save/load and progression UI.

### Phase 9 — economy, garages and city activities
Add businesses/services, purchases, garage, vehicle selection and upgrades, optional activities and balanced progression.

### Phase 10 — world simulation and audio
Add day/night, weather, surface response, ambient audio, vehicle audio, location ambience and world events.

### Phase 11 — premium UI/UX and accessibility
Complete title/menu identity, map/minimap, HUD, mission screens, garage, settings, touch customization, safe-area handling, accessibility and transitions. UI polish continues in earlier phases too.

### Phase 12 — optimization, compatibility and release readiness
Run one consolidated validation pass per planned batch; profile representative Android hardware; verify APK structure, install, launch, input, audio, save/load, memory and long-session behavior. Perform Husk validation separately and record exact device/runtime results. Prepare store-ready presentation only after release criteria pass.

---

## 12. Definition of done

A phase can be marked **Completed** only when:
- All phase requirements are implemented, not merely planned.
- The feature is integrated into the actual gameplay path.
- UI/UX and visual presentation are usable and coherent.
- Related regressions are addressed.
- The consolidated validation relevant to the phase passes.
- Any required device-only checks are completed or clearly listed as an outstanding release gate.
- Handover status, commit reference and remaining work are updated.

Use these statuses consistently:
- **Planned** — no meaningful implementation yet.
- **In progress** — implementation underway.
- **Source implemented** — code exists, but integration/validation/device checks remain.
- **Validated** — relevant automated/consolidated checks passed.
- **Device verified** — tested on the named physical device/configuration.
- **Completed** — the full phase scope and all required gates are satisfied.

---

## 13. Instructions for the next developer / agent

At the start of every session:
1. Read this file first.
2. Inspect the active branch and latest commits.
3. Inspect the latest relevant workflow result; do not assume it passed.
4. Identify the earliest incomplete phase and its remaining tasks.
5. Continue from that exact point instead of restarting completed work.

During implementation:
- Work only on `hill-climb-game` unless the owner explicitly changes the branch instruction.
- Do not merge unvalidated changes into the stable/default branch.
- Preserve the user's project identity and the official title **INFINITE HORIZONS**.
- Give equal attention to visuals, gameplay, UI/UX, world design, performance and bug fixes.
- Add useful extras where they improve the same feature set without creating avoidable scope creep.
- Do not use copyrighted GTA assets or reproduce its protected content.
- Do not misrepresent pilot map coverage, playable percentage or Husk compatibility.
- Do not repeatedly run the full test workflow while editing; consolidate validation at the end of a batch.
- Update this document and `GAME_HANDOFF.md` after meaningful progress.
- Do not build, sign or export an IPA without explicit permission.

---

## 14. Source and attribution notes

- OpenStreetMap data: https://www.openstreetmap.org/copyright
- Government of Punjab — Sialkot important places: https://sialkot.punjab.gov.pk/important_places
- Urban Unit — Sialkot Transport Sector Strategy and Action Plan: https://urbanunit.gov.pk/download/publications/files/8/2021/sialkot%20transport%20sector%20action%20plan.pdf
- Godot Engine documentation: https://docs.godotengine.org/
- Husk project documentation: https://github.com/Leviidev/Husk

Keep source dates, licences and attribution with imported data and assets. Re-check external compatibility documentation when making release decisions.
