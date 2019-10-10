local command = require('command')
local math = require('math')
local player = require('player')
local resources = require('resources')
local settings = require('settings')
local string = require('string')
local table = require('table')
local ui = require('ui')
local windower = require('windower')

local config
do
    local defaults = {
        show_capped = true,
        show = true,
    }
    config = settings.load(defaults)
end

local window_state = {
    title = 'Textbook',
    style = 'chromeless',
    color = ui.color.rgb(0, 0, 0, 192),
    width = 140,
    x = 5,
    y = 0,
}

local setup_skill_tables
do
    local format_skill = function(id)
        local p_skill = player.skills[id]
        local rc_skill = resources.skills[id]
        if rc_skill and not ((p_skill.level == 0 or not config.show_capped) and p_skill.capped) then
            return {
                id = id,
                name = rc_skill.name,
                level = p_skill.level,
                capped = p_skill.capped,
            }
        else
            return nil
        end
    end
    
    setup_skill_tables = function()
        local skills = {
            combat_skills = {},
            magic_skills = {},
        }
        
        local combat_skills = skills.combat_skills
        local magic_skills = skills.magic_skills
        
        for id = 1, 31 do
            local skill = format_skill(id)
            if skill then
                table.insert(combat_skills, skill)
            end
        end
        for id = 32, 44 do
            local skill = format_skill(id)
            if skill then
                table.insert(magic_skills, format_skill(id))
            end
        end
        return skills
    end
end

local pos
local reset_pos
do
    local y_current = 0
    pos = function(x, y_off)
        y_current = y_current + y_off
        ui.location(x, y_current)
    end
    
    reset_pos = function()
        y_current = 0
    end
end

local show_skills = function(skills)
    for _,skill in ipairs(skills) do
        pos(15,20)
        ui.text(skill.name)
        pos(120,0)
        local color = ui.color.white
        if skill.capped then
            color = ui.color.dodgerblue
        end
        ui.text(string.format(
            '[%d]{color:%s}',
            skill.level,
            ui.color.tohex(color)
        ))
    end
end

ui.display(function()
    if not (player and player.skills) or player.state.id == 4 or not config.show then
        return
    end
    
    local skills = setup_skill_tables()
    
    local height = 10
    if skills.combat_skills[1] then
        height = height + 20 * (#skills.combat_skills + 1)
    end
    if skills.combat_skills[1] and skills.magic_skills[1] then
        height = height + 5
    end
    if skills.magic_skills[1] then
        height = height + 20 * (#skills.magic_skills + 1)
    end
    window_state.height = height
    window_state.y = math.floor((windower.settings.ui_size.height - height) / 2)
    
    window_state = ui.window('textbook_window', window_state, function()
        reset_pos()
        
        if skills.combat_skills[1] then
            pos(5,5)
            ui.text('Combat Skills')
            show_skills(skills.combat_skills)
        end
        
        if skills.combat_skills[1] and skills.magic_skills[1] then
            pos(5,25)
        end
        
        if skills.magic_skills[1] then
            pos(5,5)
            ui.text('Magic Skills')
            show_skills(skills.magic_skills)
        end
    end)
end)

local handle_show = function(arg)
    if arg then
        config.show = (arg == 'true')
    else
        config.show = not config.show
    end
    settings.save()
end

local handle_capped = function(arg)
    if arg then
        config.show_capped = (arg == 'true')
    else
        config.show_capped = not config.show_capped
    end
    settings.save()
end

local textbook_command = command.new('textbook')
textbook_command:register('show', handle_show, '[one_of(true,false)]')
textbook_command:register('capped', handle_capped, '[one_of(true,false)]')