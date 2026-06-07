# addons

Use this for third-party Godot plugins and engine add-ons. Godot expects plugins
to live under `res://addons`, so this folder keeps that convention explicit.

Good examples:

- `addons/gdunit4/`
- `addons/dialogue_manager/`
- `addons/proton_scatter/`
- `addons/terrain_3d/`

When adding a plugin, keep a note here or in the plugin folder with the source
URL, version, install date, and any local changes. That makes future upgrades
less mysterious.

Avoid editing vendor code unless the change is deliberate and documented.
