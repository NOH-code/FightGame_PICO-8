-- _boot.lua : orchestration principale + règles de match (1 round simple, décidé en phase a)

game_state = "title" -- title | select | match | pause | results
players = {}
winner = nil
match_timer = 0

function _init()
 init_input()
 init_stage()
 init_audio()
end

function _update()
 if game_state == "title" then update_title()
 elseif game_state == "select" then update_select()
 elseif game_state == "match" then update_match()
 elseif game_state == "pause" then update_pause()
 elseif game_state == "results" then update_results()
 end
end

function _draw()
 cls()
 if game_state == "title" then draw_title()
 elseif game_state == "select" then draw_select()
 elseif game_state == "match" then draw_match()
 elseif game_state == "pause" then draw_pause()
 elseif game_state == "results" then draw_results()
 end
end

function update_title() if btnp(4) or btnp(4,1) then game_state="select" end end
function draw_title() print("fighting game proto", 28, 60, 7) end

function update_select() if btnp(4) then start_match() end end
function draw_select() print("select : appuyez sur o", 18, 60, 7) end

function update_pause() if btnp(4) then game_state="match" end end
function draw_pause() print("pause", 50, 60, 7) end

function update_results()
 if btnp(4) then game_state="select" end
end

function draw_results()
 if winner==0 then
  print("egalite / double ko", 24, 55, 7)
 else
  print("joueur "..winner.." gagne !", 26, 55, 7)
 end
 print("o pour rejouer", 32, 70, 6)
end

function start_match()
 -- 0 = volt (rush-down), 1 = torque (zoner) — cf. characters[] dans data.lua
 players = { new_fighter(30, 1, 0), new_fighter(90, -1, 1) }
 match_timer = round_time -- défini dans data.lua
 winner = nil
 game_state = "match"
end

function update_match()
 match_timer -= 1

 for p in all(players) do
  read_inputs(p)
  update_fighter(p)
 end
 check_hit(players[1], players[2])
 check_hit(players[2], players[1])

 if players[1].health<=0 or players[2].health<=0 or match_timer<=0 then
  end_match()
 end
end

function end_match()
 local h1, h2 = players[1].health, players[2].health
 if h1<=0 and h2<=0 then winner=0
 elseif h1<=0 then winner=2
 elseif h2<=0 then winner=1
 elseif h1==h2 then winner=0
 else winner = (h1>h2) and 1 or 2
 end
 game_state = "results"
end

function draw_match()
 draw_stage()
 for p in all(players) do draw_fighter(p) end
 draw_hud(players)
end
