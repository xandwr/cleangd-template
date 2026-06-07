# data

Use this for designer-facing definitions and project data: resource files,
tables, defaults, tuning values, save schemas, localization files, and content
catalogs. Data here should be easy to inspect and safe to reference from scenes.

Good examples:

- `data/definitions/items/medkit.tres`
- `data/definitions/enemies/basic_enemy.tres`
- `data/settings/default_video_settings.tres`
- `data/dialogue/intro_dialogue.json`
- `data/localization/game.csv`
- `data/save/current_save_version.tres`

Avoid adding runtime-only state here. Data in this folder should describe the
game, not become the live copy of a running play session.
