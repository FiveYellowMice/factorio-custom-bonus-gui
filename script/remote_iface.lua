local util = require("util")
local custom_bonus = require("script.custom_bonus")
local gui = require("script.gui")

local remote_iface = {}

---@param msg_prefix string
---@return CustomBonusScope, uint32, ...
local function preprocess_args(msg_prefix, scope, index, ...)
    local args = ... or {}

    if type(scope) == "userdata" then
        local target = scope--[[@as LuaForce | LuaPlayer]]
        table.insert(args, 1, index)

        if target.object_name == "LuaForce" then
            scope = "force"
            index = target.index
        elseif target.object_name == "LuaPlayer" then
            scope = "player"
            index = target.index
        else
            error(msg_prefix..": Target must be a LuaForce or LuaPlayer")
        end

    else
        if type(index) ~= "number" then
            error(msg_prefix..": Index must be a number")
        end
        if scope == "force" then
            if not game.forces[index] then
                error(msg_prefix..": Force with index "..index.." does not exist")
            end
        elseif scope == "player" then
            if not game.get_player(index) then
                error(msg_prefix..": Player with index "..index.." does not exist")
            end
        else
            error(msg_prefix..": Scope must be \"force\" or \"player\"")
        end
    end

    return scope, index, table.unpack(args)
end

---@param scope CustomBonusScope Scope of the custom bonus.
---@param index uint32 Player or force index to set the custom bonus on.
---@param value CustomBonus
---@overload fun(target: LuaForce | LuaPlayer, value: CustomBonus)
function remote_iface.set(scope, index, value)
    scope, index, value = preprocess_args("custom-bonus-gui.set", scope, index, value)
    ---@cast value CustomBonus

    if type(value) ~= "table" then
        error("custom-bonus-gui.set: Value must be a table")
    end
    if type(value.name) ~= "string" then
        error("custom-bonus-gui.set: CustomBonus.name must be a string")
    end
    if type(value.mod_name) ~= "string" or not script.active_mods[value.mod_name] then
        error("custom-bonus-gui.set: CustomBonus.mod_name must be the name of an active mod")
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
        if type(icon.name) ~= "string" or not prototypes[string.gsub(icon.type, "-", "_")] then
            error("custom-bonus-gui.set: CustomBonus.icons["..i.."].name \""..icon.name.."\" does not refer to an existing "..icon.type.." prototype")
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

    if scope == "player" then
        gui.refresh(game.get_player(index)--[[@as LuaPlayer]])
    elseif scope == "force" then
        for _, player in ipairs(game.forces[index].players) do
            gui.refresh(player)
        end
    end
end


---@param scope CustomBonusScope Scope of the custom bonus.
---@param index uint32 Player or force index to get the custom bonus from.
---@param name string Name of the custom bonus.
---@return CustomBonus?
---@overload fun(target: LuaForce | LuaPlayer, name: string): CustomBonus?
function remote_iface.get(scope, index, name)
    scope, index, name = preprocess_args("custom-bonus-gui.get", scope, index, name)

    if type(name) ~= "string" then
        error("custom-bonus-gui.get: Name must be a string")
    end

    return util.table.deepcopy(custom_bonus.get(scope, index, name))
end

---@param scope CustomBonusScope Scope of the custom bonus.
---@param index uint32 Player or force index to remove the custom bonus from.
---@param name string Name of the custom bonus to remove.
---@overload fun(target: LuaForce | LuaPlayer, name: string)
function remote_iface.remove(scope, index, name)
    scope, index, name = preprocess_args("custom-bonus-gui.remove", scope, index, name)

    if type(name) ~= "string" then
        error("custom-bonus-gui.remove: Name must be a string")
    end

    custom_bonus.remove(scope, index, name)

    if scope == "player" then
        gui.refresh(game.get_player(index)--[[@as LuaPlayer]])
    elseif scope == "force" then
        for _, player in ipairs(game.forces[index].players) do
            gui.refresh(player)
        end
    end
end


remote.add_interface("custom-bonus-gui", remote_iface)
