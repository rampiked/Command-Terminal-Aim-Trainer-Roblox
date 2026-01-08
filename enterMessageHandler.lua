--Local Script--

--enterMessageHandler
local terminalBox = script.Parent.Parent:WaitForChild("terminalBox")
local terminalBody = script.Parent.Parent:WaitForChild("terminalBody")
local remote = game.ReplicatedStorage:WaitForChild("CommandRemote")
local currentLines = 0
local UserInputService = game:GetService("UserInputService")
local CursorManager = require(game.ReplicatedStorage:WaitForChild("CursorManager"))

local function trimTop()
	while currentLines > 7 do
		local newlinePos = string.find(terminalBody.Text, "\n")
		if newlinePos then
			terminalBody.Text = string.sub(terminalBody.Text, newlinePos + 1)
			currentLines -= 1
		end
	end
end

local function addOutput(text)
	terminalBody.Text ..= text
	local _, count = string.gsub(text, "\n", "")
	currentLines += count
	trimTop()
end

local function clear()
	addOutput("[SYSTEM] Cleared Terminal\n")
	terminalBox.Text = ""
	currentLines = 2
	trimTop()
end

local function help()
	addOutput("[USER] " .. terminalBox.Text .. "\n")
	addOutput(
		"[SYSTEM] Commands:\n" ..
			" /clear\n" ..
			" /help\n" ..
			" /get colors\n" ..
			" /set wall dist n\n" ..
			" /set wall color colorName\n" ..
			" /set botQuantity n\n" ..
			" /cursor [Asset ID]\n"
	)
	terminalBox.Text = ""
end

local function getColors()
	addOutput("[USER] " .. terminalBox.Text .. "\n")
	addOutput("[SYSTEM] Available wall colors: Red, Green, Blue, Pink, Orange.\n")
	terminalBox.Text = ""
end

local function sendCmd()
	addOutput("[USER] " .. terminalBox.Text .. "\n")
	remote:FireServer(terminalBox.Text)
	terminalBox.Text = ""
end

local function focusLost(enterPressed)
	if not enterPressed or terminalBox.Text == "" then return end
	local cmd = terminalBox.Text

	if string.sub(cmd, 1, 1) == "/" then
		if cmd == "/clear" then
			clear()

		elseif cmd == "/help" then
			help()

		elseif cmd == "/get colors" then
			getColors()

		elseif string.sub(cmd, 1, 12) == "/set cursor " then
			local newId = string.sub(cmd, 13)
			addOutput("[USER] " .. terminalBox.Text .. "\n")

			if tonumber(newId) then
				CursorManager:SetCursor("rbxassetid://" .. newId)
				addOutput("[SYSTEM] Cursor updated to ID " .. newId .. "\n")
			else
				addOutput("[SYSTEM] Invalid cursor ID.\n")
			end

		else
			sendCmd()
		end

	else
		addOutput("[USER] " .. cmd .. "\n")
	end

	terminalBox.Text = ""
end

terminalBox.FocusLost:Connect(focusLost)

local function onKeyPress(input, gameProcessedEvent)
	if script.Parent.Transparency == 1 then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Slash and not gameProcessedEvent then
		terminalBox:CaptureFocus()
	end
end

UserInputService.InputBegan:Connect(onKeyPress)

remote.OnClientEvent:Connect(function(message)
	addOutput(message .. "\n")
end)
