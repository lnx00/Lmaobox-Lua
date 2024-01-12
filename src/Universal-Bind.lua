--[[
	Universal bind script for Lmaobox
	Author: LNX (github.com/lnx00)
]]

local options = {
	-- Bind key
	key = E_ButtonCode.KEY_J,

	-- Target option
	target = "anti aim",

	-- Update function
	update = function(current)
		return current == 1 and 0 or 1
	end
}

local last_tick = 0
callbacks.Register("Draw", function()
	local state, tick = input.IsButtonPressed(options.key)
	if state and tick ~= last_tick then
		local current = gui.GetValue(options.target)
		gui.SetValue(options.target, options.update(current))
		last_tick = tick
	end
end)
