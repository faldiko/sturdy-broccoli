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
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Îáíàðóæåíî îáíîâëåíèå. Ïûòàþñü îáíîâèòüñÿ c '..thisScript().version..' íà '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Çàãðóæåíî %d èç %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Çàãðóçêà îáíîâëåíèÿ çàâåðøåíà.')sampAddChatMessage(b..'Îáíîâëåíèå çàâåðøåíî!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Îáíîâëåíèå ïðîøëî íåóäà÷íî. Çàïóñêàþ óñòàðåâøóþ âåðñèþ..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Îáíîâëåíèå íå òðåáóåòñÿ.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Íå ìîãó ïðîâåðèòü îáíîâëåíèå. Ñìèðèòåñü èëè ïðîâåðüòå ñàìîñòîÿòåëüíî íà '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, âûõîäèì èç îæèäàíèÿ ïðîâåðêè îáíîâëåíèÿ. Ñìèðèòåñü èëè ïðîâåðüòå ñàìîñòîÿòåëüíî íà '..c)end end}]])
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
    { u8'Ðåíäåð ðàññòîÿíèÿ', u8'Îòîáðàæàåò êðóãè âîêðóã äåðåâüåâ, â ðàäèóñå êîòîðûõ íåëüçÿ ñàæàòü íîâûå.', render },
    { u8'Êîëëèçèÿ äëÿ äåðåâüåâ', u8'Îòêëþ÷àåò êîëëèçèþ ó äåðåâüåâ, ÷òîáû èçáåæàòü ïðîâàëèâàíèÿ ïðè ïîñàäêå.', collision },
    { u8'Ïîñàäêà äåðåâüåâ', u8'Íàçíà÷üòå êëàâèøó äëÿ àâòîìàòè÷åñêîé ïîñàäêè äåðåâüåâ.', posadka },
    { u8'Ïðîêà÷êà äåðåâüåâ', u8'Ïðè íàæàòèè H ðÿäîì ñ äåðåâîì äèàëîãè ïðîïóñêàþòñÿ àâòîìàòè÷åñêè.', prokachka },
    { u8'Ñïèëèâàíèå äåðåâüåâ', u8'Ïðè âêëþ÷åííîé ôóíêöèè, âû ïîäáåãàåòå ê äåðåâó è îíî ïèëèòñÿ àâòîìàòè÷åñêè', spilivanie }
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
        if imgui.BeginTabItem(u8'Õåëïåð ëåñîðóá') then
            if render[0] then
                imgui.SliderFloat(u8'Äèñòàíöèÿ ðåíäåðà (ì)', render_distance, 1.0, 50.0, '%.1f')
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
                imgui.SliderFloat(u8'Äèñòàíöèÿ ðóáêè', dist_spil, 0.5, 5.0, '%.2f')
                imgui.SliderInt(u8'Çàäåðæêà ðóáêè (ìñ)', delay_spil, 10, 500)
                cfg.config.dist_spil = dist_spil[0]
                cfg.config.delay_spil = delay_spil[0]
                inicfg.save(cfg, 'LesHelper.ini')
            end

            imgui.Checkbox(u8'Ïîñàäêà äåðåâüåâ', posadka)
            imgui.SameLine()
            imgui.Text('(?)')
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Íàçíà÷üòå êëàâèøó äëÿ àâòîìàòè÷åñêîé ïîñàäêè äåðåâüåâ.')
                imgui.EndTooltip()
            end

            imgui.Separator()

            -- Òåêñò ïåðåä êíîïêîé áèíäà è ñàìà êíîïêà (ShowHotKey)
            imgui.Text(u8'Êëàâèøà äëÿ ïîñàäêè:')
            imgui.SameLine()
            if exampleHotKey and exampleHotKey:ShowHotKey() then
                cfg.config.bind = encodeJson(exampleHotKey:GetHotKey())
                inicfg.save(cfg, 'LesHelper.ini')
            end
			
           imgui.Separator()
            imgui.Text(u8'Âñïîìîãàòåëüíûå ôóíêöèè äëÿ ôàðìà äðîâ.')
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem(u8'Õåëïåð ðûáîëîâ') then
		
            imgui.Separator()
            imgui.Text(u8'Âñïîìîãàòåëüíûå ôóíêöèè äëÿ ëîâëè ðûáû.')
            imgui.EndTabItem()
        end
		
        if imgui.BeginTabItem(u8'ÖÐ') then
            imgui.Separator()
            imgui.Text(u8'Âñïîìîãàòåëüíûå ôóíêöèè äëÿ öåíòðàëüíîãî ðûíêà.')
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem(u8'Ðóëåòêè') then
            imgui.Separator()
            imgui.Text(u8'Âñïîìîãàòåëüíûå ôóíêöèè îòêðûòèÿ ðóëåòîê')
            imgui.EndTabItem()
        end
		
if imgui.BeginTabItem(u8'Äðóãîå') then
    imgui.Separator()
    imgui.Text(u8'Ðàçíûé øëàê åáó÷èé')

    if imgui.Checkbox(u8'Ðûáèé ãëàç', camera_zoom_enabled) then
        cfg.config.camera_zoom_enabled = camera_zoom_enabled[0]
        inicfg.save(cfg, 'LesHelper.ini')
    end
    imgui.SameLine()
    imgui.Text('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Ðûáèé ãëàç (ôîâ èçìåíÿåò õóëå ñìîòðèøü âñå ïîíÿòíî)')
        imgui.EndTooltip()
    end
           imgui.Separator()
            imgui.Text(u8'Øëàê åáàíûé êàêîé-òî')
    imgui.EndTabItem()
end

        if imgui.BeginTabItem(u8'Íàñòðîéêè') then
            imgui.Text(u8'Íàñòðîéêè èíòåðôåéñà:')

            if imgui.Button(resizable[0] and u8'Îòêëþ÷èòü ðàñòÿãèâàíèå' or u8'Âêëþ÷èòü ðàñòÿãèâàíèå') then
                resizable[0] = not resizable[0]
                cfg.config.resizable = resizable[0]
                inicfg.save(cfg, 'LesHelper.ini')
            end
            imgui.SameLine()
            imgui.Text('(?)')
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Ïðè âêëþ÷åíèè âû ñìîæåòå èçìåíÿòü ðàçìåð îêíà âðó÷íóþ, òÿíóâ çà óãîë ìåíþ.')
                imgui.EndTooltip()
            end

            imgui.Separator()
            imgui.Text(u8'Òàêæå çäåñü ìîæíî òåñòèðîâàòü ôóíêöèè èëè íàñòðîéêè.')
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

    sampAddChatMessage("{00CCFF}[PenisHelper.lua] {FFFFFF}Ñêðèïò çàãðóæåí. Èñïîëüçóéòå {00CCFF}/penis{FFFFFF} äëÿ îòêðûòèÿ ìåíþ.", -1)
    sampRegisterChatCommand('penis', function() 
        Window[0] = not Window[0] 
    end)

    if type(cfg.config.bind) ~= 'string' or cfg.config.bind == '' then cfg.config.bind = '[]' end
    exampleHotKey = hotkey.RegisterHotKey('posadka', false, decodeJson(cfg.config.bind), function() end)
    hotkey.Text.NoKey = u8'Ïóñòî'
    hotkey.Text.WaitForKey = u8'Îæèä êëàâèø'

    while true do
        wait(0)
    end
end


local treeModels = {
    [765] = true, -- 1 ñòàäèÿ
    [732] = true, -- 2 ñòàäèÿ
    [727] = true, -- 3 ñòàäèÿ
    [771] = true, -- 4 ñòàäèÿ
    [777] = true, -- 5 ñòàäèÿ
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






