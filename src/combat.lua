-- combat.lua : collisions hitbox / hurtbox, dégâts, orientation, séparation des corps

function check_hit(attacker, defender)
 if not attacker.hitbox then return end
 local ax = attacker.x + attacker.hitbox.x
 local ay = attacker.y + attacker.hitbox.y
 local dx = defender.x + defender.hurtbox.x
 local dy = defender.y + defender.hurtbox.y

 if rects_overlap(ax, ay, attacker.hitbox.w, attacker.hitbox.h,
                   dx, dy, defender.hurtbox.w, defender.hurtbox.h) then
  -- garde : direction arrière maintenue au moment de l'impact, et libre de ses
  -- mouvements (idle/walk) → chip damage minimal + état block bref au lieu du
  -- hitstun complet. le facing pointant toujours vers l'adversaire, "arrière"
  -- = direction opposée au facing. le ko par chip reste possible (choix assumé)
  local back = (defender.facing==1 and defender.input.left)
            or (defender.facing==-1 and defender.input.right)
  if back and (defender.state=="idle" or defender.state=="walk") then
   defender.health = max(0, defender.health - 1)
   defender.state = "block"
   defender.stun = 8 -- récupération de garde courte, fixe quel que soit le coup
   defender.timer = 0
   sfx(sfx_block)
  else
   defender.health = max(0, defender.health - attacker.hitbox.damage)
   defender.state = "hitstun"
   defender.stun = attacker.hitbox.stun -- durée de stun propre au coup reçu
   defender.timer = 0
   defender.hitbox = nil -- le défenseur perd son attaque en cours : sinon son hitbox
                         -- survivrait au hitstun et frapperait encore, revenu en idle
   sfx(sfx_hit)
  end
  attacker.hitbox = nil -- garde ou non : pas de multi-hit sur une même frame active
 end
end

function rects_overlap(x1,y1,w1,h1,x2,y2,w2,h2)
 return x1<x2+w2 and x1+w1>x2 and y1<y2+h2 and y1+h1>y2
end

-- oriente f vers son adversaire, appelé chaque frame depuis update_match.
-- couvre idle/walk/block et la phase de startup d'une attaque ; à partir des
-- frames actives le facing est verrouillé pour que le hitbox ne saute pas de
-- l'autre côté en plein coup. jamais pendant hitstun.
function update_facing(f, opp)
 local locked = f.state=="hitstun"
  or (f.state=="attack" and f.timer >= f.current_move.startup)
 if not locked then
  f.facing = (opp.x >= f.x) and 1 or -1
 end
end

-- séparation des corps : empêche les deux persos de se superposer.
-- les deux sont toujours au sol à la même hauteur → test horizontal suffisant
function separate_bodies(a, b)
 local w = 12 -- largeur des hurtbox (gabarit sprites 24x32, identique pour tous les persos)
 local dist = abs(a.x - b.x)
 if dist >= w then return end
 local push = (w - dist) / 2
 local dir = (a.x < b.x) and -1 or 1
 if a.x == b.x then dir = (a.player_index==0) and -1 or 1 end
 a.x = mid(12, a.x + dir*push, 116) -- mêmes bornes que update_fighter (gabarit 24px)
 b.x = mid(12, b.x - dir*push, 116)
end
