# Fog Trail

Fog Trail is a ten-stage 2D platformer set on a Benguet-inspired mountain trail at dusk. Collect three lanterns to open each stage's shelter. The original trail opens the campaign, followed by longer gaps, narrower ledges, steeper climbs, and thorn crossings on the way to Summit Run.

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

## Campaign progress

Choose **Play** to start Stage 1. Each clear unlocks the next stage, and the shelter screen offers **Next Stage** or **Play Again**. The **Stage Map** lists locked, available, and cleared stages. Select any unlocked stage to replay it. **Continue** opens the next uncleared stage when you return later.

Progress is saved on the device in `user://trail_campaign.cfg`. Clearing Stage 10 shows **To be continued…**. All ten stages remain replayable from the map.

## Edit the game in Godot

Stage 1 is in `scenes/trail.tscn`. Open a numbered scene under `scenes/stages/` to edit Stages 2–10. `scripts/trail_stages.gd` defines the map names and campaign order.

| Change | Where to edit |
| --- | --- |
| Move or resize a platform | Open the stage scene and expand `Terrain`. Move an instance with the 2D move tool. Its **Size** property sets both the drawn platform and the collision. The instance origin is the platform's upper-left edge. |
| Adjust movement | Open `scenes/hiker.tscn`, select `Hiker` and change **Move Speed**, **Jump Strength**, **Gravity**, **Coyote Time**, or **Jump Buffer** in the Inspector. The last two settings are in seconds. |
| Move a lantern | Select the lantern under `Lanterns` in the stage scene and place it within reach of the hiker. |
| Add a lantern | Instance `scenes/trail_lantern.tscn` under `Lanterns` and give it a unique, nonempty **Lantern Id**. The HUD and shelter use the count of lanterns in that stage. |
| Move or add a checkpoint | Move the existing marker under `Checkpoints` or instance `scenes/trail_checkpoint.tscn` there. The `Spawn` marker is where the hiker's feet appear after a respawn. Place it over safe ground. |
| Change where the stage begins or ends | Move the root-level `Trailhead` marker or `Shelter`. Increase **Trail Length** on the root if you extend the route so the camera can follow. |

`scripts/trail_progress.gd` holds the lantern and checkpoint state of one attempt. `scripts/trail_campaign.gd` saves campaign unlocks. After a stage edit, test the jumps in both directions and check that the lanterns and checkpoint are reachable.

## Export a landscape Android APK

1. In Godot, open **Editor → Manage Export Templates** and install the templates for **4.6.3 stable**.
2. Install OpenJDK 17 and the Android SDK. This build used Platform **36**, Build-Tools **36.0.0**, and Android SDK Platform-Tools. The preset uses Godot's prebuilt Android template.
3. In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** to the JDK folder and **Android SDK Path** to the SDK folder.
4. Open **Project → Export**, select **Android APK**, and choose **Export Project** with **Export With Debug** checked. Save a `.apk` file. The preset exports `arm64-v8a` for 64-bit ARM phones and `x86_64` for emulators, uses landscape orientation, and leaves Internet permission off.
5. Install the APK on a test device or emulator. With Android debugging enabled, use `adb install -r build/FogTrail.apk`, then open **Fog Trail**. Use a release keystore and the distribution format appropriate to your store if you later publish the game.

The 1.1.0 APK uses a new debug signing key. Remove the 1.0.0 debug installation before installing 1.1.0 on the same device.

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
godot --headless --fixed-fps 60 --script res://tests/campaign_qa.gd
```

The suites exit with an error when a check fails. See [`QA_LOG.md`](QA_LOG.md) for playthroughs, bug fixes, and platform coverage. Add `-- --touch-controls` to a desktop launch to show the mobile controls.

To run the graphical check, use `godot --script res://tests/visual_check.gd` on a machine with a display. It writes screenshots to the game's `user://qa_screenshots` folder. Set the `FOG_QA_SHOTS` environment variable to choose an output folder.

## Credits and licenses

The stages, scenery, sprites, icons, and sound cues were created for Fog Trail. Instrument Serif and Inter are distributed under the SIL Open Font License. Their notices are in `assets/fonts`. Godot engine and third-party notices are in `licenses`.

## Development history

Read [the development record](DEVELOPMENT.md) for the first trail scene, the failed QA runs, the fixes, and the final regression results.
