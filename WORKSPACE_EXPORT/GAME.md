# Healing Without — Project Knowledge (take-home snapshot)

> Captured by Hermes Agent on 2026-08-19. This is a working mental model of the
> project as it stood after the cleanup pass. Use it to get any AI assistant
> (or your future self) oriented fast.

## What the game is
A first-person narrative **horror** game built in **Godot 4.7** (renderers:
`Forward Plus` + `gl_compatibility`; Windows graphics driver `d3d12`).
You play **Mother (Beth)** in a small apartment. Your daughter **Sarah** is
behind a locked bedroom door making scratching sounds; a static-filled
**television** is the only notable light source. Tone: oppressive, quiet,
psychological.

## File layout (what each piece does)
### Scenes (`res://scenes/`)
- `MainMenu.tscn` — **main scene** (`run/main_scene` in project.godot). Menu UI, horror font `dark-whispers.regular.otf`.
- `backstory.tscn` — intro story screen. Uses `dark-whispers` font + `new_theme.tres`.
- `apartment_root.tscn` — **root 3D scene**. Contains: `WorldEnvironment` (ambient light = black/0), instanced `our_home`, instanced `Television`, `Apt_music` (AudioStreamPlayer2D), `PlayerRoot` (the player), and the added `DialogueOverlay` instance.
- `our_home.tscn` — apartment geometry as a `CSGCombiner3D` (`our_home`) plus walls/doors/furniture CSG boxes and `Interactable` children. **Note: many node transforms are intentionally skewed (non-90°) — do NOT "fix" them.**
- `television.tscn` — TV mesh + `SubViewport`/`VideoStreamPlayer` (tv_static.ogv) + an `Interactable` (`interaction_type="tv"`).
- `DialogueOverlay.tscn` — `Control` UI used for the hand-rolled Sarah-door and TV dialogues.
- `yard.tscn` / `YardEnvironment.tscn` / `baseModel.tscn` — environment/asset stubs (minor).

### Scripts (`res://scripts/`)
- `PlayerController.gd` — `CharacterBody3D`. Movement (WASD + Shift run, Space jump, X crouch), `V` = noclip toggle, mouse-look. **E key** does a raycast (`InteractionRayCast`) → finds an `Interactable` → dispatches by `interaction_type`:
  - `couch` → sit (also starts TV video)
  - `sarah_door` → `../DialogueOverlay.start_door_interaction()`
  - `tv` → `../DialogueOverlay.start_tv_interaction()`
- `DialogueOverlay.gd` — hand-rolled dialogue graph (`dialogue_nodes` dict). Nodes: `start` (Sarah-door scene), `tv_start` (TV scene), plus `end_neutral/encourage/punish` and `tv_static/channel/off`. `start_door_interaction()` / `start_tv_interaction()` set the starting node and show the panel. Choice selection calls `GameState.modify_metrics(action)`. Uses font `res://fonts/dark-whispers.regular.otf`.
- `GameState.gd` — **autoload**. Behavioral metrics: `manipulation_level`, `house_anxiety`, `max_sanity_cap`, plus `sarah_alone_points`, `mother_alone_points`, `both_together_points`. `modify_metrics(action)` handles `encourage/punish/neutral`.
- `Interactable.gd` — `class_name Interactable` (`Node3D`). Two `@export`s: `prompt_message` and `interaction_type` (e.g. `"tv"`, `"couch"`, `"sarah_door"`).
- `ApartmentRoot.gd`, `MainMenu.gd`, `Backstory.gd`, `splashloader.gd` — scene logic. `splashloader.gd` is a `CanvasLayer` that fades a logo then loads `res://scenes/MainMenu.tscn`.

### Dialogic (`res://dilogic/`)
- Addon **Dialogic** is installed and configured in project.godot (`[dialogic]` block).
- Timelines in `dilogic/timelines/`:
  - `first-big-choice.dtl` — **ACTIVE / for later** (Sarah-door branch with Yes/No + `set {GameState.sarah_alone_points_}`). Left untouched on purpose.
  - `start_timeline.dtl` and `timeline.dtl` — **were empty (0 bytes) and DELETED** during cleanup; their `dtl_directory` entries were pruned. Only `first-big-choice` remains registered.
- Characters: `Mother`, `Narrator`, `sarah`. Audio channels: `voice`→Voice bus, `otherroom`→Voice 2, `music`→Music.

### Addons (`res://addons/`, gitignored)
- `ambientcg` — material/environment generator. `[ambientcg]` in project.godot points `extract_path` etc. at `res://addons/ambientcg/Extracted`. Its 4 autoloads (`AmbientAPI`, `AmbientParser`, `AmbientFileHandler`, `AmbientMaterialMaker`) resolve via their `.uid` files.
- `dialogic`, `boot_splash_plus`, `footstepper`, `nodes_plus`, `ExtensionResolver`, `asset_placer_with_physics`, `easyik`, `state_machine` — enabled editor plugins.

### Audio
- Bus layout: `res://resources/default_bus_layout.tres` defines **Master / Music / Voice / Voice 2 / Inside / sfx** (pointed by `audio/buses/default_bus_layout`).
- `audio/` has `ap1.wav`, `ap2.wav`, `crying.wav`, `drone_loop.wav`, `firetree.wav`, `intro_1.wav`, `intro_1_1.wav`, `Impact Vox Hammer.wav`, `Environment/steps*.wav`, and `first-choice/` (contains `sarah_1_muffled.wav`; several other `first-choice/*.wav` exist only as `.import` stubs — sources missing).
- `first-big-choice.dtl` references `res://audio/first-choice/sarah_1_muffled.wav` (present).

### Fonts (`res://fonts/`)
- `dark-whispers.regular.otf` — the horror display font (used by MainMenu, backstory, DialogueOverlay).
- `GrotleyRegular-mLEWv.otf` — secondary UI font.

## Interaction flow (current)
1. Player walks up to an object with an `Interactable` child, looks at it (raycast).
2. HUD shows `prompt_message` ("[E] Knock on Sarah's Door", "[E] Use Television", "[E] Sit on Couch").
3. Press **E** → `PlayerController._handle_object_interaction()` matches `interaction_type`.
4. `sarah_door` → `DialogueOverlay.start_door_interaction()` (shows the "Sarah's room is completely dark…" branching dialogue).
5. Choices call `GameState.modify_metrics(action)` and branch to `end_neutral/encourage/punish`.

## Cleanup already done (so you don't redo it)
- Removed all AI-integration code + a leaked OpenRouter key (files `openclaw.gd`, `kindred_connector.gd`); key was never committed (working tree only). Rotate the key at OpenRouter anyway.
- Fixed AmbientCG `[ambientcg]` paths + `backstory.tscn` ext_resource (`res://AmbientCG/…` → `res://addons/ambientcg/…`).
- Created audio bus layout + wired it in project.godot.
- Deleted 16 stale `.import` files with broken `res://AmbientCG/` paths (editor reimport regenerates them).
- Deleted 2 empty `.dtl` timelines + pruned refs.
- Wired `sarah_door` → `DialogueOverlay.start_door_interaction()` (was calling a nonexistent `Dialogic.start("apartment_start")`).
- Repointed TV interaction from deleted `Dialogic.start("timeline")` → `DialogueOverlay.start_tv_interaction()`.
- Fixed `splashloader.gd` target → `res://scenes/MainMenu.tscn`.
- Restored horror font references to `res://fonts/dark-whispers.regular.otf` (it was missing/misnamed before).

## Known gaps / "for later" (intentionally not fixed)
- **TV light**: `WorldEnvironment` ambient is black; the broken TV `WorldEnvironment` light was removed. TV is meant to be the main light source but isn't yet — only decorative `OmniLight3D`s exist. Not implemented yet.
- **`our_home.tscn` skewed transforms**: intentional, leave them.
- **Missing `first-choice` wavs**: only `.import` stubs for 10/19/20/hot_2/medium_3/7/8; `sarah_1_muffled.wav` is present.
- **Metrics**: tracked but lightly used; `first-big-choice.dtl` writes `GameState.sarah_alone_points_` (note trailing underscore — the real var is `sarah_alone_points`; mismatch, deferred).
- **`notes/` folder**: contains story notes — leave it alone.

## Git state
- `/addons` is gitignored. `scripts/`, `scenes/`, `dilogic/` are **untracked** (working-tree only).
- No commits/pushes were made (standing user rule). Repo currently shows a large set of staged deletions (`D`) unrelated to this work — review separately before any commit.
