-- #############################################################################
-- loadfile(awful.util.getdir("config").."/extra.lua")()
-- #############################################################################
--{{{    Inicializacion
--------------------------------------------------------------------------------
--  usamos muchos widgets genericos de wicked
require("wicked")
--  Wallpaper
imgpath = awful.util.getdir("config")..'/imgs/'
setrndwall = "awsetbg -t -r "..awful.util.getdir("config").."/walls"
setwall = "awsetbg -c "..awful.util.getdir("config").."/walls/vladstudio_microbes_1920x1200.jpg"
--}}}
--{{{    Util
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
-- Modificada para leer ficheros.
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
function createIco(widget,file,click)
    if not widget or not file or not click then return nil end
    widget.image = image(imgpath..'/'..file)
    widget.resize = false
    widget:buttons({button({ }, 1, function () awful.util.spawn(click) end)})
end
--}}}
--{{{    Bateria (texto)
--------------------------------------------------------------------------------
function batInfo(widget)
    local cur = fread("/sys/class/power_supply/BAT0/charge_now")
    local cap = fread("/sys/class/power_supply/BAT0/charge_full")
    local sta = fread("/sys/class/power_supply/BAT0/status")
    if not cur or not cap or not sta then
        widget.text = 'ERR'
        return
    end
    local battery = math.floor(cur * 100 / cap)
    if sta:match("Charging") then
        dir = "+"
        battery = "A/C~"..battery
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
        battery = "A/C~"
    end
    widget.text = battery..dir
end
battery = io.open("/sys/class/power_supply/BAT0/charge_now")
if battery then
    bat_ico = widget({ type = "imagebox", align = "right" })
    createIco(bat_ico,'bat.png','urxvtc -e xterm')
    batterywidget = widget({ type  = "textbox"
                           , name  = "batterywidget"
                           , align = "right"
                           })
    batInfo(batterywidget)
    batterywidget.mouse_enter = function()
        naughty.destroy(pop)
        local text = fread("/proc/acpi/battery/BAT0/info")
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
--}}}
--{{{    Separador (text)
space = widget({
    type = 'textbox',
    name = 'space',
    align = 'right'
})
function pipe()
    return {" "}
end
wicked.register(space, pipe, '<span color="green">$1</span>')
--}}}
--{{{    Separadores (img)
--------------------------------------------------------------------------------
Rseparator = widget({ type = 'imagebox'
        , name  = 'Rseparator'
        , align = 'right'
        })
Rseparator.image = image(awful.util.getdir("config").."/imgs/separador2.png")
Rseparator.resize = false
Lseparator = widget({ type = 'imagebox'
        , name  = 'Lseparator'
        , align = 'left'
        })
Lseparator.image = image(awful.util.getdir("config").."/imgs/separador2.png")
Lseparator.resize = false
--}}}
--{{{    mpd (text) requiere mpc
--------------------------------------------------------------------------------
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
    local text = pread("mpc; echo ; mpc stats")
    pop = naughty.notify({ title     = '<span color="white">MPC Stats</span>\n'
                         , text      = awful.util.escape(text)
                         , icon      = imgpath..'mpd.png'
                         , icon_size = 28
                         , timeout   = 0
                         , width     = 400
                         , position  = "bottom_left"
                         , bg        = beautiful.bg_focus
                         })
end
mpdwidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    Memory (text)
--------------------------------------------------------------------------------
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
    local text = pread("free")
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
---}}}
--{{{    Swap (text)
--------------------------------------------------------------------------------
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
        local text = fread("/proc/meminfo")
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
---}}}
--{{{    Mem (bar)
--------------------------------------------------------------------------------
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
--}}}
--{{{    Cpu (text)
--------------------------------------------------------------------------------
cpuwidget = widget({
    type = 'textbox',
    name = 'cpuwidget',
    align = 'right'
})
wicked.register(cpuwidget, wicked.widgets.cpu, '<span color="white">C1:</span>$2%<span color="white"> C2:</span>$3%', nil, nil, 2)
--}}}
--{{{    Cpu (bar)
--------------------------------------------------------------------------------
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
    local text = pread("ps afo pid,tty,stat,time,pcpu,pmem,comm")
    pop = naughty.notify({ title     = '<span color="white">Processes</span>\n'
                         , text      = awful.util.escape(text)
                         , icon      = imgpath..'cpu.png'
                         , icon_size = 28
                         , timeout   = 0
                         , width     = 600
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
end
cpuwidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    FileSystem (text)
--------------------------------------------------------------------------------
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
    local text = pread("df -ha")
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
--}}}
--{{{    Net (text)
--------------------------------------------------------------------------------
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
--}}}
--{{{    Load (text)
--------------------------------------------------------------------------------
load_ico = widget({ type = "imagebox", align = "right" })
createIco(load_ico,'load.png','urxvtc -e htop')
loadwidget = widget({ type = 'textbox'
                    , name = 'loadwidget'
                    , align = 'right'
                    })
wicked.register(loadwidget, 'function', function (widget, args)
  local n = fread('/proc/loadavg')
  local pos = n:find(' ', n:find(' ', n:find(' ')+1)+1)
  return  n:sub(1,pos-1)
end, 2)
loadwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = pread("uptime; echo; who")
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
--}}}
--{{{    Volume (Custom) requiere alsa-utils
--------------------------------------------------------------------------------
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
line = pread("amixer -c 0 | head -1")
if line and line ~= '' then
    channel = string.match(line, ".+'(%w+)'.+")
end
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
--}}}
--{{{    Wibox
--------------------------------------------------------------------------------
for s = 1, screen.count() do
    -- Defino la barra
    statusbar = {}
    -- La creo
    statusbar[s] = wibox({ position = "bottom"
                , fg = beautiful.fg_normal
                , bg = beautiful.bg_normal
                , border_color = beautiful.border_normal
                , height = 15
                , border_width = 1
                })
    -- Le enchufo los widgets
    statusbar[s].widgets = { vol_ico
                           , volumewidget
                           , volumewidget and Lseparator or nil
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
--}}}
