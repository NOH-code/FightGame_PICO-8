-- input.lua : lecture manettes / clavier
-- pico-8 : jusqu'à 8 joueurs, 6 boutons natifs (gauche,droite,haut,bas,o,x)
-- index joueur pico-8 : 0 = p1, 1 = p2

function init_input()
 -- rien à initialiser : la détection manette est automatique côté pico-8
end

-- btn()  = maintenu (déplacement, garde)
-- btnp() = pressé cette frame (attaques : évite l'auto-répétition)
-- 2 boutons d'action seulement : o=light, x=heavy, o+x même frame=medium
-- (la résolution o+x vs o seul se fait dans fighter.lua, medium testé en premier)
function read_inputs(f)
 local idx = f.player_index
 f.input = {
  left  = btn(0, idx),
  right = btn(1, idx),
  up    = btn(2, idx), -- pas encore utilisé : réservé pour le saut
  down  = btn(3, idx),
  light = btnp(4, idx), -- bouton o
  heavy = btnp(5, idx), -- bouton x
 }
end
