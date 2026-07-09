# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

A **playable vertical slice**: `main.p8` + all eight `src/*.lua` modules exist. Two characters with distinct archetypes walk, attack, take damage, and the match ends on K.O. or timeout.

Three French design docs drive the work and are the source of truth for intent:
- [Architecture_Base_FightingGame_PICO8.md](Architecture_Base_FightingGame_PICO8.md) — module layout and baseline code
- [Roadmap_Setup_FightingGame_PICO8.md](Roadmap_Setup_FightingGame_PICO8.md) — env, stack, milestones
- [Elements_A_Definir_FightingGame_PICO8.md](Elements_A_Definir_FightingGame_PICO8.md) — remaining game-design decisions

Note the shipped code has **moved past** the architecture doc's snippets (data-driven moves, a generic `attack` state, match-end rules). Trust `src/` over the doc where they disagree.

Project notes and comments are written in **French** — match that language when editing code comments or docs.

## PICO-8 workflow (critical constraints)

- Code is split across external `.lua` files pulled into `main.p8` via `#include`. PICO-8 re-reads these files on every `run`, so you edit `.lua` in the IDE, then `run` in PICO-8 — no copy-paste back into the cart.
- **Assets cannot be externalized.** Sprites, map, SFX, and music live in the `__gfx__` / `__map__` / `__sfx__` / `__music__` sections of `main.p8` and are only editable with PICO-8's built-in editors (`Esc` → sprite/map/sfx/music tabs). Only the `__lua__` section is externalized. Never hand-write or hand-edit those binary-ish sections.
- `main.p8` currently has **no asset sections at all** — only a header and `__lua__` with the `#include` lines. PICO-8 treats absent sections as empty and writes them back, correctly formatted, on the first `save main.p8`. Never hand-write or hand-edit those sections; let PICO-8 generate them.
- To test: `load main.p8` then `run` inside PICO-8.

Nothing here can be built, linted, or tested from the command line — PICO-8 is the only runtime, and it is a GUI application. Verifying a change means running the cart.

## Architecture

`_boot.lua` defines PICO-8's `_init` / `_update` / `_draw` entry points and dispatches on a single global `game_state` string through the state machine:

```
title → select → match ⇄ pause,  match → results → select
```

Each state has an `update_<state>()` / `draw_<state>()` pair in `_boot.lua`. The match loop reads input, updates each fighter, then runs `check_hit()` in both directions.

Module responsibilities (files under `src/`, included in this order in `main.p8`):

- **_boot.lua** — orchestration + global state machine; owns `players` and `game_state`.
- **input.lua** — `read_inputs(f)` maps PICO-8 buttons to a per-fighter `input` table. Player index: `0` = P1, `1` = P2. Controller detection is automatic; nothing to init.
- **fighter.lua** — per-character state machine (`idle`/`walk`/`attack`/`hitstun`) and physics. `new_fighter(x, facing, character_id)`; `facing` is `1` (right) / `-1` (left) and also derives `player_index`.
- **combat.lua** — hitbox/hurtbox overlap (`rects_overlap`) and damage application. Clears **both** fighters' hitboxes on a landed hit: the attacker's to prevent multi-hit within one active frame, the defender's so an interrupted attack doesn't leave a hitbox that outlives hitstun.
- **stage.lua**, **ui.lua**, **audio.lua** — background/bounds (`ground_y = 96`), health bars/timer, and sfx index constants (`sfx_hit`, …).
- **data.lua** — `characters[0]` = `volt` (rush-down), `characters[1]` = `torque` (zoner), plus `round_time`. Each move carries `startup`/`active`/`recovery`/`damage`/`range`/`hy`/`size`.

### Key design decision

There is **one generic `attack` state**, not one state per move. `update_fighter()` selects a move table from `characters[id].moves` and stores it in `f.current_move`; `update_attack(f, move)` drives startup/active/recovery from that table. Adding a move means adding data, not code — preserve this when extending.

Balance and match rules live entirely in `data.lua`. Tuning the game should not require touching `fighter.lua`.

### Deliberately deferred (do not treat as bugs)

- `draw_fighter()` draws a colored rectangle; replace with `spr()`/`sspr()` once sprites exist.
- SFX indices are reserved in `audio.lua` but no sounds are drawn yet — `sfx()` on an empty slot is silent, not a crash.
- `_boot.lua` has a `pause` state but nothing transitions into it (PICO-8 reserves its own pause menu).
- Jump, block, and knockdown appear in the design doc's state machine but are not implemented.
