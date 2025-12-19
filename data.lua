local constants = require("constants")

local styles = data.raw["gui-style"]["default"]

styles[constants.style_prefix.."scroll_pane"] = {
    type = "scroll_pane_style",
    extra_padding_when_activated = 0,
}

styles[constants.style_prefix.."table"] = {
    type = "table_style",
    horizontal_spacing = 0,
    vertical_spacing = 0,
    vertically_stretchable = "off",
}
