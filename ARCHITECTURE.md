# Architecture

How xandbox is built. Three rules, one goal: **you can test gameplay without booting the
game.** Everything below exists to make `godot --headless -s res://tests/run.gd` a real,
sub-second iteration loop.

If you're adding a new spawnable thing (an actor, a prop, a system), follow these three
rules and it will be testable by construction. If something here is getting in your way,
that's worth a conversation before you route around it.

---

## Rule 1 — Builders, not structural scenes

**Every spawnable thing is a `static func build(ctx: World) -> Node`, never a `.tscn`.**

A "scene" is a pure constructor: you `.new()` the types, set their fields, parent them, and
return the root. It's greppable, diffable, merges without conflict, and has no invisible-node
or stale-`@onready` bugs.

`.tscn` files survive **only as leaf art assets** — a mesh export, a material, imported world
geometry. You `preload()` them and `.instantiate()` them inside a builder, treating the file
as an *opaque visual asset*. You never wire logic into a `.tscn`, never attach a gameplay
script to one, never reach into its node tree from code.

The reference builder is [game/actors/player/player_scene.gd](game/actors/player/player_scene.gd):

```gdscript
class_name PlayerScene

const _MESH := preload("res://assets/instances/player/player_mesh.tscn")  # art only, opaque

static func build(ctx: World) -> Player:
    var player := Player.new()
    var body := PlayerBody.new()
    body.add_child(_collision_capsule(ctx.tuning))   # logic/tuning-driven -> built in code
    body.add_child(_MESH.instantiate())              # imported art -> opaque
    ...
    player.bind(ctx)                                 # dependency injection (Rule 2)
    return player
```

**Where to draw the art/structure line:** if a node's shape is driven by gameplay tuning or it
carries behavior, build it in code (the collision capsule, whose height comes from
`MovementTuning`). If it's a placeholder or final visual with no logic, it's a `.tscn` art leaf
(the capsule mesh). When unsure, ask: "would a test ever need to assert on this?" If yes, code.

Current `.tscn` inventory — keep this list short:
- [world.tscn](world.tscn) — level art (ground, light, environment) + the bootstrap script. The
  player is *not* instanced here; it's builder-spawned (see Rule 2).
- [assets/instances/player/player_mesh.tscn](assets/instances/player/player_mesh.tscn) — the
  placeholder capsule mesh. Pure art.

---

## Rule 2 — Inject a `World` context; no autoloads, no globals

**Nodes receive their dependencies through `bind(ctx)` in their builder, not from a global
lookup.** This is the rule that actually makes things testable, and it matters more than the
builders.

[app/world.gd](app/world.gd) is a plain `RefCounted` holding the shared per-run state — `mode`,
`tick`, and a [MovementTuning](game/actors/player/movement_tuning.gd):

```gdscript
class_name World extends RefCounted
var mode: int = 0
var tick: int = 0
var tuning := MovementTuning.new()
```

Why this and not an autoload: autoloads are global mutable state. Every test shares them, you
can't construct two of them, and you can't run two worlds side by side. A `World` retires that.
You `World.new()` per test and assert. You can stand up **two worlds in one headless process**
(the foundation for server+client netcode integration tests later) — proven today by the
`two_worlds_coexist` test, which tunes two players differently and ticks both.

**Tuning lives on the context, not as scene-baked `@export`s.** Movement constants
(`walk_speed`, `gravity`, `acceleration`, heights, …) are fields on `MovementTuning`, reached via
`world.tuning`. A test swaps tuning by constructing a different `World`; nothing is baked into a
node or a `.tscn`.

**The injection seam:** the builder calls `player.bind(ctx)`, which threads the context down
([player.gd](game/actors/player/player.gd) → [player_body.gd](game/actors/player/player_body.gd)).
A node reads `world.tuning`, never a singleton.

> **Deliberately absent.** Earlier sketches named a `CommandBus` and a `MouseLock` autoload.
> Neither exists, because nothing consumes them yet. `World` is built to grow a `commands`
> field when there's a real consumer — we don't add speculative structure. (`PlayerCamera`
> currently writes `Input.mouse_mode` directly; that's a known seam to revisit, not a global
> we've blessed.)

---

## Rule 3 — A headless `SceneTree` test harness

**Tests boot a real `SceneTree` with no main scene, build the real types, tick by hand, assert,
free.** Zero third-party dependencies; the entry point is just a script that `extends SceneTree`.

Run it:

```sh
godot --headless -s res://tests/run.gd
```

Single-digit seconds, no window, exits non-zero on failure (CI-ready). The files:

- [tests/run.gd](tests/run.gd) — `extends SceneTree`; `_initialize()` runs each suite, sums
  failures, `quit(failures)`.
- [tests/test_suite.gd](tests/test_suite.gd) — tiny base with `check(ok, label)`. Suites extend it.
- [tests/motor_tests.gd](tests/motor_tests.gd) — movement math: build a player, drive crafted
  input frames, assert on resulting state (speed, capsule height, …).
- [tests/pipeline_tests.gd](tests/pipeline_tests.gd) — the builder→inject→tick→assert pipeline,
  including the two-worlds-coexist proof.

A suite is the whole pattern in a few lines:

```gdscript
var ctx := World.new()
var player := PlayerScene.build(ctx)
tree.root.add_child(player)
player.body.resolve_velocity(PlayerInputFrame.make(Vector2(0, 1)), 1.0 / 120.0)
check(player.body.velocity.length() > 0.0, "forward input produces velocity")
player.queue_free()
```

> GdUnit4 is worth adopting eventually for assertion ergonomics and reports, and it composes
> with this — but the `extends SceneTree` harness is the **zero-dependency core** and stays
> regardless.

### The input-frame seam (what makes simulation tickable by hand)

A node that reads `Input` directly inside `_physics_process` can't be driven by a test — there's
no input device headless. So input is captured into a value object once, and simulation consumes
that object:

[PlayerInputFrame](game/actors/player/player_input_frame.gd) is a `RefCounted` snapshot
(`move_dir`, `sprint`, `crouch`, `jump`). `capture()` reads `Input` — it's the **only** runtime
`Input` read for movement. `make(...)` constructs a frame by hand for tests.

`PlayerBody` then splits the work:

- `resolve_velocity(frame, delta)` — **pure**: reads `frame` + `world.tuning`, writes `velocity`
  and crouch state, makes **no physics-server calls**. This is what tests drive.
- `simulate(frame, delta)` — `resolve_velocity()` then `move_and_slide()`. The runtime path.

The split exists because of a hard headless constraint: **`move_and_slide()`, `get_gravity()`,
and global-transform reads fault in a manually-ticked tree** — there's no stepped physics space.
So anything a test asserts on must be computed *before* the move. (That's also why gravity is a
`MovementTuning` constant, not `get_gravity()` — the latter reads physics-server state and was a
hidden global besides.) `is_on_floor()` is safe to call; it returns the cached flag (false
headless), so off-floor branches stay deterministic. Asserting on post-`move_and_slide` *position*
belongs in an in-engine integration test, not the unit harness.

The general rule when you add an actor: **capture input into a frame, put the resolvable math in a
pure method, keep `move_and_slide()` (and any physics-server call) in a thin runtime wrapper.**

---

## Layout

```
app/        project shell: World context, scene bootstrap. No game-specific rules.
game/       the game: actors/levels/mechanics, colocated by feature
              actors/player/  player_scene (builder), player, player_body,
                              player_camera, player_input_frame, movement_tuning
assets/     imported media. assets/instances/<x>/ holds opaque .tscn art leaves.
tests/      the headless harness: run.gd + *_tests.gd suites
```

(`ui/`, `data/`, `shared/`, `tools/`, `addons/` per the broader template convention — add them
when there's something to put in them.)

---

## Checklist for a new spawnable

1. Write `XScene.build(ctx: World) -> X`. `.new()` everything; `.instantiate()` only art `.tscn`s.
2. Give `X` a `bind(ctx)` that stores `world` and binds its children. Read tuning from `world`.
3. If it simulates: `capture()` input into a frame, put the math in a pure `resolve_*`, keep
   `move_and_slide()`/physics calls in a thin wrapper.
4. Add a suite in `tests/` that `World.new()`s, builds it, ticks the pure path, and asserts.
5. Sanity grep: no `script =` in any `.tscn` under `game/`; `Input.` only in your capture +
   look seams.
