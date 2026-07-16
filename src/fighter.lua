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
  hurtbox={x=-6,y=-24,w=12,h=24}, -- élargie au gabarit des sprites 24x32

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

 elseif f.state=="block" then
  -- coup paré : brève récupération de garde puis retour à idle (cf. check_hit)
  if f.timer > f.stun then f.state="idle"; f.timer=0 end
 end

 f.x = mid(12, f.x, 116) -- demi-largeur visuelle du sprite (24px)
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

-- rendu sprite : bloc 24x32 (3x4 cellules), pieds ancrés à (f.x, f.y).
-- petit langage de poses sans sprites supplémentaires : décalage + effets de palette.
function draw_fighter(f)
 local n = characters[f.character_id].spr_n
 local ox = 0 -- décalage horizontal selon la pose en cours

 if f.state=="attack" then
  ox = 2*f.facing  -- projeté vers l'avant : vend l'impact du coup
 elseif f.state=="block" then
  ox = -1*f.facing -- recul pendant la garde
 end

 if f.state=="hitstun" and f.timer%4<2 then
  -- flash blanc clignotant : toutes les couleurs remappées en blanc (7)
  for i=1,15 do pal(i,7) end
 end

 palt(14,true) -- 14 = transparence des sprites/tuiles
 palt(0,false) -- le noir reste opaque (il sert aux contours)
 spr(n, f.x-12+ox, f.y-31, 3, 4, f.facing==-1)

 if f.state=="attack" and f.hitbox then
  -- flash de tir au centre du hitbox pendant les frames actives : les deux
  -- persos tirent avec des armes à feu, ça vend le coup sans sprite dédié
  local cx = f.x + f.hitbox.x + f.hitbox.w/2
  local cy = f.y + f.hitbox.y + f.hitbox.h/2
  circfill(cx, cy, 2, 10)
  circfill(cx, cy, 1, 7)
 elseif f.state=="block" then
  -- liseré de garde côté avant : feedback visuel du coup paré
  local bx = f.x + 6*f.facing
  line(bx, f.y-14, bx, f.y-2, 7)
 end

 pal() -- remet palette de couleurs ET transparence d'aplomb, aucune fuite d'état
end
