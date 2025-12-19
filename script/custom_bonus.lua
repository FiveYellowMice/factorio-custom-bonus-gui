local custom_bonus = {}

---@class (exact) CustomBonus
---@field name string The internal name of the bonus. Must be unique across all mods. Setting a custom bonus whose name already exists for the same target overwrites the previous one.
---@field mod_name string The mod owning this bonus. The bonus will be removed when the mod is removed.
---@field icons CustomBonus.Icon[] Icons to display.
---@field texts LocalisedString[] Text labels to display.

---@class (exact) CustomBonus.Icon
---@field type CustomBonus.IconType The type of the icon.
---@field name string Name of the prototype to display the icon of.

---@enum (key) CustomBonus.IconType
custom_bonus.valid_icon_types = {
    ["sprite"] = true,
    ["item"] = true,
    ["tile"] = true,
    ["entity"] = true,
    ["virtual-signal"] = true,
    ["fluid"] = true,
    ["recipe"] = true,
    ["decorative"] = true,
    ["item-group"] = true,
    ["achievement"] = true,
    ["equipment"] = true,
    ["technology"] = true,
    ["asteroid-chunk"] = true,
    ["space-location"] = true,
}

---@alias CustomBonusStorage table<uint32, table<string, CustomBonus?>?>

---@enum (key) CustomBonusScope
custom_bonus.valid_scopes = {
    force = true,
    player = true,
}


function custom_bonus.on_init()
    ---@package
    ---@type CustomBonusStorage
    storage.force_bonuses = {}

    ---@package
    ---@type CustomBonusStorage
    storage.player_bonuses = {}
end

---@package
---@type table<CustomBonusScope, CustomBonusStorage>
custom_bonus.scope_storages = setmetatable({}, {
    __index = function (t, k)
        local v = ({
            force = storage.force_bonuses,
            player = storage.player_bonuses,
        })[k]
        t[k] = v
        return v
    end
})

---@param event EventData.on_forces_merged
function custom_bonus.on_forces_merged(event)
    storage.player_bonuses[event.source_index] = nil
end

---@param event EventData.on_player_removed
function custom_bonus.on_player_removed(event)
    storage.player_bonuses[event.player_index] = nil
end

---@param event ConfigurationChangedData
function custom_bonus.on_configuration_changed(event)
    for mod, change in pairs(event.mod_changes) do
        if not change.new_version then
            -- Mod removed, so we remove all custom bonuses owned by it
            for scope, _ in pairs(custom_bonus.valid_scopes) do
                for _, bonuses in pairs(custom_bonus.scope_storages[scope]) do
                    for name, bonus in pairs(bonuses) do
                        if bonus.mod_name == mod then
                            bonuses[name] = nil
                        end
                    end
                end
            end
        end
    end
end

---@param scope CustomBonusScope
---@param index uint32
---@param value CustomBonus
function custom_bonus.set(scope, index, value)
    local target_bonuses = custom_bonus.scope_storages[scope][index]
    if not target_bonuses then
        target_bonuses = {}
        custom_bonus.scope_storages[scope][index] = target_bonuses
    end

    target_bonuses[value.name] = value
end

---@param scope CustomBonusScope
---@param index uint32
---@param name string
---@return CustomBonus?
function custom_bonus.get(scope, index, name)
    local target_bonuses = custom_bonus.scope_storages[scope][index]
    if not target_bonuses then return nil end
    return target_bonuses[name]
end

---@param scope CustomBonusScope
---@param index uint32
---@param name string
function custom_bonus.remove(scope, index, name)
    local target_bonuses = custom_bonus.scope_storages[scope][index]
    if not target_bonuses then return nil end
    target_bonuses[name] = nil
end

---@param player LuaPlayer
---@return table<string, CustomBonus?>
function custom_bonus.get_player_merged_bonuses(player)
    local merged = {}
    local force_bonuses = custom_bonus.scope_storages.force--[[@as CustomBonusStorage]][player.force_index]
    if force_bonuses then
        for _, bonus in pairs(force_bonuses) do
            merged[bonus.name] = bonus
        end
    end
    local player_bonuses = custom_bonus.scope_storages.player--[[@as CustomBonusStorage]][player.index]
    if player_bonuses then
        for _, bonus in pairs(player_bonuses) do
            merged[bonus.name] = bonus
        end
    end
    return merged
end

---@param icon CustomBonus.Icon
---@return SpritePath
function custom_bonus.icon_to_sprite_path(icon)
    if icon.type == "sprite" then
        return icon.name
    else
        return icon.type.."/"..icon.name
    end
end

---@param icon CustomBonus.Icon
---@return ElemID?
function custom_bonus.icon_to_elem_id(icon)
    if icon.type == "virtual-signal" then
        return {
            type = "signal",
            name = icon.name,
            signal_type = "virtual",
        }
    elseif icon.type == "sprite" then
        return nil
    else
        return icon--[[@as ElemID]]
    end
end

return custom_bonus
