# tools

Use this for development utilities: editor plugins local to the project, import
helpers, migration scripts, asset generators, validation scripts, and one-off
automation that is worth keeping.

Good examples:

- `tools/editor/level_validation_plugin.gd`
- `tools/import/generate_collision_shapes.gd`
- `tools/build/export_all.sh`
- `tools/migrations/rename_item_ids.gd`
- `tools/generators/create_input_prompt_icons.gd`

Avoid putting runtime gameplay code here. If a script ships as part of the game
or runs during normal play, it belongs in `app/`, `game/`, `ui/`, or `shared/`.
