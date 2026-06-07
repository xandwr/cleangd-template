# shared

Use this for reusable helpers, base resources, math utilities, constants, and
small abstractions that can survive being copied into another project. Code here
should avoid knowing about a specific game's enemies, weapons, levels, or UI.

Good examples:

- `shared/math/spring.gd`
- `shared/math/random_weighted_picker.gd`
- `shared/resources/stat_block.gd`
- `shared/resources/id_reference.gd`
- `shared/utils/node_paths.gd`
- `shared/utils/time_format.gd`

Avoid turning this into a miscellaneous junk drawer. If a helper only makes
sense for one gameplay feature, keep it near that feature in `game/`.
