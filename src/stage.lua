-- stage.lua : décor et limites du terrain

-- le sol est à y=96 : c'est la ligne sur laquelle new_fighter() pose les persos
-- (fighter.lua : y=96, et draw_fighter dessine de y-16 à y)
ground_y = 96

-- bornes horizontales, cohérentes avec le mid(8, f.x, 120) de update_fighter
stage_left  = 8
stage_right = 120

function init_stage() end

function draw_stage()
 rectfill(0, 0, 127, 127, 1)          -- fond placeholder
 rectfill(0, ground_y+1, 127, 127, 3) -- sol
 line(0, ground_y, 127, ground_y, 6)  -- ligne de sol
end
