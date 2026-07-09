-- combat.lua : collisions hitbox / hurtbox, dégâts, orientation, séparation des corps

function check_hit(attacker, defender)
 if not attacker.hitbox then return end
 local ax = attacker.x + attacker.hitbox.x
 local ay = attacker.y + attacker.hitbox.y
 local dx = defender.x + defender.hurtbox.x
 local dy = defender.y + defender.hurtbox.y

 if rects_overlap(ax, ay, attacker.hitbox.w, attacker.hitbox.h,
                   dx, dy, defender.hurtbox.w, defender.hurtbox.h) then
  defender.health = max(0, defender.health - attacker.hitbox.damage)
  defender.state = "hitstun"
  defender.stun = attacker.hitbox.stun -- durée de stun propre au coup reçu
  defender.timer = 0
  defender.hitbox = nil -- le défenseur perd son attaque en cours : sinon son hitbox
                        -- survivrait au hitstun et frapperait encore, revenu en idle
  attacker.hitbox = nil -- évite le multi-hit sur une même frame active
  sfx(sfx_hit)
 end
end

function rects_overlap(x1,y1,w1,h1,x2,y2,w2,h2)
 return x1<x2+w2 and x1+w1>x2 and y1<y2+h2 and y1+h1>y2
end

-- oriente f vers son adversaire, appelé chaque frame depuis update_match.
-- pas pendant attack/hitstun : le hitbox actif reste cohérent avec le coup parti
function update_facing(f, opp)
 if f.state=="idle" or f.state=="walk" then
  f.facing = (opp.x >= f.x) and 1 or -1
 end
end

-- séparation des corps : empêche les deux persos de se superposer.
-- les deux sont toujours au sol à la même hauteur → test horizontal suffisant
function separate_bodies(a, b)
 local w = 8 -- largeur des hurtbox (identique pour tous les persos)
 local dist = abs(a.x - b.x)
 if dist >= w then return end
 local push = (w - dist) / 2
 local dir = (a.x < b.x) and -1 or 1
 if a.x == b.x then dir = (a.player_index==0) and -1 or 1 end
 a.x = mid(8, a.x + dir*push, 120)
 b.x = mid(8, b.x - dir*push, 120)
end
