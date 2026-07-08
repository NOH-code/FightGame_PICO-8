# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

The repo is a **PICO-8 fighting game skeleton, not yet scaffolded**. It currently holds a single design document — [Architecture_Base_FightingGame_PICO8.md](Architecture_Base_FightingGame_PICO8.md) — written in French, which specifies the intended structure and provides working placeholder code for every module. Nothing has been created from it yet (no `main.p8`, no `src/`). That document is the source of truth; treat CLAUDE.md as a summary and defer to it for the actual code snippets.

Project notes and comments are written in **French** — match that language when editing code comments or docs.

## PICO-8 workflow (critical constraints)

- Code is split across external `.lua` files pulled into `main.p8` via `#include`. PICO-8 re-reads these files on every `run`, so you edit `.lua` in the IDE, then `run` in PICO-8 — no copy-paste back into the cart.
- **Assets cannot be externalized.** Sprites, map, SFX, and music live in the `__gfx__` / `__map__` / `__sfx__` / `__music__` sections of `main.p8` and are only editable with PICO-8's built-in editors (`Esc` → sprite/map/sfx/music tabs). Only the `__lua__` section is externalized. Never hand-write or hand-edit those binary-ish sections.
- **Do not create `main.p8` from scratch.** Generate it by running `save main.p8` on an empty cart inside PICO-8 (produces correctly-formatted empty sections), then replace the `__lua__` section body with the `#include src/*.lua` lines and leave the other sections as generated.
- To test: `load main.p8` then `run` inside PICO-8.

## Architecture

`_boot.lua` defines PICO-8's `_init` / `_update` / `_draw` entry points and dispatches on a single global `game_state` string through the state machine:

```
title → select → match ⇄ pause,  match → results → select
```

Each state has an `update_<state>()` / `draw_<state>()` pair in `_boot.lua`. The match loop reads input, updates each fighter, then runs `check_hit()` in both directions.

Module responsibilities (files under `src/`, included in this order in `main.p8`):

- **_boot.lua** — orchestration + global state machine; owns `players` and `game_state`.
- **input.lua** — `read_inputs(f)` maps PICO-8 buttons to a per-fighter `input` table. Player index: `0` = P1, `1` = P2. Controller detection is automatic; nothing to init.
- **fighter.lua** — per-character state machine (`idle`/`walk`/`attack_light`/`attack_heavy`/`hitstun`) and physics. `new_fighter(x, facing)` builds a fighter; `facing` is `1` (right) / `-1` (left) and currently also derives `player_index`.
- **combat.lua** — hitbox/hurtbox overlap (`rects_overlap`) and damage application. Clears the attacker's hitbox on a landed hit to prevent multi-hit within one active frame.
- **stage.lua**, **ui.lua**, **audio.lua** — background/bounds, health bars/timer/HUD, and sfx/music triggers.
- **data.lua** — intended home for movesets and frame data (`startup`/`active`/`recovery`/`damage` per move), keyed by character. Currently an empty stub.

### Deliberately deferred (do not treat as bugs)

These are intentional placeholders per the design doc, to validate the technical pipeline before investing in content:

- Frame data and damage are **hardcoded** in `fighter.lua` / `combat.lua`; migrate them into `data.lua` once movesets are defined.
- `new_fighter()` has no character identity — a `character_id` param is planned once the roster is fixed.
- `draw_fighter()` draws a colored rectangle; replace with `spr()`/`sspr()` once sprites exist.
