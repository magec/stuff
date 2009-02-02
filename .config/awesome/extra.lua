-- ###############################################################################
-- Insertar la siguiente linea en rc.lua despues de "beautiful.init(theme_path)":
-- loadfile(awful.util.getdir("config").."/extra.lua")()
-- ###############################################################################
-- {{{ Tema
awesome.font = "Terminus 10"
beautiful.font = "Terminus 10"
--beautiful.bg_normal     = '#222222AA'
--beautiful.bg_focus      = '#3465a4AA'
--beautiful.border_width  = 2
--beautiful.border_normal = '#555555'
beautiful.bg_normal     = '#000000AA'
beautiful.bg_focus      = '#2F4F4FAA'
beautiful.bg_urgent     = '#8B0000'
beautiful.fg_normal     = '#F5DEB3'
beautiful.fg_focus      = '#FFA500'
beautiful.fg_urgent     = '#FFFF00'
beautiful.border_width  = 1
beautiful.border_normal = '#2F4F4F66'
beautiful.border_focus  = '#FFA50066'
beautiful.border_marked = '#8B000066'
-- }}}
-- {{{ Inicializacion
-- usamos muchos widgets genericos de wicked
require("wicked")
modkey = "Mod4"
-- Wallpaper
imgpath = awful.util.getdir("config")..'/imgs/'
setrndwall = "awsetbg -t -r "..awful.util.getdir("config").."/walls"
setwall = "awsetbg -c "..awful.util.getdir("config").."/walls/vladstudio_microbes_1920x1200.jpg"
awful.util.spawn(setrndwall)
-- }}}
-- {{{ Widgets
-- {{{ Bateria (texto)
bat_ico = widget({ type = "imagebox", align = "right" })
bat_ico.image = image(imgpath..'bat.png')
--bat_ico.resize = false
bat_ico:buttons({button({ }, 1, function () awful.util.spawn('xterm') end)})
batterywidget = widget({type = "textbox"
                        , name = "batterywidget"
                        , align = "right"
                        })
function batteryInfo()
    local adapter = "BAT0"
    local fcur = io.open("/sys/class/power_supply/"..adapter.."/charge_now")
    if not fcur then
        return "A/C"
    end
    local fcap = io.open("/sys/class/power_supply/"..adapter.."/charge_full")
    local fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
    local cur = fcur:read()
    local cap = fcap:read()
    local sta = fsta:read()
    fcur:close()
    fcap:close()
    fsta:close()
    local battery = math.floor(cur * 100 / cap)
    if sta:match("Charging") then
        dir = "+"
        battery = "A/C ("..battery..")"
    elseif sta:match("Discharging") then
        dir = "-"
            if tonumber(battery) < 10 then
                naughty.notify({ title      = '<span color="white">Battery Warning</span>\n'
                               , text       = "Battery low!"..battery.."% left!"
                               , timeout    = 10
                               , position   = "top_right"
                               , fg         = beautiful.fg_focus
                               , bg         = beautiful.bg_focus
                               })
            end
    else
        dir = "="
        battery = "A/C"
    end
    return battery..dir
end
wicked.register(batterywidget, batteryInfo, "$1", 3)
-- }}}
-- {{{ Separador (text)
space = widget({
    type = 'textbox',
    name = 'space',
    align = 'right'
})
function pipe()
    return {" "}
end
wicked.register(space, pipe, '<span color="green">$1</span>')
-- }}}
-- {{{ Separadores (img)
Rseparator = widget({ type = 'imagebox'
        , name  = 'Rseparator'
        , align = 'right'
        })
Rseparator.image = image(awful.util.getdir("config").."/imgs/separador2.png")
Rseparator.resize = false
--
Lseparator = widget({ type = 'imagebox'
        , name  = 'Lseparator'
        , align = 'left'
        })
Lseparator.image = image(awful.util.getdir("config").."/imgs/separador2.png")
Lseparator.resize = false
-- }}}
-- {{{ mpd (text) requiere mpc
--
mpd_ico = widget({ type = "imagebox", align = "left" })
mpd_ico.image = image(imgpath..'mpd.png')
--mpd_ico.resize = false
mpd_ico:buttons({button({ }, 1, function () awful.util.spawn('urxvtc -e ncmpcpp') end)})
mpdwidget = widget({ type = 'textbox'
            ,name   = 'mpdwidget'
        ,align  = 'flex'
        })
wicked.register(mpdwidget, wicked.widgets.mpd, '"$1"')
mpdwidget:buttons({
    button({ }, 1, function ()
        awful.util.spawn('mpc play')
    end),
    button({ }, 2, function ()
        awful.util.spawn('mpc stop')
    end),
    button({ }, 3, function ()
        awful.util.spawn('mpc pause')
    end),
    button({ }, 4, function()
        awful.util.spawn('mpc prev')
        wicked.widgets.mpd()
        mpdwidget.mouse_enter()
    end),
    button({ }, 5, function()
        awful.util.spawn('mpc next')
        wicked.widgets.mpd()
        mpdwidget.mouse_enter()
    end),
})
mpdwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = awful.util.pread("mpc; echo ; mpc stats")
    pop = naughty.notify({  title      = '<span color="white">MPC Stats</span>\n'
                      , text       = awful.util.escape(text)
                      , icon       = imgpath..'mpd.png'
                      , icon_size  = 28
                      , timeout    = 0
                      , width      = 400
                      , position   = "bottom_left"
                      , bg         = beautiful.bg_focus
                      })
end
mpdwidget.mouse_leave = function() naughty.destroy(pop) end
-- }}}
-- {{{ Memory (text)
--
mem_ico = widget({ type = "imagebox", align = "right" })
mem_ico.image = image(imgpath..'mem.png')
--mem_ico.resize = false
mem_ico:buttons({button({ }, 1, function () awful.util.spawn('urxvtc -e htop') end)})
memwidget = widget({
    type = 'textbox',
    name = 'memwidget',
    align = 'right'
})
wicked.register(memwidget, wicked.widgets.mem, '$2Mb($1%)')
memwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = awful.util.pread("free")
    pop = naughty.notify({  title  = '<span color="white">Free</span>\n'
                      , text       = awful.util.escape(text)
                      , icon       = imgpath..'mem.png'
                      , icon_size  = 32
                      , timeout    = 0
                      , width      = 700
                      , position   = "bottom_right"
                      , bg         = beautiful.bg_focus
                      })
end
memwidget.mouse_leave = function() naughty.destroy(pop) end
--- }}}
-- {{{ Swap (text)
--
line = awful.util.pread("grep -i swap /etc/fstab | head -1")
if string.match(line, 'swap') then
    swp_ico = widget({ type = "imagebox", align = "right" })
    swp_ico.image = image(imgpath..'swp.png')
    --swp_ico.resize = false
    swp_ico:buttons({button({ }, 1, function () awful.util.spawn('urxvtc -e htop') end)})
    swpwidget = widget({
        type = 'textbox',
        name = 'swpwidget',
        align = 'right'
    })
    wicked.register(swpwidget, wicked.widgets.swap, '$2Mb($1%)')
    swpwidget.mouse_enter = function()
        naughty.destroy(pop)
        local text = awful.util.pread("cat /proc/meminfo")
        pop = naughty.notify({  title  = '<span color="white">/proc/meminfo</span>\n'
                          , text       = awful.util.escape(text)
                          , icon       = imgpath..'swp.png'
                          , icon_size  = 32
                          , timeout    = 0
                          , position   = "bottom_right"
                          , bg         = beautiful.bg_focus
                          })
    end
    swpwidget.mouse_leave = function() naughty.destroy(pop) end
end
--- }}}
-- {{{ Mem (bar)
--
membarwidget = widget({ type = 'progressbar'
            , name = 'membarwidget'
            , align = 'right'
            })
membarwidget.width = 50
membarwidget.height = 0.8
membarwidget.gap = 5
membarwidget.ticks_count = 20
membarwidget.ticks_gap = 1
membarwidget:bar_properties_set('mem', { bg = '#222222'
                                        , fg = '#00FF00'
                                        , fg_center = '#777700'
                                        , fg_end = '#FF0000'
                                        , fg_off = '#222222'
                                        , reverse = false
                                        , max_value = 100
                                        , border_color = '#FFFFFF'
                                        })
wicked.register(membarwidget, wicked.widgets.mem, '$1', 1, 'mem')
-- }}}
-- {{{ Cpu (text)
--
cpuwidget = widget({
    type = 'textbox',
    name = 'cpuwidget',
    align = 'right'
})
wicked.register(cpuwidget, wicked.widgets.cpu, '<span color="white">C1:</span>$2%<span color="white"> C2:</span>$3%', nil, nil, 2)
-- }}}
-- {{{ Cpu (bar)
--

cpu_ico = widget({ type = "imagebox", align = "right" })
cpu_ico.image = image(imgpath..'cpu.png')
--cpu_ico.resize = false
cpu_ico:buttons({button({ }, 1, function () awful.util.spawn('urxvtc -e htop') end)})
cpugraphwidget = widget({ type = 'graph'
                        , name = 'cpugraphwidget'
                        , align = 'right'
                        })
cpugraphwidget.height = 0.8
cpugraphwidget.width = 40
cpugraphwidget.bg = '#222222'
cpugraphwidget.border_color = '#FFFFFF'
cpugraphwidget.grow = 'left'
cpugraphwidget:plot_properties_set('cpu', { fg = '#00FF00'
                                        , fg_center = '#777700'
                                        , fg_end = '#FF0000'
                                        , vertical_gradient = true
                                        })
wicked.register(cpugraphwidget, wicked.widgets.cpu, '$1', 1, 'cpu')
cpuwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = awful.util.pread("ps afo pid,tty,stat,time,pcpu,pmem,comm")
    pop = naughty.notify({  title      = '<span color="white">Processes</span>\n'
                      , text       = awful.util.escape(text)
                      , icon       = imgpath..'cpu.png'
                      , icon_size  = 28
                      , timeout    = 0
                      , width      = 600
                      , position   = "bottom_right"
                      , bg         = beautiful.bg_focus
                      })
end
cpuwidget.mouse_leave = function() naughty.destroy(pop) end

-- }}}
-- {{{ FileSystem (text)
--
fs_ico = widget({ type = "imagebox", align = "right" })
fs_ico.image = image(imgpath..'fs.png')
--fs_ico.resize = false
fs_ico:buttons({button({ }, 1, function () awful.util.spawn('urxvtc -e mc') end)})
fswidget = widget({
    type = 'textbox',
    name = 'fswidget',
    align = 'right'
})
fs_args = '<span color="white">/:</span>${/ usep}%'
line = awful.util.pread("grep -i home /etc/fstab | head -1")
if string.match(line, 'home') then
    fs_args = fs_args..'<span color="white">~:</span>${/home usep}%'
end
line = awful.util.pread("grep -i /opt /etc/fstab | head -1")
if string.match(line, 'opt') then
    fs_args = fs_args..'<span color="white">/OPT:</span>${/opt usep}%'
end
wicked.register(fswidget, wicked.widgets.fs, fs_args, 10)
wicked.widgets.fs()
fswidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = awful.util.pread("df -ha")
    pop = naughty.notify({  title  = '<span color="white">Disk Usage</span>\n'
                      , text       = awful.util.escape(text)
                      , icon       = imgpath..'fs.png'
                      , icon_size  = 32
                      , timeout    = 0
                      , width      = 550
                      , position   = "bottom_right"
                      , bg         = beautiful.bg_focus
                      })
end
fswidget.mouse_leave = function() naughty.destroy(pop) end
--- }}}
-- {{{ Net (text)
--
net_ico = widget({ type = "imagebox", align = "right" })
net_ico.image = image(imgpath..'net-wired.png')
--net_ico.resize = false
net_ico:buttons({button({ }, 1, function () awful.util.spawn('xterm') end)})
netwidget = widget({
    type = 'textbox',
    name = 'netwidget',
    align = 'right'
})
wicked.register(netwidget, wicked.widgets.net, '${eth0 down}', 5, nil, 3)
-- <span color="white">[</span>${eth0 rx} rx<span color="white">/</span>${eth0 tx} tx<span color="white">]</span>', 5, nil, 3)
netwidget.mouse_enter = function()
    naughty.destroy(pop)
    local listen = awful.util.pread("netstat -patun | awk '/ESTABLISHED/{ if ($4 !~ /127.0.0.1|localhost/) print  \"(\"$7\")\t\"$5}'")
    pop = naughty.notify({  title      = '<span color="white">Established</span>\n'
                      , text       = awful.util.escape(listen)
                      , icon       = imgpath..'net-wired.png'
                      , icon_size  = 32
                      , timeout    = 0
                      , position   = "bottom_right"
                      , width      = 350
                      , bg         = beautiful.bg_focus
                      })
end
netwidget.mouse_leave = function() naughty.destroy(pop) end
-- }}}
-- {{{ Load (text)
--
load_ico = widget({ type = "imagebox", align = "right" })
load_ico.image = image(imgpath..'load.png')
--load_ico.resize = false
load_ico:buttons({button({ }, 1, function () awful.util.spawn('urxvtc -e htop') end)})

loadwidget = widget({ type = 'textbox'
                    , name = 'loadwidget'
                    , align = 'right'
                    })
wicked.register(loadwidget, 'function', function (widget, args)
  local f = io.open('/proc/loadavg')
  local n = f:read()
  f:close()
  local pos = n:find(' ', n:find(' ', n:find(' ')+1)+1)
  return  n:sub(1,pos-1)
end, 2)
loadwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = awful.util.pread("uptime; echo; who")
    pop = naughty.notify({  title  = '<span color="white">Uptime</span>\n'
                      , text       = awful.util.escape(text)
                      , icon       = imgpath..'load.png'
                      , icon_size  = 32
                      , timeout    = 0
                      , width      = 600
                      , position   = "bottom_right"
                      , bg         = beautiful.bg_focus
                      })
end
loadwidget.mouse_leave = function() naughty.destroy(pop) end
-- }}}
-- {{{ Volume (Custom) requiere alsa-utils
--
line = awful.util.pread("amixer -c 0 | head -1")
channel = string.match(line, ".+'(%w+)'.+")
function getVol()
    local status = io.popen("amixer -c 0 -- sget ".. channel):read("*all")
    local volume = string.match(status, "(%d?%d?%d)%%")
    volume = string.format("%3d", volume)
    status = string.match(status, "%[(o[^%]]*)%]")
    if status and string.find(status, "on", 1, true) then
        volume = volume.."%"
    else
        volume = volume.."M"
    end
        volumewidget.text = volume
        return volume
end
if channel then
    vol_ico = widget({ type = "imagebox", align = "left" })
    vol_ico.image = image(imgpath..'vol.png')
    --vol_ico.resize = false
    vol_ico:buttons({button({ }, 1, function () awful.util.spawn('urxvtc -e alsamixer') end)})
    volumewidget = widget({ type = 'textbox'
                , name = 'volumewidget'
                , align = 'left'
                })
    wicked.register(volumewidget, getVol, "$1", 5)
    volumewidget:buttons({
        button({ }, 4, function()
             awful.util.spawn('amixer -c 0 set '..channel..' 3dB+');
             getVol()
        end),
        button({ }, 5, function()
             awful.util.spawn('amixer -c 0 set '..channel..' 3dB-');
             getVol()
        end),
    })
end
-- }}}
-- Cierre de Widgets}}}
-- {{{ Wibox
for s = 1, screen.count() do
    -- Defino la barra
    mywibox_b = {}
    -- La creo
    mywibox_b[s] = wibox({ position = "bottom"
                , fg = beautiful.fg_normal
                , bg = beautiful.bg_normal
                , border_color = beautiful.border_normal
                , height = 16
                , border_width = 1
                })
    -- Le enchufo los widgets
    mywibox_b[s].widgets = { vol_ico
                , volumewidget
                , Lseparator
                , mpd_ico
                , mpdwidget
                , Rseparator
                , load_ico
                , loadwidget
                , Rseparator
                , cpu_ico
                , cpuwidget
                , cpugraphwidget
                , Rseparator
                , mem_ico
                , memwidget
                , membarwidget
                , swp_ico
                , swpwidget
                , Rseparator
                , bat_ico
                , batterywidget
                , Rseparator
                , fs_ico
                , fswidget
                , Rseparator
                , net_ico
                , netwidget
                , s == 1 and mysystray or nil }
    mywibox_b[s].screen = s
end
-- }}}
--  {{{ Mis Hotkeys
my_keys = {}
table.insert(my_keys, key({ modkey, "Control" }, "w", function () awful.util.spawn(setrndwall) end))
table.insert(my_keys, key({ modkey, "Control" }, "q", function () awful.util.spawn(setwall) end))
table.insert(my_keys, key({ modkey, "Control" }, "t", function () awful.util.spawn('thunar') end))
table.insert(my_keys, key({ modkey, "Control" }, "p", function () awful.util.spawn('pidgin') end))
table.insert(my_keys, key({ modkey, "Control" }, "c", function () awful.util.spawn('urxvtc -e mc') end))
table.insert(my_keys, key({ modkey, "Control" }, "f", function () awful.util.spawn('firefox') end))
table.insert(my_keys, key({ modkey, "Control" }, "g", function () awful.util.spawn('gvim') end))
table.insert(my_keys, key({ modkey, "Control" }, "a", function () awful.util.spawn('ruc_web_resolucio.sh') end))
table.insert(my_keys, key({ modkey, "Control" }, "s", function () awful.util.spawn('slock') end))
table.insert(my_keys, key({ modkey, "Control" }, "v", function () awful.util.spawn('urxvtc -e ncmpcpp') end))
table.insert(my_keys, key({ modkey, "Control" }, "b", function () awful.util.spawn('mpc play') end))
table.insert(my_keys, key({ modkey, "Control" }, "n", function () awful.util.spawn('mpc pause') end))
table.insert(my_keys, key({ modkey, "Control" }, "m", function () awful.util.spawn('mpc prev'); wicked.widgets.mpd() end))
table.insert(my_keys, key({ modkey, "Control" }, ",", function () awful.util.spawn('mpc next'); wicked.widgets.mpd() end))
table.insert(my_keys, key({ modkey, "Control" }, ".", function () awful.util.spawn('amixer -c 0 set '..channel..' 3dB-'); getVol() end))
table.insert(my_keys, key({ modkey, "Control" }, "-", function () awful.util.spawn('amixer -c 0 set '..channel..' 3dB+'); getVol() end))
table.insert(my_keys, key({ modkey }, "Up", function () awful.client.focus.byidx(1); if client.focus then client.focus:raise() end end))
table.insert(my_keys, key({ modkey }, "Down", function () awful.client.focus.byidx(-1);  if client.focus then client.focus:raise() end end))
-- }}}
--- Revelation {{{
require("revelation")
table.insert(my_keys, key({ modkey, "Control" }, "x", revelation.revelation))
--- }}}
