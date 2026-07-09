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
  max_health=c.health, -- référence pour le hud (barre proportionnelle)
  stun=0,              -- durée du hitstun en cours, fixée par le coup reçu
  hurtbox={x=-4,y=-16,w=8,h=16},
  hitbox=nil,
  current_move=nil,
  input={},
 }
end

function update_fighter(f)
 f.timer += 1
 local c = characters[f.character_id]

 if f.state=="idle" or f.state=="walk" then
  -- attaques initiables depuis idle ou walk (choix assumé : interdire l'attaque
  -- en marchant rendrait le rush-down injouable). jamais depuis attack/hitstun :
  -- pas de cancel ni d'enchaînement.
  -- o+x testé AVANT o seul et x seul : sinon presser les deux la même frame
  -- déclencherait light (et heavy) au lieu de medium
  if f.input.light and f.input.heavy then
   start_move(f, c.moves.medium)
  elseif f.input.light then
   start_move(f, c.moves.light)
  elseif f.input.heavy then
   start_move(f, c.moves.heavy)
  else
   local dir = (f.input.right and 1 or 0) + (f.input.left and -1 or 0)
   f.x += dir * f.speed
   f.state = (dir!=0) and "walk" or "idle"
  end

 elseif f.state=="attack" then
  update_attack(f, f.current_move)

 elseif f.state=="hitstun" then
  -- durée portée par le coup reçu (cf. check_hit), pas fixe : un coup lourd
  -- immobilise plus longtemps qu'un coup léger
  if f.timer > f.stun then f.state="idle"; f.timer=0 end
 end

 f.x = mid(8, f.x, 120)
end

function start_move(f, move)
 f.current_move = move
 f.state = "attack"
 f.timer = 0
 sfx(sfx_whoosh)
end

-- un seul état "attack" générique piloté par la table move
-- au lieu d'un état par coup : ça scale sans ajouter de code
function update_attack(f, move)
 local active_end = move.startup + move.active - 1
 local total = move.startup + move.active + move.recovery

 if f.timer >= move.startup and f.timer <= active_end then
  -- ancrage symétrique : bord intérieur du hitbox à `range` du centre quel que
  -- soit le sens (bug corrigé : x=range*facing raccourcissait les coups vers la
  -- gauche de `size` pixels, le bord EXTÉRIEUR se retrouvait à range du centre)
  local hx = (f.facing==1) and move.range or -(move.range+move.size)
  f.hitbox = {x=hx, y=move.hy, w=move.size, h=move.size,
              damage=move.damage, stun=move.stun}
 else
  f.hitbox = nil
 end

 if f.timer >= total then f.state="idle"; f.timer=0 end
end

function draw_fighter(f)
 -- placeholder rectangle, à remplacer par spr()/sspr() une fois les sprites prêts
 rectfill(f.x-4, f.y-16, f.x+4, f.y, f.player_index==0 and 11 or 9)
end
