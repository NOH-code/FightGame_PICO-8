pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- fighting game (noh-dev)
-- le code vit dans src/*.lua, relu par pico-8 à chaque `run`
-- les assets (gfx/map/sfx/music) vivent dans ce cart, via les éditeurs intégrés

#include src/_boot.lua
#include src/input.lua
#include src/fighter.lua
#include src/combat.lua
#include src/stage.lua
#include src/ui.lua
#include src/audio.lua
#include src/data.lua
