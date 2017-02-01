require("config")
require("util")

function check_queue(force)
	for i, tech in ipairs(global.researchQ[force.name]) do
		if force.technologies[tech] then	--checks if the technology still exsists 
			for _, pre in pairs(force.technologies[tech].prerequisites) do
				if not pre.researched then		--checks if the prerequisite is already researched
					local isInQueue = false
					for j = 1, i do	-- checks if the prerequisite is in the queue before the technology
						if pre.name == global.researchQ[force.name][j] then 	
							isInQueue = true 
							break
						end
					end
					if not isInQueue then remove_research(force, tech) end	
				end
			end
		else
			remove_research(force, tech)	
		end
	end
end

function promt_overwrite_research(player, research_name)
	if player.force.current_research ~= research_name then
		if player.gui.center.Q then player.gui.center.Q.destroy() end
		local warning = player.gui.center.add{type = "frame", name = "warning", style = "frame_style"}
		warning.add{type = "frame", name = "warning-icon", style = "rq-warning-icon"}
		local text = warning.add{type = "flow", name = "rq-warning-text", style = "flow_style", direction = "vertical"}
		local caption = "Overwrite current research? (".. math.ceil(player.force.research_progress*1000)/10 .."% done)"
		text.add{type = "label", name = "rq-warning-text-content", caption = caption, style = "description_label_style"}
		local buttons = text.add{type = "flow", name = "rq-warning-buttons", style = "flow_style", direction = "horizontal"}
		buttons.add{type = "button", name = "rq-overwrite-yes", style = "button_style", caption = "Yes"}
		buttons.add{type = "button", name = "rq-overwrite-no", style = "button_style", caption = "No"}
	end
end

function est_time(force)
	local est = {}
	local speed = 0
	for i, lab in ipairs(global.labs[force.name]) do
		if not lab.valid then table.remove(global.labs[force.name],i) 
		else
			local speed_modifier = 0
			local productivity_modifier = 0
			local consumption_modifier = 0
			for item, count in pairs(lab.get_module_inventory().get_contents()) do
				module_effect = game.item_prototypes[item].module_effects
				if module_effect.speed then speed_modifier = speed_modifier + module_effect.speed.bonus * count end
				if module_effect.productivity then productivity_modifier = productivity_modifier + module_effect.productivity.bonus * count end
				if module_effect.consumption then consumption_modifier = consumption_modifier + module_effect.consumption.bonus * count end
			end
			if lab.name == "lab" then --if base lab then use energy values
				speed = speed + ( (1 + speed_modifier) * (1 + productivity_modifier) * math.min(lab.energy/(math.max(1 + consumption_modifier,0.2) * 60*160/9),1) )
			else	-- ignore enery values for modded labs, only check if it has energy or not
				speed = speed + ( (1 + speed_modifier) * (1 + productivity_modifier) * math.min(lab.energy,1) )
			end
		end
	end
	speed = speed * (1 + force.laboratory_speed_modifier)
	for i, tech in ipairs(global.researchQ[force.name]) do
		local t = (1 - force.research_progress) * force.current_research.research_unit_count * force.current_research.research_unit_energy / speed
		if force.current_research.name == tech then 
			est[i] = t		
		elseif i == 1 then
			est[i] = t + force.technologies[tech].research_unit_count * force.technologies[tech].research_unit_energy / speed
		elseif i > 2 and global.researchQ[force.name][i-1] == force.current_research.name then
			est[i] = est[i-2] + force.technologies[tech].research_unit_count * force.technologies[tech].research_unit_energy / speed
		else
			est[i] = est[i-1] + force.technologies[tech].research_unit_count * force.technologies[tech].research_unit_energy / speed
		end
	end
	return est
end

function add_research(force, research_name)
	for _, pre in pairs(force.technologies[research_name].prerequisites) do --checks if the prerequisites are allrady researched, if not call this function for those techs first.
		if not pre.researched then add_research(force, pre.name) end
	end
	local isInList = false		--check if the technology to add is already in the queue
	for _, tech in ipairs(global.researchQ[force.name]) do
		if tech == research_name then isInList = true end
	end
	if not isInList and not force.technologies[research_name].researched then
		table.insert(global.researchQ[force.name], research_name)
	end
end

function remove_research(force, research_name)	
	local research_index = nil
	for i, tech in ipairs(global.researchQ[force.name]) do	--find the table index corresponding to the technology
		if tech == research_name then 
			research_index = i 
			break
		end
	end
	table.remove(global.researchQ[force.name], research_index)
	for index, _ in pairs(force.players) do
		if global.offset_queue[index] > 0 then global.offset_queue[index] = global.offset_queue[index] -1 end
	end
	check_queue(force)
	if force.current_research == research_name and global.researchQ[force.name][1] ~= nil then force.current_research = global.researchQ[force.name][1] end --starts the new researchers for the new top item in the queue
end

function up(player, research_name)
	local force = player.force
	local research_index = nil
	for i, tech in ipairs(global.researchQ[force.name]) do	--find the table index corresponding to the technology
		if tech == research_name then 
			research_index = i 
			break
		end
	end
	if research_index > 1 then --not on top of the queue
		local canMoveUp = true
		for _, pre in pairs(force.technologies[research_name].prerequisites) do
			if pre.name == global.researchQ[force.name][research_index-1] then canMoveUp = false end --checks if the item is a prerequisite to the item above it
		end
		if canMoveUp then
			table.remove(global.researchQ[force.name], research_index)
			table.insert(global.researchQ[force.name], research_index-1, research_name)
		end
	else
		if force.current_research.name ~= research_name then promt_overwrite_research(player, research_name) end	--starts the new top research
	end
end

function down(force, research_name)
	local research_index = nil
	for i, tech in ipairs(global.researchQ[force.name]) do	--find the table index corresponding to the technology
		if tech == research_name then 
			research_index = i 
			break
		end
	end
	if research_index < #global.researchQ[force.name] then --thus not at the end of the queue
		local canMoveDown = true
		for _, pre in pairs(force.technologies[global.researchQ[force.name][research_index+1]].prerequisites) do --checks if the item above it is it's prerequisites
			if pre.name == research_name then canMoveDown = false end
		end
		if canMoveDown then
			table.remove(global.researchQ[force.name], research_index)
			table.insert(global.researchQ[force.name], research_index+1, research_name)
		end
	end
end

function updateQ(force)
	local time_estimation = est_time(force)
	for index, player in pairs(force.players) do
		if player.gui.center.Q then
			if not player.gui.center.Q.current_q then player.gui.center.Q.add{type = "frame", name = "current_q", caption = "Currrent queue", style = "technology_preview_frame_style"} end
			if player.gui.center.Q.current_q.list then player.gui.center.Q.current_q.list.destroy() end
			
			local list = player.gui.center.Q.current_q.add{type = "flow", name = "list", style = "rq-flow", direction = "vertical"}
			
			if not global.researchQ[force.name][1] then
				list.add{type = "label", name = "empty", caption = "No research queued"} --if the queue is empty
			else
				for i, tech in ipairs(global.researchQ[force.name]) do
					local technology = force.technologies[tech]
					if global.offset_queue[index] < i and i <= (rq.q_per_page+global.offset_queue[index]) then
						local frame = list.add{type = "frame", name = "rq"..tech.."frame", style = "rq-frame"} --create a frame for each item in the queue
						
						frame.add{type = "frame", name = "rq"..tech.."icon", style = "rq-tech"..tech} --adds a big icon in the frame
						
						local description = frame.add{type = "flow", name = "rq"..tech.."description", style = "rq-flow", direction = "vertical"} -- adds a description frame in the frame
						description.style.minimal_width = 185
						description.add{type = "label", name = "rq"..tech.."name", caption = technology.localised_name, style = "description_label_style"}	-- places the name of the technology
						local ingredients = description.add{type = "table", name = "rq"..tech.."ingredients", style = "table_style", colspan = 8}	-- add the ingredients and time
						ingredients.add{type = "frame", name = "rqtime", caption = (technology.research_unit_energy/60), style = "rq-clock"}
						for _,item in pairs(technology.research_unit_ingredients) do
							ingredients.add{type = "frame", name = "rq"..item.name, caption = item.amount, style = "rq-tool"..item.name.."frame"}
						end
						ingredients.add{type = "label", name = "rqresearch_unit_count", caption = "X "..technology.research_unit_count, style = "label_style"}
						local caption = nil
						if time_estimation[i] ~= math.huge then
							caption = "Estimated time: "..util.formattime(time_estimation[i])
						else
							caption = "Estimated time: infinity"
						end
						description.add{type = "label", name = "rq"..tech.."time", caption = caption, style = "label_style"}
						
						
						local buttons = frame.add{type = "table", name = "rq"..tech.."buttons", style = "slot_table_style", colspan = 1}	--adds the up/cancel/down buttons
						buttons.add{type = "button", name = "rq".."upbutton"..tech, style = "rq-up-button"}
						buttons.add{type = "button", name = "rq".."cancelbutton"..tech, style = "rq-cancel-button"}
						buttons.add{type = "button", name = "rq".."downbutton"..tech, style = "rq-down-button"}
						
					elseif i == global.offset_queue[index] then	--adds scrollbuttons to the top and bottom of the list
						list.add{type = "button", name = "rqscrollqueueup", style = "rq-up-button"}
					elseif i > rq.q_per_page+global.offset_queue[index] then
						list.add{type = "button", name = "rqscrollqueuedown", style = "rq-down-button"}
						break
					end
				end
			end
		end
	end
end