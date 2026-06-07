# boot

Use this for the first scene Godot loads. Keep it small and boring: initialize
autoload-driven services, hand off to a menu or prototype scene, and avoid
putting long-term gameplay logic here.

Good examples:

- `boot.tscn` as the project's `run/main_scene`.
- `boot.gd` for one-time startup checks.
- A loading screen that asks `SceneRouter` to open the first real scene.

When a project grows, this scene should usually become a handoff point rather
than the place where the game lives.
