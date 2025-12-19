# Custom Bonus GUI

This Factorio mod library provides a convient method for mods to display custom bonus cards in the "Bonuses" GUI. Useful for bonuses implemented by scripts.

## Features

* A remote interface to set custom bonuses for display.
* Each custom bonus may contain any number of icons and text labels.
* Each custom bonus may be attached to a force or a player.

## Caveats

* When the player has no vanilla bonuses during early game, their vanilla "Bonuses" button will be disabled, even when they have custom bonuses. This mod adds a `/bonus` command to display the GUI in such cases.

## Example

This example shows a mod `example-mod` providing a bonus called "Radioactivity", implemented elsewhere by script. This bonus is gained by a research called `radioactivity`.

```lua
script.on_event({
    -- Run when research status changes.
    defines.events.on_research_finished,
    defines.events.on_research_reversed,
    defines.events.on_force_reset
}, function(event)
    local force = event.force or event.research.force

    -- Calculate the bonus value.
    local radioactivity = force.technologies['radioactivity'].level * 0.01
    -- Put the value in storage to be used by the implementation of the bonus.
    storage.forces[force.index].radioactivity_bonus = radioactivity

    if radioactivity > 0 then
        -- Show the bonus.
        remote.call("custom-bonus-gui", "set", force, {
            name = "example-mod-radioactivity", -- prefixed to avoid conflicts
            mod_name = "example-mod",
            order = "b",
            icons = {
                {type = 'item', name = 'uranium-rounds-magazine'},
                {type = 'item', name = 'uranium-cannon-shell'},
                {type = 'item', name = 'explosive-uranium-cannon-shell'},
                {type = 'item', name = 'atomic-bomb'},
            },
            texts = {
                -- In locale file:
                -- [example-mod]
                -- radioactivity-bonus=Radioactivity: __1__ Gy
                {"example-mod.radioactivity-bonus", radioactivity},
            }
        })
    else
        -- Remove the bonus.
        remote.call("custom-bonus-gui", "remove", force, "example-mod-radioactivity")
    end
end)
```

## API Reference

### remote.custom-bonus-gui

#### set

```lua
remote.call("custom-bonus-gui", "set", target, value)
```

Set a custom bonus to be displayed.

A custom bonus may be attached to a force or a player.
* If it is attached to a force, it is visible to all players in the force;
* If it is attached to a player, it is visible to them only, and is displayed in favour to the same bonus attached to their force.

If a custom bonus with the same name already exists for this target, it is overwritten.

@*param* `target` LuaForce|LuaPlayer — Force or player to attach the custom bonus to.

@*param* `value` CustomBonus — Definitions of the custom bonus.

#### get

```lua
remote.call("custom-bonus-gui", "get", target, name)
```

Get a copy of a previously set custom bonus.

@*param* `target` LuaForce|LuaPlayer — Force or player to get the custom bonus from.

@*param* `name` string — Name of the custom bonus.

@*return* CustomBonus?

#### remove

```lua
remote.call("custom-bonus-gui", "remove", target, name)
```

Remove a custom bonus from display. Does nothing if it does not exist.

@*param* `target` LuaForce|LuaPlayer — Force or player to remove the custom bonus from.

@*param* `name` string — Name of the custom bonus to remove.

### CustomBonus

@*field* `name` string — The internal name of the bonus. Must be unique across all mods. Setting a custom bonus whose name already exists for the same target overwrites the previous one.

@*field* `mod_name` string — The mod owning this bonus. The bonus will be removed when the mod is removed.

@*field* `order` string? — String to alphabetically sort the custom bonus with.

@*field* `icons` CustomBonus.Icon[] — Icons to display.

@*field* `texts` LocalisedString[] — Text labels to display.

### CustomBonus.Icon

@*field* `type` CustomBonus.IconType — The type of the icon.

@*field* `name` string — Name of the prototype to display the icon of.

### CustomBonus.IconType

```lua
"sprite" | "item" | "tile" | "entity" | "virtual-signal" | "fluid" | "recipe" | "decorative" | "item-group" | "achievement" | "equipment" | "technology" | "asteroid-chunk" | "space-location"
```
