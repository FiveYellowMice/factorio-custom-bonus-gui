local custom_bonus = require("script.custom_bonus")
local gui = require("script.gui")
require("script.remote_iface")


script.on_init(function()
    custom_bonus.on_init()
end)

script.on_configuration_changed(function(event)
    gui.on_configuration_changed(event)
end)

script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    if event.gui_type == defines.gui_type.bonus then
        gui.create(player)
    else
        gui.destroy(player)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    if event.gui_type == defines.gui_type.bonus then
        gui.destroy(player)
    end
end)

script.on_event({
    defines.events.on_player_display_resolution_changed,
    defines.events.on_player_display_scale_changed,
},
---@param event
---| EventData.on_player_display_resolution_changed
---| EventData.on_player_display_scale_changed
function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    gui.resize(player)
end)

script.on_event(defines.events.on_player_removed, function(event)
    custom_bonus.on_player_removed(event)
end)

script.on_event(defines.events.on_forces_merged, function(event)
    custom_bonus.on_forces_merged(event)
end)

script.on_event(defines.events.on_player_changed_force, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    gui.refresh(player)
end)
