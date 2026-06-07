# CleanGD Template

This is a clean, production-ready and scalable template setup
for Godot 4.6.3, with opinionated defaults that I believe
lead to a more ergonomic experience when bootstrapping new
games from the void.

## Project Structure

The template uses top-level folders for ownership, not file type. Godot
projects scale best when scenes, scripts, resources, and imported data can stay
near the feature they belong to.

- `app/`: Project shell, boot flow, autoloads, app-level services.
- `game/`: Game-specific scenes, actors, systems, mechanics, and levels.
- `ui/`: Menus, HUDs, widgets, themes, and UI-specific controllers.
- `assets/`: Imported art/audio/font assets and their source files.
- `data/`: Designer-facing resources, definitions, tables, and defaults.
- `shared/`: Reusable code and resources that are not tied to one game.
- `tests/`: Automated tests, fixtures, and test-only helpers.
- `tools/`: Editor scripts, import helpers, generators, and local utilities.
- `addons/`: Third-party Godot plugins and plugin-specific notes.

Each folder has its own README with scope notes and examples.
