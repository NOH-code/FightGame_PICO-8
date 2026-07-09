-- data.lua : personnages et frame data
-- volt = rush-down (rapide, courte portée, dégâts faibles, pression)
-- torque = zoner (lent, longue portée, dégâts élevés, poke)
-- les noms sont cosmétiques : renommer via le champ "name" ne touche à rien d'autre
-- stun = frames de hitstun infligées au défenseur (coup lourd > coup léger)

characters = {
 [0] = {
  name = "volt",
  speed = 2.0,
  health = 100,
  moves = {
   light = { startup=2, active=3, recovery=8,  damage=6,  range=6,  hy=-12, size=6, stun=10 },
   heavy = { startup=4, active=5, recovery=14, damage=12, range=8,  hy=-12, size=6, stun=18 },
   low   = { startup=3, active=4, recovery=10, damage=7,  range=6,  hy=-4,  size=5, stun=12 },
  },
 },
 [1] = {
  name = "torque",
  speed = 0.8,
  health = 100,
  moves = {
   light = { startup=5, active=6, recovery=10, damage=9,  range=14, hy=-12, size=7, stun=12 },
   heavy = { startup=8, active=8, recovery=18, damage=16, range=18, hy=-12, size=8, stun=22 },
   low   = { startup=6, active=5, recovery=12, damage=10, range=12, hy=-4,  size=6, stun=14 },
  },
 },
}

-- règles de match : best-of-3, premier à rounds_to_win rounds gagnés.
-- des rounds nuls (double ko, vies égales au timeout) ne rapportent à personne,
-- donc après max_rounds joués sans vainqueur direct : le plus de rounds
-- gagnés l'emporte, et si égalité parfaite le match est nul (cf. end_round)
rounds_to_win = 2
max_rounds = 3
round_time = 1800 -- 60 secondes à 30 fps (_update, pas _update60)
