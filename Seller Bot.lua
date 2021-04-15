script_name("Seller Bot")
script_author("Miron Diamond")

script_version = 1.0

require("moonloader")

sampev = require("lib.samp.events")
imgui = require("imgui")
memory = require("memory")
effil = require("effil")
https = require("ssl.https")
encoding = require("encoding")
inicfg = require 'inicfg'
directIni = "moonloader\\Seller Bot\\settings.ini"
mainIni = inicfg.load(nil, directIni)
effil = require 'effil'
https = require 'ssl.https'
dlstatus = require('moonloader').download_status
encoding.default = ("CP1251")
u8 = encoding.UTF8

DATABASE_PATH = (getGameDirectory().."\\moonloader\\Seller Bot\\database.json"):format(getFolderPath(0x05))
SELL_LIST_PATH = (getGameDirectory().."\\moonloader\\Seller Bot\\sell_list.json"):format(getFolderPath(0x05))

VK_ADMIN_ID = {tostring(mainIni.Main.vk_admin_1),tostring(mainIni.Main.vk_admin_2), tostring(mainIni.Main.vk_admin_3)}

VK_GROUP_ID = tostring(mainIni.Main.vk_id)
VK_GROUP_TOKEN = tostring(mainIni.Main.vk_token)

PRICE = 0.000005

DATABASE = {}

SELL_LIST = {}

SERVER_LIST = {
	["Phoenix"] = "185.169.134.3",
	["Tucson"] = "185.169.134.4",
	["Scottdale"] = "185.169.134.43",
	["Chandler"] = "185.169.134.44",
	["Brainburg"] = "185.169.134.45",
	["Saint Rose"] = "185.169.134.5",
	["Mesa"] = "185.169.134.59",
	["Red Rock"] = "185.169.134.61",
	["Yuma"] = "185.169.134.107",
	["Surprise"] = "185.169.134.109",
	["Prescott"] = "185.169.134.166",
	["Glendale"] = "185.169.134.171",
	["Kingman"] = "185.169.134.172",
	["Winslow"] = "185.169.134.173",
	["Payson"] = "185.169.134.174"
}

WAIT = false

TRADE_DATA = nil

sw, sh = getScreenResolution()

main_window_state = imgui.ImBool(false)
text_buffer_password = imgui.ImBuffer(256)
text_buffer_vk_token = imgui.ImBuffer(256)
text_buffer_vk_id = imgui.ImBuffer(256)
text_buffer_vk_admin_1 = imgui.ImBuffer(256)
text_buffer_vk_admin_2 = imgui.ImBuffer(256)
text_buffer_vk_admin_3 = imgui.ImBuffer(256)

text_buffer_password.v = tostring(mainIni.Main.password)
text_buffer_vk_token.v = tostring(mainIni.Main.vk_token)
text_buffer_vk_id.v = tostring(mainIni.Main.vk_id)
text_buffer_vk_admin_1.v = tostring(mainIni.Main.vk_admin_1)
text_buffer_vk_admin_2.v = tostring(mainIni.Main.vk_admin_2)
text_buffer_vk_admin_3.v = tostring(mainIni.Main.vk_admin_3)

update_url = "https://github.com/MironDiamond/Seller-Bot/raw/main/Seller%20Bot.lua"
update_path = thisScript().path

-- Script

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
	lua_thread.create(function()
		local update_text = https.request("https://raw.githubusercontent.com/MironDiamond/Seller-Bot/main/update.ini")
		local update_version = update_text:match("version=(.*)")
		if tonumber(update_version) > script_version then
			print("Обновление..")
			downloadUrlToFile(update_url, update_path, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					print("Обновление завершено!")
				end
			end)
		end
	end)
	AntiAFK()
	loadDatabase()
	loadSellList()
	sampRegisterChatCommand("bot", function()
		main_window_state.v = not main_window_state.v
		imgui.Process = main_window_state.v
	end)
	VK_CONNECT()
	while not key do wait(10) end
	loop_async_http_request(server .. '?act=a_check&key=' .. key .. '&ts=' .. ts .. '&wait=25', '')
	wait(-1)
end

-- Imgui

function imgui.OnDrawFrame()
	if not main_window_state.v then
		imgui.Process = false
	end

	if main_window_state.v then
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(450, 380), imgui.Cond.FirstUseEver)
		imgui.Begin(u8"Бот по продаже виртов | Arizona RP", main_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize)
		if imgui.CollapsingHeader(u8("База данных")) then
			imgui.BeginChild("##1", imgui.ImVec2(-0.1, 200), true)
			imgui.Columns(4, nil, false)
			imgui.SetColumnWidth(-1, 55)
			imgui.CenterColumnText(u8"№")
			imgui.NextColumn()
			imgui.VerticalSeparator()
			imgui.CenterColumnText(u8"Ник")
			imgui.NextColumn()
			imgui.VerticalSeparator()
			imgui.SetColumnWidth(-1, 150)
			imgui.CenterColumnText(u8"VK ID")
			imgui.NextColumn()
			imgui.VerticalSeparator()
			imgui.SetColumnWidth(-1, 150)
			imgui.CenterColumnText(u8"Режим")
			imgui.Columns(1, nil, false)
			imgui.Columns(4, nil, false)
			imgui.Separator()
				for id, data in ipairs(DATABASE) do
					imgui.CenterColumnText(tostring(id))
					imgui.NextColumn()
					imgui.CenterColumnText(data.nick)
					imgui.NextColumn()
					imgui.CenterColumnText(data.id)
					imgui.NextColumn()
					imgui.CenterColumnText(tostring(data.mode))
					imgui.NextColumn()
				end
			imgui.EndChild()
		end
		if imgui.CollapsingHeader(u8("Очередь сделок")) then
			imgui.BeginChild("##2", imgui.ImVec2(-0.1, 200), true)
			imgui.Columns(5, nil, false)
			imgui.SetColumnWidth(-1, 55)
			imgui.CenterColumnText(u8"№")
			imgui.NextColumn()
			imgui.VerticalSeparator()
			imgui.SetColumnWidth(-1, 110)
			imgui.CenterColumnText(u8"Ник")
			imgui.NextColumn()
			imgui.VerticalSeparator()
			imgui.SetColumnWidth(-1, 100)
			imgui.CenterColumnText(u8"Сервер")
			imgui.NextColumn()
			imgui.VerticalSeparator()
			imgui.SetColumnWidth(-1, 90)
			imgui.CenterColumnText(u8"Вирты")
			imgui.NextColumn()
			imgui.VerticalSeparator()
			imgui.SetColumnWidth(-1, 80)
			imgui.CenterColumnText(u8"Цена")
			imgui.Columns(1, nil, false)
			imgui.Columns(5, nil, false)
			imgui.Separator()
				for id, data in ipairs(SELL_LIST) do
					imgui.CenterColumnText(tostring(id))
					imgui.NextColumn()
					imgui.CenterColumnText(data.nick)
					imgui.NextColumn()
					imgui.CenterColumnText(data.server)
					imgui.NextColumn()
					imgui.CenterColumnText(tostring(data.money))
					imgui.NextColumn()
					imgui.CenterColumnText(tostring(data.value))
					imgui.NextColumn()
				end
			imgui.EndChild()
		end
		if imgui.CollapsingHeader(u8("Список виртов")) then
			imgui.BeginChild("##3", imgui.ImVec2(-0.1, 283), true)
			for name, data in pairs(SERVER_LIST) do
				if name:find("Phoenix") then
					imgui.Text(name..": "..mainIni.Money.Phoenix.."$")
				elseif name:find("Tucson") then
					imgui.Text(name..": "..mainIni.Money.Tucson.."$")
				elseif name:find("Scottdale") then
					imgui.Text(name..": "..mainIni.Money.Scottdale.."$")
				elseif name:find("Chandler") then
					imgui.Text(name..": "..mainIni.Money.Chandler.."$")
				elseif name:find("Brainburg") then
					imgui.Text(name..": "..mainIni.Money.Brainburg.."$")
				elseif name:find("Saint Rose") then
					imgui.Text(name..": "..mainIni.Money.Saint_Rose.."$")
				elseif name:find("Mesa") then
					imgui.Text(name..": "..mainIni.Money.Mesa.."$")
				elseif name:find("Red Rock") then
					imgui.Text(name..": "..mainIni.Money.Red_Rock.."$")
				elseif name:find("Yuma") then
					imgui.Text(name..": "..mainIni.Money.Yuma.."$")
				elseif name:find("Surprise") then
					imgui.Text(name..": "..mainIni.Money.Surprise.."$")
				elseif name:find("Prescott") then
					imgui.Text(name..": "..mainIni.Money.Prescott.."$")
				elseif name:find("Glendale") then
					imgui.Text(name..": "..mainIni.Money.Glendale.."$")
				elseif name:find("Kingman") then
					imgui.Text(name..": "..mainIni.Money.Kingman.."$")
				elseif name:find("Winslow") then
					imgui.Text(name..": "..mainIni.Money.Winslow.."$")
				elseif name:find("Payson") then
					imgui.Text(name..": "..mainIni.Money.Payson.."$")
				end
			end
			imgui.EndChild()
		end
		imgui.Separator()
		imgui.NewInputText('##Password', text_buffer_password, -1, u8'Пароль от аккаунтов', 1)
		imgui.NewInputText('##VK_ID', text_buffer_vk_id, -1, u8'ID группы', 1)
		imgui.NewInputText('##Token', text_buffer_vk_token, -1, u8'Токен группы', 1)
		imgui.Separator()
		imgui.NewInputText('##VK_ADMIN_ID_1', text_buffer_vk_admin_1, -1, u8'ID Администратора №1', 1)
		imgui.NewInputText('##VK_ADMIN_ID_2', text_buffer_vk_admin_2, -1, u8'ID Администратора №2', 1)
		imgui.NewInputText('##VK_ADMIN_ID_3', text_buffer_vk_admin_3, -1, u8'ID Администратора №3', 1)
		imgui.Separator()
		if imgui.Button(u8"Обновить вирты на данном сервере", imgui.ImVec2(-1, 20)) then
			sampSendChat("/stats")
		end
		if imgui.Button(u8"Обнулить базу данных", imgui.ImVec2(-1, 20)) then
			Warning_Database = true
		end
		if Warning_Database then
			imgui.BeginChild("##4", imgui.ImVec2(-0.1, 50), true)
			local textSize = imgui.CalcTextSize(u8"Вы действительно хотите обнулить базу данных?")
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - textSize.x / 2)
			imgui.Text(u8"Вы действительно хотите обнулить базу данных?")
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - textSize.x / 5)
			if imgui.Button(u8"Да", imgui.ImVec2(50, 20)) then
				DATABASE = {}
				Warning_Database = false
			end
			imgui.SameLine()
			if imgui.Button(u8"Нет", imgui.ImVec2(50, 20)) then
				Warning_Database = false
			end
			imgui.EndChild()
		end
		if imgui.Button(u8"Обнулить очередь сделок", imgui.ImVec2(-1, 20)) then
			Warning_SellList = true
		end
		if Warning_SellList then
			imgui.BeginChild("##5", imgui.ImVec2(-0.1, 50), true)
			local textSize = imgui.CalcTextSize(u8"Вы действительно хотите очередь сделок?")
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - textSize.x / 1.6)
			imgui.Text(u8"Вы действительно хотите обнулить очередь сделок?")
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - textSize.x / 4.6)
			if imgui.Button(u8"Да", imgui.ImVec2(50, 20)) then
				SELL_LIST = {}
				Warning_SellList = false
			end
			imgui.SameLine()
			if imgui.Button(u8"Нет", imgui.ImVec2(50, 20)) then
				Warning_SellList = false
			end
			imgui.EndChild()
		end
		if imgui.Button(u8"Перезагрузить скрипт", imgui.ImVec2(-1, 20)) then
			thisScript():reload()
		end
		if imgui.Button(u8"Выключить скрипт", imgui.ImVec2(-1, 20)) then
			thisScript():unload()
		end
		imgui.End()
	end

	mainIni.Main.password = tostring(text_buffer_password.v)
	mainIni.Main.vk_id = tostring(text_buffer_vk_id.v)
	mainIni.Main.vk_token = tostring(text_buffer_vk_token.v)
	mainIni.Main.vk_admin_1 = tostring(text_buffer_vk_admin_1.v)
	mainIni.Main.vk_admin_2 = tostring(text_buffer_vk_admin_2.v)
	mainIni.Main.vk_admin_3 = tostring(text_buffer_vk_admin_3.v)
end

-- Events

function sampev.onSendSpawn()
	if WAIT then
		SPAWN_TIMER_THREAD:run()
	end
end

function sampev.onServerMessage(color, text)
	if WAIT then
		if text:find("%[Информация%] {ffffff}Сделка прошла успешно%.") then
			SELL_THREAD:terminate()
			TRADE_TIMER_THREAD:terminate()
			VK_SEND(SELL_LIST[1], 0, "&#9989; Спасибо за покупку!")
			for id, data in ipairs(DATABASE) do
				if SELL_LIST[1].id == data.id then
					data.mode = 0
				end
			end
			table.remove(SELL_LIST, 1)
			sampSendChat("/stats")
		elseif text:find("(.+)%[(%d+)%] отменил сделку") and not text:find("говорит") and not text:find("%(%(") then
			local check_name = text:match("(.+)%[%d+%] отменил сделку")
			if check_name:find(TRADE_DATA.nick) then
				TRADE_TIMER_THREAD:terminate()
				SPAWN_TIMER_THREAD:terminate()
				WAIT = false
				VK_SEND(TRADE_DATA.id, 3, "&#8505; Сделка отменена! Вы отменили сделку.\n\n	Желаете вернуться обратно в очередь?")
				wait(1000)
				VK_SEND(VK_ADMIN_ID[1], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] отменил сделку.")
				wait(1000)
				VK_SEND(VK_ADMIN_ID[2], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] отменил сделку.")
				wait(1000)
				VK_SEND(VK_ADMIN_ID[3], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] отменил сделку.")
				for id, data in ipairs(DATABASE) do
					if TRADE_DATA.id == data.id then
						data.mode = 4
					elseif data.id == VK_ADMIN_ID[1] or data.id == VK_ADMIN_ID[2] or data.id == VK_ADMIN_ID[3] then
						data.mode = 10
					end
				end
				table.remove(SELL_LIST, 1)
			end
		end
	end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	if text:find("пароль") then
		if #tostring(mainIni.Main.password) > 0 then
			sampSendDialogResponse(id, 1, -1, tostring(mainIni.Main.password))
			return false
		end
	end

	if title:find("Основная статистика") then
		if not WAIT then
			local value = tonumber(text:match("Деньги: {......}%[$(%d+)%]"))
			local server = sampGetCurrentServerAddress()
			for name, ip in pairs(SERVER_LIST) do
				if ip == server then
					if name:find("Phoenix") then
						mainIni.Money.Phoenix = value
					elseif name:find("Tucson") then
						mainIni.Money.Tucson = value
					elseif name:find("Scottdale") then
						mainIni.Money.Scottdale = value
					elseif name:find("Chandler") then
						mainIni.Money.Chandler = value
					elseif name:find("Brainburg") then
						mainIni.Money.Brainburg = value
					elseif name:find("Saint Rose") then
						mainIni.Money.Saint_Rose = value
					elseif name:find("Mesa") then
						mainIni.Money.Mesa = value
					elseif name:find("Red Rock") then
						mainIni.Money.Red_Rock = value
					elseif name:find("Yuma") then
						mainIni.Money.Yuma = value
					elseif name:find("Surprise") then
						mainIni.Money.Surprise = value
					elseif name:find("Prescott") then
						mainIni.Money.Prescott = value
					elseif name:find("Glendale") then
						mainIni.Money.Glendale = value
					elseif name:find("Kingman") then
						mainIni.Money.Kingman = value
					elseif name:find("Winslow") then
						mainIni.Money.Winslow = value
					elseif name:find("Payson") then
						mainIni.Money.Payson = value
					end
					break
				end
			end
		else
			local value = tonumber(text:match("Деньги: {......}%[$(%d+)%]"))
			local server = sampGetCurrentServerAddress()
			for name, ip in pairs(SERVER_LIST) do
				if ip == server then
					if name:find("Phoenix") then
						mainIni.Money.Phoenix = value
					elseif name:find("Tucson") then
						mainIni.Money.Tucson = value
					elseif name:find("Scottdale") then
						mainIni.Money.Scottdale = value
					elseif name:find("Chandler") then
						mainIni.Money.Chandler = value
					elseif name:find("Brainburg") then
						mainIni.Money.Brainburg = value
					elseif name:find("Saint Rose") then
						mainIni.Money.Saint_Rose = value
					elseif name:find("Mesa") then
						mainIni.Money.Mesa = value
					elseif name:find("Red Rock") then
						mainIni.Money.Red_Rock = value
					elseif name:find("Yuma") then
						mainIni.Money.Yuma = value
					elseif name:find("Surprise") then
						mainIni.Money.Surprise = value
					elseif name:find("Prescott") then
						mainIni.Money.Prescott = value
					elseif name:find("Glendale") then
						mainIni.Money.Glendale = value
					elseif name:find("Kingman") then
						mainIni.Money.Kingman = value
					elseif name:find("Winslow") then
						mainIni.Money.Winslow = value
					elseif name:find("Payson") then
						mainIni.Money.Payson = value
					end
					break
				end
			end
			sampConnectToServer("0.0.0.0",7777)
		end
		return false
	end

	if WAIT then
		if text:find("Игрок (.+)%[(%d+)%] предлагает вам торговлю%.") then
			local name = text:match("Игрок (.+)%[%d+%] предлагает вам торговлю%.")
			if name:find(TRADE_DATA.nick) then
				sampSendDialogResponse(id, 1, -1, -1)
				TRADE_TIMER_THREAD:run()
			else
				sampSendDialogResponse(id, 0, -1, -1)
			end
			return false
		elseif title:find("Предупреждение!") then
			SELL_THREAD:terminate()
			SELL_THREAD = lua_thread.create(function()
				sampSendDialogResponse(id, 1, -1, -1)
				while true do
					sampSendClickTextdraw(2082)
					wait(3000)
				end
			end)
			return false
		elseif title:find("Торговля") then
			SELL_THREAD:terminate()
			SELL_THREAD = lua_thread.create(function()
				sampSendDialogResponse(id, 1, -1, tostring(TRADE_DATA.money))
				wait(2500)
				sampSendClickTextdraw(2082)
			end)
			return false
		end
	end
end

function sampev.onShowTextDraw(id)
	if id == 2072 then
		sampSendClickTextdraw(2072)
	end
	return false
end

function onScriptTerminate(script, quitGame)
  if thisScript() == script then
		inicfg.save(mainIni, directIni)
    saveDatabase()
		saveSellList()
  end
end

-- Thread

SELL_THREAD = lua_thread.create(function() end)

SPAWN_TIMER_THREAD = lua_thread.create_suspended(function()
	local location = nil
	local mx, my, mz = getCharCoordinates(PLAYER_PED)
	local _, bot_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if getDistanceBetweenCoords2d(mx, my, 1761.6706542969, -1895.7725830078) < 60 then
		location = "ЖДЛС"
	elseif getDistanceBetweenCoords2d(mx, my, 2215.6975097656, -1165.43896484387) < 60 then
		location = "Мотель ЛС"
	elseif getDistanceBetweenCoords2d(mx, my, -1968.9661865234, 138.09382629395) < 100 then
		location = "ЖДСФ"
	elseif getDistanceBetweenCoords2d(mx, my, 2848.462890625, 1290.9520263672) < 100 then
		location = "ЖДЛВ"
	else
		location = "error"
	end
	VK_SEND(TRADE_DATA.id, 3, "&#8505; Внимание! Бот уже подключился к серверу!\n\n&#128506; Бот находится на: "..location.."\n&#128506; ID бота: "..bot_id.."\n\n&#128181; Для получения виртов, отправляйтесь к боту на его местоположение. Как прибудете на место, предложите боту /trade и бот автоматически передаст нужную вам сумму. Ваша адача просто подтвердить трейд.\n\n&#9888; Что бы найти бота и предложить ему трейд, у вас есть: 15 минут.\n&#9888; На совершение сделки у вас есть: 5 минут.")
	local start = os.time()
	local sec = 15 * 60
	start = os.time()
	while os.time() - start < sec do
		local timer_text = sec - (os.time() - start)
		wait(1000)
	end
	WAIT = false
	VK_SEND(TRADE_DATA.id, 4, "&#8505; Сделка отменена! Вы не совершили трейд с ботом в течении 15 минут.\n\n	Желаете вернуться обратно в очередь?")
	wait(1000)
	VK_SEND(VK_ADMIN_ID[1], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] не совершил трейд в течении 15 минут.")
	wait(1000)
	VK_SEND(VK_ADMIN_ID[2], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] не совершил трейд в течении 15 минут.")
	wait(1000)
	VK_SEND(VK_ADMIN_ID[3], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] не совершил трейд в течении 15 минут.")
	for id, data in ipairs(DATABASE) do
		if TRADE_DATA.id == data.id then
			data.mode = 4
		elseif data.id == VK_ADMIN_ID[1] or data.id == VK_ADMIN_ID[2] or data.id == VK_ADMIN_ID[3] then
			data.mode = 10
		end
	end
	table.remove(SELL_LIST, 1)
end)

TRADE_TIMER_THREAD = lua_thread.create_suspended(function()
	SPAWN_TIMER_THREAD:terminate()
	local start = os.time()
	local sec = 5 * 60
	start = os.time()
	while os.time() - start < sec do
		local timer_text = sec - (os.time() - start)
		wait(1000)
	end
	WAIT = false
	VK_SEND(TRADE_DATA.id, 3, "&#8505; Сделка отменена! Вы не подтвердили сделку с ботом в течении 5 минут.\n\n	Желаете вернуться обратно в очередь?")
	wait(1000)
	VK_SEND(VK_ADMIN_ID[1], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] не подтвердил сделку в течении 5 минут.")
	wait(1000)
	VK_SEND(VK_ADMIN_ID[2], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] не подтвердил сделку в течении 5 минут.")
	wait(1000)
	VK_SEND(VK_ADMIN_ID[3], 10, "&#8505; Игрок [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."] не подтвердил сделку в течении 5 минут.")
	for id, data in ipairs(DATABASE) do
		if TRADE_DATA.id == data.id then
			data.mode = 4
		elseif data.id == VK_ADMIN_ID[1] or data.id == VK_ADMIN_ID[2] or data.id == VK_ADMIN_ID[3] then
			data.mode = 10
		end
	end
	table.remove(SELL_LIST, 1)
end)

-- VK

function VK_SEND(user_id, keyboard_mode, msg)
	msg = msg:gsub('{......}', '')
	msg = u8(msg)
	msg = url_encode(msg)
	local keyboard = VK_KEYBOARD(keyboard_mode)
	keyboard = u8(keyboard)
	keyboard = url_encode(keyboard)
	msg = msg .. '&keyboard=' .. keyboard
	async_http_request('https://api.vk.com/method/messages.send', 'user_id=' .. tostring(user_id) .. '&message=' .. tostring(msg) .. '&access_token=' .. tostring(VK_GROUP_TOKEN) .. '&v=5.80',	function (result)
		local t = decodeJson(result)
		if not t then
			return
		end
	end)
end

function VK_READ(result)
	if result then
		local t = decodeJson(result)
		if t.ts then
			ts = t.ts
		end
		for k, v in ipairs(t.updates) do
			if v.type == 'message_new' and v.object.text then
				local user_id = tostring(v.object.from_id)
				local text = u8:decode(v.object.text .. ' ')
        if user_id ~= VK_ADMIN_ID[1] and user_id ~= VK_ADMIN_ID[2] and user_id ~= VK_ADMIN_ID[3] then
          if text:find("Начать") then
            if #DATABASE > 0 then
              for id, data in ipairs(DATABASE) do
                if tostring(data.id) == user_id then
                  break
                elseif tostring(data.id) ~= user_id and id == #data then
                  VK_SEND(user_id, 0, "&#129302; Здравствуйте! Вижу вы тут впервые..\nЯ бот который был создан для продажи виртов на Arizona RP.\nПользуйтесь кнопками ниже, а так же читайте инструкции!")
                  table.insert(DATABASE, {id = tostring(user_id), mode = 0, server = "N/A", nick = "N/A", money = "0", value = "0"})
                  break
                end
              end
            else
              VK_SEND(user_id, 0, "&#129302; Здравствуйте! Вижу вы тут впервые..\nЯ бот который был создан для продажи виртов на Arizona RP.\nПользуйтесь кнопками ниже, а так же читайте инструкции!")
              table.insert(DATABASE, {id = tostring(user_id), mode = 0, server = "N/A", nick = "N/A", money = "0", value = "0"})
            end
          elseif text:find("Купить") then
            for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 0 then
      					VK_SEND(user_id, 0, "&#128176; Для покупки виртуальной валюты, введите команду:\n	/buy [название сервера] [игровой ник] [сумма]\n\n&#128221; Пример:\n	/buy Scottdale Miron_Diamond 5000000")
                break
              end
            end
          elseif text:find("/buy (.+) (.+) (%d+)") then
            for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 0 then
                local server, nick, money = text:match("/buy (.+) (.+) (%d+)")
								local value = round(PRICE*tonumber(money))
								local server_id = 0
								local bool = false
								for name, data in pairs(SERVER_LIST) do
									server_id = server_id + 1
									if server:find(name) and tonumber(money) >= 5000000 then
										if name:find("Phoenix") then
											if mainIni.Money.Phoenix >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Tucson") then
											if mainIni.Money.Tucson >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Scottdale") then
											if mainIni.Money.Scottdale >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Chandler") then
											if mainIni.Money.Chandler >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Brainburg") then
											if mainIni.Money.Brainburg >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Saint Rose") then
											if mainIni.Money.Saint_Rose >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Mesa") then
											if mainIni.Money.Mesa >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Red Rock") then
											if mainIni.Money.Red_Rock >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Yuma") then
											if mainIni.Money.Yuma >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Surprise") then
											if mainIni.Money.Surprise >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Prescott") then
											if mainIni.Money.Prescott >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Glendale") then
											if mainIni.Money.Glendale >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Kingman") then
											if mainIni.Money.Kingman >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Winslow") then
											if mainIni.Money.Winslow >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										elseif name:find("Payson") then
											if mainIni.Money.Payson >= tonumber(money) then
												bool = true
											else
												VK_SEND(user_id, 0, "&#128549; Простите, но данной суммы нет на нужном вам сервере.")
											end
										end
										break
									elseif server_id == 15 and (not server:find(name) or tonumber(money) < 5000000) then
										VK_SEND(user_id, 0, "&#9940; Ошибка параметров!\nПерепроверьте название сервера, а так же сумму заказа.\n	Минимальная сумма заказа должна быть 5000000$.")
										bool = false
										break
									end
								end
								if bool then
									VK_SEND(user_id, 1, "&#128204; Информация о заказе:\n\n-  Сервер: Arizona RP | "..tostring(server).."\n- Игровой ник: "..tostring(nick).."\n- Сумма виртов: "..tostring(money).."$\n\n&#128176; Цена: "..value.." руб.\n\n&#9989; Вы согласны оплатить заказ?")
									data.mode = 1
									data.server = tostring(server)
									data.nick = tostring(nick)
									data.money = tostring(money)
									data.value = tostring(value)
								end
                break
              end
            end
  				elseif text:find("Оплатить") then
            for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 1 then
      					VK_SEND(user_id, 2, "&#129309; Список доступных способов оплаты:\n\n1. qiwi.com/n/BARIGASAMPA\n\n&#9888; После оплаты, ваша заявка отправляется в очередь на проверку. Если вы подтвердили платеж и не совершили оплату, то ваша заявка будет отклонена.")
                data.mode = 2
                break
              end
            end
          elseif text:find("Отмена") then
            for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 1 or data.mode == 2 then
                VK_SEND(user_id, 0, "&#128683; Операция отменена.")
                data.mode = 0
                break
              end
            end
          elseif text:find("Подтвердить платеж") then
            for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 2 then
                VK_SEND(user_id, 3, "&#10004; Ваша заявка была отправлена в очередь!")
								table.insert(SELL_LIST, {id = data.id, server = data.server, nick = data.nick, money = data.money, value = data.value})
                data.mode = 3
                break
              end
            end
          elseif text:find("Узнать позицию в очереди") then
            for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 3 then
                VK_SEND(user_id, 3, "&#8505; Ваша позиция в очереди: "..id)
                break
              end
            end
					elseif text:find("Да") then
						for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 4 then
								table.insert(SELL_LIST, {id = data.id, server = data.server, nick = data.nick, money = data.money, value = data.value})
                VK_SEND(user_id, 3, "&#9989; Вы подали заявку обратно в очередь!\n Ваша новая позиция в очереди: "..#SELL_LIST)
								data.mode = 3
                break
              end
            end
					elseif text:find("Нет") then
						for id, data in ipairs(DATABASE) do
              if tostring(data.id) == user_id and data.mode == 4 then
                VK_SEND(user_id, 0, "&#10062; Вы отменили заказ.")
								data.mode = 0
                break
              end
            end
					end
        elseif user_id == VK_ADMIN_ID[1] or user_id == VK_ADMIN_ID[2] or user_id == VK_ADMIN_ID[3] then
					if not WAIT or text:find("Отменить сделку") then
	          if text:find("Начать") then
	            if #DATABASE > 0 then
	              for id, data in ipairs(DATABASE) do
	                if tostring(data.id) == user_id then
	                  break
	                elseif tostring(data.id) ~= user_id and id == #data then
	                  VK_SEND(user_id, 10, "&#129302; Вы авторизировались как администратор.")
	                  table.insert(DATABASE, {id = tostring(user_id), mode = 10, server = "N/A", nick = "N/A", money = "0", value = "0"})
	                  break
	                end
	              end
	            else
	              VK_SEND(user_id, 10, "&#129302; Вы авторизировались как администратор.")
	              table.insert(DATABASE, {id = tostring(user_id), mode = 10, server = "N/A", nick = "N/A", money = "0", value = "0"})
	            end
	          elseif text:find("Список заказов") then
	            for id, data in ipairs(DATABASE) do
	              if tostring(data.id) == user_id and data.mode == 10 then
	                if #SELL_LIST > 0 then
	                  VK_SEND(user_id, 11, "&#128204; Информация о заказе:\n\n&#127380; Клиент: [id"..tostring(SELL_LIST[1].id).."|"..tostring(SELL_LIST[1].id).."]\n\n- Сервер: Arizona RP | "..tostring(SELL_LIST[1].server).."\n- Игровой ник: "..tostring(SELL_LIST[1].nick).."\n- Сумма виртов: "..tostring(SELL_LIST[1].money).."$\n\n&#128176; Цена: "..tostring(SELL_LIST[1].value).." руб.")
	                  data.mode = 11
	                  break
	                else
	                  VK_SEND(user_id, 10, "&#128577; Список заказов пуст.")
	                  break
	                end
	              end
	            end
						elseif text:find("Подтвердить сделку") then
							for id, data in ipairs(DATABASE) do
	              if tostring(data.id) == user_id and data.mode == 11 then
									WAIT = true
									TRADE_DATA = SELL_LIST[1]
									lua_thread.create(function()
										VK_SEND(TRADE_DATA.id, 3, "&#8505; Заказ подтвержден!")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[1], 12, "&#8505; [id"..user_id.."|Администратор] подтвердил сделку игроку [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."].")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[2], 12, "&#8505; [id"..user_id.."|Администратор] подтвердил сделку игроку [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."].")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[3], 12, "&#8505; [id"..user_id.."|Администратор] подтвердил сделку игроку [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."].")
										local server = TRADE_DATA.server
											for name, ip in pairs(SERVER_LIST) do
												if name == server then
													sampConnectToServer(tostring(ip),7777)
													break
												end
											end
										data.mode = 12
									end)
									break
								end
							end
						elseif text:find("Отклонить сделку") then
							for id, data in ipairs(DATABASE) do
								if tostring(data.id) == user_id and data.mode == 11 then
									lua_thread.create(function()
										VK_SEND(SELL_LIST[1].id, 0, "&#8505; Ваш заказ отклонен.")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[1], 10, "&#8505; [id"..user_id.."|Администратор] отклонил сделку игроку [id"..SELL_LIST[1].id.."|"..SELL_LIST[1].nick.."].")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[2], 10, "&#8505; [id"..user_id.."|Администратор] отклонил сделку игроку [id"..SELL_LIST[1].id.."|"..SELL_LIST[1].nick.."].")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[3], 10, "&#8505; [id"..user_id.."|Администратор] отклонил сделку игроку [id"..SELL_LIST[1].id.."|"..SELL_LIST[1].nick.."].")
										for id, data in ipairs(DATABASE) do
											if SELL_LIST[1].id == data.id then
												data.mode = 0
												break
											end
										end
										table.remove(SELL_LIST, 1)
										data.mode = 10
									end)
									break
								end
							end
						elseif text:find("Отменить сделку") then
							for id, data in ipairs(DATABASE) do
								if tostring(data.id) == user_id and data.mode == 12 then
									WAIT = false
									SPAWN_TIMER_THREAD:terminate()
									TRADE_TIMER_THREAD:terminate()
									lua_thread.create(function()
										VK_SEND(TRADE_DATA.id, 0, "&#8505; Ваш заказ отменен.")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[1], 10, "&#8505; [id"..user_id.."|Администратор] отменил сделку игроку [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."].")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[2], 10, "&#8505; [id"..user_id.."|Администратор] отменил сделку игроку [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."].")
										wait(1000)
										VK_SEND(VK_ADMIN_ID[3], 10, "&#8505; [id"..user_id.."|Администратор] отменил сделку игроку [id"..TRADE_DATA.id.."|"..TRADE_DATA.nick.."].")
										for id, data in ipairs(DATABASE) do
											if TRADE_DATA.id == data.id then
												data.mode = 0
												break
											end
										end
										table.remove(SELL_LIST, 1)
										data.mode = 10
									end)
									break
								end
							end
						end
					else
						VK_SEND(user_id, 12, "&#9940; Недоступно! В данный момент проводится сделка.")
					end
				end
			end
		end
	end
end

function VK_CONNECT()
	async_http_request('https://api.vk.com/method/groups.getLongPollServer?group_id=' .. VK_GROUP_ID .. '&access_token=' .. VK_GROUP_TOKEN .. '&v=5.80', '', function (result)
		if result then
			if not result:sub(1,1) == '{' then
				return
			end
			local t = decodeJson(result)
			if t.error then
				return
			end
			server = t.response.server
			ts = t.response.ts
			key = t.response.key
		end
	end)
end

function VK_KEYBOARD(mode)
	if mode == 0 then
		local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'primary'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Купить'
		return encodeJson(keyboard)
	elseif mode == 1 then
		local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'positive'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Оплатить'
		row[2] = {}
		row[2].action = {}
		row[2].color = 'negative'
		row[2].action.type = 'text'
		row[2].action.payload = '{"button": "status"}'
		row[2].action.label = 'Отмена'
		return encodeJson(keyboard)
	elseif mode == 2 then
		local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'positive'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Подтвердить платеж'
		row[2] = {}
		row[2].action = {}
		row[2].color = 'negative'
		row[2].action.type = 'text'
		row[2].action.payload = '{"button": "status"}'
		row[2].action.label = 'Отмена'
		return encodeJson(keyboard)
	elseif mode == 3 then
    local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'primary'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Узнать позицию в очереди'
		return encodeJson(keyboard)
	elseif mode == 4 then
		local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'positive'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Да'
		row[2] = {}
		row[2].action = {}
		row[2].color = 'negative'
		row[2].action.type = 'text'
		row[2].action.payload = '{"button": "status"}'
		row[2].action.label = 'Нет'
		return encodeJson(keyboard)
	elseif mode == 10 then
    local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'primary'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Список заказов'
		return encodeJson(keyboard)
	elseif mode == 11 then
		local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'positive'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Подтвердить сделку'
		row[2] = {}
		row[2].action = {}
		row[2].color = 'negative'
		row[2].action.type = 'text'
		row[2].action.payload = '{"button": "status"}'
		row[2].action.label = 'Отклонить сделку'
		return encodeJson(keyboard)
	elseif mode == 12 then
		local keyboard = {}
		keyboard.one_time = false
		keyboard.buttons = {}
		keyboard.buttons[1] = {}
		local row = keyboard.buttons[1]
		row[1] = {}
		row[1].action = {}
		row[1].color = 'negative'
		row[1].action.type = 'text'
		row[1].action.payload = '{"button": "status"}'
		row[1].action.label = 'Отменить сделку'
		return encodeJson(keyboard)
	end
end

-- Function

function AntiAFK()
	memory.setuint8(7634870, 1, false)
	memory.setuint8(7635034, 1, false)
	memory.fill(7623723, 144, 8, false)
	memory.fill(5499528, 144, 6, false)
end

function loadDatabase()
  for line in io.lines(DATABASE_PATH) do
    local result, data = pcall(decodeJson, line)
    if result then
	    table.insert(DATABASE, data)
		end
	end
end

function saveDatabase()
  local file = io.open(DATABASE_PATH, "w")
  for i, data in ipairs(DATABASE) do
      file:write(encodeJson(data, true))
      if #DATABASE ~= i then file:write("\n") end
  end
  file:close()
end

function loadSellList()
  for line in io.lines(SELL_LIST_PATH) do
    local result, data = pcall(decodeJson, line)
    if result then
	    table.insert(SELL_LIST, data)
		end
	end
end

function saveSellList()
  local file = io.open(SELL_LIST_PATH, "w")
  for i, data in ipairs(SELL_LIST) do
      file:write(encodeJson(data, true))
      if #SELL_LIST ~= i then file:write("\n") end
  end
  file:close()
end

-- Technical Function

function imgui.NewInputText(lable, val, width, hint, hintpos)
    local hint = hint and hint or ''
    local hintpos = tonumber(hintpos) and tonumber(hintpos) or 1
    local cPos = imgui.GetCursorPos()
    imgui.PushItemWidth(width)
    local result = imgui.InputText(lable, val)
    if #val.v == 0 then
        local hintSize = imgui.CalcTextSize(hint)
        if hintpos == 2 then imgui.SameLine(cPos.x + (width - hintSize.x) / 2)
        elseif hintpos == 3 then imgui.SameLine(cPos.x + (width - hintSize.x - 5))
        else imgui.SameLine(cPos.x + 5) end
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 0.40), tostring(hint))
    end
    imgui.PopItemWidth()
    return result
end

function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function imgui.VerticalSeparator()
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x, p.y + 999999999999999999), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.Separator]))
end

function sampGetPlayerIdByNickname(nick)
  nick = tostring(nick)
  local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
  if nick == sampGetPlayerNickname(myid) then return myid end
  for i = 0, 1003 do
    if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
      return i
    end
  end
end

function requestRunner()
	return effil.thread(function(u, a)
		local https = require 'ssl.https'
		local ok, result = pcall(https.request, u, a)
		if ok then
			return {true, result}
		else
			return {false, result}
		end
	end)
end

function threadHandle(runner, url, args, resolve, reject)
	local t = runner(url, args)
	local r = t:get(0)
	while not r do
		r = t:get(0)
		wait(0)
	end
	local status = t:status()
	if status == 'completed' then
		local ok, result = r[1], r[2]
		if ok then resolve(result) else reject(result) end
	elseif err then
		reject(err)
	elseif status == 'canceled' then
		reject(status)
	end
	t:cancel(0)
end

function async_http_request(url, args, resolve, reject)
	local runner = requestRunner()
	if not reject then reject = function() end end
	lua_thread.create(function()
		threadHandle(runner, url, args, resolve, reject)
	end)
end

function loop_async_http_request(url, args, reject)
	local runner = requestRunner()
	if not reject then reject = function() end end
	lua_thread.create(function()
		while true do
			while not key do wait(0) end
			url = server .. '?act=a_check&key=' .. key .. '&ts=' .. ts .. '&wait=25'
			threadHandle(runner, url, args, VK_READ, reject)
		end
	end)
end

function char_to_hex(str)
  return string.format("%%%02X", string.byte(str))
end

function url_encode(str)
  local str = string.gsub(str, "\\", "\\")
  local str = string.gsub(str, "([^%w])", char_to_hex)
  return str
end

function round(number)
  if (number - (number % 0.1)) - (number - (number % 1)) < 0.5 then
    number = number - (number % 1)
  else
    number = (number - (number % 1)) + 1
  end
 return number
end

function apply_custom_style()
    imgui.SwitchContext()
		style = imgui.GetStyle()
		colors = style.Colors
		clr = imgui.Col
		ImVec4 = imgui.ImVec4
		ImVec2 = imgui.ImVec2
		style.WindowRounding = 3
		style.FrameRounding = 2.5
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
		colors[clr.Text]                 = ImVec4(0.86, 0.93, 0.89, 0.78)
		colors[clr.TextDisabled]         = ImVec4(0.36, 0.42, 0.47, 1.00)
		colors[clr.WindowBg]             = ImVec4(0.11, 0.15, 0.17, 1.00)
		colors[clr.ChildWindowBg]        = ImVec4(0.15, 0.18, 0.22, 1.00)
		colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
		colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
		colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
		colors[clr.FrameBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
		colors[clr.FrameBgHovered]       = ImVec4(0.19, 0.12, 0.28, 1.00)
		colors[clr.FrameBgActive]        = ImVec4(0.09, 0.12, 0.14, 1.00)
		colors[clr.TitleBg]              = ImVec4(0.04, 0.04, 0.04, 1.00)
		colors[clr.TitleBgActive]        = ImVec4(0.41, 0.19, 0.63, 1.00)
		colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
		colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
		colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
		colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
		colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
		colors[clr.ScrollbarGrabActive]  = ImVec4(0.20, 0.09, 0.31, 1.00)
		colors[clr.ComboBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
		colors[clr.CheckMark]            = ImVec4(0.59, 0.28, 1.00, 1.00)
		colors[clr.SliderGrab]           = ImVec4(0.41, 0.19, 0.63, 1.00)
		colors[clr.SliderGrabActive]     = ImVec4(0.41, 0.19, 0.63, 1.00)
		colors[clr.Button]               = ImVec4(0.41, 0.19, 0.63, 0.44)
		colors[clr.ButtonHovered]        = ImVec4(0.41, 0.19, 0.63, 0.86)
		colors[clr.ButtonActive]         = ImVec4(0.64, 0.33, 0.94, 1.00)
		colors[clr.Header]               = ImVec4(0.20, 0.25, 0.29, 0.55)
		colors[clr.HeaderHovered]        = ImVec4(0.51, 0.26, 0.98, 0.80)
		colors[clr.HeaderActive]         = ImVec4(0.53, 0.26, 0.98, 1.00)
		colors[clr.Separator]            = ImVec4(0.50, 0.50, 0.50, 1.00)
		colors[clr.SeparatorHovered]     = ImVec4(0.60, 0.60, 0.70, 1.00)
		colors[clr.SeparatorActive]      = ImVec4(0.70, 0.70, 0.90, 1.00)
		colors[clr.ResizeGrip]           = ImVec4(0.59, 0.26, 0.98, 0.25)
		colors[clr.ResizeGripHovered]    = ImVec4(0.61, 0.26, 0.98, 0.67)
		colors[clr.ResizeGripActive]     = ImVec4(0.06, 0.05, 0.07, 1.00)
		colors[clr.CloseButton]          = ImVec4(0.40, 0.39, 0.38, 0.16)
		colors[clr.CloseButtonHovered]   = ImVec4(0.40, 0.39, 0.38, 0.39)
		colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
		colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
		colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
		colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
		colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.TextSelectedBg]       = ImVec4(0.25, 1.00, 0.00, 0.43)
		colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
apply_custom_style()
