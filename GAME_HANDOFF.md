# INFINITE HORIZONS — Development Handoff

Updated: 2026-11-15

## Project
- Official game title: **INFINITE HORIZONS**
- Master handover: `docs/INFINITE_HORIZONS_HANDOFF.md` (mission, complete vision, quality standards, architecture and roadmap)
- Repository: https://github.com/strideproject77-lgtm/Hill-Climb
- Active branch: `hill-climb-game`
- Engine: Godot 4.4.1
- Targets: Android ARM64 APK (Ubuntu GitHub Actions) + iOS IPA (manual, gated GitHub-hosted macOS Actions workflow)
- Application ID: `com.strideproject.openworld`
- APK artifact: `stride-open-world-android-arm64`

## Cross-platform foundation (2026-11-15)\n- Shared Godot source for Android and iOS; platform helper: `game/scripts/platform_profile.gd`.\n- Android workflow remains `.github/workflows/hill-climb-android.yml`.\n- iOS workflow: `.github/workflows/infinite-horizons-ios.yml`; manual dispatch only, authorization defaults to false.\n- iOS signing requires Actions secrets documented in `game/CROSS_PLATFORM_BUILDS.md`. No IPA was built or exported in this implementation batch.\n- Current status: source and workflow prepared; macOS export/signing validation remains outstanding.\n\n## Product direction
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
3. **Sialkot Geospatial Base Map — Clock Tower / Saddar Bazaar test district source implemented; validation pending**
   - First playable scope: a compact GTA-style Sialkot-inspired layout anchored by Clock Tower / Saddar Bazaar, Cantonment side and the Mehrajke-direction corridor. Distances may be compressed and streets simplified/repositioned for gameplay; villages and distant outer areas deferred.
4. **Sialkot Landmarks & Shopfronts — Planned**
   - Iqbal Manzil, Clock Tower/Saddar Bazaar, Holy Trinity Cathedral, Murray College, mapped markets and public businesses; varied ordinary shopfronts.
5. **City Streaming & Performance — Planned**
   - Tile streaming, LOD, culling, simplified collision and memory budgets.
6. **Player Character & Interaction — Third-person player, camera, touch movement and vehicle switching source implemented; validation pending**
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

### Phase 3 — Compact Sialkot-inspired city blockout — Source added; validation pending
- Added `game/scripts/sialkot_city.gd` with a central Clock Tower/Saddar-style plaza and tower silhouette, narrow bazaar street grid, Cantonment-style grid and gate, Mehrajke-direction arterial, ring connectors, building blocks, street lights, trees and wayfinding labels.
- Replaced the mountainous test landscape startup in `game/scripts/open_world.gd` with the new compact urban layout and moved the player vehicle spawn onto the city road network.
- Updated the HUD location text to identify the Sialkot city slice.
- Extra improvements: recognizable district wayfinding, different street hierarchy between bazaar and Cantonment, and a ring connector to make free-roam navigation more interesting.
- Design rule: GTA-style adaptation, not 1:1 recreation. Distances and street layouts may be compressed/simplified; Clock Tower/Saddar, Cantonment and the Mehrajke-direction corridor are the first anchors. Villages and distant outer areas are deferred.
- Remaining: one consolidated Godot + Android APK validation; inspect visual layout; add building collision and improve roads/buildings, map UI, shopfronts, streaming/LOD and performance. Phase 3 remains incomplete.

## Progress entry — 2026-11-14

### Phase 3 — Sialkot Geospatial Base Map — Pilot pipeline implemented; validation pending
- Added an Android-build data step that fetches a bounded central-Sialkot OpenStreetMap extract through public Overpass mirrors.
- Added coordinate conversion to local metres and preserved OSM IDs/tags, names, ODbL attribution, retrieval timestamp, coverage bounds and per-layer counts.
- Added batched runtime geometry for mapped roads, building footprints with basic height extrusion, railways and waterways.
- Added an in-game SIALKOT / OPENSTREETMAP PILOT label; the old procedural test landscape remains only as a fallback when map data is unavailable.
- Extra improvements: data refresh during APK builds, source metadata for later corrections, merged geometry to reduce scene-node overhead, and bounded feature counts for mobile memory.
- Limitation: this is a central-city pilot rectangle, not a verified urban playable boundary or complete 1:1 Sialkot map. POIs are preserved in the data but bespoke storefronts are not implemented yet.
- New scope decision: the first playable map uses GTA-style adaptation, not 1:1 GIS recreation. It is a compact Sialkot-inspired layout anchored by Clock Tower / Saddar Bazaar, Cantonment side and the Mehrajke corridor. Distances/blocks/streets may be simplified or rearranged for gameplay; villages and distant outer areas are deferred.
- Remaining: define the compact gameplay layout and its anchor references; implement the adapted street network; one consolidated Godot + APK validation; add streaming/LOD and building collision; inspect on a real device. Phase 3 is not complete.

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


## Progress entry — 2026-11-15
### Clock Tower playable testing slice — Source implemented; validation pending
- Narrowed the temporary playable map to an approximately 860 m square Clock Tower / Saddar Bazaar area.
- Added a stepped stone Clock Tower landmark with four clock dials, traffic island, cross streets, smaller bazaar lanes, shopfront facades, awnings, signs, upper windows, streetlights and static building/tower collision.
- Added a procedural human player character with third-person movement, walk/run speeds, basic limb animation and a smoothed over-the-shoulder camera.
- Integrated the existing sedan with a separate driving camera and on-foot / vehicle mode switch. Added proximity-based enter/exit and mobile touch controls for walking, sprinting, driving, steering and braking.
- Improved the field-test HUD with current mode and district identity.
- Extra improvements: collision is disabled for the hidden player while inside the car; player and vehicle spawn near each other for immediate testing; the map scope is kept deliberately small to focus on landmark and character quality.
- Limitations: character is procedural and not yet a fully rigged production model; tower geometry/dial orientation and local shopfront references need visual review; no pedestrians, traffic, interiors or minimap yet.
- Remaining: one consolidated Godot + Android ARM64 APK validation and real-device inspection of visual fidelity, camera, movement, vehicle entry/exit, wheel contact and touch layout. Phase 3 and Phase 6 remain incomplete.


## Progress entry — 2026-11-15
### Visual + driving foundation correction batch — Source updated; validation pending
- Corrected handheld and Android export orientation to landscape for the 1280×720 game viewport.
- Increased sedan engine/brake response and improved suspension damping, stiffness and tyre grip.
- Corrected chase-camera placement to follow from behind the vehicle.
- Reworked mobile driving controls with steering on the left, larger accelerator/brake targets on the right, and simultaneous multi-touch input recomputation.
- Added original sedan exterior details (side glazing, door seams/handles, skirts, hood creases and dashboard) and player face/clothing details (eyes, pockets, cuffs and shoe soles).
- Extra improvements: clearer control grouping, more responsive handling and more defined character/vehicle silhouettes.
- Remaining: one consolidated Godot parse/export validation, real-device visual and driving inspection, rigged character animation and production-quality original PBR assets. This is not yet GTA V-level fidelity. Phases 2 and 6 remain incomplete pending validation.


## Progress entry — 2026-11-15
### Phase 6 — Player character visual-detail pass — Source committed; validation pending
- Expanded the existing procedural player from a basic capsule silhouette with a defined face: nose bridge/tip, mouth, eyebrows, inner ears, hairline and rear hair silhouette.
- Added tailored jacket lapels, shoulder shaping, pocket flaps/buttons, belt and buckle, trouser fly/knee panels, shoe toe/laces, and individual finger/thumb geometry.
- Added subtle movement sway and reduced the previous exaggerated vertical bob; added a small idle breathing scale variation.
- Extra improvements: better facial readability at third-person camera distance and more coherent clothing silhouette without external asset dependencies.
- Remaining: replace procedural primitive construction with a properly authored, rigged high-detail human mesh; add skeletal walk/run/idle animations, foot planting, facial animation and device-level visual/performance validation. Current work is a detail improvement, not a photorealistic/GTA V-quality character. Phase 6 is not complete.


## Progress entry — 2026-11-15
### Phase 6 — Articulated character movement pass — Source committed; validation pending
- Reworked the procedural character's limb hierarchy so each leg has a separate knee pivot and each arm has a separate elbow pivot; lower limbs now rotate independently rather than moving as one rigid piece.
- Added alternating knee flexion, opposing arm swing, slight elbow bend, shoulder counter-sway and subtle torso yaw during locomotion.
- Improved stride rhythm and reduced the old stiff, straight-leg walking appearance. Existing face, hair, clothing, hand and shoe detail remains in place.
- Extra improvements: distinct left/right limb animation state, better foot/hand articulation and a more natural idle-to-walk transition using the existing movement blend.
- Remaining: replace procedural primitives with a high-quality authored human mesh and a true Skeleton3D/skinned rig; add polished walk/run/idle animation clips, foot planting, turning, facial animation and device performance validation. This procedural pass is not photorealistic and Phase 6 remains incomplete.


## Progress entry — 2026-11-15
### Phase 6 — Foot articulation and walk/run gait pass — Source committed; validation pending
- Added independent ankle pivots and parented the primary foot meshes to them, enabling foot pitch and vertical lift during each stride.
- Added alternating foot-lift timing, ankle counter-rotation and speed/sprint-aware walk/run cadence and stride amplitudes.
- Added restrained turn lean from horizontal movement input and separate walk/run body bob tuning.
- Extra improvements: idle motion is kept subtle, gait responds to actual horizontal speed, and the changes remain asset-free and mobile-conscious.
- Remaining: precise foot planting/contact, high-quality authored human mesh, true Skeleton3D/skinned rig, polished walk/run/idle clips, facial animation and device-level performance/visual validation. This is still a procedural character, not photorealistic. Phase 6 remains incomplete.


## Progress entry — 2026-11-15
### Phase 6 — Ground-aware foot contact and gait polish — Source committed; validation pending
- Added a smoothed grounded animation weight driven by the character's actual floor-contact state; airborne movement fades out the grounded gait rather than continuing a full walk cycle.
- Refined alternating swing-foot lift with a separate stance phase, softer lift curves and toe-off ankle roll.
- Walk/run blend now depends on sprint input plus actual horizontal speed, and cadence scales with movement speed.
- Extra improvements: reduced accidental run animation while nearly stationary, made airborne limb motion less exaggerated and kept foot contact motion lightweight/procedural.
- Remaining: this is an approximation, not physics-based foot locking. True planted-foot IK, a high-quality authored human mesh, a fully skinned Skeleton3D rig, polished animation clips, facial animation and device validation remain. Phase 6 is incomplete.


## Progress entry — 2026-11-15
### Phase 6 — Turning, acceleration and idle transition polish — Source committed; validation pending
- Added world-space movement intent tracking and horizontal acceleration sampling to drive character animation from actual movement rather than touch-axis assumptions.
- Added smoothed turn intensity from the relationship between current velocity and new movement direction; the upper body now leans subtly into turns, with stronger response at run speed.
- Added acceleration-aware forward body pitch and a separate low-amplitude idle sway/breathing clock; idle motion settles independently from the walking gait.
- Extra improvements: more reliable turning response for camera-relative touch and keyboard movement, smoother stop/start blending, and less idle animation dependence on the locomotion clock.
- Remaining: authored high-detail human mesh, genuinely skinned Skeleton3D rig, polished animation clips, foot-locking IK, facial animation, and consolidated Godot/Android plus device validation. Procedural geometry remains a placeholder-quality model; Phase 6 is incomplete.


## Progress entry — 2026-11-15
### Phase 6 — Wrist hierarchy and hand-animation integration — Source committed; validation pending
- Added independent wrist pivots beneath both elbow joints and attached the palm geometry to the wrist nodes.
- Rebuilt finger and thumb geometry in wrist-local space, correcting the previous issue where digits were positioned directly under the character root and did not follow arm movement.
- Added restrained wrist counter-motion during gait so palms and fingers follow the forearm rather than remaining visually detached.
- Extra improvements: corrected hand alignment, improved left/right hand symmetry and kept the additional animation lightweight with no external assets.
- Remaining: authored high-detail human mesh, truly skinned Skeleton3D rig, polished animation clips, hand/finger posing, foot-locking IK, facial animation and consolidated Godot/Android plus device validation. This is still a procedural character; Phase 6 remains incomplete.


## Progress entry — 2026-11-15
### Phase 6 — Facial motion and uneven-ground foot adaptation — Source committed; validation pending
- Added timed eyelid blinking, subtle pupil gaze response based on movement direction and restrained idle mouth movement to animate the existing procedural face.
- Added per-foot downward ground probes with smoothed ankle-height correction on grounded terrain, helping feet adapt to small road/sidewalk height differences.
- Extra improvements: ray queries exclude the player body, offsets are clamped, and corrections are smoothed to avoid abrupt ankle snapping.
- Limitations: this is procedural facial motion and ankle-height adaptation, not an authored high-detail face, blendshape rig or full two-bone foot-locking IK. A real skinned human asset, Skeleton3D skin weights and authored animation clips remain outstanding. Phase 6 remains incomplete; consolidated validation is pending.

## Progress entry — 2026-11-15
### Phase 6 — Head articulation and foot-contact integration — Source committed; validation pending
- Added a dedicated head/neck pivot and moved the existing head, hair, eyes and facial details beneath it while preserving their world-space placement.
- Added smoothed head-look yaw from movement direction and restrained pitch/idle micro-motion, so the face no longer remains rigidly fixed while the body turns.
- Fixed a foot-contact integration issue: the locomotion animation previously overwrote ankle offsets calculated by the ground probes in the same physics frame. Ground adaptation is now blended into stance-phase ankle height and fades during foot swing.
- Extra improvements: pupil gaze coordinates now use the head pivot's local space; head movement remains damped to avoid abrupt snapping.
- Limitations: the character is still assembled from procedural primitive meshes. No authored high-detail human asset, deforming skin weights, full Skeleton3D rig, authored animation clips or full two-bone foot-locking IK has been added. Phase 6 remains incomplete; consolidated validation is pending.


## Progress entry — 2026-11-15
### Phase 6 — Slope-aware foot contact polish — Source committed; validation pending
- Extended each foot's ground probe to read the contacted surface normal and convert it into character-local space.
- Added smoothed, clamped pitch and roll adaptation so planted feet can align more naturally with small road/sidewalk slopes instead of correcting height alone.
- Ground tilt fades during the swing phase and is combined with the existing walk/run ankle motion; airborne/no-hit frames ease the target back toward neutral.
- Extra improvements: separate left/right contact state, bounded angular response to reduce sudden rotations, and preserved the existing low-cost raycast approach for mobile.
- Limitations: this is slope-aware procedural contact, not a true foot-locking or two-bone IK solver. A high-detail authored human mesh, weighted Skeleton3D rig, authored animation clips, full facial/hand posing and consolidated Godot/Android/device validation remain outstanding. Phase 6 remains incomplete.


## Progress entry — 2026-11-15
### Phase 6 — Responsive facial expression and hand posing — Source committed; validation pending
- Added eyebrow node references and subtle brow tension driven by movement exertion and acceleration.
- Facial expression now responds to sprint effort with restrained eye narrowing and mouth shape changes, while preserving timed blinking and gaze tracking.
- Added references for each procedural finger mesh and a small exertion-based finger curl so hands no longer remain completely static during faster movement.
- Extra improvements: expression values are bounded and lightweight; all changes reuse existing geometry and avoid per-frame node creation.
- Limitations: these are procedural expression/pose controls, not facial blendshapes or a true hand skeleton. A high-detail authored character, weighted Skeleton3D rig, authored animation clips, full two-bone foot-locking IK and consolidated Godot/Android/device validation remain outstanding. Phase 6 remains incomplete.


## Progress entry — 2026-11-15
### Phase 6 — Multi-point foot contact refinement — Source implemented; validation pending
- Replaced the single ground ray per foot with four probes distributed across heel, toe and both shoe edges.
- Averages valid contact positions and surface normals before calculating ankle height, pitch and roll. This reduces sensitivity to narrow seams and small collision features compared with a single center ray.
- Requires at least two valid samples before applying a new contact target; missing samples smoothly relax toward neutral instead of snapping.
- Extra improvements: probe offsets follow the character's world orientation; normals are normalized and flipped to the upward hemisphere before averaging; per-foot smoothing remains independent.
- Scope boundary: this improves multi-point procedural foot contact only. It is not a planted-foot lock, a two-bone IK solver, or a replacement for an authored weighted character rig.
- Remaining Phase 6 work: proper authored 3D human mesh and weighted Skeleton3D, animation clips/blending, full foot-locking IK, interaction prompts/doors and reliable vehicle transition polish. Run the planned consolidated Godot parse/startup and Android validation once the phase batch is ready. No IPA build/sign/export was performed.


## Progress entry — 2026-11-15
### Phase 6 — Analog on-foot joystick and character refinement — Source implemented; validation pending
- Added an analog virtual joystick for on-foot movement, with a movable thumb control, dead zone, normalized diagonal movement, multi-touch-friendly separate sprint and vehicle controls, and release-to-neutral behavior.
- Replaced the four directional walk buttons with the joystick; the joystick is hidden during driving and restored on foot.
- Added layered pelvis/abdomen/chest silhouette shaping and subtle upper-body counter-rotation.
- Fixed shoe hierarchy so toe, lace and sole details follow the ankle pivots instead of remaining static at the character root.
- Extra improvements: desktop mouse joystick emulation and smoother analog input around the center.
- Limitation: character remains procedural geometry; authored photorealistic model, weighted Skeleton3D, mocap-quality clips and true two-bone foot IK are not implemented. No authored character asset was available in the repository asset tree.
- No tests/workflows were run; consolidated validation remains pending. No IPA build/sign/export was performed.
