# Fog Trail

Fog Trail is a single-level 2D platformer set on a Benguet-inspired mountain trail at dusk. Find three lanterns and bring their light to the shelter. Follow the sign to the upper ledge in Pine Ridge and look for a warm glow below the bridge in Foggy Hollow.

Built with **Godot 4.6.3 stable** (`4.6.3.stable.official.7d41c59c4`, standard GDScript edition). The project uses typed GDScript and the Compatibility renderer.

## Play on Windows

Extract the Windows ZIP and open `FogTrail.exe`. Keep `FogTrail.pck` next to the executable. The build is for 64-bit Windows and is unsigned.

To play from source, clone or download this repository. In Godot Project Manager, choose **Import**, select `project.godot` in the repository root, and open the project. Press **F5** to launch the main menu.

| Action | Windows | Android |
| --- | --- | --- |
| Move | A / D or Left / Right | Two arrows at the bottom left |
| Jump | Space | Up arrow at the bottom right |
| Pause | Esc | Pause at the top right |
| Resume | Esc or Resume | Resume |

You can hold a direction and tap jump on Android. Falling into a pit or touching thorns returns you to the last checkpoint or the trailhead. Lanterns stay collected on respawn. **Restart Level** and **Play Again** reset the whole attempt.

## Edit the game in Godot

| Change | Where to edit |
| --- | --- |
| Move or resize a platform | Open `scenes/trail.tscn` and expand `Terrain`. Move an instance with the 2D move tool. Its **Size** property sets both the drawn platform and the collision. The instance origin is the platform's upper-left edge. |
| Adjust movement | Open `scenes/hiker.tscn`, select `Hiker` and change **Move Speed**, **Jump Strength**, **Gravity**, **Coyote Time**, or **Jump Buffer** in the Inspector. The last two settings are in seconds. |
| Move a lantern | In `scenes/trail.tscn`, select the lantern under `Lanterns` and place it within reach of the hiker. |
| Add a lantern | Instance `scenes/trail_lantern.tscn` under `Lanterns` and give it a unique, nonempty **Lantern Id**. The HUD and shelter both use the count of lanterns in that group. If you change the total, also update the main-menu instruction in `scripts/trail_hud.gd`. |
| Move or add a checkpoint | Move `Checkpoints/RidgeCheckpoint` or instance `scenes/trail_checkpoint.tscn` under `Checkpoints`. The `Spawn` marker is where the hiker's feet appear after a respawn. Place it over safe ground. |
| Change where the level starts or ends | Move the root-level `Trailhead` marker or `Shelter` in `scenes/trail.tscn`. If you extend the route, increase **Trail Length** on the root so the camera can follow. |

`scripts/trail_progress.gd` holds lantern, checkpoint, and completion state for one attempt. `scripts/trail_level.gd` connects the scenes to that state. After a level edit, play in both directions and test the approach to each new landing.

## Export a landscape Android APK

1. In Godot, open **Editor → Manage Export Templates** and install the templates for **4.6.3 stable**.
2. Install OpenJDK 17 and the Android SDK. This build used Platform **36**, Build-Tools **36.0.0**, and Android SDK Platform-Tools. The preset uses Godot's prebuilt Android template.
3. In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** to the JDK folder and **Android SDK Path** to the SDK folder.
4. Open **Project → Export**, select **Android APK**, and choose **Export Project** with **Export With Debug** checked. Save a `.apk` file. The preset exports `arm64-v8a` for 64-bit ARM phones and `x86_64` for emulators, uses landscape orientation, and leaves Internet permission off.
5. Install the APK on a test device or emulator. With Android debugging enabled, use `adb install -r build/FogTrail.apk`, then open **Fog Trail**. Use a release keystore and the distribution format appropriate to your store if you later publish the game.

After installing the tools and templates, you can build either package from a terminal in the project folder. Create `build` first. Use the Godot console executable if your Windows install uses a different command name.

```sh
godot --headless --editor --import --quit
godot --headless --export-release "Windows Desktop" build/FogTrail.exe
godot --headless --export-debug "Android APK" build/FogTrail.apk
```

[Godot 4.6.3 download and matching export templates](https://godotengine.org/download/archive/4.6.3-stable/) · [Godot Android export guide](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html)

## Run the tests

```sh
godot --headless --editor --import --quit
godot --headless --fixed-fps 60 --script res://tests/qa.gd
```

The suite exits with an error when a check fails. See [`QA_LOG.md`](QA_LOG.md) for playthroughs, bug fixes, and platform coverage. Add `-- --touch-controls` to a desktop launch to show the mobile controls.

To run the graphical check, use `godot --script res://tests/visual_check.gd` on a machine with a display. It writes screenshots to the game's `user://qa_screenshots` folder. Set the `FOG_QA_SHOTS` environment variable to choose an output folder.

## Credits and licenses

The level, scenery, sprites, icons, and sound cues were created for Fog Trail. Instrument Serif and Inter are distributed under the SIL Open Font License. Their notices are in `assets/fonts`. Godot engine and third-party notices are in `licenses`.

## Development history

Read [the development record](DEVELOPMENT.md) for the first trail scene, the failed QA runs, the fixes, and the final regression results.
