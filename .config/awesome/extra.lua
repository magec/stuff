-- #############################################################################
-- loadfile(awful.util.getdir("config").."/extra.lua")()
-- #############################################################################
--{{{    Inicializacion
--------------------------------------------------------------------------------
imgpath = awful.util.getdir("config")..'/imgs/'
confdir = awful.util.getdir("config")..'/'
setrndwall = "awsetbg -t -r "..awful.util.getdir("config").."/walls"
setwall = "awsetbg -c "..awful.util.getdir("config").."/walls/vladstudio_microbes_1920x1200.jpg"
--}}}
--{{{    Utilidades/Funciones
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
--  menos bloat creando iconos
function createIco(widget,file,click)
    if not widget or not file or not click then return nil end
    widget.image = image(imgpath..'/'..file)
    widget.resize = false
    widget:buttons({button({ }, 1, function () os.execute(click) end)})
end
-- Converts bytes to human-readable units, returns value (number) and unit (string)
function bytestoh(bytes)
    local tUnits={"KB","GB","GB","TB","PB"} -- MUST be enough. :D
    local v,u
    for k=table.getn(tUnits),1,-1 do
        if math.mod(bytes,1024^k)~=bytes then v=bytes/(1024^k); u=tUnits[k] break end
    end
    return v or bytes,u or "B"
end





--}}}
--{{{    GMail (imagebox+textbox)
--------------------------------------------------------------------------------
--  Datos de gmail
mailadd  = 'oprietop@intranet.uoc.edu'
mailpass = escape(fread(confdir..mailadd..'.passwd'))
mailurl  = 'https://mail.google.com/a/intranet.uoc.edu/feed/atom/unread'
-- mailurl  = 'https://mail.google.com/feed/atom/unread'
--  Actualiza el estadop del widget a partir de un feed de gmail bajado.
function check_gmail()
    local feed = fread(confdir..mailadd)
    if not feed or feed == '' then
         return nil
    end
    if not count then
        count = 0
    end
    local lcount = 0
    if feed:match('fullcount>%d+<') then
        lcount = feed:match('fullcount>(%d+)<')
    else
        return '<span color="red">No "fullcount" TAG.</span>'
    end
    if lcount ~= count then
        for title,summary,name,email in feed:gmatch('<entry>\n<title>(.-)</title>\n<summary>(.-)</summary>.-<name>(.-)</name>\n<email>(.-)</email>') do
            pop = naughty.notify({ title      = '<span color="white">New mail on </span>'..mailadd
                                 , text       = escape(name..' ('..email..')\n'..title..'\n'..summary)
                                 , timeout    = 20
                                 , position   = "top_right"
                                 , fg         = beautiful.fg_focus
                                 , bg         = beautiful.bg_focus
                                 })
        end
        count = lcount
    end
    if tonumber(lcount) > 0 then
        return '<span color="red">(<b>'..lcount..'</b>)</span>'
    else
        return nil
    end
end
--  lanza un wget en background para bajar el feed de gmail.
function getMail()
    if confdir and mailadd and mailpass and mailurl then
        local cmd = 'wget '..mailurl..' -qO '..confdir..mailadd..' --http-user='..mailadd..' --http-passwd='..mailpass
        os.execute(escape(cmd))
    end
end
--  imagebox
mail_ico = widget({ type = "imagebox", align = "right" })
createIco(mail_ico,'mail.png','firefox '..mailurl)
--  textbox
mailwidget = widget({ type  = "textbox"
                    , name  = "mailwidget"
                    , align = "right"
                    })
mailwidget.text=check_gmail()
--  mouse_enter
mailwidget.mouse_enter = function()
    count = 0
    check_gmail()
end
--  mouse_leave
mailwidget.mouse_leave = function() naughty.destroy(pop) end
--  buttons
mailwidget:buttons({
    button({ }, 1, function ()
        getMail()
        os.execute('firefox '..mailurl)
    end),
})
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
pop = naughty.notify({ title  = '<span color="white">BAT0/info</span>\n'
                     , text       = escape(text)
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
--{{{    Separadores (img)
--------------------------------------------------------------------------------
--  con align right
Rseparator = widget({ type = 'imagebox'
                    , name  = 'Rseparator'
                    , align = 'right'
                    })
Rseparator.image = image(awful.util.getdir("config").."/imgs/separador2.png")
Rseparator.resize = false
--  con align left
Lseparator = widget({ type = 'imagebox'
                    , name  = 'Lseparator'
                    , align = 'left'
                    })
Lseparator.image = image(awful.util.getdir("config").."/imgs/separador2.png")
Lseparator.resize = false
--}}}
--{{{    MPC (imagebox+textbox) requiere mpc/mpd
--------------------------------------------------------------------------------
--  Devuelve estado de mpc
function mpc_info()
    local now = pread("mpc")
    if now and now ~= '' then
        song,state,time = now:match('^(.-)\n%[(%w+)%]%s+#%d+/%d+%s+(.-)\nvolume')
        if state == 'playing' then
            if song and song ~= '' then
                return '[Play]<span color="white"> "'..escape(song)..'"</span> '..time
            end
        elseif state == 'paused' then
            if song and song ~= '' then
                return '[Wait] '..escape(song)..' '..time
            end
        elseif now:match('^volume:%s+%d+') then
            return '[Stop] ZZzzz...'
        else
            return '<span color="red">[DEAD]</span> :_('
        end
    else
        return '<span color="red">NO MPC</span> :_('
    end
end
--  imagebox
mpd_ico = widget({ type = "imagebox", align = "left" })
createIco(mpd_ico,'mpd.png','urxvtc -e ncmpcpp')
--  textbox
mpcwidget = widget({ type = 'textbox'
                   ,name  = 'mpcwidget'
                   ,align  = 'flex'
                   })
-- llamada inicial a la función
mpcwidget.text = mpc_info()
-- textbox buttons
mpcwidget:buttons({
    button({ }, 1, function ()
        os.execute('mpc play')
        mpcwidget.mouse_enter()
    end),
    button({ }, 2, function ()
        os.execute('mpc stop')
        mpcwidget.mouse_enter()
    end),
    button({ }, 3, function ()
        os.execute('mpc pause')
        mpcwidget.mouse_enter()
    end),
    button({ }, 4, function()
        os.execute('mpc prev')
        mpc_info()
        mpcwidget.mouse_enter()
    end),
    button({ }, 5, function()
        os.execute('mpc next')
        mpc_info()
        mpcwidget.mouse_enter()
    end),
})
--  mouse_enter
mpcwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = pread("mpc; echo ; mpc stats")
    pop = naughty.notify({ title     = '<span color="white">MPC Stats</span>\n'
                         , text      = escape(text)
                         , icon      = imgpath..'mpd.png'
                         , icon_size = 28
                         , timeout   = 0
                         , width     = 400
                         , position  = "bottom_left"
                         , bg        = beautiful.bg_focus
                         })
end
--  mouse_leave
mpcwidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    Memory (imagebox+textbox+progressbar)
--------------------------------------------------------------------------------
--  Devuelve la ram usada en MB(%). Tb actualiza la progressbar
function activeram()
    local total,free,buffers,cached,active,used,percent
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+):\ +(%d+).+") do
            if key == "MemTotal" then
                total = tonumber(value)
            elseif key == "MemFree" then
                free = tonumber(value)
            elseif key == "Buffers" then
                buffers = tonumber(value)
            elseif key == "Cached" then
                cached = tonumber(value)
            end
        end
    end
    active = total-(free+buffers+cached)
    used = string.format("%.0fMB",(active/1024))
    percent = string.format("%.0f",(active/total)*100)
    if membarwidget then
        membarwidget:bar_data_add('mem', percent)
    end
    return used..'('..percent..'%)'
end
--  imagebox
mem_ico = widget({ type = "imagebox", align = "right" })
createIco(mem_ico,'mem.png','urxvtc -e htop')
--  textbox
memwidget = widget({ type = 'textbox'
                   , name = 'memwidget'
                   , align = 'right'
                   })
--  progressbar
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
--  Llamada inicial a la función
memwidget.text = activeram()
--  mouse_enter
memwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = pread("free")
    pop = naughty.notify({  title  = '<span color="white">Free</span>\n'
                         , text       = escape(text)
                         , icon       = imgpath..'mem.png'
                         , icon_size  = 32
                         , timeout    = 0
                         , width      = 700
                         , position   = "bottom_right"
                         , bg         = beautiful.bg_focus
                         })
    end
--  mouse_leave
memwidget.mouse_leave = function() naughty.destroy(pop) end
---}}}
--{{{    Swap (imagebox+textbox)
--------------------------------------------------------------------------------
--  Devuelve la swap usada en MB(%)
function activeswap()
    local active, total, free
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+):\ +(%d+).+") do
            if key == "SwapTotal" then
                if tonumber(value) == 0 then
                    return nil -- No hay Swap!
                end
                total = tonumber(value)
            elseif key == "SwapFree" then
                free = tonumber(value)
            end
        end
    end
    active = total - free
    return string.format("%.0fMB",(active/1024))..'('..string.format("%.0f%%",(active/total)*100)..')'
end
--  imagebox
swp_ico = widget({ type = "imagebox", align = "right" })
createIco(swp_ico,'swp.png','urxvtc -e htop')
--  textbox
swpwidget = widget({ type = 'textbox'
                   , name = 'swpwidget'
                   , align = 'right'
                   })
--  llamada inicial a la función
swpwidget.text = activeswap()
--  mouse_enter
swpwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = fread("/proc/meminfo")
    pop = naughty.notify({  title  = '<span color="white">/proc/meminfo</span>\n'
                         , text       = escape(text)
                         , icon       = imgpath..'swp.png'
                         , icon_size  = 32
                         , timeout    = 0
                         , position   = "bottom_right"
                         , bg         = beautiful.bg_focus
                         })
    end
--  mouse_leave
swpwidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    Cpu (imagebox+textbox+graph)
--------------------------------------------------------------------------------
--  Devuelve el % de uso de cada CPU y actualiza la gráfica con la media.
--  user + nice + system + idle = 100/second
--  so diffs of: $2+$3+$4 / all-together * 100 = %
--  or: 100 - ( $5 / all-together) * 100 = %
--  or: 100 - 100 * ( $5 / all-together)= %
function cpu_info()
    if not cpu then
        cpu={}
    end
    local s = 0
    local info = fread("/proc/stat")
    if not info then
        return "Error leyendo /proc/stat"
    end
    for user,nice,system,idle in info:gmatch("cpu.-%s(%d+)%s+(%d+)%s+(%d+)%s+(%d+)") do
        if not cpu[s] then
            cpu[s]={}
            cpu[s].sum  = 0
            cpu[s].res  = 0
            cpu[s].idle = 0
        end
        local new_sum   = user + nice + system + idle
        local diff      = new_sum - cpu[s].sum
        cpu[s].res  = 100
        if diff > 0 then -- should be always true - but on heavy load no update is possible
            cpu[s].res = 100 - 100 * (idle - cpu[s].idle) / diff
        end
        cpu[s].sum  = new_sum
        cpu[s].idle = idle
        s = s + 1
    end
    -- next(cpu) devuelve nil si la tabla cpu está vacía
    if not next(cpu) then
        return "No hay cpus en /proc/stat"
    end
    if cpugraphwidget and cpu[0].res then
        cpugraphwidget:plot_data_add('cpu', cpu[0].res)
    end
    info = ''
    for s = 0, #cpu do
        if cpu[s].res > 99 then
            info = info..'<span color="white">C'..s..':</span><span color="red">LOL</span>'
        else
            info = info..'<span color="white">C'..s..':</span>'..string.format("%02d",cpu[s].res)..'%'
        end
        if s ~= #cpu then
            info = info..' '
        end
    end
    return info
end
--  imagebox
cpu_ico = widget({ type = "imagebox", align = "right" })
createIco(cpu_ico,'cpu.png','urxvtc -e htop')
--  textbox
cpuwidget = widget({ type = 'textbox'
                   , name = 'cpuwidget'
                   , align = 'right'
                   })
--  graph
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
--  primera llamada a la función
cpuwidget.text = cpu_info()
--  mouse_enter
cpuwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = pread("ps -eo %cpu,%mem,ruser,pid,comm --sort -%cpu | head -20")
    pop = naughty.notify({ title     = '<span color="white">Processes</span>\n'
                         , text      = escape(text)
                         , icon      = imgpath..'cpu.png'
                         , icon_size = 28
                         , timeout   = 0
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
end
--  mouse_leave
cpuwidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    FileSystem (imagebox+textbox)
--------------------------------------------------------------------------------
--Busca puntos de pontaje concreto en 'df' y lista el espacio usado.
function fs_info()
    local mounts  = { "/"
                    , "/home"
                    , "/opt"
                    , "/usr"
                    , "/var"
                    , "/tmp"
                    }
    local result = ''
    local df = pread("df")
    if df then
        for percent, mpoint in df:gmatch("(%d+)%%%s+(/.-)%s") do
            for key, value in ipairs(mounts) do
                if value == string.lower(mpoint) then
                    if tonumber(percent) < 90 then
                        result = result..'<span color="white">'..value..'~</span>'..percent..'%'
                    else
                        result = result..'<span color="white">'..value..'~</span><span color="red">'..percent..'%</span>'
                    end
                end
            end
        end
    end
    return result
end

--  imagebox
fs_ico = widget({ type = "imagebox", align = "right" })
createIco(fs_ico,'fs.png','urxvtc -e fdisk -l')
--  textbox
fswidget = widget({ type = 'textbox'
                  , name = 'fswidget'
                  , align = 'right'
                  })
--  primera llamada a la función
fswidget.text = fs_info()
--  mouse_enter
fswidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = pread("df -ha")
    pop = naughty.notify({ title      = '<span color="white">Disk Usage</span>'
                         , text       = escape(text..'\n')
                         , icon       = imgpath..'fs.png'
                         , icon_size  = 32
                         , timeout    = 0
                         , width      = 550
                         , position   = "bottom_right"
                         , bg         = beautiful.bg_focus
                         })
end
--  mouse_leave
fswidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    Net (imagebox+textbox)
--------------------------------------------------------------------------------
--  Devuelve el tráfico de la interface de red usada como default GW.
function net_info()
    if not old_rx or not old_tx or not old_time then
        old_rx,old_tx,old_time = 0,0,1
    end
    local iface,cur_rx,cur_tx,rx,rxu,tx,txu
    local file = fread("/proc/net/route")
    if file then
        iface = file:match('(%w+)%s+00000000%s+%w+%s+0003%s+')
        if not iface or iface == '' then
            return nil --'<span color="red">NO</span>' -- "No Def GW"
        end
    else
        return "Err: /proc/net/route."
    end
    --Sacamos cur_rx y cur_tx de /proc/net/dev
    file = fread("/proc/net/dev")
    if file then
       cur_rx,cur_tx = file:match(iface..':%s*(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)%s+')
    else
        return "Err: /proc/net/dev"
    end
    cur_time = os.time()
    interval = cur_time - old_time -- diferencia entre mediciones
--    rx = ( cur_rx - old_rx ) / 1024 / interval -- resultado en kb
--    tx = ( cur_tx - old_tx ) / 1024 / interval
    rx,rxu = bytestoh( ( cur_rx - old_rx ) / interval )
    tx,txu = bytestoh( ( cur_tx - old_tx ) / interval )
    old_rx,old_tx,old_time = cur_rx,cur_tx,cur_time
    return iface..'<span color="white">↓</span>'..string.format("%03d%2s",rx,rxu)..'<span color="white">↑</span>'..string.format("%03d%2s",tx,txu)
end
--  imagebox
net_ico = widget({ type = "imagebox", align = "right" })
createIco(net_ico,'net-wired.png','urxvtc -e netstat -ltunpp')
--  textbox
netwidget = widget({ type = 'textbox'
                   , name = 'netwidget'
                   , align = 'right'
                   })
--  primera llamada a la función
netwidget.text = net_info()
--  mouse_enter
netwidget.mouse_enter = function()
    naughty.destroy(pop)
    local listen = pread("netstat -patun | awk '/ESTABLISHED/{ if ($4 !~ /127.0.0.1|localhost/) print  \"(\"$7\")\t\"$5}'")
    pop = naughty.notify({ title      = '<span color="white">Established</span>\n'
                         , text       = escape(listen)
                         , icon       = imgpath..'net-wired.png'
                         , icon_size  = 32
                         , timeout    = 0
                         , position   = "bottom_right"
                         , width      = 350
                         , bg         = beautiful.bg_focus
                         })
end
-- mouse_leave
netwidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    Load (magebox+textbox)
--------------------------------------------------------------------------------
--  Devuelve el load average 
function avg_load()
    local n = fread('/proc/loadavg')
    local pos = n:find(' ', n:find(' ', n:find(' ')+1)+1)
    return  n:sub(1,pos-1)
end
--  imagebox
load_ico = widget({ type = "imagebox", align = "right" })
createIco(load_ico,'load.png','urxvtc -e htop')
--  textbox
loadwidget = widget({ type = 'textbox'
                    , name = 'loadwidget'
                    , align = 'right'
                    })
-- llamada inicial a la función
loadwidget.text = avg_load()
--  mouse_enter
loadwidget.mouse_enter = function()
    naughty.destroy(pop)
    local text = pread("uptime; echo; who")
    pop = naughty.notify({ title  = '<span color="white">Uptime</span>\n'
                         , text       = escape(text)
                         , icon       = imgpath..'load.png'
                         , icon_size  = 32
                         , timeout    = 0
                         , width      = 600
                         , position   = "bottom_right"
                         , bg         = beautiful.bg_focus
                         })
end
-- mouse_leave
loadwidget.mouse_leave = function() naughty.destroy(pop) end
--}}}
--{{{    Volume (Custom) requiere alsa-utils
--------------------------------------------------------------------------------
-- Devuelve el volumen "Master" en alsa.
function get_vol()
    local txt = pread('amixer get Master')
    if txt then
        if txt:match('%[off%]') then
            return 'Mute'
        else
            return txt:match('%[(%d+%%)%]')
        end
    else
        return nil
    end
end
--  imagebox
vol_ico = widget({ type = "imagebox", align = "left" })
createIco(vol_ico,'vol.png','urxvtc -e alsamixer')
--  textbox
volwidget = widget({ type = 'textbox'
                      , name = 'volwidget'
                      , align = 'left'
                      })
--  primera llamada a la función
volwidget.text = get_vol()
--  buttons
volwidget:buttons({
    button({ }, 4, function()
        os.execute('amixer -c 0 set Master 3dB+');
        volwidget.text = get_vol()
    end),
    button({ }, 5, function()
        os.execute('amixer -c 0 set Master 3dB-');
        volwidget.text = get_vol()
    end),
})
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
                           , volwidget
                           , volwidget and Lseparator or nil
                           , mpd_ico
                           , mpcwidget
                           , Rseparator
                           , mail_ico
                           , mailwidget
                           , mailwidget and Rseparator or nil
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
