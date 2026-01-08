--Module Script--

--CursorManager
local CursorManager = {}
CursorManager.CurrentCursor = "rbxassetid://5332090416"
CursorManager.ChangedConnection = {}

function CursorManager:SetCursor(id)
	self.CurrentCursor = id
	-- fire all listeners
	for _, func in ipairs(self.ChangedConnection) do
		func()
	end
end

function CursorManager:GetCursor()
	return self.CurrentCursor
end

return CursorManager
