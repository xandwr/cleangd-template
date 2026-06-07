# app

Use this for the project shell: bootstrapping, autoload scripts, scene routing,
global settings, save plumbing, and debug services. Code here should know how
the application starts and runs, but it should avoid game-specific rules.

Good examples:

- `app/autoload/app.gd` for pause, quit, restart, and lifecycle helpers.
- `app/autoload/scene_router.gd` for loading screens and scene transitions.
- `app/autoload/settings.gd` for video, audio, input, and config persistence.
- `app/autoload/save_system.gd` for save slot IO and versioned save files.
- `app/debug/debug_overlay.tscn` for FPS, frame time, and dev toggles.

Avoid putting player movement, combat, level scripting, enemy AI, or item
definitions here. Those belong in `game/`.
