theme = {}

theme.font          = "smoothansi 9"

--bg
theme.bg_normal     = "#222222AA"
theme.bg_focus      = "#2F4F4FAA"
theme.bg_urgent     = "#8B0000"
theme.bg_minimize   = "#444444"

--fg
theme.fg_normal     = "#F5DEB3"
theme.fg_focus      = "#FFA500"
theme.fg_urgent     = "#FFFF00"
theme.fg_minimize   = "#ffffff"

--border
theme.border_width  = "2"
theme.border_normal = "#2F4F4F66"
theme.border_focus  = "#FFA50066"
theme.border_marked = "#8B000066"

-- There are another variables sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- Example:
--taglist_bg_focus = #ff0000

-- Display the taglist squares
theme.taglist_squares_sel = "/usr/share/awesome/themes/default/taglist/squarefw.png"
theme.taglist_squares_unsel = "/usr/share/awesome/themes/default/taglist/squarew.png"
theme.tasklist_floating_icon = "/usr/share/awesome/themes/default/tasklist/floatingw.png"

-- You can use your own command to set your wallpaper
--theme.wallpaper_cmd = { "awsetbg -t -r /home/oscar/.config/awesome/walls/" }
theme.wallpaper_cmd = { 'awsetbg -t -r '..os.getenv("HOME")..'/.config/awesome/walls/' }

-- You can use your own layout icons like this:
theme.layout_fairh = os.getenv("HOME")..'/.config/awesome/layouts/fairhw.png'
theme.layout_fairv = os.getenv("HOME")..'/.config/awesome/layouts/fairvw.png'
theme.layout_floating = os.getenv("HOME")..'/.config/awesome/layouts/floatingw.png'
theme.layout_magnifier = os.getenv("HOME")..'/.config/awesome/layouts/magnifierw.png'
theme.layout_max = os.getenv("HOME")..'/.config/awesome/layouts/maxw.png'
theme.layout_fullscreen = os.getenv("HOME")..'/.config/awesome/layouts/fullscreenw.png'
theme.layout_tilebottom = os.getenv("HOME")..'/.config/awesome/layouts/tilebottomw.png'
theme.layout_tileleft = os.getenv("HOME")..'/.config/awesome/layouts/tileleftw.png'
theme.layout_tile = os.getenv("HOME")..'/.config/awesome/layouts/tilew.png'
theme.layout_tiletop = os.getenv("HOME")..'/.config/awesome/layouts/tiletopw.png'

return theme
