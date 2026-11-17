# Fog Trail development history

The Git history was assembled for publication from the saved Godot project,
the original trail scene generator, and retained QA output. The early commits
reconstruct the original development stages. Commit dates reflect when this
repository was prepared. The test excerpts under `docs/qa` are from the actual
development runs.

The first snapshot launches into the trail scene so movement and terrain can
be inspected. The next snapshot adds the menus, audio, touch input, and export
presets before the recorded fixes.

## QA record

| Milestone | Retained evidence |
| --- | --- |
| Focus error during repeated menu changes | [First test run](docs/qa/qa-01.log) and [focus retest](docs/qa/qa-02.log) |
| Return jump fails when backtracking from the shelter | [Failure](docs/qa/qa-02.log) and [route retest](docs/qa/qa-03.log) |
| A zero jump buffer prevents jumps | [Reproduction](docs/qa/qa-04.log) and [retest](docs/qa/qa-05.log) |
| Headless audio resource remains in use at exit | [Reproduction](docs/qa/qa-03.log) and [retest](docs/qa/qa-05.log) |
| Android texture configuration blocks export | [Export defect and retest](QA_LOG.md#ft-005--high--android-export-configuration) |
| Second finger cannot pause while direction is held | [Before](docs/qa/pause-touch-before.log) and [after](docs/qa/pause-touch-after.log) |
| Final gameplay and build checks | [Source](docs/qa/qa-09.log), [graphics and input](docs/qa/render-check.log), [Windows resources](docs/qa/windows-pack-qa-final.log), and [Android resources](docs/qa/android-package-qa.log) |

The [QA log](QA_LOG.md) contains reproduction steps, affected files, test
commands, and platform coverage. The source passed 199 regression checks.
Native Windows play and Android installation and play remain unverified.
