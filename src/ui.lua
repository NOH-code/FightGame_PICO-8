-- ui.lua : barres de vie, timer, hud

function draw_hud(players)
 rectfill(4,4,4+players[1].health,8,8)
 rect(4,4,104,8,7)
 rectfill(124-players[2].health,4,124,8,12)
 rect(24,4,124,8,7)
 print(flr(match_timer/30), 60, 2, 7)
end
