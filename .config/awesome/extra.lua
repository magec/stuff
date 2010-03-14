-- #############################################################################
-- loadfile(awful.util.getdir("config").."/extra.lua")()
-- #############################################################################
--{{{    Inicializacion
--------------------------------------------------------------------------------
imgpath = awful.util.getdir("config")..'/imgs/'
confdir = awful.util.getdir("config")..'/'
setrndwall = "awsetbg -r "..awful.util.getdir("config").."/walls"
setrndtile = "awsetbg -t -r "..awful.util.getdir("config").."/tiles"
setwall = "awsetbg -c "..awful.util.getdir("config").."/walls/vladstudio_microbes_1920x1200.jpg"
browser = os.getenv('BROWSER') or 'chromium'
--}}}
--{{{    Utilidades/Funciones
function escape(text)
    if text then
        return awful.util.escape(text or 'UNKNOWN')
    end
end
-- Bold
function bold(text)
    return '<b>' .. text .. '</b>'
end
-- Italic
function italic(text)
    return '<i>' .. text .. '</i>'
end
-- Foreground color
function fgc(text,color)
    if not color then color = 'white' end
    return '<span color="'..color..'">'..text..'</span>'
end
-- process_read (io.popen)
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
-- file_read (io.open)
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
--  esto se carga todas las notificaciones de naughty
function desnaug()
    for p,pos in pairs(naughty.notifications[mouse.screen]) do
        for i,notification in pairs(naughty.notifications[mouse.screen][p]) do
            naughty.destroy(notification)
            desnaug()
        end
    end
end
--  menos bloat creando iconos
function createIco(widget,file,click)
    if not widget or not file or not click then return nil end
    widget.image = image(imgpath..'/'..file)
    widget.resize = false
    awful.widget.layout.margins[widget] = { top = 1, bottom = 1, left = 1, right = 1 }
    widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function ()
            awful.util.spawn(click,false)
        end)
    ))
end
-- Converts bytes to human-readable units, returns value (number) and unit (string)
function bytestoh(bytes)
    local tUnits={"K","M","G","T","P"} -- MUST be enough. :D
    local v,u
    for k=table.getn(tUnits),1,-1 do
        if math.fmod(bytes,1024^k) ~= bytes then v=bytes/(1024^k); u=tUnits[k] break end
    end
    return v or bytes,u or "B"
end
-- Crea, muestra y esconde clientes flotantes
-- http://awesome.naquadah.org/wiki/Drop-down_terminal
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}
local dropdown = {}
-- Create a new window for the drop-down application when it doesn't
-- exist, or toggle between hidden and visible states when it does
function toggle(prog,height,sticky,screen)
    local height = height or 0.3 -- 30%
    local sticky = sticky or false
    local screen = screen or capi.mouse.screen
    if not dropdown[prog] then
        dropdown[prog] = {}

        -- Add unmanage signal for teardrop programs
        capi.client.add_signal("unmanage", function (c)
            for scr, cl in pairs(dropdown[prog]) do
                if cl == c then
                    dropdown[prog][scr] = nil
                end
            end
        end)
    end
    if not dropdown[prog][screen] then
        spawnw = function (c)
            dropdown[prog][screen] = c
            -- Teardrop clients are floaters
            awful.client.floating.set(c, true)
            -- Client geometry
            local screengeom = capi.screen[screen].workarea
            if height < 1 then
                height = screengeom.height * height
            else
                height = screengeom.height
            end
            -- Client properties
            c:geometry({ x = screengeom.x/2, y = 0, width = screengeom.width, height = height })
            c.ontop = true
            c.above = true
            c.skip_taskbar = true
            if sticky then c.sticky = true end
            if c.titlebar then awful.titlebar.remove(c) end
            c:raise()
            capi.client.focus = c
            capi.client.remove_signal("manage", spawnw)
        end
        -- Add manage signal and spawn the program
        capi.client.add_signal("manage", spawnw)
        awful.util.spawn(prog, false)
    else
        -- Get a running client
        c = dropdown[prog][screen]
        -- Switch the client to the current workspace
        if c:isvisible() == false then c.hidden = true;
            awful.client.movetotag(awful.tag.selected(screen), c)
        end
        -- Focus and raise if hidden
        if c.hidden then
            c.hidden = false
            c:raise()
            capi.client.focus = c
        else -- Hide and detach tags if not
            c.hidden = true
            local ctags = c:tags()
            for i, v in pairs(ctags) do
                ctags[i] = nil
            end
            c:tags(ctags)
        end
    end
end
--}}}
--
--{{{    GMail (imagebox+textbox)
--------------------------------------------------------------------------------
--  Datos de gmail
mailadd  = 'oprietop@intranet.uoc.edu'
mailpass = escape(fread(confdir..mailadd..'.passwd'))
mailurl  = 'https://mail.google.com/a/intranet.uoc.edu/feed/atom/unread'
--  mailurl  = 'https://mail.google.com/feed/atom/unread'
--  Actualiza el estado del widget a partir de un feed de gmail bajado.
count = 0
function check_gmail()
    local feed = fread(confdir..mailadd)
    local lcount = count
    if feed:match('fullcount>%d+<') then
        lcount = feed:match('fullcount>(%d+)<')
    end
    if lcount ~= count then
        for title,summary,name,email in feed:gmatch('<entry>\n<title>(.-)</title>\n<summary>(.-)</summary>.-<name>(.-)</name>\n<email>(.-)</email>') do
            pop = naughty.notify({ title    = fgc('New mail on ')..mailadd
                                 , opacity  = 1
                                 , icon     = imgpath..'yellow_mail.png'
                                 , text     = escape(name..' ('..email..')\n'..title..'\n'..summary)
                                 , timeout  = 20
                                 , position = "top_right"
                                 , fg       = beautiful.fg_focus
                                 , bg       = beautiful.bg_focus
                                 })
        end
        count = lcount
    end
    if tonumber(lcount) > 0 then
        return fgc(bold(lcount), 'red')
    else
        return ''
    end
end
--  lanza un wget en background para bajar el feed de gmail.
function getMail()
    if confdir and mailadd and mailpass and mailurl then
        os.execute('wget '..mailurl..' -qO '..confdir..mailadd..' --http-user='..mailadd..' --http-passwd="'..mailpass..'"&')
    end
end
if mailpass then
    --  imagebox
    mail_ico = widget({ type = "imagebox" })
    createIco(mail_ico, 'mail.png', browser..' '..mailurl..'"&')
    --  textbox
    mailwidget = widget({ type  = "textbox"
                        , name  = "mailwidget"
                        })
    -- llamada inicial a la función
    mailwidget.text=check_gmail()
    --  mouse_enter
    mailwidget:add_signal("mouse::enter", function()
        count = 0
        check_gmail()
    end)
    --  mouse_leave
    mailwidget:add_signal("mouse::leave", function() desnaug() end)
    --  buttons
    mailwidget:buttons(awful.util.table.join(
        awful.button({ }, 1, function ()
            getMail()
            os.execute(browser..' "'..mailurl..'"&')
        end)
    ))
end
--}}}
--{{{    Bateria (texto)
--------------------------------------------------------------------------------
function bat_info()
    local cur = fread("/sys/class/power_supply/BAT0/charge_now")
    local cap = fread("/sys/class/power_supply/BAT0/charge_full")
    local sta = fread("/sys/class/power_supply/BAT0/status")
    if not cur or not cap or not sta or tonumber(cap) <= 0 then
        return 'ERR'
    end
    local battery = math.floor(cur * 100 / cap)
    if sta:match("Charging") then
        dir = "+"
        battery = "A/C~"..battery
        elseif sta:match("Discharging") then
        dir = "-"
        if tonumber(battery) < 10 then
            naughty.notify({ title    = fgc('Battery Warning\n')
                           , text     = "Battery low!"..battery.."% left!"
                           , timeout  = 10
                           , position = "top_right"
                           , fg       = beautiful.fg_focus
                           , bg       = beautiful.bg_focus
                           })
        end
    else
        dir = "="
        battery = "A/C~"
    end
    return battery..dir
end
battery = io.open("/sys/class/power_supply/BAT0/charge_now")
if battery then
    bat_ico = widget({ type = "imagebox" })
    createIco(bat_ico, 'bat.png', terminal..' -e xterm')
    batterywidget = widget({ type  = "textbox"
                       , name  = "batterywidget"
                       })
    -- llamada inicial a la función
    batterywidget.text = bat_info()
    batterywidget:add_signal("mouse::enter",function()
        naughty.destroy(pop)
        local text = fread("/proc/acpi/battery/BAT0/info")
        pop = naughty.notify({ title = fgc('BAT0/info\n')
                         , text      = escape(text)
                         , icon      = imgpath..'swp.png'
                         , icon_size = 32
                         , timeout   = 0
                         , position  = "bottom_right"
                         , fg        = beautiful.fg_focus
                         , bg        = beautiful.bg_focus
                         })
    end)
    batterywidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
end
--}}}
--{{{    Separadores (img)
--------------------------------------------------------------------------------
separator = widget({ type = 'imagebox'
                   , name  = 'separator'
                   })
separator.image = image(awful.util.getdir("config").."/imgs/separador2.png")
separator.resize = false
--}}}
--{{{    MPC (imagebox+textbox) requiere mpc/mpd
--------------------------------------------------------------------------------
--  Devuelve estado de mpc
local oldsong
function mpc_info()
    local now = escape(pread('mpc -f "%name%\n%artist%\n%album%\n%title%\n%track%\n%time%\n%file%"'))
    if now and now ~= '' then
        local name,artist,album,title,track,total,file,state,time = now:match('^(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n%[(%w+)%]%s+#%d+/%d+%s+(.-%(%d+%%%))')
        if state and state ~= '' then
            if artist and title and time then
                song = artist.." - "..title
                if string.len(song) > 60 then
                    song = '...'..string.sub(song, -57)
                 end
            else
                return 'ZOMFG Format Error!'
            end
            if state == 'playing' then
                -- Popup con el track
                if album ~= '' and song ~= oldsong then
                    naughty.notify { icon    = imgpath .. 'mpd_logo.png'
                                   , timeout = 3
                                   , fg      = beautiful.fg_focus
                                   , bg      = beautiful.bg_focus
                                   , text    = string.format("\n%s %s\n%s  %s\n%s  %s"
                                                            , 'Artist:', fgc(bold(artist))
                                                            , 'Album:' , fgc(bold(album))
                                                            , 'Title:' , fgc(bold(title))
                                                            )
                                   }
                end
                oldsong = song
                -- ugly utf8 workaround Part 1
                return '[Play]<span font_desc="Sans 8" color="white"> "'..song..'"</span> '..time
            elseif state == 'paused' then
                if song ~= '' and time ~= '' then
                    return '[Wait] '..song..' '..time
                end
            end
        else
            if now:match('^Updating%sDB') then
                return '[Wait] Updating Database...'
            elseif now:match('^volume:') then
                return '[Stop] ZZzzz...'
            else
                return fgc('[DEAD]', 'red')..' :_('
            end
        end
    else
        return fgc('NO MPC', 'red')..' :_('
    end
end
--  imagebox
mpd_ico = widget({ type = "imagebox" })
createIco(mpd_ico, 'mpd.png', terminal..' -e ncmpcpp')
--  textbox
mpcwidget = widget({ type    = 'textbox'
                   , name    = 'mpcwidget'
                   })
-- ugly utf8 workaround Part 2
awful.widget.layout.margins[mpcwidget] = { top = 1, bottom = 0, left = 0, right = 0 }
-- llamada inicial a la función
mpcwidget.text = mpc_info()
-- textbox buttons
mpcwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        os.execute('mpc play')
        print_mpc()
    end),
    awful.button({ }, 2, function ()
        os.execute('mpc stop')
        print_mpc()
    end),
    awful.button({ }, 3, function ()
        os.execute('mpc pause')
        print_mpc()
    end),
    awful.button({ }, 4, function()
        os.execute('mpc prev')
        print_mpc()
    end),
    awful.button({ }, 5, function()
        os.execute('mpc next')
        print_mpc()
    end)
))
-- muestra el track actual
function print_mpc()
    naughty.destroy(pop)
    local text = pread("mpc; echo ; mpc stats")
    pop = naughty.notify({ title    = fgc('MPC Stats\n')
                         , text     = text
                         , icon     = imgpath..'mpd_logo.png'
                         , timeout  = 0
                         , position = "bottom_left"
                         , bg       = beautiful.bg_focus
                         })
end
--  mouse_enter
mpcwidget:add_signal("mouse::enter",function()
    print_mpc()
end)
--  mouse_leave
mpcwidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
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
                if total <= 0 then --wtf
                    return ''
                end
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
        membarwidget:set_value(percent/100)
    end
    return used..'('..percent..'%)'
end
--  imagebox
mem_ico = widget({ type = "imagebox" })
createIco(mem_ico,'mem.png', terminal..' -e htop')
--  textbox
memwidget = widget({ type = 'textbox'
                   , name = 'memwidget'
                   })
--  progressbar
membarwidget = awful.widget.progressbar()
membarwidget:set_width(40)
membarwidget:set_height(13)
membarwidget:set_background_color('black')
membarwidget:set_border_color('white')
membarwidget:set_gradient_colors({'green', 'red'})
awful.widget.layout.margins[membarwidget.widget] = { top = 1, bottom = 1 }
--  Llamada inicial a la función
memwidget.text = activeram()
--  mouse_enter
memwidget:add_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = pread("free -tm")
    pop = naughty.notify({ title     = fgc('Free\n')
                         , text      = text
                         , icon      = imgpath..'mem.png'
                         , icon_size = 32
                         , timeout   = 0
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
    end)
--  mouse_leave
memwidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
---}}}
--{{{    Swap (imagebox+textbox)
--------------------------------------------------------------------------------
--  Devuelve la swap usada en MB(%)
function activeswap()
    local active, total, free
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+):\ +(%d+).+") do
            if key == "SwapTotal" then
                total = tonumber(value)
                if total == 0 then
                    return '' -- No hay Swap!
                end
            elseif key == "SwapFree" then
                free = tonumber(value)
            end
        end
    end
    active = total - free
    return string.format("%.0fMB",(active/1024))..'('..string.format("%.0f%%",(active/total)*100)..')'
end
--  imagebox
swp_ico = widget({ type = "imagebox" })
createIco(swp_ico,'swp.png', terminal..' -e htop')
--  textbox
swpwidget = widget({ type = 'textbox'
                   , name = 'swpwidget'
                   })
--  llamada inicial a la función
swpwidget.text = activeswap()
--  mouse_enter
swpwidget:add_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = fread("/proc/meminfo")
    pop = naughty.notify({ title     = fgc('/proc/meminfo\n')
                         , text      = text
                         , icon      = imgpath..'swp.png'
                         , icon_size = 32
                         , timeout   = 0
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
    end)
--  mouse_leave
swpwidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
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
        if diff > 0 then -- siempre devería cumplirse, excepto cargas elevadas.
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
        cpugraphwidget:add_value(cpu[0].res)
    end
    info = ''
    for s = 0, #cpu do
        if cpu[s].res > 99 then
            info = info..fgc('C'..s..':')..fgc('LOL', 'red')
        else
            info = info..fgc('C'..s..':')..string.format("%02d",cpu[s].res)..'%'
        end
        if s ~= #cpu then
            info = info..' '
        end
    end
    return info
end
--  imagebox
cpu_ico = widget({ type = "imagebox" })
createIco(cpu_ico,'cpu.png', terminal..' -e htop')
--  textbox
cpuwidget = widget({ type = 'textbox'
                   , name = 'cpuwidget'
                   })
--  graph
cpugraphwidget = awful.widget.graph()
cpugraphwidget:set_width(40)
cpugraphwidget:set_height(13)
cpugraphwidget:set_max_value(100)
cpugraphwidget:set_background_color('black')
cpugraphwidget:set_border_color('white')
cpugraphwidget:set_gradient_angle(0)
cpugraphwidget:set_gradient_colors({'red', 'green'})
awful.widget.layout.margins[cpugraphwidget.widget] = { top = 1, bottom = 1 }
--  primera llamada a la función
cpuwidget.text = cpu_info()
--  mouse_enter
cpuwidget:add_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = pread("ps -eo %cpu,%mem,ruser,pid,comm --sort -%cpu | head -20")
    pop = naughty.notify({ title     = fgc('Processes\n')
                         , text      = text
                         , icon      = imgpath..'cpu.png'
                         , icon_size = 28
                         , timeout   = 0
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
end)
--  mouse_leave
cpuwidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
--}}}
--{{{    FileSystem (imagebox+textbox)
--------------------------------------------------------------------------------
-- Busca puntos de pontaje concreto en 'df' y lista el espacio usado.
-- la llamada statfs de fs tarda la tira en leer mis discos FAT32 (7 segundos a veces)
-- por primera vez y hace que awesome se demore ese tanto.
-- De momento he puesto un df >/dev/null&1 en rc.local supercutre para evitarlo.
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
                        result = result..fgc(value..'~')..percent..'%'
                    else
                        result = result..fgc(value..'~')..fgc(percent..'%', 'red')
                    end
                end
            end
        end
    end
    return result
end

--  imagebox
fs_ico = widget({ type = "imagebox" })
createIco(fs_ico,'fs.png', terminal..' -e fdisk -l')
--  textbox
fswidget = widget({ type = 'textbox'
                  , name = 'fswidget'
                  })
--  primera llamada a la función
fswidget.text = fs_info()
--  mouse_enter
fswidget:add_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = pread("df -ha")
    pop = naughty.notify({ title     = fgc('Disk Usage\n')
                         , text      = text
                         , icon      = imgpath..'fs.png'
                         , icon_size = 32
                         , timeout   = 0
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
end)
--  mouse_leave
fswidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
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
        iface = file:match('(%S+)%s+00000000%s+%w+%s+0003%s+')
        if not iface or iface == '' then
            return '' --fgc('No Def GW', 'red')
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
    if tonumber(interval) > 0 then -- porsia
        rx,rxu = bytestoh( ( cur_rx - old_rx ) / interval )
        tx,txu = bytestoh( ( cur_tx - old_tx ) / interval )
        old_rx,old_tx,old_time = cur_rx,cur_tx,cur_time
    else
        rx,tx,rxu,txu = "0","0","B","B"
    end
    return iface..fgc('↓')..string.format("%04d%2s",rx,rxu)..fgc('↑')..string.format("%04d%2s",tx,txu)
end
--  imagebox
net_ico = widget({ type = "imagebox" })
createIco(net_ico,'net-wired.png', terminal..' -e screen -S awesome watch -n5 "lsof -ni"')
--  textbox
netwidget = widget({ type = 'textbox'
                   , name = 'netwidget'
                   })
--  primera llamada a la función
netwidget.text = net_info()
--  mouse_enter
netwidget:add_signal("mouse::enter", function()
    naughty.destroy(pop)
    local listen = pread("netstat -patun 2>&1 | awk '/ESTABLISHED/{ if ($4 !~ /127.0.0.1|localhost/) print  \"(\"$7\")\t\"$5}'")
    pop = naughty.notify({ title     = fgc('Established\n')
                         , text      = listen
                         , icon      = imgpath..'net-wired.png'
                         , icon_size = 32
                         , timeout   = 0
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
end)
-- mouse_leave
netwidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
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
load_ico = widget({ type = "imagebox" })
createIco(load_ico,'load.png', terminal..' -e htop')
--  textbox
loadwidget = widget({ type = 'textbox'
                    , name = 'loadwidget'
                    })
-- llamada inicial a la función
loadwidget.text = avg_load()
--  mouse_enter
loadwidget:add_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = pread("uptime; echo; who")
    pop = naughty.notify({ title     = fgc('Uptime\n')
                         , text      = text
                         , icon      = imgpath..'load.png'
                         , icon_size = 32
                         , timeout   = 0
                         , position  = "bottom_right"
                         , bg        = beautiful.bg_focus
                         })
end)
-- mouse_leave
loadwidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
--}}}
--{{{    Volume (Custom) requiere alsa-utils
--------------------------------------------------------------------------------
-- Devuelve el volumen "Master" en alsa.
amixline = pread('amixer | head -1')
if amixline then
    sdev = amixline:match(".-%s%'(%w+)%',0")
end

function get_vol()
    if not sdev then
        return ''
    end
    local txt = pread('amixer get '..sdev)
    if txt then
        if txt:match('%[off%]') then
            return 'Mute'
        else
            return txt:match('%[(%d+%%)%]')
        end
    else
        return ''
    end
end
--  imagebox
vol_ico = widget({ type = "imagebox" })
createIco(vol_ico,'vol.png', terminal..' -e alsamixer')
--  textbox
volwidget = widget({ type = 'textbox'
                   , name = 'volwidget'
                   })
--  primera llamada a la función
volwidget.text = get_vol()
--  buttons
volwidget:buttons(awful.util.table.join(
    awful.button({ }, 4, function()
        os.execute('amixer -c 0 set '..sdev..' 3dB+');
        volwidget.text = get_vol()
    end),
    awful.button({ }, 5, function()
        os.execute('amixer -c 0 set '..sdev..' 3dB-');
        volwidget.text = get_vol()
    end)
))
-- mouse_enter
volwidget:add_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = pread('amixer get '..sdev)
    pop = naughty.notify({ title     = fgc('Volume\n')
                         , text      = text
                         , icon      = imgpath..'vol.png'
                         , icon_size = 28
                         , timeout   = 0
                         , position  = "bottom_left"
                         , bg        = beautiful.bg_focus
                         })
end)
--  mouse_leave
volwidget:add_signal("mouse::leave", function() naughty.destroy(pop) end)
--}}}
--
--{{{   Timers
--------------------------------------------------------------------------------
--  Hook every sec
timer1 = timer { timeout = 1 }
timer1:add_signal("timeout", function()
    cpuwidget.text  = cpu_info()
    loadwidget.text = avg_load()
    netwidget.text  = net_info()
end)
timer1:start()
-- Hook called every 5 secs
timer5 = timer { timeout = 5 }
timer5:add_signal("timeout", function()
    volwidget.text = get_vol()
    memwidget.text = activeram()
    swpwidget.text = activeswap()
    mpcwidget.text = mpc_info()
end)
timer5:start()
--  Hook every 30 secs
timer30 = timer { timeout = 30 }
timer30:add_signal("timeout", function()
    if batterywidget then batterywidget.text = bat_info() end
    if mailpass then mailwidget.text = check_gmail() end
end)
timer30:start()
-- Hook called every minute
timer60 = timer { timeout = 60 }
timer60:add_signal("timeout", function()
    if mailpass then getMail() end
    fswidget.text = fs_info()
end)
timer60:start()
--}}}
--
--{{{    Wibox
--------------------------------------------------------------------------------
for s = 1, screen.count() do
    -- Defino la barra
    statusbar = {}
    -- La creo
    statusbar[s] = awful.wibox({ position = "bottom"
                               , fg = beautiful.fg_normal
                               , bg = beautiful.bg_normal
                               , border_color = beautiful.border_normal
                               , height = 15
                               , border_width = 1
                               })
    -- Le enchufo los widgets
    statusbar[s].widgets = {    { vol_ico
                                , volwidget
                                , volwidget and separator or nil
                                , mpd_ico
                                , mpcwidget
                                , layout = awful.widget.layout.horizontal.leftright
                                }
                           , netwidget
                           , net_ico
                           , separator
                           , fswidget
                           , fs_ico
                           , batterywidget and separator or nil
                           , batterywidget
                           , bat_ico
                           , separator
                           , swpwidget
                           , swp_ico
                           , membarwidget.widget
                           , memwidget
                           , mem_ico
                           , cpugraphwidget.widget
                           , cpuwidget
                           , cpu_ico
                           , separator
                           , loadwidget
                           , load_ico
                           , mailwidget and separator or nil
                           , mailwidget
                           , mail_ico
                           , separator
                           , layout = awful.widget.layout.horizontal.rightleft
                           }
    -- La asigno.
    statusbar[s].screen = s
end
--}}}
--
--{{{    Keybindings
--------------------------------------------------------------------------------
--  Actualizo la tabla globalkeys añadiendo mis keybindings.
--  Los keycodes se pueden ver con el comando 'xev'
globalkeys = awful.util.table.join(globalkeys,
    awful.key({ modkey,           }, "masculine",  function () toggle(terminal) end), -- tecla º
    awful.key({ modkey,           }, "Print",      function () toggle('scrot -e gqview') end), -- tecla Print Screen
    awful.key({ modkey,           }, "BackSpace",  function () awful.util.spawn('urxvt -pe tabbed') end),
    awful.key({ modkey, "Control" }, "w",          function () awful.util.spawn(setrndwall) end),
    awful.key({ modkey, "Control" }, "e",          function () awful.util.spawn(setrndtile) end),
    awful.key({ modkey, "Control" }, "q",          function () awful.util.spawn(setwall) end),
    awful.key({ modkey, "Control" }, "t",          function () awful.util.spawn('thunar') end),
    awful.key({ modkey, "Control" }, "p",          function () awful.util.spawn('pidgin') end),
    awful.key({ modkey, "Control" }, "c",          function () awful.util.spawn(terminal..' -e mc') end),
    awful.key({ modkey, "Control" }, "f",          function () awful.util.spawn(browser) end),
    awful.key({ modkey, "Control" }, "g",          function () awful.util.spawn('gvim') end),
    awful.key({ modkey, "Control" }, "a",          function () awful.util.spawn('ruc_web_resolucio.sh') end),
    awful.key({ modkey, "Control" }, "s",          function () awful.util.spawn('sonata') end),
    awful.key({ modkey, "Control" }, "x",          function () awful.util.spawn('slock') end),
    awful.key({ modkey, "Control" }, "v",          function () awful.util.spawn(terminal..' -e ncmpcpp') end),
    awful.key({ modkey, "Control" }, "0",          function () awful.util.spawn('xrandr -o left') end),
    awful.key({ modkey, "Control" }, "'",          function () awful.util.spawn('xrandr -o normal') end),
    awful.key({ modkey, "Control" }, "exclamdown", function () awful.util.spawn('xrandr --output VGA1 --mode 1280x1024') end),
    awful.key({ modkey, "Control" }, "b",          function () awful.util.spawn('mpc play') end),
    awful.key({ modkey, "Control" }, "n",          function () awful.util.spawn('mpc pause') end),
    awful.key({ modkey, "Control" }, "m",          function () awful.util.spawn('mpc prev'); wicked.widgets.mpd() end),
    awful.key({ modkey, "Control" }, ",",          function () awful.util.spawn('mpc next'); wicked.widgets.mpd() end),
    awful.key({ modkey, "Control" }, ".",          function () awful.util.spawn('amixer -c 0 set '..sdev..' 3dB-'); getVol() end),
    awful.key({ modkey, "Control" }, "-",          function () awful.util.spawn('amixer -c 0 set '..sdev..' 3dB+'); getVol() end),
    awful.key({ modkey }           , "Up",         function () awful.client.focus.byidx(1); if client.focus then client.focus:raise() end end),
    awful.key({ modkey }           , "Down",       function () awful.client.focus.byidx(-1);  if client.focus then client.focus:raise() end end)
)
--  Aplico los keybindings
root.keys(globalkeys)
--}}}
