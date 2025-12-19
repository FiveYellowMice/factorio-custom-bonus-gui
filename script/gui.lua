local constants = require("constants")
local custom_bonus = require("script.custom_bonus")

local gui = {}

---@param event ConfigurationChangedData
function gui.on_configuration_changed(event)
    if event.mod_changes["custom-bonus-gui"] or event.new_version then
        -- Destroy GUI for everyone
        for _, player in pairs(game.players) do
            gui.destroy(player)
        end
    end
end

---@param player LuaPlayer
function gui.create(player)
    local frame = gui.get(player)
    if frame then return end

    frame = player.gui.relative.add{
        name = constants.gui_window_name,
        type = "frame",
        anchor = {
            gui = defines.relative_gui_type.bonus_gui,
            position = defines.relative_gui_position.right,
        },
        caption = {"custom-bonus-gui.window-title"},
        direction = "vertical",
    }
    local inside_frame = frame.add{
        type = "frame",
        style = "inside_deep_frame",
        direction = "vertical",
    }
    local scroll_pane = inside_frame.add{
        type = "scroll-pane",
        direction = "vertical",
        style = constants.style_prefix.."scroll_pane",
        horizontal_scroll_policy = "never",
        vertical_scroll_policy = "auto",
    }
    local table = scroll_pane.add{
        type = "table",
        column_count = 1,
        style = constants.style_prefix.."table",
    }

    gui.resize(player)
    gui.refresh(player)
end

---@param player LuaPlayer
function gui.destroy(player)
    local frame = gui.get(player)
    if frame then
        frame.destroy()
    end
end

---@param player LuaPlayer
---@return LuaGuiElement?
function gui.get(player)
    return player.gui.relative[constants.gui_window_name]
end

---@param player LuaPlayer
function gui.resize(player)
    local frame = gui.get(player)
    if not frame then return end

    local normalized_display_height = player.display_resolution.height / player.display_scale

    -- Mimic the height of vanilla bonus GUI
    local frame_height
    if normalized_display_height < 950 then
        frame_height = normalized_display_height - 24
    else
        frame_height = normalized_display_height - 150
    end
    frame.style.maximal_height = frame_height
end

---@param player LuaPlayer
function gui.refresh(player)
    local frame = gui.get(player)
    if not frame then return end

    local table = frame.children[1].children[1].children[1]
    table.clear()

    local bonuses = custom_bonus.get_player_merged_bonuses(player)

    frame.visible = next(bonuses) ~= nil

    for _, bonus in pairs(bonuses) do
        local card = table.add{
            type = "frame",
            style = "bonus_card_frame",
            direction = "vertical",
        }
        card.style.horizontally_stretchable = true
        card.style.vertically_stretchable = true

        --- Icons
        local icon_table = card.add{
            type = "table",
            column_count = 5,
        }

        for _, bonus_icon in ipairs(bonus.icons) do
            icon_table.add{
                type = "sprite-button",
                style = "transparent_slot",
                game_controller_interaction = defines.game_controller_interaction.never,
                sprite = custom_bonus.icon_to_sprite_path(bonus_icon),
                elem_tooltip = custom_bonus.icon_to_elem_id(bonus_icon),
            }
        end

        --- Texts
        local text_flow = card.add{
            type = "flow",
            direction = "vertical",
            style = "packed_vertical_flow",
        }

        for _, bonus_text in ipairs(bonus.texts) do
            text_flow.add{
                type = "label",
                caption = bonus_text,
            }
        end
    end
end

return gui
