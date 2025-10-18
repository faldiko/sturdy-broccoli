script_name('Lesorub-Helper')

local imgui = require 'mimgui'
local encoding = require 'encoding'
local hotkey = require 'mimgui_hotkeys'
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local ffi = require("ffi")
local dlstatus = require('moonloader').download_status

encoding.default = 'CP1251'
local u8 = encoding.UTF8
local new = imgui.new

update_state = false -- Если переменная == true, значит начнётся обновление.
update_found = false -- Если будет true, будет доступна команда /update.

local script_vers = 1.1
local script_vers_text = "v1.1" -- Название нашей версии. В будущем будем её выводить ползователю.

local update_url = 'https://raw.githubusercontent.com/faldiko/sturdy-broccoli/refs/heads/main/version.ini' -- Путь к ini файлу. Позже нам понадобиться.
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = 'https://raw.githubusercontent.com/faldiko/sturdy-broccoli/refs/heads/main/FaldHelper.lua' -- Путь скрипту.
local script_path = thisScript().path

function check_update() -- Создаём функцию которая будет проверять наличие обновлений при запуске скрипта.
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then -- Сверяем версию в скрипте и в ini файле на github
                sampAddChatMessage("{FFFFFF}Имеется {32CD32}новая {FFFFFF}версия скрипта. Версия: {32CD32}"..updateIni.info.vers_text..". {FFFFFF}/update что-бы обновить", 0xFF0000) -- Сообщаем о новой версии.
                update_found = true -- если обновление найдено, ставим переменной значение true
            end
            os.remove(update_path)
        end
    end)
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

local Window = new.bool(true)
local render = new.bool(false)
local collision = new.bool(false)
local posadka = new.bool(false)
local prokachka = new.bool(false)
local spilivanie = new.bool(false)

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

    imgui.Begin(u8'Лесоруб хелпер', Window, flags)

    if imgui.BeginTabBar('Tabs') then
        if imgui.BeginTabItem(u8'Основное') then
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

            imgui.EndTabItem()
        end


        -- Вторая вкладка — посадка деревьев
        if imgui.BeginTabItem(u8'Посадка') then
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
            imgui.Text(u8'При активации функция будет автоматически сажать деревья по назначенной клавише.')
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
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    -- Проверяем наличие обновления
    check_update()

    if update_found then
        sampAddChatMessage('{00CCFF}[LesHelper] {FFFFFF}Доступно обновление! Используйте {00CCFF}/update{FFFFFF} для установки.', -1)
        sampRegisterChatCommand('update', function()
            update_state = true
        end)
    else
        sampAddChatMessage('{00CCFF}[LesHelper] {FFFFFF}Обновлений не найдено.', -1)
    end

    -- Запускаем основные потоки скрипта
    lua_thread.create(RenderRadius)
    lua_thread.create(Collision)
    lua_thread.create(AutoPressH)
    lua_thread.create(posadkaq)
    lua_thread.create(spilivanieq)

    sampAddChatMessage("{00CCFF}[LesHelper] {FFFFFF}Скрипт загружен. Используйте {00CCFF}/leshelp{FFFFFF} для меню.", -1)
    sampRegisterChatCommand('leshelp', function()
        Window[0] = not Window[0]
    end)

    if type(cfg.config.bind) ~= 'string' or cfg.config.bind == '' then cfg.config.bind = '[]' end
    exampleHotKey = hotkey.RegisterHotKey('posadka', false, decodeJson(cfg.config.bind), function() end)
    hotkey.Text.NoKey = u8'Пусто'
    hotkey.Text.WaitForKey = u8'Ожид клавиш'

    -- Основной цикл
    while true do
        wait(0)

        if update_state then
            sampAddChatMessage("{00CCFF}[LesHelper] {FFFFFF}Скачиваю новую версию...", -1)

            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("{00CCFF}[LesHelper] {32CD32}Скрипт успешно обновлён!{FFFFFF} Перезапуск...", -1)
                    thisScript():reload()
                end
            end)

            update_state = false
            break
        end
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
        -- Проверка, активна ли игра
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


function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if prokachka[0] then
        if text:match('{FFFFFF}Будет готов через:') then
            sampSendDialogResponse(dialogId, 1, 1, nil)
            return false
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







