script_name('penis updater')
script_version("00.00.01")

local imgui = require 'mimgui'
local encoding = require 'encoding'
local hotkey = require 'mimgui_hotkeys'
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'

encoding.default = 'CP1251'
local u8 = encoding.UTF8
local new = imgui.new

local enable_autoupdate = true
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/faldiko/sturdy-broccoli/refs/heads/main/version.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://raw.githubusercontent.com/faldiko/sturdy-broccoli/refs/heads/main/version.json"
        end
    end
end

local cfg = inicfg.load({
    config = {
        bind = '[32]',
        resizable = false,
        render_distance = 10.0,
        dist_spil = 1.7,
        delay_spil = 50
    }
}, 'LesHelper.ini')
inicfg.save(cfg, 'LesHelper.ini')

local Window = new.bool(false)
local render = new.bool(false)
local collision = new.bool(false)
local posadka = new.bool(false)
local prokachka = new.bool(false)
local spilivanie = new.bool(false)
local CameraZoomButton = new.bool(false)
local camera_zoom_enabled = new.bool(cfg.config.camera_zoom_enabled or false)
local enabled = false
local locked = false

local resizable = new.bool(cfg.config.resizable or false)
local render_distance = new.float(cfg.config.render_distance or 10.0)
local dist_spil = new.float(cfg.config.dist_spil or 1.7)
local delay_spil = new.int(cfg.config.delay_spil or 50)

local exampleHotKey = nil

local checkboxData = {
    { u8'Рендер расстояния', u8'Отображает круги вокруг деревьев, в радиусе которых нельзя сажать новые.', render },
    { u8'Коллизия для деревьев', u8'Отключает коллизию у деревьев, чтобы избежать проваливания при посадке.', collision },
    { u8'Посадка деревьев', u8'Назначьте клавишу для автоматической посадки деревьев.', posadka },
    { u8'Прокачка деревьев', u8'При нажатии H рядом с деревом диалоги пропускаются автоматически.', prokachka },
    { u8'Спиливание деревьев', u8'При включенной функции, вы подбегаете к дереву и оно пилится автоматически', spilivanie }
}

imgui.OnFrame(function() return Window[0] end, function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2.5, sh / 2), imgui.Cond.FirstUseEver)

    local flags = imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoCollapse
    if not resizable[0] then
        flags = flags + imgui.WindowFlags.AlwaysAutoResize
    end

    imgui.Begin(u8'Penis Helper.lua', Window, flags)

    if imgui.BeginTabBar('Tabs') then
        if imgui.BeginTabItem(u8'Хелпер лесоруб') then
            if render[0] then
                imgui.SliderFloat(u8'Дистанция рендера (м)', render_distance, 1.0, 50.0, '%.1f')
                cfg.config.render_distance = render_distance[0]
                inicfg.save(cfg, 'LesHelper.ini')
            end

            for i, checkbox in ipairs(checkboxData) do
                if i ~= 3 then
                    imgui.Checkbox(checkbox[1], checkbox[3])
                    imgui.SameLine()
                    imgui.Text('(?)')
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(checkbox[2])
                        imgui.EndTooltip()
                    end
                end
            end

            if spilivanie[0] then
                imgui.SliderFloat(u8'Дистанция рубки', dist_spil, 0.5, 5.0, '%.2f')
                imgui.SliderInt(u8'Задержка рубки (мс)', delay_spil, 10, 500)
                cfg.config.dist_spil = dist_spil[0]
                cfg.config.delay_spil = delay_spil[0]
                inicfg.save(cfg, 'LesHelper.ini')
            end

            imgui.Checkbox(u8'Посадка деревьев', posadka)
            imgui.SameLine()
            imgui.Text('(?)')
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Назначьте клавишу для автоматической посадки деревьев.')
                imgui.EndTooltip()
            end

            imgui.Separator()

            -- Текст перед кнопкой бинда и сама кнопка (ShowHotKey)
            imgui.Text(u8'Клавиша для посадки:')
            imgui.SameLine()
            if exampleHotKey and exampleHotKey:ShowHotKey() then
                cfg.config.bind = encodeJson(exampleHotKey:GetHotKey())
                inicfg.save(cfg, 'LesHelper.ini')
            end
			
           imgui.Separator()
            imgui.Text(u8'Вспомогательные функции для фарма дров.')
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem(u8'Хелпер рыболов') then
		
            imgui.Separator()
            imgui.Text(u8'Вспомогательные функции для ловли рыбы.')
            imgui.EndTabItem()
        end
		
        if imgui.BeginTabItem(u8'ЦР') then
            imgui.Separator()
            imgui.Text(u8'Вспомогательные функции для центрального рынка.')
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem(u8'Рулетки') then
            imgui.Separator()
            imgui.Text(u8'Вспомогательные функции открытия рулеток')
            imgui.EndTabItem()
        end
		
if imgui.BeginTabItem(u8'Другое') then
    imgui.Separator()
    imgui.Text(u8'Разный шлак ебучий')

    if imgui.Checkbox(u8'Рыбий глаз', camera_zoom_enabled) then
        cfg.config.camera_zoom_enabled = camera_zoom_enabled[0]
        inicfg.save(cfg, 'LesHelper.ini')
    end
    imgui.SameLine()
    imgui.Text('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Рыбий глаз (фов изменяет хуле смотришь все понятно)')
        imgui.EndTooltip()
    end
           imgui.Separator()
            imgui.Text(u8'Шлак ебаный какой-то')
    imgui.EndTabItem()
end

        if imgui.BeginTabItem(u8'Настройки') then
            imgui.Text(u8'Настройки интерфейса:')

            if imgui.Button(resizable[0] and u8'Отключить растягивание' or u8'Включить растягивание') then
                resizable[0] = not resizable[0]
                cfg.config.resizable = resizable[0]
                inicfg.save(cfg, 'LesHelper.ini')
            end
            imgui.SameLine()
            imgui.Text('(?)')
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'При включении вы сможете изменять размер окна вручную, тянув за угол меню.')
                imgui.EndTooltip()
            end

            imgui.Separator()
            imgui.Text(u8'Также здесь можно тестировать функции или настройки.')
            imgui.EndTabItem()
        end

        imgui.EndTabBar()
    end

    imgui.End()
end)

function main()
    while not isSampAvailable() do wait(100) end

    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end

    lua_thread.create(RenderRadius)
    lua_thread.create(Collision)
    lua_thread.create(AutoPressH)
	lua_thread.create(CameraZoom)
    lua_thread.create(posadkaq)
    lua_thread.create(spilivanieq)

    sampAddChatMessage("{00CCFF}[PenisHelper.lua] {FFFFFF}Скрипт загружен. Используйте {00CCFF}/penis{FFFFFF} для открытия меню.", -1)
    sampRegisterChatCommand('penis', function() 
        Window[0] = not Window[0] 
    end)

    if type(cfg.config.bind) ~= 'string' or cfg.config.bind == '' then cfg.config.bind = '[]' end
    exampleHotKey = hotkey.RegisterHotKey('posadka', false, decodeJson(cfg.config.bind), function() end)
    hotkey.Text.NoKey = u8'Пусто'
    hotkey.Text.WaitForKey = u8'Ожид клавиш'

    while true do
        wait(0)
    end
end


local treeModels = {
    [765] = true, -- 1 стадия
    [732] = true, -- 2 стадия
    [727] = true, -- 3 стадия
    [771] = true, -- 4 стадия
    [777] = true, -- 5 стадия
}

function RenderRadius()
    while true do
        if not isGameWindowForeground() then
            repeat
                wait(500)
            until isGameWindowForeground()
        end

        wait(10)

        local currentDistRender = render_distance[0] or 1.7
        if render[0] == true then
            local px, py, pz = getCharCoordinates(PLAYER_PED)

            for _, obj in pairs(getAllObjects()) do
                local model = getObjectModel(obj)
                if treeModels[model] then
                    local _, x, y, z = getObjectCoordinates(obj)
                    local dist = getDistanceBetweenCoords3d(x, y, z, px, py, pz)
                    if dist <= currentDistRender and isObjectOnScreen(obj) then
                        drawCircleIn3d(x, y, z - 0, 3.15, 36, 1.5, dist > 3.15 and 0xFFFFFFFF or 0xFFFF0000)
                    end
                end
            end
        end
    end
end

function drawCircleIn3d(x, y, z, r, n, w, c)
    local s, px, py = 360 / (n or 36)
    for a = 0, 360, s do
        local wx = x + r * math.cos(math.rad(a))
        local wy = y + r * math.sin(math.rad(a))
        local _, sx, sy, vis = convert3DCoordsToScreenEx(wx, wy, z)
        if vis > 1 and px and py then renderDrawLine(sx, sy, px, py, w, c) end
        px, py = sx, sy
    end
end


function Collision()
    while true do
        wait(10)
        if collision[0] == true then
        for id = 0, 1000 do
            local handle = sampGetObjectHandleBySampId(id)
            if doesObjectExist(handle) and tostring(getObjectModel(handle)) then
                setObjectCollision(handle, false)
                end
            end
        end
        if collision[0] == false then
            for id = 0, 1000 do
                local handle = sampGetObjectHandleBySampId(id)
                if doesObjectExist(handle) and tostring(getObjectModel(handle)) then
                    setObjectCollision(handle, true)
                    end
                end
            end
    end
end

function posadkaq()
    while true do 
        if not isGameWindowForeground() then
            repeat
                wait(500)
            until isGameWindowForeground()
        end
        wait(0)
        local stopFlood = false
        if not isSampAvailable() then stopFlood = true end
        if sampIsChatInputActive() then stopFlood = true end
        if sampIsDialogActive() then stopFlood = true end
        if Window[0] then stopFlood = true end
        if not isGameWindowForeground() then stopFlood = true end
        if not stopFlood and posadka[0] and wasKeyPressed(table.concat(exampleHotKey:GetHotKey())) then
            sampSendChat("/seat")
        end
    end
end


function AutoPressH()
    while true do 
        if not isGameWindowForeground() then
            repeat
                wait(500)
            until isGameWindowForeground()
        end
        wait(1000)
        if prokachka[0] and isSampAvailable() then
            local px, py, pz = getCharCoordinates(PLAYER_PED)
            for _, obj in pairs(getAllObjects()) do
                local model = getObjectModel(obj)
                if treeModels[model] then
                    local _, x, y, z = getObjectCoordinates(obj)
                    local dist = getDistanceBetweenCoords3d(x, y, z, px, py, pz)
                    if dist <= 1.5 then
                        setVirtualKeyDown(0x48, true)
                        wait(50)
                        setVirtualKeyDown(0x48, false)
                    end
                end
            end
        end
    end
end

function CameraZoom()
    enabled = camera_zoom_enabled[0]
    while true do
        wait(0)
        enabled = camera_zoom_enabled[0]
		if enabled then
			if isCurrentCharWeapon(PLAYER_PED, 34) and isKeyDown(2) then
				if not locked then 
					cameraSetLerpFov(70.0, 70.0, 1000, 1)
					locked = true
				end
			else
				cameraSetLerpFov(101.0, 101.0, 1000, 1)
				locked = false
            end
        end
    end
end

function spilivanieq()
    local lastRotate = 0
    while true do
        wait(0)
        
        if spilivanie[0] then
            local px, py, pz = getCharCoordinates(PLAYER_PED)
            local tick = os.clock() * 1000
            local currentDist = dist_spil[0] or 1.7
            local currentDelay = delay_spil[0] or 50
            for _, obj in pairs(getAllObjects()) do
                if doesObjectExist(obj) then
                    local model = getObjectModel(obj)
                    if treeModels[model] then
                        local _, x, y, z = getObjectCoordinates(obj)
                        local dist = getDistanceBetweenCoords3d(x, y, z, px, py, pz)
                        if dist <= currentDist then
                            if tick - lastRotate >= 5 then
                                local dx, dy = x - px, y - py
                                local rot = math.deg(math.atan2(-dx, dy))
                                setCharHeading(PLAYER_PED, rot)
                                setCameraBehindPlayer()
                                lastRotate = tick
                            end
                            setGameKeyState(17, -128)
                            wait(currentDelay)
                            setGameKeyState(17, 0)
                        end
                    end
                end
            end
        else
            wait(50)
        end
    end
end





