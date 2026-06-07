# ui

Use this for interface scenes and UI-specific scripts: menus, HUDs, overlays,
dialogs, widgets, themes, and input prompts. UI can talk to app services and
game state, but should keep presentation details out of gameplay systems.

Good examples:

- `ui/screens/main_menu/main_menu.tscn`
- `ui/screens/pause_menu/pause_menu.gd`
- `ui/hud/player_hud/player_hud.tscn`
- `ui/widgets/input_prompt/input_prompt.gd`
- `ui/themes/default_theme.tres`

Avoid putting game rules here. A health bar can display health, but health
calculation belongs in `game/`.
