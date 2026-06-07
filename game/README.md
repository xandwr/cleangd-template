# game

Use this for the actual game: actors, levels, mechanics, components, gameplay
systems, and game-specific resources. This is the folder that should change the
most from project to project.

Prefer colocating scenes, scripts, and resources by feature once something has
a clear identity.

Good examples:

- `game/actors/player/player.tscn`
- `game/actors/player/player.gd`
- `game/components/interaction/interactor_3d.gd`
- `game/components/interaction/interactor_2d.gd`
- `game/items/keycard/keycard.tscn`
- `game/levels/prototype/prototype_level.tscn`
- `game/systems/objective_system.gd`

Avoid organizing gameplay only by file type, such as one global `scripts/`
folder and one global `scenes/` folder. That starts tidy, then scatters each
feature across the project.
