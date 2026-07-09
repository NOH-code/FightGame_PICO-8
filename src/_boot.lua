-- _boot.lua : orchestration principale, machine à états globale, logique de match
-- format de match : best-of-3, premier joueur à rounds_to_win rounds (cf. data.lua)

game_state = "title" -- title | select | round_intro | match | pause | results
players = {}
winner = nil      -- vainqueur du match : 1, 2, ou 0 (match nul)
match_timer = 0
round_num = 1
rounds_won = {0,0}
intro_timer = 0

function _init()
 init_input()
 init_stage()
 init_audio()
end

function _update()
 if game_state == "title" then update_title()
 elseif game_state == "select" then update_select()
 elseif game_state == "round_intro" then update_round_intro()
 elseif game_state == "match" then update_match()
 elseif game_state == "pause" then update_pause()
 elseif game_state == "results" then update_results()
 end
end

function _draw()
 cls()
 if game_state == "title" then draw_title()
 elseif game_state == "select" then draw_select()
 elseif game_state == "round_intro" then draw_round_intro()
 elseif game_state == "match" then draw_match()
 elseif game_state == "pause" then draw_pause()
 elseif game_state == "results" then draw_results()
 end
end

function update_title() if btnp(4) or btnp(4,1) then game_state="select" end end
function draw_title() print("fighting game proto", 28, 60, 7) end

function update_select() if btnp(4) then start_match() end end
function draw_select() print("select : appuyez sur o", 18, 60, 7) end

-- etat pause : conservé mais non câblé — pico-8 réserve enter à son propre menu
function update_pause() if btnp(4) then game_state="match" end end
function draw_pause() print("pause", 50, 60, 7) end

function update_results()
 if btnp(4) then game_state="select" end
end

function draw_results()
 if winner==0 then
  print("egalite !", 46, 48, 7)
 else
  print("joueur "..winner.." gagne le match !", 8, 48, 7)
 end
 print("score : "..rounds_won[1].." - "..rounds_won[2], 38, 60, 6)
 print("o pour rejouer", 36, 76, 5)
end

-- démarre un MATCH : remet les scores de rounds à zéro puis lance le round 1
function start_match()
 -- 0 = volt (rush-down), 1 = torque (zoner) — cf. characters[] dans data.lua
 rounds_won = {0,0}
 round_num = 1
 winner = nil
 start_round()
end

-- (re)lance un ROUND : vie au max et positions de départ réinitialisées
-- (p1 à gauche, p2 à droite), le compteur de rounds gagnés est conservé
function start_round()
 players = { new_fighter(34, 1, 0), new_fighter(94, -1, 1) }
 match_timer = round_time
 intro_timer = 0
 game_state = "round_intro"
end

-- affiche "round n" pendant 60 frames avant de rendre la main aux joueurs
function update_round_intro()
 intro_timer += 1
 if intro_timer > 60 then game_state = "match" end
end

function draw_round_intro()
 draw_match()
 print("round "..round_num, 50, 48, 7)
end

function update_match()
 match_timer -= 1

 update_facing(players[1], players[2])
 update_facing(players[2], players[1])

 for p in all(players) do
  read_inputs(p)
  update_fighter(p)
 end

 -- p1 évalué d'abord : sur coups strictement simultanés, priorité assumée à p1
 check_hit(players[1], players[2])
 check_hit(players[2], players[1])
 separate_bodies(players[1], players[2])

 if players[1].health<=0 or players[2].health<=0 or match_timer<=0 then
  end_round()
 end
end

-- fin de ROUND, distincte de la fin de MATCH : on attribue le round, et le match
-- ne se termine que si un joueur atteint rounds_to_win ou que max_rounds sont joués
function end_round()
 local h1, h2 = players[1].health, players[2].health
 local rw = 0 -- 0 = round nul (double ko, ou vies égales au timeout)
 if h1<=0 and h2<=0 then rw=0
 elseif h1<=0 then rw=2
 elseif h2<=0 then rw=1
 elseif h1==h2 then rw=0
 else rw = (h1>h2) and 1 or 2
 end
 if rw>0 then rounds_won[rw] += 1 end
 if h1<=0 or h2<=0 then sfx(sfx_ko) end

 if rounds_won[1]>=rounds_to_win or rounds_won[2]>=rounds_to_win
    or round_num>=max_rounds then
  -- règle de repli : si personne n'atteint rounds_to_win après max_rounds joués
  -- (rounds nuls possibles), le plus de rounds gagnés l'emporte ;
  -- égalité parfaite → match nul (winner=0)
  if rounds_won[1]==rounds_won[2] then winner=0
  else winner = (rounds_won[1]>rounds_won[2]) and 1 or 2 end
  game_state = "results"
 else
  round_num += 1
  start_round()
 end
end

function draw_match()
 draw_stage()
 for p in all(players) do draw_fighter(p) end
 draw_hud(players)
end
