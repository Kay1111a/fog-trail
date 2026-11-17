# Fog Trail QA Log

## Version 1.1.0 campaign verification

| Area | Result and observed behavior |
| --- | --- |
| Campaign progression | **Pass.** The stage map starts with one available stage. Clearing each shelter unlocks exactly one successor. The tenth clear shows **To be continued…** and keeps the campaign replayable. |
| Parkour routes | **Pass.** The original Stage 1 suite completed three runs. Movement and jump input cleared every gap and thorn crossing in Stages 2–10, collected all three lanterns per stage, and reached each shelter. Summit Run also passed a return journey from its locked shelter. |
| Saved progress | **Pass.** Saves survived a new game instance. An invalid stored count reopened Stage 1. Replaying earlier courses kept later stages unlocked. |
| Rendered game | **Pass on Linux.** Keyboard controls, pause, touch layout, and the ten-card map ran at 854 × 480 and 1180 × 540. |
| Windows and Android resources | **Pass on Linux.** Both export resource sets passed the 199 original checks and the 114 campaign checks. The APK passed v2 and v3 signature checks and 16 KB alignment verification. |

The first campaign run found a tight thorn approach in Stage 6. Moving the thorns farther from the landing added room to start the jump. The rerun cleared the course and continued through Stage 10. See [the campaign run log](docs/qa/campaign-1.1.0.log).

Reproduce the two headless suites from the Godot project root.

```sh
godot --headless --editor --import --quit
godot --headless --fixed-fps 60 --script res://tests/qa.gd
godot --headless --fixed-fps 60 --script res://tests/campaign_qa.gd
```

The Windows executable is unsigned. The APK uses a new debug signing key. Native Windows play and Android installation and play remain unverified for this version.

## Version 1.0.0 verification

Godot `4.6.3.stable.official.7d41c59c4` · Fog Trail 1.0

**Game and export bugs found — 6. Fixed — 6. Blocked — 0.** Four were High and two were Medium. Zero known Critical or High bugs remain in the checks that ran. Platform checks are listed below.

## Regression results

| Area | Result and observed behavior |
| --- | --- |
| Movement and collisions | **Pass.** Directional input, jumping, takeoff with a zero jump buffer, floor, walls, ceiling, and platform landing. |
| Lanterns and HUD | **Pass.** Game-state tests covered all six collection orders and repeated touches. Scene contacts in ridge, hollow, crossing order hid each pickup and advanced the HUD from 0/3 to 3/3. |
| Respawn and checkpoint | **Pass.** Pit and thorn deaths before and after checkpoint activation, three consecutive hazard deaths, immediate recovery, and lantern persistence. |
| Shelter | **Pass.** Actual trigger collisions at 0/3, 1/3, and 2/3 report the correct missing count. The shelter opens at 3/3, emits one completion, and stops gameplay. |
| Pause, restart, and replay | **Pass.** Pausing freezes a moving or jumping hiker and preserves progress. Restart and Play Again restore the starting position, all three lanterns, and the initial checkpoint state. |
| Continuous playthroughs | **Pass.** The first run reached the locked shelter at 2/3, returned for the Hollow lantern, and completed. The second run completed after Play Again. A third run reached the shelter at 0/3, returned as far as the first crossing, and collected every lantern before completing. These runs sent movement and jump input through the real physics scene. |
| Rendered desktop | **Pass on Linux.** Keyboard events opened Play, moved, jumped, and paused. The pickup started its audio cue. Rendered views at 854 × 480 and 1180 × 540 kept the HUD and touch controls on screen. |
| Touch regression | **Pass with simulated Godot input.** Right and jump together, both finger release orders, touch cancellation, a second finger tapping Pause, and fresh input after Resume. |
| Windows x64 | **Export passed.** The Windows executable and resource pack were created. The latter ran the full regression from the exported resources on Linux. Native Windows launch and playthrough are unverified. |
| Android | **Export passed. Device playtest blocked.** The debug-signed APK verified for `arm64-v8a` and `x86_64`. Its manifest specifies landscape. The exported Godot resources passed the same regression on Linux. |

## Verification commands

From the project directory, with matching export templates and the SDK paths configured. Run the graphical command on a desktop with a display. Create `build` before exporting.

```sh
godot --version
godot --headless --editor --import --quit
godot --headless --fixed-fps 60 --script res://tests/qa.gd
godot --script res://tests/visual_check.gd
godot --headless --export-release "Windows Desktop" build/FogTrail.exe
godot --headless --export-debug "Android APK" build/Fog-Trail-Android.apk
godot --headless --fixed-fps 60 --main-pack build/FogTrail.pck --script /absolute/path/to/FogTrail/tests/qa.gd
apksigner verify --verbose build/Fog-Trail-Android.apk
zipalign -c -P 16 -v 4 build/Fog-Trail-Android.apk
aapt2 dump xmltree --file AndroidManifest.xml build/Fog-Trail-Android.apk
```

- Source import passed from a fresh copy. The source regression reported `199 assertions, 0 failures` with exit code 0.
- The desktop rendering check captured the title, trail, both landscape touch layouts, and pause. The software graphics driver logged a V-Sync capability warning.
- The Windows executable's file header reported `PE32+`, x86-64. Its exported game resources passed the same 199 assertions when run by Godot on Linux.
- `apksigner` verified the APK with v2 and v3 signatures, and `zipalign` passed. The manifest reported `screenOrientation=0` (landscape), minimum API 24, and target API 36. Godot also passed 199 assertions against the game's resources extracted from the APK.

## Platform notes

The test machine ran Linux. No native Windows session was available. An attempted Wine launch exited in the compatibility runtime before the game opened.

The Android 15 (API 35) x86-64 emulator ran without hardware acceleration. On a boot that reached the package service, `adb install -r` failed with `Can't find service: package` after the service disconnected. A smaller-display boot and a non-incremental install retry were prepared. The emulator watchdog then killed `system_server` on repeated boots before the package service stabilized. The APK installation and Android gameplay could not be confirmed. Multi-touch crossed the Godot input and gameplay layers in the regression suite. Native Android touch delivery still needs a working device or emulator.

## Fixed defects

### FT-001 · Medium · Desktop menus

1. Open **Controls** and return to the main menu.
2. Start a run, open **Pause**, then return to the main menu. Inspect the Godot log.

- **Expected result** — Focus follows the visible menu and the log stays clear.
- **Observed result** — A deferred focus request targeted a freed button and logged `!is_inside_tree()` from `grab_focus`.
- **Affected file** — `scripts/trail_hud.gd`
- **Retest** — Passed after setting focus only after adding the target button. Enter starts Play in the rendered game.

### FT-002 · High · Foggy Hollow collisions

1. Cross the upper bridge and reach the shelter without the Hollow lantern.
2. Backtrack, drop to the lower floor, and collect that lantern.
3. Jump right from the low floor to the return step.

- **Expected result** — The jump leads to a climbable return to the main trail.
- **Observed result** — The jump hit the underside of the bridge or missed the narrow landing and respawned the hiker.
- **Affected scene** — `scenes/trail.tscn`
- **Retest** — Passed after shortening the overhead bridge and extending the lower floor toward a repositioned return step. Both directions of the surrounding route and all three completions passed.

### FT-003 · High · Jump input with zero buffer

1. Open `scenes/hiker.tscn` and set **Jump Buffer** to `0`.
2. Stand on the trailhead ground and press Space.

- **Expected result** — The hiker jumps immediately.
- **Observed result** — The press only populated the buffer, so a zero buffer caused the hiker to stay grounded.
- **Affected file** — `scripts/hiker.gd`
- **Retest** — Passed after letting a fresh press trigger a grounded jump directly. Default and zero-buffer jumps passed.

### FT-004 · Medium · Headless audio teardown

1. Run the complete route in the headless test runner.
2. Exit the test after triggering the completion cue and inspect the verbose log.

- **Expected result** — The test runner exits without a resource warning.
- **Observed result** — `complete.wav` could remain in use at exit.
- **Affected file** — `scripts/fog_trail.gd`
- **Retest** — Passed after clearing the audio stream on level transitions and skipping playback on the headless display backend. The rendered game still starts pickup audio.

### FT-005 · High · Android export configuration

1. Install the matching Android template, OpenJDK, and Android build tools.
2. Configure the paths in Godot and export the **Android APK** preset.

- **Expected result** — Godot creates the test APK.
- **Observed result** — Export stopped with a configuration error because the project had mobile texture import disabled.
- **Affected file** — `project.godot`
- **Retest** — Passed with ETC2/ASTC texture import enabled. Godot exported the APK and both signature schemes verified.

### FT-006 · High · Android multi-touch pause

1. Start with touch controls active.
2. Keep one finger on the right arrow.
3. Press and release **Pause** with a second finger while holding the first finger down.

- **Expected result** — The game pauses and clears movement.
- **Observed result** — Pause relied on single-finger mouse emulation. A second screen contact left the game in its playing state with right input active.
- **Affected file** — `scripts/trail_hud.gd`
- **Retest** — Passed after accepting touch presses on the pause button directly. The same two-finger sequence entered Pause with a zero movement axis, and movement worked after resuming.
