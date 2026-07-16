-- stage.lua : décor et limites du terrain
-- stage unique et fixe (pas de scroll), ambiance street caribéenne au couchant :
-- le décor (façades, tôle, guirlande d'ampoules, bitume) vient désormais de la
-- map pico-8 (tuiles 8x8), dessinée par-dessus le ciel procédural.
-- palette : ciel réservé 9 (orange) + 2 (violet foncé) ; linge 8/10/12.

-- le sol est à y=96 : c'est la ligne sur laquelle new_fighter() pose les persos
ground_y = 96

-- bornes horizontales, cohérentes avec le mid(12, f.x, 116) de update_fighter
stage_left  = 12
stage_right = 116

function init_stage() end

function draw_stage()
 draw_sky()

 -- décor tuilé (façades, tôle, guirlande d'ampoules, bitume) : map 16x16
 -- stockée en (0,0) de la mémoire map. la tuile 0 est vide : le ciel reste
 -- visible à travers.
 palt(14,true) -- 14 = transparence des tuiles
 palt(0,false) -- le noir reste opaque (contours)
 map(0,0, 0,0, 16,16)
 palt() -- restaure la transparence par défaut

 -- ligne de linge tendue entre les deux bâtiments, par-dessus le décor tuilé
 line(40, 66, 76, 70, 6)
 draw_cloth(48, 67, 8)
 draw_cloth(58, 68, 12)
 draw_cloth(68, 69, 10)
end

-- ciel de fin de journée : violet foncé en haut vers orange à l'horizon,
-- bande centrale tramée (fillp damier) pour un faux dégradé à 2 couleurs
function draw_sky()
 rectfill(0, 0, 127, 13, 2)
 fillp(0b0101101001011010)
 rectfill(0, 14, 127, 21, 0x29)
 fillp()
 -- l'orange descend jusqu'au sol : la map ne couvre pas la trouée entre les
 -- bâtiments (tuile 0), sans ce fond on verrait le noir du cls()
 rectfill(0, 22, 127, 95, 9)
end

-- petit vêtement suspendu à la ligne de linge
function draw_cloth(x, y, col)
 rectfill(x, y, x+3, y+4, col)
end
