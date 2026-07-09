# 🥋 Fighting Game — PICO-8 (NOH-DEV)

Prototype de jeu de combat 1v1 local, écrit en Lua pour [PICO-8](https://www.lexaloffle.com/pico-8.php).

État actuel : **vertical slice jouable** — deux personnages aux archétypes distincts se déplacent, se frappent, et le match se termine sur K.O. ou fin du timer.

## Lancer le jeu

Prérequis : PICO-8 installé (licence payante, ~15 $).

```
pico8
> cd /chemin/vers/FightGame_PICO-8
> load main.p8
> run
```

`Esc` met en pause / ouvre les éditeurs intégrés, `Esc` à nouveau revient à la console.

## Contrôles

Mapping clavier par défaut de PICO-8 (`Player 1 : Cursors + ZX/NM/CV`, `Player 2 : SDFE + tab,Q / shift A`) :

| Action | P1 (clavier) | P2 (clavier) |
|---|---|---|
| Gauche / Droite | `←` / `→` | `S` / `F` |
| Bas | `↓` | `D` |
| Coup léger (bouton O) | `Z` / `C` / `N` | `Tab` / `LShift` |
| Coup lourd (bouton X) | `X` / `V` / `M` | `Q` / `A` |
| Coup bas | Bas + léger | Bas + léger |

Les manettes sont détectées automatiquement par PICO-8, sans configuration. Pour remapper : commande `keyconfig` dans la console PICO-8.

## Personnages

Définis dans [src/data.lua](src/data.lua) — modifier les chiffres suffit à réequilibrer le jeu.

| Perso | Archétype | Vitesse | Portée | Dégâts |
|---|---|---|---|---|
| `volt` | Rush-down | Rapide (2.0) | Courte | Faibles |
| `torque` | Zoner | Lent (0.8) | Longue | Élevés |

Règles de match : 1 round, 60 secondes (`round_time` dans `data.lua`), 100 PV chacun.

## Structure

Le code est externalisé dans `src/*.lua` et agrégé par `main.p8` via `#include`. PICO-8 relit ces fichiers à chaque `run` : on édite dans son IDE, on tape `run` dans PICO-8, sans copier-coller.

```
main.p8          ← cart : #include + assets (gfx/map/sfx/music)
src/
  _boot.lua      ← _init/_update/_draw, machine à états globale, règles de match
  input.lua      ← lecture manettes P1/P2
  fighter.lua    ← state machine + physique d'un perso
  combat.lua     ← collisions hitbox/hurtbox, dégâts
  stage.lua      ← décor, sol, limites
  ui.lua         ← barres de vie, timer
  audio.lua      ← index sfx, musique
  data.lua       ← personnages et frame data
```

⚠️ Les sprites, la map, les SFX et la musique **ne peuvent pas** être externalisés : ils vivent dans les sections `__gfx__` / `__map__` / `__sfx__` / `__music__` de `main.p8` et s'éditent uniquement via les éditeurs intégrés de PICO-8 (`Esc` → onglets).

## Documentation

- [Architecture_Base_FightingGame_PICO8.md](Architecture_Base_FightingGame_PICO8.md) — architecture et code de base
- [Roadmap_Setup_FightingGame_PICO8.md](Roadmap_Setup_FightingGame_PICO8.md) — environnement, stack, jalons
- [Elements_A_Definir_FightingGame_PICO8.md](Elements_A_Definir_FightingGame_PICO8.md) — décisions de game design restantes

## Prochaines étapes

Placeholders assumés, à traiter dans cet ordre (cf. roadmap) :

- Sprites — `draw_fighter()` dessine un rectangle coloré, à remplacer par `spr()`/`sspr()`
- SFX — les index sont réservés dans `audio.lua`, les sons restent à dessiner
- États manquants — saut, garde, knockdown (prévus dans la state machine du doc)
- Transition `pause` — l'état existe dans `_boot.lua` mais aucun bouton ne le déclenche
- Export HTML5 (`export game.html`) pour intégration portfolio
