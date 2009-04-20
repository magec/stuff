-- ###############################################################################
-- loadfile(awful.util.getdir("config").."/extra.lua")()
-- ###############################################################################
--{{{   Tema
--awesome.font = "smoothansi 10"
--beautiful.font = "smoothansi 10"
--
--beautiful.bg_normal     = '#222222AA'
--beautiful.bg_focus      = '#3465a4AA'
--beautiful.bg_normal     = '#000000AA'
--beautiful.bg_focus      = '#2F4F4FAA'
--beautiful.bg_urgent     = '#8B0000'
--beautiful.fg_normal     = '#F5DEB3'
--beautiful.fg_focus      = '#FFA500'
--beautiful.fg_urgent     = '#FFFF00'
--beautiful.border_width  = 1
--beautiful.border_normal = '#2F4F4F66'
--beautiful.border_focus  = '#FFA50066'
--beautiful.border_marked = '#8B000066'
--}}}
--{{{   Inicializacion
--  usamos muchos widgets genericos de wicked
require("wicked")
--  Wallpaper
imgpath = awful.util.getdir("config")..'/imgs/'
setrndwall = "awsetbg -t -r "..awful.util.getdir("config").."/walls"
setwall = "awsetbg -c "..awful.util.getdir("config").."/walls/vladstudio_microbes_1920x1200.jpg"
--}}}
--{{{   Util
function escape(text)
    return awful.util.escape(text or 'nil')
end

-- Copy from awful.util
function pread(cmd)
    if cmd and cmd ~= '' then
        local f, err = io.popen(cmd, 'r')
        if f then
            local s = f:read('*all')
            f:close()
            return s
        else
            print(err)
        end
    end
end
-- Same as pread, but files instead of processes
function fread(cmd)
    if cmd and cmd ~= '' then
        local f, err = io.open(cmd, 'r')
        if f then
            local s = f:read('*all')
            f:close()
            return s
        else
            print(err)
        end
    end
end
--
function createIco(widget,file,click)
    if not widget or not file or not click then return nil end
    widget.image = image(imgpath..'/'..file)
    widget.resize = true
    widget:buttons({button({ }, 1, function () awful.util.spawn(click) end)})
end
--}}}
-- {{{ Bateria (texto)
battery = io.open("/sys/class/power_supply/BAT0/charge_now")
if battery  then
    wicked.register(batterywidget, batteryInfo, "$1", 3)

    bat_ico = widget({ type = "imagebox", align = "right" })
    createIco(bat_ico,'bat.png','urxvtc -e xterm')

    batterywidget = widget({type = "textbox"
                            , name = "batterywidget"
                            , align = "right"
                            })

    batterywidget.mouse_enter = function()
        naughty.destroy(pop)

        local text = awful.util.pread("cat /proc/acpi/battery/BAT0/info")
        pop = naughty.notify({  title  = '<span color="white">BAT0/info</span>\n'
                      , text       = awful.util.escape(text)
                      , icon       = imgpath..'swp.png'
                      , icon_size  = 32
                      , timeout    = 0
                      , position   = "bottom_right"
                      , bg         = beautiful.bg_focus
                      })
    end

    batterywidget.mouse_leave = function() naughty.destroy(pop) end
end

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
        battery = "A/C("..battery..")"
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
createIco(mpd_ico,'mpd.png','urxvtc -e ncmpcpp')

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
createIco(mem_ico,'mem.png','urxvtc -e htop')

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
    createIco(swp_ico,'swp.png','urxvtc -e htop')

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
createIco(cpu_ico,'cpu.png','urxvtc -e htop')

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
createIco(fs_ico,'fs.png','urxvtc -e fdisk -l')

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
createIco(net_ico,'net-wired.png','urxvtc -e netstat -ltunpp')

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
createIco(load_ico,'load.png','urxvtc -e htop')

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
function getVol(widget, mixer)
    if not widget or not mixer then return nil end
    local vol = ''
    local txt = pread('amixer get '..mixer)
    if txt:match('%[off%]') then
        vol = 'Mute'
    else
        vol = txt:match('%[(%d+%%)%]')
    end

    widget.text = vol
end
--
line = awful.util.pread("amixer -c 0 | head -1")
if line and line ~= '' then
    channel = string.match(line, ".+'(%w+)'.+")
end
--
if channel and channel ~= '' then
    vol_ico = widget({ type = "imagebox", align = "left" })
    createIco(vol_ico,'vol.png','urxvtc -e alsamixer')
    volumewidget = widget({ type = 'textbox'
                , name = 'volumewidget'
                , align = 'left'
                })
    getVol(volumewidget, channel)
    volumewidget:buttons({
        button({ }, 4, function()
             awful.util.spawn('amixer -c 0 set '..channel..' 3dB+');
            getVol(volumewidget, channel)
        end),
        button({ }, 5, function()
             awful.util.spawn('amixer -c 0 set '..channel..' 3dB-');
             getVol(volumewidget, channel)
        end),
    })
end
-- }}}
-- {{{ Wibox
for s = 1, screen.count() do
    -- Defino la barra
    statusbar = {}
    -- La creo
    statusbar[s] = wibox({ position = "bottom"
                , fg = beautiful.fg_normal
                , bg = beautiful.bg_normal
                , border_color = beautiful.border_normal
                , height = 16
                , border_width = 1
                })
    -- Le enchufo los widgets
    statusbar[s].widgets = { vol_ico
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
                           , mem_ico
                           , memwidget
                           , membarwidget
                           , swp_ico
                           , swpwidget
                           , Rseparator
                           , bat_ico
                           , batterywidget
                           , batterywidget and Rseparator or nil
                           , fs_ico
                           , fswidget
                           , Rseparator
                           , net_ico
                           , netwidget
                           }
    statusbar[s].screen = s
end
-- }}}
--  {{{ Mis Hotkeys
--my_keys = {}
--table.insert(my_keys, key({ modkey, "Control" }, "w", function () awful.util.spawn(setrndwall) end))
--table.insert(my_keys, key({ modkey, "Control" }, "q", function () awful.util.spawn(setwall) end))
--table.insert(my_keys, key({ modkey, "Control" }, "t", function () awful.util.spawn('thunar') end))
--table.insert(my_keys, key({ modkey, "Control" }, "p", function () awful.util.spawn('pidgin') end))
--table.insert(my_keys, key({ modkey, "Control" }, "c", function () awful.util.spawn('urxvtc -e mc') end))
--table.insert(my_keys, key({ modkey, "Control" }, "f", function () awful.util.spawn('firefox') end))
--table.insert(my_keys, key({ modkey, "Control" }, "g", function () awful.util.spawn('gvim') end))
--table.insert(my_keys, key({ modkey, "Control" }, "a", function () awful.util.spawn('ruc_web_resolucio.sh') end))
--table.insert(my_keys, key({ modkey, "Control" }, "s", function () awful.util.spawn('sonata') end))
--table.insert(my_keys, key({ modkey, "Control" }, "x", function () awful.util.spawn('slock') end))
--table.insert(my_keys, key({ modkey, "Control" }, "v", function () awful.util.spawn('urxvtc -e ncmpcpp') end))
--table.insert(my_keys, key({ modkey, "Control" }, "0", function () awful.util.spawn('xrandr -o left') end))
--table.insert(my_keys, key({ modkey, "Control" }, "'", function () awful.util.spawn('xrandr -o normal') end))
--table.insert(my_keys, key({ modkey, "Control" }, "b", function () awful.util.spawn('mpc play') end))
--table.insert(my_keys, key({ modkey, "Control" }, "n", function () awful.util.spawn('mpc pause') end))
--table.insert(my_keys, key({ modkey, "Control" }, "m", function () awful.util.spawn('mpc prev'); wicked.widgets.mpd() end))
--table.insert(my_keys, key({ modkey, "Control" }, ",", function () awful.util.spawn('mpc next'); wicked.widgets.mpd() end))
--table.insert(my_keys, key({ modkey, "Control" }, ".", function () awful.util.spawn('amixer -c 0 set '..channel..' 3dB-'); getVol() end))
--table.insert(my_keys, key({ modkey, "Control" }, "-", function () awful.util.spawn('amixer -c 0 set '..channel..' 3dB+'); getVol() end))
--table.insert(my_keys, key({ modkey }, "Up", function () awful.client.focus.byidx(1); if client.focus then client.focus:raise() end end))
--table.insert(my_keys, key({ modkey }, "Down", function () awful.client.focus.byidx(-1);  if client.focus then client.focus:raise() end end))
-- }}}
--- Revelation {{{
--require("revelation")
--table.insert(my_keys, key({ modkey, "Control" }, "x", revelation.revelation))
--- }}}
