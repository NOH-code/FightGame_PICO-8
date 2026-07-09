-- ui.lua : barres de vie, indicateurs de rounds, timer

function draw_hud(players)
 -- p1 : barre ancrée à gauche, p2 : ancrée à droite (se vident vers le centre)
 draw_health_bar(4,  players[1], 8,  false)
 draw_health_bar(72, players[2], 12, true)
 draw_round_pips(7,   1,  rounds_won[1])
 draw_round_pips(120, -1, rounds_won[2])
 -- timer borné à 0 : jamais de valeur négative à l'écran en fin de round
 local t = flr(max(0, match_timer)/30)
 print(t, t>9 and 60 or 62, 3, 7)
end

-- barre de vie : bordure fixe toujours affichée, remplissage proportionnel
-- à la vie courante (50px utiles), jamais de largeur négative (vie bornée à 0)
function draw_health_bar(x, p, col, from_right)
 rect(x, 4, x+51, 8, 7)
 local w = flr(50 * max(0, p.health) / p.max_health)
 if w>0 then
  if from_right then
   rectfill(x+51-w, 5, x+50, 7, col)
  else
   rectfill(x+1, 5, x+w, 7, col)
  end
 end
end

-- pastilles de rounds gagnés au-dessus de chaque barre (pleine = round gagné),
-- dir=-1 pour p2 : les pastilles se déploient en miroir depuis le bord droit
function draw_round_pips(x, dir, won)
 for i=1,rounds_to_win do
  local cx = x + (i-1)*6*dir
  if i<=won then circfill(cx, 2, 1, 7) else circ(cx, 2, 1, 5) end
 end
end
