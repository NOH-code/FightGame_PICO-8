-- fighter.lua : state machine + physique, pilotée par characters[] (data.lua)

function new_fighter(x, facing, character_id)
 local c = characters[character_id]
 return {
  x=x, y=96, facing=facing,
  player_index = (facing==1) and 0 or 1,
  character_id = character_id,
  speed = c.speed,
  state="idle", timer=0,
  health=c.health,
  hurtbox={x=-4,y=-16,w=8,h=16},
  hitbox=nil,
  current_move=nil,
  input={},
 }
end

function update_fighter(f)
 f.timer += 1
 local c = characters[f.character_id]

 if f.state=="idle" then
  if f.input.down and f.input.light then
   f.current_move=c.moves.low; f.state="attack"; f.timer=0
  elseif f.input.light then
   f.current_move=c.moves.light; f.state="attack"; f.timer=0
  elseif f.input.heavy then
   f.current_move=c.moves.heavy; f.state="attack"; f.timer=0
  elseif f.input.left or f.input.right then
   f.state="walk"; f.timer=0
  end

 elseif f.state=="walk" then
  local dir = f.input.right and 1 or (f.input.left and -1 or 0)
  f.x += dir * f.speed
  if not (f.input.left or f.input.right) then f.state="idle"; f.timer=0 end

 elseif f.state=="attack" then
  update_attack(f, f.current_move)

 elseif f.state=="hitstun" then
  if f.timer > 15 then f.state="idle"; f.timer=0 end
 end

 f.x = mid(8, f.x, 120)
end

-- un seul état "attack" générique piloté par la table move (light/heavy/low/futurs specials)
-- au lieu d'un état par coup : ça scale sans ajouter de code quand tu rajouteras des coups
function update_attack(f, move)
 local active_end = move.startup + move.active - 1
 local total = move.startup + move.active + move.recovery

 if f.timer >= move.startup and f.timer <= active_end then
  f.hitbox = {x=move.range*f.facing, y=move.hy, w=move.size, h=move.size, damage=move.damage}
 else
  f.hitbox = nil
 end

 if f.timer >= total then f.state="idle"; f.timer=0 end
end

function draw_fighter(f)
 -- placeholder rectangle, à remplacer par spr()/sspr() une fois les sprites prêts
 rectfill(f.x-4, f.y-16, f.x+4, f.y, f.player_index==0 and 11 or 9)
end
