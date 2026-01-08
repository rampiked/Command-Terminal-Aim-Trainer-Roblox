--Server Script--

--messageReceiver
local wallDistValue = 75
local gameSettings = require(game.ServerStorage:WaitForChild("gameSettings"))
local remote = game.ReplicatedStorage:WaitForChild("CommandRemote")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local updateAccuracyEvent = ReplicatedStorage:WaitForChild("UpdateAccuracy")

-- Teleport all players to center
local function teleportAllPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local hrp = character:WaitForChild("HumanoidRootPart")
			hrp.CFrame = CFrame.new(0, 1, 0)
		end
	end
end

-- Force respawn all players
local function respawnPlayer()
	for _, player in pairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end
end

-- Normalize commands (remove extra spaces and lowercase)
local function normalizeCommand(cmd)
	cmd = cmd:gsub("^%s+", ""):gsub("%s+$", "") -- trim
	return cmd:lower()
end

remote.OnServerEvent:Connect(function(player, command)
	print("Received command: " .. command)
	local cmd = normalizeCommand(command)
	
	-- /set commands
	if string.sub(cmd, 1, 5) == "/set " then
		-- Wall distance
		if string.sub(cmd, 1, 15) == "/set wall dist " then
			local valueString = string.sub(cmd, 16)
			local newValue = tonumber(valueString)
			if not newValue or newValue < 5 or newValue > 150 then
				remote:FireClient(player, "[SYSTEM] Invalid wall distance. Provide 5-150.")
				return
			end
			wallDistValue = newValue
			gameSettings.wallDistValue = wallDistValue

			-- Fire botScript event
			local botScript = game.ServerScriptService:FindFirstChild("botScript")
			if botScript then
				local event = botScript:FindFirstChild("WallDistChanged")
				if event then event:Fire() end
			end

			-- Move walls
			game.Workspace.posXSmaller.Position = Vector3.new(-wallDistValue, 75, 0)
			game.Workspace.negXSmaller.Position = Vector3.new(wallDistValue, 75, 0)
			game.Workspace.posZSmaller.Position = Vector3.new(0, 75, -wallDistValue)
			game.Workspace.negZSmaller.Position = Vector3.new(0, 75, wallDistValue)

			remote:FireClient(player, "[SYSTEM] Walls set to distance " .. wallDistValue)
			respawnPlayer()

			-- Wall color
		elseif string.sub(cmd, 1, 16) == "/set wall color " then
			local valueString = string.sub(command, 17) -- preserve capitalization for colors
			local colorMap = {
				red = BrickColor.Red().Color,
				green = BrickColor.Green().Color,
				blue = BrickColor.palette(5).Color,
				pink = BrickColor.palette(77).Color,
				orange = Color3.fromRGB(181, 121, 0)
			}

			local color = colorMap[valueString:lower()]
			if color then
				game.Workspace.posXSmaller.Color = color
				game.Workspace.negXSmaller.Color = color
				game.Workspace.posZSmaller.Color = color
				game.Workspace.negZSmaller.Color = color
				remote:FireClient(player, "[SYSTEM] Walls set to " .. valueString)
			else
				remote:FireClient(player, "[SYSTEM] Invalid color. Options: Red, Green, Blue, Pink, Orange.")
			end

			-- Bot quantity
		elseif string.sub(cmd, 1, 18) == "/set bot quantity " then
			local valueString = string.sub(command, 19) -- everything after "/set bot quantity "
			local newQuantity = tonumber(valueString)
			if newQuantity and newQuantity > 0 and newQuantity <= 20 then
				local botScript = game.ServerScriptService:FindFirstChild("botScript")
				if botScript then
					local event = botScript:FindFirstChild("BotQuantityChanged")
					if event then
						event:Fire(newQuantity)
					end
				end
				respawnPlayer()
				remote:FireClient(player, "[SYSTEM] Bot quantity set to " .. newQuantity)
			else
				remote:FireClient(player, "[SYSTEM] Invalid bot quantity. Must be 1-20.")
			end
		else
			remote:FireClient(player, "[SYSTEM] Invalid /set command.")
		end
	
	elseif cmd == "/acc" then
		local totalShots = _G.TotalShots or 0
		local totalHits = _G.TotalHits or 0
		local accuracy = 0
		if totalShots > 0 then
			accuracy = math.floor((totalHits / totalShots) * 100)
		end
		local message = string.format("[SYSTEM] Total Shots: %d, Hits: %d, Accuracy: %d%%", totalShots, totalHits, accuracy)
		remote:FireClient(player, message)

		-- /reset acc
	elseif cmd == "/resetacc" then
		_G.TotalShots = 0
		_G.TotalHits = 0
		remote:FireClient(player, "[SYSTEM] Your accuracy has been reset.")

		-- 🔹 Update the GUI immediately to show "0%"
		updateAccuracyEvent:FireClient(player, 0)
	else
		remote:FireClient(player, "[SYSTEM] Unknown command. Use /help.")
	end
end)
