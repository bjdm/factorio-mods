function init()
	if global.researchQ == nil then global.researchQ = {} end
	if global.labs == nil then global.labs = {} end
	for name, force in pairs(game.forces) do
		if global.researchQ[name] == nil then 
			global.researchQ[name] = {}
			if force.current_research then table.insert(global.researchQ[name],force.current_research.name) end
		end
		global.labs[name] = find_all_entities({type = "lab", force = force})
	end
	if global.showIcon == nil then global.showIcon = {} end
	if global.showResearched == nil then global.showResearched = {} end
	if global.offset_queue == nil then global.offset_queue = {} end
	if global.offset_tech == nil then global.offset_tech = {} end
	if global.showExtended == nil then global.showExtended = {} end
	if global.science == nil then global.science = {} end
	for name, item in pairs(game.item_prototypes) do
		if item.type == "tool" then
			global.science[name] = {}
		end
	end
	colspan = nil
	global.bobsmodules = {
		["module-case"] = true, 
		["module-circuit-board"] = true, 
		["speed-processor"] = true, 
		["effectivity-processor"] = true, 
		["productivity-processor"] = true, 
		["pollution-clean-processor"] = true, 
		["pollution-create-processor"] = true
		}
	if global.showBobsmodules == nil then global.showBobsmodules = {} end
	global.bobsaliens = {
		["alien-science-pack-blue"] = true, 
		["alien-science-pack-orange"] = true, 
		["alien-science-pack-purple"] = true, 
		["alien-science-pack-yellow"] = true, 
		["alien-science-pack-green"] = true, 
		["alien-science-pack-red"] = true
		}
	if global.showBobsaliens == nil then global.showBobsaliens = {} end
	global.pop_when_empty_queue = true
end

function player_init(player_index)
	if global.researchQ == nil then init() end
	if not game.players[player_index].gui.top.research_Q then game.players[player_index].gui.top.add{type = "button", name = "research_Q", caption = "RQ", style = "rq-top-button"} end
	global.showIcon[player_index] = true
	global.showResearched[player_index] = false
	global.offset_queue[player_index] = 0
	global.offset_tech[player_index] = 0
	global.showExtended[player_index] = false
	for name, science in pairs(global.science) do
		if game.players[player_index].force.recipes[name] ~= nil then
		science[player_index] = game.players[player_index].force.recipes[name].enabled
		else science[player_index] = false
		end
	end
	global.showBobsmodules[player_index] = game.players[player_index].force.technologies["modules"].researched
	if game.players[player_index].force.technologies["alien-research"] then 
		global.showBobsaliens[player_index] = game.players[player_index].force.technologies["alien-research"].researched
	else
		global.showBobsaliens[player_index] = false
	end
end

remote.add_interface("RQ", {popup = function(bool) 
	global.pop_when_empty_queue = bool 
	for k,v in pairs(game.players) do
		if bool then
			v.print("Popup is now enabled")
		else
			v.print("Popup is now disabled")
		end
	end
end})

function create_number_table(array)
	local new_array = {}
	for _,v in pairs(array) do
		table.insert(new_array,v)
	end
	return new_array
end

function find_all_entities(input)
	-- input = {name = string, type = string, force = string or force, surface = string or {table of surface(s)}
	local array = {}
	
	if type(input.surface) == "string" then input.surface = {game.surfaces[input.surface]} end
	local surfaces = input.surface or game.surfaces
	
	for _,surface in pairs(surfaces) do
		for chunk in surface.get_chunks() do
			local entities = surface.find_entities_filtered{
				area = {left_top = {chunk.x*32, chunk.y*32}, right_bottom = {(chunk.x+1)*32, (chunk.y+1)*32}}, 
				name = input.name, 
				type = input.type, 
				force = input.force}
			for _,entity in ipairs(entities) do
				array["x"..entity.position.x.."y"..entity.position.y] = entity
			end
		end
	end
	return create_number_table(array)
end

