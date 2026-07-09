-- stage.lua : décor et limites du terrain
-- stage unique et fixe (pas de scroll), ambiance street caribéenne au couchant :
-- façades pastel délavées, clôture en tôle ondulée, linge suspendu, mur tagué,
-- palmier en silhouette, bitume craquelé.
-- palette : ciel réservé 9 (orange) + 2 (violet foncé) ; façades 14/15/12 ;
-- tôle et bitume 5/6 ; accents linge 8/10/12 ; silhouettes et fissures 0

-- le sol est à y=96 : c'est la ligne sur laquelle new_fighter() pose les persos
ground_y = 96

-- bornes horizontales, cohérentes avec le mid(8, f.x, 120) de update_fighter
stage_left  = 8
stage_right = 120

function init_stage() end

function draw_stage()
 draw_sky()
 draw_palm()      -- avant les façades : le palmier reste derrière la tôle
 draw_buildings()
 draw_ground()
end

-- ciel de fin de journée : violet foncé en haut vers orange à l'horizon,
-- bande centrale tramée (fillp damier) pour un faux dégradé à 2 couleurs
function draw_sky()
 rectfill(0, 0, 127, 13, 2)
 fillp(0b0101101001011010)
 rectfill(0, 14, 127, 21, 0x29)
 fillp()
 rectfill(0, 22, 127, 55, 9)
 circfill(20, 18, 4, 10) -- soleil bas
end

-- silhouette de palmier découpée sur le couchant
function draw_palm()
 line(108, 66, 106, 52, 0) -- tronc légèrement incurvé
 line(106, 52, 105, 42, 0)
 line(105, 42, 96, 38, 0)  -- palmes
 line(105, 42, 98, 46, 0)
 line(105, 42, 112, 36, 0)
 line(105, 42, 114, 44, 0)
 line(105, 42, 104, 34, 0)
end

function draw_buildings()
 -- façade rose fané, fenêtres sombres
 rectfill(0, 52, 30, 96, 14)
 rectfill(0, 52, 30, 54, 4) -- corniche
 for wx=4,24,10 do
  rectfill(wx, 60, wx+4, 66, 2)
  rectfill(wx, 74, wx+4, 80, 2)
 end

 -- façade ocre plus haute, mur tagué
 rectfill(31, 46, 62, 96, 15)
 rectfill(31, 46, 62, 48, 4)
 rectfill(36, 56, 42, 64, 1)
 rectfill(50, 56, 56, 64, 1)
 print("noh", 41, 78, 8)   -- tag bombé
 line(38, 86, 56, 86, 12)  -- trait de bombe sous le tag

 -- façade turquoise passée, porte en bois
 rectfill(63, 56, 92, 96, 12)
 rectfill(63, 56, 92, 58, 1)
 rectfill(68, 64, 73, 71, 1)
 rectfill(80, 64, 85, 71, 1)
 rectfill(72, 82, 80, 96, 4)

 -- clôture en tôle ondulée (stries verticales)
 rectfill(93, 66, 127, 96, 5)
 for x=94,126,4 do line(x, 68, x, 95, 6) end
 line(93, 66, 127, 66, 6)

 -- ligne de linge tendue en travers des deux premières façades
 line(8, 55, 48, 50, 6)
 draw_cloth(16, 54, 8)
 draw_cloth(26, 53, 12)
 draw_cloth(38, 51, 10)
end

-- petit vêtement suspendu à la ligne de linge
function draw_cloth(x, y, col)
 rectfill(x, y, x+3, y+4, col)
end

-- sol : bitume craquelé
function draw_ground()
 rectfill(0, ground_y+1, 127, 127, 5)
 line(0, ground_y, 127, ground_y, 6)
 line(14, 104, 22, 110, 0) -- fissures
 line(22, 110, 20, 118, 0)
 line(60, 100, 68, 106, 0)
 line(96, 108, 88, 116, 0)
 line(40, 120, 50, 124, 0)
end
