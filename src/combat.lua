-- combat.lua : collisions hitbox / hurtbox — dégâts tirés du hitbox (donc de data.lua)

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
  defender.timer = 0
  defender.hitbox = nil -- le défenseur perd son attaque en cours : sinon son hitbox
                        -- survit au hitstun et frappe encore une fois revenu en idle
  attacker.hitbox = nil -- évite le multi-hit sur une même frame active
  sfx(sfx_hit) -- son d'impact, dessiné dans l'éditeur sfx (audio.lua)
 end
end

function rects_overlap(x1,y1,w1,h1,x2,y2,w2,h2)
 return x1<x2+w2 and x1+w1>x2 and y1<y2+h2 and y1+h1>y2
end
