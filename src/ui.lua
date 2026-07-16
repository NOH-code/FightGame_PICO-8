-- ui.lua : barres de vie, indicateurs de rounds, timer, noms
-- géométrie calée sur la maquette : barres crème/noir/vert, pastilles de
-- rounds au-dessus côté intérieur, gros timer central, noms en bas d'écran

function draw_hud(players)
 -- p1 : barre ancrée à gauche (x=4), p2 : ancrée à droite (x=72, se vide vers le centre)
 draw_health_bar(4,  players[1], false)
 draw_health_bar(72, players[2], true)
 -- pastilles côté intérieur : p1 se remplit vers la droite, p2 vers la gauche
 draw_round_pips(40, 1,  rounds_won[1])
 draw_round_pips(84, -1, rounds_won[2])
 draw_timer()
 draw_names(players)
end

-- barre de vie : liseré crème externe, double bordure noire, remplissage vert
-- proportionnel (46px utiles), jamais de largeur négative (vie bornée à 0)
function draw_health_bar(x, p, from_right)
 rect(x,   5,  x+51, 13, 15) -- liseré crème externe
 rect(x+1, 6,  x+50, 12, 0)  -- bordure noire
 rect(x+2, 7,  x+49, 11, 0)  -- bordure noire (2e trait)
 local w = flr(46 * max(0, p.health) / p.max_health)
 if w >= 1 then
  if from_right then
   rectfill(x+49-w+1, 8, x+49, 10, 11) -- p2 : se vide vers le centre
  else
   rectfill(x+3, 8, x+3+w-1, 10, 11)
  end
 end
end

-- pastilles de rounds gagnés au-dessus de la barre, côté intérieur.
-- base = position de la 1ère pastille, dir = sens de remplissage (+1 p1, -1 p2)
function draw_round_pips(base, dir, won)
 for i=1,rounds_to_win do
  local px = base + (i-1)*8*dir
  if i <= won then
   circfill(px, 2, 1, 11)
  else
   circfill(px, 2, 1, 5)
  end
  circ(px, 2, 1, 0)
 end
end

-- gros timer centré, chiffres double largeur/hauteur (p8scii natif 0.2.5g)
function draw_timer()
 local t = flr(max(0, match_timer)/30)
 local x0 = (t>9) and 56 or 60
 print("\^w\^t"..t, x0+1, 5, 0)  -- ombre
 print("\^w\^t"..t, x0,   5, 15)
end

-- noms des combattants, bas d'écran : p1 aligné à gauche, p2 à droite
function draw_names(players)
 local n1 = characters[players[1].character_id].name
 print(n1, 9, 113, 0) -- ombre
 print(n1, 8, 112, 15)

 local n2 = characters[players[2].character_id].name
 local x2 = 120 - #n2*4
 print(n2, x2+1, 113, 0) -- ombre
 print(n2, x2,   112, 15)
end
