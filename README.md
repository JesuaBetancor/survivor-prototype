# Parry Survivor — prototype

A survivor-like with **no auto-attack**. Your only offence is a **radial parry
pulse**: press a button, a short window opens, and every enemy inside a radius
that is currently winding up an attack takes the hit. You never aim at anyone —
either they are telegraphing inside the radius, or nothing happens.

This prototype exists to answer **one question**: does the parry feel good?
Everything else is deliberately minimal.

Godot **4.7** · 1280x720 · no sprites, every visual is a drawn geometric shape.

---

## Playing it

**From a build** (no Godot needed):

```bash
open build/ParrySurvivor-macOS/ParrySurvivor.app
```

If it isn't there, run `./build.sh` (needs the 4.7 export templates).

**From source:**

```bash
./run.sh
```

## Handing it to other people

`./build.sh` exports all three platforms and packages them into `build/dist/`:

| Archive | Size | Notes |
|---|---|---|
| `ParrySurvivor-0.1.0-Windows.zip` | 36 MB | single `.exe`, x86_64, pck embedded |
| `ParrySurvivor-0.1.0-Linux.tar.gz` | 27 MB | x86_64; `tar` so the executable bit survives |
| `ParrySurvivor-0.1.0-macOS.zip` | 58 MB | universal (Apple Silicon + Intel) |

Every archive ships a `LEEME.txt` (Spanish — these builds were made for a
specific group of friends) with the controls and how to get past the OS warning.
None of the builds are signed, so all three systems object:

- **Windows** — SmartScreen: *More info* → *Run anyway*.
- **macOS** — Gatekeeper may claim the app is "damaged". It isn't; that's the
  download quarantine flag: `xattr -dr com.apple.quarantine ParrySurvivor.app`.
- **Linux** — `chmod +x` and run.

`build/` is gitignored (~120 MB). Upload the archives somewhere, or attach them
to a GitHub release.

## Controls

| Key | Action |
|---|---|
| `WASD` / arrows | Move (8-directional, constant speed) |
| `Space` or **left click** | Parry |
| `E` | Spawn 3 enemies (debug) |
| `R` | Restart the run |
| `Esc` | Quit |

Parry is bound to both inputs on purpose, so you can feel out which one reads
better without touching code.

---

## Reading the screen

**Silhouette carries the counterplay**, ahead of colour:

| Shape | Type | What to do |
|---|---|---|
| ● Solid red circle | **Fodder** — dies to 1 parry | Parry when it turns yellow |
| ● Large purple circle | **Resistente** — 3 hits, long telegraph | Parry three separate telegraphs |
| ▲ Cyan triangle | **Esquivable** — never parriable | Move. Capped at 5 alive |
| ◎ Pink ring | **Tirador** — fires from 340 px | Dodge the shot, or close in and parry it before it fires |

**Yellow always means "parry now"**, across every parriable type. The ring
closing in on an enemy is the time you have left: when it reaches the body, the
attack lands.

Around the player, the green arc is the parry **cooldown** refilling. The large
ring on a pulse is its **true radius** — green if it connected, grey if it
whiffed, so you can tell a timing mistake from a positioning one.

---

## What to look at

In priority order:

1. **Does the radial pulse hold up?** That's the central bet. The alternative was
   a one-to-one directed parry; switching would be a scope change, not an
   architectural one.
2. **Does the telegraph give enough warning?** 0.8s on fodder. Too much time and
   the game is permissive; never enough and it's unfair.
3. **Is one upgrade obviously better than the others?** Always picking radius
   means the base pulse is too small. Always picking cooldown means it's too
   punishing.
4. **Do 1:05 and 1:30 change anything?** That's when the shooters and the
   triangles unlock. If the rhythm doesn't shift, they need more weight.
5. **Does the hit-stop read as weight, or as a stutter?**

The debug HUD (top left) shows a live **pulse accuracy** percentage. Finishing a
run at 95% means the parry is too easy.

---

## Tuning

Everything below is an `@export`, changeable from the Godot inspector without
touching code.

| To change… | Where |
|---|---|
| Window, radius, cooldown, damage, i-frames | `Player` node in `scenes/main.tscn` |
| Player health | `Player` → `max_health` |
| Telegraph warning, speed, range, hits to kill | That type's `.tres` in `resources/` |
| When a type unlocks and how heavily it spawns | Same `.tres`, *Spawning* group |
| Wave pacing | `Spawner` → `base_interval`, `min_interval`, `ramp_seconds` |
| Hit-stop and shake strength | `Main` node → *Juice* group |
| Arena size | `Arena` → `size` |

Adding an enemy type is **one more `.tres`**, not a new scene — a single
`enemy.tscn` backs all of them.

---

## Layout

```
scenes/     main, player, enemy, projectile, floating_text
scripts/    one script per system, statically typed throughout
resources/  one .tres per enemy type (stats + spawn schedule)
```

Worth reading before changing anything:

- `enemy.gd` — the `Idle → Telegraph → Attack → Recovery` state machine. Only
  `Telegraph` is parriable. It's an enum and a `match`, not a tree of state
  nodes: at survivor-like enemy counts, per-node state objects cost more than
  they clarify.
- `player.gd` — the parry pulse. The `Area2D` monitors **continuously** and the
  pulse is purely logical. Switching monitoring on at press time would cost a
  physics frame of latency in the one place that can't afford it.
- `upgrades.gd` — the upgrade pool and its caps. The damage cap is derived from
  the roster rather than fixed, so the toughest enemy always costs at least two
  parries.
- `sfx.gd` — **placeholder audio synthesised at runtime**. There is not a single
  sound asset in this repo; replace these before anyone else hears them.

## Deliberately out of scope

No store packaging, no final art, no main menu, no save system. The roster has
four types — one more than originally planned; the shooter was added so the
pulse-radius upgrade had something to do.

Ideas parked for after the prototype live in [BACKLOG.md](BACKLOG.md).
