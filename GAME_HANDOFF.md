# Stride Open World — Development Handoff

Updated: 2026-11-14

## Project
- Repository: https://github.com/strideproject77-lgtm/Hill-Climb
- Active branch: `hill-climb-game`
- Engine: Godot 4.4.1
- Target: Android ARM64 APK, built by GitHub Actions
- Application ID: `com.strideproject.openworld`
- APK artifact: `stride-open-world-android-arm64`
- Main scene: `game/scenes/main.tscn`
- Production APK workflow: `.github/workflows/hill-climb-android.yml`

## Product direction
Replace the former 2D Hill Climb game with an original, realistic 3D open-world driving/action game. Use GTA V as a high-level quality and gameplay reference only. Do not copy proprietary GTA assets, characters, maps, branding, audio, or code.

## Development rules
- One manageable phase per implementation batch.
- Treat visual quality, gameplay, world design, UI/UX, audio, and optimization as equal priorities.
- Do not present primitive placeholders or static mockups as finished systems.
- Do not claim a feature works until it is implemented and verified.
- Keep Android ARM64 APK export automated in GitHub Actions.
- Do not require the user to build locally.
- Each meaningful phase updates this handoff.
- Run one consolidated validation pass at the end of the agreed implementation batch sequence, not repeatedly after every small edit.

## Phase roadmap
1. **3D World Foundation — Partial**
   - Convert startup scene to Node3D.
   - Add procedural terrain, curved road, terrain material, sky, sun, vegetation and distant landscape.
   - Remaining: visual inspection of the APK on device; improve terrain/road art using original licensed assets and shaders as needed.
2. **Player & Vehicle Foundation — Not started**
   - Third-person player controller, camera follow, original detailed vehicle model, enter/exit flow, mobile driving controls.
3. **Vehicle Physics & Driving — Not started**
   - Suspension, traction, steering, braking, collision response, damage and multiple vehicle profiles.
4. **Open-World Streaming & Districts — Not started**
   - Chunk streaming, city/residential/industrial/coastal/rural districts, roads, landmarks and selected interiors.
5. **Character, Animation & Interaction — Not started**
   - Character rig, locomotion, interaction system, vehicle transitions and animation state machine.
6. **Traffic, Pedestrians & Police AI — Not started**
   - Navigation, traffic rules, ambient routines, pursuit and safe despawn/streaming.
7. **Missions & Progression — Not started**
   - Mission framework, objectives, checkpoints, save/load, economy and activities.
8. **World Simulation — Not started**
   - Day/night, weather, water, audio zones, ambient audio and world events.
9. **Premium UI/UX — Not started**
   - Main menu, pause, map, minimap, mission HUD, settings, garage and touch layouts.
10. **Optimization & Release Readiness — Not started**
   - LOD, occlusion, memory budgets, asset compression, frame pacing, APK size and device profiling.

## Progress entry — 2026-11-14
### Phase 1 — 3D World Foundation — Partial
- Replaced the 2D startup scene with a 3D Node3D world entry point.
- Added layered-noise terrain mesh, a winding asphalt road and dashed center markings.
- Added procedural vegetation, distant ridge silhouettes, filmic sky and late-afternoon directional lighting.
- Switched the game identity and viewport to a landscape 3D open-world direction.
- Added a dedicated Android package identity and renamed the APK/artifact for the new game.
- APK export remains automatic on pushes to `hill-climb-game` and can be manually dispatched in GitHub Actions.
- Extra improvement: created an explicit roadmap/handoff and honest scope notes so later work does not confuse the world foundation with a complete playable game.
- Remaining: run the consolidated Godot import/startup and Android ARM64 APK workflow; visually inspect the generated APK on a physical Android device; proceed to Phase 2 player/vehicle foundation.
- Tests: deferred to the consolidated validation pass.
- APK: not built in this implementation batch.
