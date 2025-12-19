local util = require("util")
local custom_bonus = require("script.custom_bonus")
local gui = require("script.gui")

---@class remote.custom-bonus-gui
local remote_iface = {}

---@param msg_prefix string
---@return CustomBonusScope scope, uint32 index
local function validate_target(msg_prefix, target)
    if type(target) ~= "userdata" then goto error end

    if target.object_name == "LuaForce" and target.valid then
        return "force", target.index
    elseif target.object_name == "LuaPlayer" and target.valid then
        return "player", target.index
    end

    ::error::
    error(msg_prefix..": Target must be a valid LuaForce or LuaPlayer")
end

---Set a custom bonus to be displayed.
---
---A custom bonus may be attached to a force or a player.
---* If it is attached to a force, it is visible to all players in the force;
---* If it is attached to a player, it is visible to them only, and is displayed in favour to the same bonus attached to their force.
---
---If a custom bonus with the same name already exists for this target, it is overwritten.
---@param target LuaForce | LuaPlayer Force or player to attach the custom bonus to.
---@param value CustomBonus Definitions of the custom bonus.
function remote_iface.set(target, value)
    scope, index = validate_target("custom-bonus-gui.set", target)

    if type(value) ~= "table" then
        error("custom-bonus-gui.set: Value must be a table")
    end
    if type(value.name) ~= "string" then
        error("custom-bonus-gui.set: CustomBonus.name must be a string")
    end
    if type(value.mod_name) ~= "string" or not script.active_mods[value.mod_name] then
        error("custom-bonus-gui.set: CustomBonus.mod_name must be the name of an active mod")
    end
    if type(value.order) ~= "nil" and type(value.order) ~= "string" then
        error("custom-bonus-gui.set: CustomBonus.order must be nil or a string")
    end
    if type(value.icons) ~= "table" then
        error("custom-bonus-gui.set: CustomBonus.icons must be an array")
    end
    for i, icon in pairs(value.icons) do
        if type(i) ~= "number" then
            error("custom-bonus-gui.set: CustomBonus.icons may only contain numerical keys")
        end
        if type(icon) ~= "table" then
            error("custom-bonus-gui.set: CustomBonus.icons["..i.."] must be a table")
        end
        if type(icon.type) ~= "string" or not custom_bonus.valid_icon_types[icon.type] then
            local s = {}; for a, _ in pairs(custom_bonus.valid_icon_types) do table.insert(s, a) end
            error("custom-bonus-gui.set: CustomBonus.icons["..i.."].type must be one of: \""..table.concat(s, "\", \"").."\"")
        end
        if type(icon.name) ~= "string" or not helpers.is_valid_sprite_path(custom_bonus.icon_to_sprite_path(icon)) then
            error("custom-bonus-gui.set: CustomBonus.icons["..i.."].name \""..tostring(icon.name).."\" does not refer to a "..icon.type.." with a valid sprite")
        end
    end
    if type(value.texts) ~= "table" then
        error("custom-bonus-gui.set: CustomBonus.texts must be an array of LocalisedString")
    end
    for i, text in pairs(value.texts) do
        if type(i) ~= "number" then
            error("custom-bonus-gui.set: CustomBonus.texts may only contain numerical keys")
        end
    end

    custom_bonus.set(scope, index, util.table.deepcopy(value))

    if target.object_name == "LuaPlayer" then
        gui.refresh(target)
    elseif target.object_name == "LuaForce" then
        for _, player in ipairs(target.players) do
            gui.refresh(player)
        end
    end
end

---Get a copy of a previously set custom bonus.
---@param target LuaForce | LuaPlayer Force or player to get the custom bonus from.
---@param name string Name of the custom bonus.
---@return CustomBonus?
function remote_iface.get(target, name)
    scope, index = validate_target("custom-bonus-gui.get", target)

    if type(name) ~= "string" then
        error("custom-bonus-gui.get: Name must be a string")
    end

    return util.table.deepcopy(custom_bonus.get(scope, index, name))
end

---Remove a custom bonus from display. Does nothing if it does not exist.
---@param target LuaForce | LuaPlayer Force or player to remove the custom bonus from.
---@param name string Name of the custom bonus to remove.
function remote_iface.remove(target, name)
    scope, index = validate_target("custom-bonus-gui.remove", target)

    if type(name) ~= "string" then
        error("custom-bonus-gui.remove: Name must be a string")
    end

    custom_bonus.remove(scope, index, name)

    if target.object_name == "LuaPlayer" then
        gui.refresh(target)
    elseif target.object_name == "LuaForce" then
        for _, player in ipairs(target.players) do
            gui.refresh(player)
        end
    end
end


remote.add_interface("custom-bonus-gui", remote_iface)
