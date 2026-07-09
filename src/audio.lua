-- audio.lua : déclenchement sfx / musique
-- les sons se créent dans l'éditeur sfx intégré pico-8 (esc > onglet sfx)
-- tant qu'aucun sfx n'est dessiné, ces appels sont silencieux : aucun crash

-- index sfx réservés (à dessiner dans l'éditeur) :
sfx_hit    = 0 -- impact, appelé par check_hit() dans combat.lua
sfx_whoosh = 1 -- attaque dans le vide
sfx_block  = 2 -- coup paré (pas encore d'état block)
sfx_ko     = 3 -- k.o.
sfx_menu   = 4 -- confirmation menu

function init_audio()
 -- music(0) -- à activer une fois un pattern musical créé
end
