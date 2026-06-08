## Sandbox I/O Primitives

**Primitive layer**:
- Button
- AreaTrigger
- Timer
- Counter
- Relay
- AndGate
- OrGate
- NotGate
- ToggleGate
- BranchGate
- Sensor
- Mover
- Spawner
- Light
- Sound
- Prop
- TextPrompt
- MapState
- SpawnPoint
- Connection
- ConnectionFilter
- SandboxContext
- WorldIO / Dispatcher

**Game mode layer** (named here only to assert they are *not* primitives — they compose over `MapState` + primitive receivers; their design is deferred):
- Objective
- Quest
- Checkpoint
- Wave
- Win condition
- Score rules

---

The sandbox interaction model is built around three concepts:

* **Emitters**: objects that produce named outputs.
* **Receivers**: objects that expose named inputs.
* **Connections**: edges from one emitter output to one receiver input.

Many objects may be both emitters and receivers. A `Counter`, for example, receives increment/reset inputs and emits `hit_target`. A `Mover` receives `open`/`close` inputs and may later emit `opened`, `closed`, or `reached_marker`.

The primitive layer should stay mechanism-only. It describes what physically or systemically happens, not what that event means inside a game mode.

### Emitters

#### Button

A usable object that emits when activated.

Outputs:

* `pressed`
* `released`, optional
* `toggled_on`, optional
* `toggled_off`, optional

#### AreaTrigger

A geometric volume backed by `Area3D`.

It is only responsible for overlap/presence events. It should not evaluate arbitrary conditions or poll world state.

Outputs:

* `entered`
* `exited`
* `touched`, optional

#### Timer

Emits after a delay or repeatedly on an interval.

Inputs:

* `start`
* `stop`
* `reset`

Outputs:

* `fired`

#### Counter

Accumulates incoming hits until a target count is reached.

Inputs:

* `increment`
* `decrement`
* `reset`
* `set_count`

Outputs:

* `hit_target`
* `changed`, optional

#### Logic

Logic is an editor/category label, not a single generic node type.

Each logic operation is its own primitive node with explicit inputs, outputs, and tests:

* `Relay`
* `AndGate`
* `OrGate`
* `NotGate`
* `ToggleGate`
* `BranchGate`

This avoids turning one `Logic` node into a hidden scripting language with a `mode` enum and mode-specific fields. Each node should do one small mechanical thing.

`BranchGate` must branch over fixed engine predicates or a referenced `ConnectionFilter`; it must not evaluate arbitrary expressions.

#### Sensor

A predicate-based emitter that watches world state and emits on state edges.

Unlike `AreaTrigger`, which is purely geometric, a `Sensor` polls a fixed engine predicate and emits on its edges. It is not a script hook and not an expression evaluator.

Initial predicate enum:

* `looked_at`
* `is_moving`
* `velocity_over`
* `line_of_sight`
* `var_compare`
* `group_present`
* `distance_less_than`

Sensors must use this fixed enum of supported predicates. They must not evaluate arbitrary user-authored code or freeform boolean expressions.

Outputs:

* `became_true`
* `became_false`
* `changed`

### Receivers

#### Mover

Moves, opens, closes, or travels to a marker.

Inputs:

* `open`
* `close`
* `toggle`
* `move_to`

Possible outputs:

* `opened`
* `closed`
* `reached_marker`
* `blocked`

#### Spawner

Creates and clears entities.

Inputs:

* `spawn`
* `clear`
* `spawn_at`

Possible outputs:

* `spawned`
* `cleared`
* `all_dead`

#### Light

Controls a light source.

Inputs:

* `on`
* `off`
* `toggle`
* `set_color`
* `set_energy`

#### Sound

Plays or stops a sound.

Inputs:

* `play`
* `stop`
* `set_volume`
* `set_pitch`

#### Prop

Controls a physical object.

Inputs:

* `freeze`
* `unfreeze`
* `apply_impulse`
* `set_visible`
* `destroy`

#### TextPrompt

Shows or hides a simple UI prompt.

Inputs:

* `show`
* `hide`
* `set_text`

The primitive layer only provides the message. The engine owns presentation, layout, styling, animation, and accessibility behavior. Map content should not control UI style directly.

#### MapState

A per-map blackboard for primitive state.

Inputs:

* `set_var`
* `add_var`   (increment/decrement are `add_var ±1`; not separate inputs)
* `add_score`

Possible outputs:

* `var_changed`
* `score_changed`

Game concepts such as objectives, quests, checkpoints, waves, and win conditions should be composed above this layer using `MapState` plus primitive receivers. They should not be primitive receivers themselves.

A checkpoint system implies respawn rules, save serialization, and state restoration, so it belongs to the game mode layer. If only a respawn location is needed, use a simple `SpawnPoint` marker instead.

### Connections

A `Connection` is the only glue object.

It represents one edge from an emitter output to a receiver input.

```gdscript
Connection {
    target: NodePath
    input: StringName
    args: Dictionary
    delay: float = 0.0
    once: bool = false
    filter: ConnectionFilter = null   # fixed-kind predicate, see Runtime / Dispatch
}
```

`delay`, `once`, `filter`, and `args` are fields on the connection. They are not separate graph nodes.

Each emitter output owns a list of connections:

```gdscript
outputs = {
    &"pressed": [
        Connection(target=door, input=&"open", delay=0.0, once=false),
        Connection(target=sound, input=&"play", args={"sound": "button_click"})
    ]
}
```

Dispatch flow (full order in *Runtime / Dispatch → Dispatch order*):

```txt
Emitter output fires
→ each Connection is evaluated independently
→ filter checked, then once consumed on acceptance
→ delivered now, or enqueued if delayed
```

This keeps the wiring model flat, inspectable, and editor-friendly. A button does not need to wire into delay boxes, once boxes, filter boxes, and parameter boxes. It simply owns output rows, each row describing what target input to fire and how.

### Runtime / Dispatch

The data model above (emitters, connections, receivers) describes *what is wired*. This section describes *how a signal travels*. Four owners, no overlap:

```txt
Emitter     owns: when an output fires
Connection  owns: where it goes and with what modifiers
Dispatcher  owns: the boring mechanics of delivering it
Receiver    owns: what an input means
```

The emitter initiates; a shared dispatcher executes; the receiver interprets.

#### The dispatcher lives on `World`

There is no global dispatcher. The dispatcher is an instance on the `World` context — `world.io` — reached through the same `bind(ctx)` injection seam as everything else (ARCHITECTURE.md Rule 2). This is the `commands` field that ARCHITECTURE.md anticipated "when there's a real consumer"; the I/O system is that consumer. Because it is per-`World`, two worlds run side by side with independent buses, and the headless harness builds a fresh one per test.

#### SandboxContext — what travels through a chain

A single value object threads through the entire dispatch, carrying *causality*, not just data:

```gdscript
class_name SandboxContext extends RefCounted

var origin: Node                 # first emitter that started the chain
var emitter: Node                # current emitter firing this output
var activator: Node = null       # entity that caused the original event (may be null)
var output: StringName
var payload: Dictionary = {}     # event-specific data; read-only by convention
var depth: int = 0               # forwarding depth; loop guard

func forwarded(new_emitter: Node, new_output: StringName) -> SandboxContext:
    var n := SandboxContext.new()
    n.origin = origin
    n.emitter = new_emitter
    n.activator = activator
    n.output = new_output
    n.payload = payload          # shared by reference; receivers never mutate it
    n.depth = depth + 1
    return n
```

Naming, by example:

```txt
Player presses Button → Door opens
    origin: Button   emitter: Button   activator: Player

Player presses Button → Counter increments → Counter hits target → Door opens
    origin: Button   emitter: Counter  activator: Player

Crate enters AreaTrigger → Spawner spawns enemy
    origin: AreaTrigger  emitter: AreaTrigger  activator: Crate

Timer fires → Light on
    origin: Timer    emitter: Timer    activator: null   (autonomous; no cause)
```

The **activator is the causal actor, not the sender.** It follows the signal through the whole graph so a downstream filter can ask `activator` who started it, and `MapState.add_score` can know *whose* score. A `null` activator (autonomous emitters like `Timer`) correctly fails any activator-predicate filter.

`SandboxContext extends RefCounted`, which has **no** `duplicate()` — forwarding uses the explicit `forwarded()` fork above, never `Resource.duplicate()`. `payload` is shared by reference and treated as immutable; receivers read it, never write it.

#### Emitter and receiver contracts

```gdscript
# emitter side (shared base/mixin)
func emit_output(output: StringName, activator: Node = null, payload := {}) -> void:
    var ctx := SandboxContext.new()
    ctx.origin = self
    ctx.emitter = self
    ctx.activator = activator
    ctx.output = output
    ctx.payload = payload
    world.io.dispatch(self, output, ctx)

# forwarding emitter (Relay, Logic, Counter) preserves origin + activator
func sandbox_input(input: StringName, args := {}, context: SandboxContext = null) -> void:
    match input:
        &"trigger":
            world.io.dispatch(self, &"triggered", context.forwarded(self, &"triggered"))

# receiver side
func sandbox_input(input: StringName, args := {}, context: SandboxContext = null) -> void:
    match input:
        &"open":
            # reads context.activator / context.payload; mutates neither
            ...
```

#### Loop guard

Connection graphs can cycle (`Button → Relay → Button`, or a Logic gate feeding itself). User maps *will* produce loops, deliberately and not. The context carries `depth`, incremented on every `forwarded()`; the dispatcher refuses delivery past a ceiling:

```txt
if context.depth > MAX_DISPATCH_DEPTH:
    push_warning("sandbox I/O loop guard tripped"); return
```

Without this, the first map with an accidental feedback loop hard-locks the game and the headless suite. It is not optional for a user-content system.

#### Delay is a tick-driven queue, never scene timers

`Connection.delay > 0` cannot deliver synchronously. The dispatcher does **not** call `get_tree().create_timer()` — that would reintroduce a global time source (Rule 2) and make delayed connections untestable in the manually-ticked harness (Rule 3, the same constraint documented for `move_and_slide`). Instead the dispatcher holds a small queue of `(fire_at_tick, connection, context)` and drains it on the `tick(delta)` that `World` already advances.

A headless test fires an output, ticks the world N times, and asserts delivery — delay becomes deterministic.

#### Dispatch order

When an emitter output fires, `world.io` processes each connection independently:

```txt
1. Skip the connection if it is already disabled/fired.
2. Evaluate the connection filter, if present.
3. If the filter fails, stop.
4. If `once` is true, mark the connection fired immediately.
5. If `delay > 0`, enqueue the accepted delivery.
6. Otherwise, deliver immediately.
```

A delayed connection is an accepted event scheduled for later delivery. **Filters are evaluated when the event is accepted (step 2), not when the delay expires.** Likewise `once` is consumed on acceptance (step 4), so spamming a one-shot button queues exactly one delivery — first valid fire wins, the rest are ignored — rather than queueing N delayed one-shots.

If a map needs to check a condition *later*, it must wire that explicitly (`Timer.fired → Sensor.check`, or a gate). Deferred re-evaluation is never smuggled into delay semantics.

#### Filter is constrained exactly like Sensor

`Connection.filter` is the one place a predicate sits on the dispatch hot path — it is a `Sensor` evaluated at delivery time, and carries the same hazard. It must use a **fixed-kind enum** (`by_name`, `by_group`, `by_class`, `by_team`, `var_compare` against `MapState`), never an arbitrary `Resource` with attached script and never a freeform expression. Type it as a small `ConnectionFilter` resource with a `kind` field, mirroring how `Sensor` is constrained. A filter evaluates against `context.activator`; a `null` activator fails every activator-kind filter.
