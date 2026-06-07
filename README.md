# CleanGD Template

This is a clean, production-ready and scalable template setup
for Godot 4.6.3, with opinionated defaults that I believe
lead to a more ergonomic experience when bootstrapping new
games from the void.

## Using This Template

To start a new project from this repository:

1. Create a new repository from this template, clone it, or copy the folder.
2. Rename the project in `project.godot` under `application/config/name`.
3. Open Godot's Project Manager, choose Import, and select this folder or its
   `project.godot` file.
4. Press Play. The default main scene is `res://app/boot/boot.tscn`.

The boot scene is intentionally minimal. Replace it with a menu, prototype
level, loading screen, or scene-router handoff when the project has a real
entry point.

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
