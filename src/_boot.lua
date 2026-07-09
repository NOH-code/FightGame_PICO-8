-- _boot.lua : orchestration principale, machine à états globale, logique de match
-- format de match : best-of-3, premier joueur à rounds_to_win rounds (cf. data.lua)

game_state = "title" -- title | controls | select | round_intro | match | pause | results
players = {}
winner = nil      -- vainqueur du match : 1, 2, ou 0 (match nul)
match_timer = 0
round_num = 1
rounds_won = {0,0}
intro_timer = 0
title_cursor = 1
title_options = {"start", "controles"}
roster = {}  -- ids de characters[] jouables, construit par init_select
sel = nil    -- curseur + confirmation par joueur (cf. init_select)

function _init()
 init_input()
 init_stage()
 init_audio()
end

function _update()
 if game_state == "title" then update_title()
 elseif game_state == "controls" then update_controls()
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
 elseif game_state == "controls" then draw_controls()
 elseif game_state == "select" then draw_select()
 elseif game_state == "round_intro" then draw_round_intro()
 elseif game_state == "match" then draw_match()
 elseif game_state == "pause" then draw_pause()
 elseif game_state == "results" then draw_results()
 end
end

-- écran titre : options navigables haut/bas, o pour valider (p1 ou p2)
function update_title()
 if btnp(2) or btnp(2,1) then title_cursor = max(1, title_cursor-1); sfx(sfx_cursor) end
 if btnp(3) or btnp(3,1) then title_cursor = min(#title_options, title_cursor+1); sfx(sfx_cursor) end
 if btnp(4) or btnp(4,1) then
  sfx(sfx_menu)
  if title_cursor == 1 then
   init_select()
   game_state = "select"
  else
   game_state = "controls"
  end
 end
end

function draw_title()
 print("fighting game", 38, 32, 7)
 print("noh-dev", 50, 40, 6)
 for i,opt in ipairs(title_options) do
  local y = 68 + (i-1)*10
  if i == title_cursor then print(">", 44, y, 8) end
  print(opt, 52, y, i==title_cursor and 7 or 5)
 end
end

-- écran des contrôles (mapping clavier par défaut de pico-8)
function update_controls()
 if btnp(4) or btnp(4,1) or btnp(5) or btnp(5,1) then
  sfx(sfx_menu)
  game_state = "title"
 end
end

function draw_controls()
 print("controles", 46, 8, 7)
 print("p1", 12, 24, 11)
 print("bouger : fleches", 12, 32, 6)
 print("o: z/c/n   x: x/v/m", 12, 40, 6)
 print("p2", 12, 56, 9)
 print("bouger : s,d,f", 12, 64, 6)
 print("o: tab/lshift   x: q/a", 12, 72, 6)
 print("o=leger  x=lourd", 12, 88, 5)
 print("o+x ensemble = coup moyen", 12, 96, 5)
 print("o ou x : retour", 36, 116, 5)
end

-- sélection de personnage, générique : roster construit depuis characters[],
-- un curseur + un flag confirmé par joueur — scale sans changement quand
-- le roster grandira (aucun "2 persos" codé en dur)
function init_select()
 roster = {}
 local i = 0
 while characters[i] do add(roster, i); i += 1 end
 sel = {
  {cursor=1, ok=false},
  {cursor=min(2, #roster), ok=false}, -- p2 démarre sur le 2e perso s'il existe
 }
end

function update_select()
 for pi=1,2 do
  local s = sel[pi]
  local idx = pi-1 -- index manette pico-8 (0=p1, 1=p2)
  if not s.ok then
   if btnp(0,idx) then s.cursor = (s.cursor-2) % #roster + 1; sfx(sfx_cursor) end
   if btnp(1,idx) then s.cursor = s.cursor % #roster + 1; sfx(sfx_cursor) end
   if btnp(4,idx) then s.ok = true; sfx(sfx_menu) end
  elseif btnp(5,idx) then
   s.ok = false; sfx(sfx_cursor) -- x : revenir sur sa confirmation
  end
 end
 -- le combat démarre quand les deux joueurs ont confirmé (miroir autorisé)
 if sel[1].ok and sel[2].ok then start_match() end
end

function draw_select()
 print("selection des combattants", 14, 8, 7)
 local n, w = #roster, 28
 local x0 = 64 - flr(n*w/2)
 for i,cid in ipairs(roster) do
  local x = x0 + (i-1)*w
  rect(x, 44, x+w-4, 66, 5)
  print(characters[cid].name, x+3, 53, 7)
 end
 draw_select_cursor(1, x0, w, 36, 11)
 draw_select_cursor(2, x0, w, 70, 9)
 print("fleches: choisir  o: valider", 8, 100, 5)
 print("x: annuler sa selection", 18, 108, 5)
end

-- marqueur d'un joueur au-dessus (p1) ou en dessous (p2) de la case visée
function draw_select_cursor(pi, x0, w, y, col)
 local s = sel[pi]
 local x = x0 + (s.cursor-1)*w + 4
 print("p"..pi, x, y, col)
 if s.ok then print("ok", x+10, y, 7) end
end

-- etat pause : conservé mais non câblé — pico-8 réserve enter à son propre menu
function update_pause() if btnp(4) then game_state="match" end end
function draw_pause() print("pause", 50, 60, 7) end

function update_results()
 if btnp(4) or btnp(4,1) then
  sfx(sfx_menu)
  init_select() -- repartir sur une sélection fraîche (confirmations annulées)
  game_state = "select"
 end
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
 rounds_won = {0,0}
 round_num = 1
 winner = nil
 start_round()
end

-- (re)lance un ROUND : vie au max et positions de départ réinitialisées
-- (p1 à gauche, p2 à droite), le compteur de rounds gagnés est conservé
function start_round()
 players = {
  new_fighter(34,  1, roster[sel[1].cursor]),
  new_fighter(94, -1, roster[sel[2].cursor]),
 }
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
