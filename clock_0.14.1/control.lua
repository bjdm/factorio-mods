if not bobmods then bobmods = {} end
if not bobmods.clock then bobmods.clock = {} end
bobmods.clock.min = 0
bobmods.clock.hour = 0

script.on_event(defines.events.on_tick, function(event)
	bobmods.clock.min_previous = bobmods.clock.min

	if remote.interfaces.MoWeather then
		bobmods.clock.time = remote.call("MoWeather","getdaytime") *24 +12
	else
		bobmods.clock.time = game.surfaces[1].daytime *24 +12
	end
	if bobmods.clock.time >= 24 then
		bobmods.clock.time = bobmods.clock.time -24
	end

	bobmods.clock.hour = math.floor(bobmods.clock.time)
	bobmods.clock.min = math.floor((bobmods.clock.time % 1) * 60)

	if bobmods.clock.min_previous ~= bobmods.clock.min then
		for i, player in pairs(game.connected_players) do
			if player.gui.top.clockGUI == nil then player.gui.top.add{type="button", name="clockGUI"} end
			player.gui.top.clockGUI.caption = string.format("%02d:%02d", bobmods.clock.hour, bobmods.clock.min)
		end
	end
end)

