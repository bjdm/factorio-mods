require("config")

function define_colspan()
	local n_tech = 0
	for _, tech in pairs(game.forces.player.technologies) do 
		if not tech.upgrade then n_tech = n_tech +1 end
	end
	local set_colspan = 5
	while n_tech / set_colspan > rq.research_table_height do
		if rq.research_table_width > set_colspan then
			set_colspan = set_colspan +1
		else
			break
		end
	end	
	return set_colspan
end

function options(player)
	local caption = player.gui.center.Q.add2q.add{type = "label", name = "options_caption", caption = "Options"}
	caption.style.minimal_width = set_colspan * 68
	local options = player.gui.center.Q.add2q.add{type = "table", name = "options", style = "rq-table2", colspan = set_colspan}
	
	local style = nil
	if global.showExtended[player.index] then style = "rq-compact-button" else style = "rq-extend-button" end
	options.add{type = "button", name = "rqextend-button", style = style}
	
	local check = options.add{type = "checkbox", name = "rqtext", style = "rq-text-checkbox", state = global.showIcon[player.index]}
	
	options.add{type = "checkbox", name = "rqscience", style = "rq-scienceDone-checkbox", state = not global.showResearched[player.index]}
	
	for name, science in pairs(global.science) do
		if global.showExtended[player.index] or not (global.bobsmodules[name] or global.bobsaliens[name]) then
			options.add{type = "checkbox", name = "rq-science"..name, style = "rq-tool"..name, state = not science[player.index]}
		elseif global.bobsmodules[name] and not options["rq-bobsmodules"] then
			options.add{type = "checkbox", name = "rq-bobsmodules", style = "rq-bobsmodules", state = not global.showBobsmodules[player.index]}
		elseif global.bobsaliens[name] and not options["rq-bobsaliens"] then
			options.add{type = "checkbox", name = "rq-bobsaliens", style = "rq-bobsalien", state = not global.showBobsaliens[player.index]}
		end
	end
end

function technologies(player)
	local caption = player.gui.center.Q.add2q.add{type = "label", name = "add2q_caption", caption = "List of technologies"} 
	caption.style.minimal_width = set_colspan * 68
	if global.showIcon[player.index] then colSpan = set_colspan else colSpan = math.floor(set_colspan / 3) end --create a smaller table if text is displayed.
	local rq_table = player.gui.center.Q.add2q.add{type = "table", name = "add2q_table", style = "rq-table1", colspan = colSpan}
	local count = 0
	for name, tech in pairs(player.force.technologies) do
		if tech.enabled and (not tech.researched or global.showResearched[player.index]) then --checks if the research is enabled and either not completed or if it should show completed.
			if (global.showExtended[player.index] or not tech.upgrade or not any(tech.prerequisites, "upgrade") or any(tech.prerequisites, "researched") or matches(tech.prerequisites, "name", global.researchQ[player.force.name])) then
			-- ^checks if the research is an upgrade technology and whether or not to show it.
				local t = {} -- create a table of research ingredients that the research may not have.
				for item, science in pairs(global.science) do
					if not science[player.index] then table.insert(t, item) end
				end
				
				if not matches(tech.research_unit_ingredients, "name", t) then --checks if any on the research ingredients match the banned list
					local background1, background2 = nil, nil --select the right (color) of background depending on the status of the technology (done/available or in queue)
					if tech.researched then 
						background1 = "rq-done-frame"
						background2 = "rq-done-button"
					else 
						background1 = "rq-available-frame" 
						background2 = "rq-available-button"
					end
					for _, q in ipairs(global.researchQ[player.force.name]) do
						if name == q then 
							background1 = "rq-inq-frame" 
							background2 = "rq-inq-button"
						end
					end
					count = count +1
					if global.showIcon[player.index] then
						local row = math.ceil(count / set_colspan)
						if global.offset_tech[player.index] < row and row <= (rq.research_table_height + global.offset_tech[player.index]) then
							local frame1 = rq_table.add{type = "frame", name = "rq"..name.."background_frame", style = background1} --background frame
							local frame2 = frame1.add{type = "frame", name = name.."frame", style = "rq-tech"..name}	--technology icon
							local caption = string.match(name, "%-%d+")	--finds if the technology has a number (eg, autmation-2) and creates a label with that number
							if caption then caption = string.gsub(caption, "%-", " ") end
							local frame3 = frame2.add{type = "label", name = name.."label", style = "rq-label", caption = caption}
							local button = frame3.add{type = "button", name = "rq-add"..name, style = "rq-button"}	--adds the final button that can be clicked on top.
							
						elseif row == global.offset_tech[player.index] and not player.gui.center.Q.add2q.rqscrolltechup then 
							player.gui.center.Q.add2q.add{type = "button", name = "rqscrolltechup", style = "rq-up-button"}
						elseif row > rq.research_table_height + global.offset_tech[player.index] and not player.gui.center.Q.add2q.rqscrolltechdown then
							player.gui.center.Q.add2q.add{type = "button", name = "rqscrolltechdown", style = "rq-down-button"}
							break
						end
					else
						local row = math.ceil(count / math.floor(set_colspan / 3))
						if global.offset_tech[player.index] < row and row <= ((rq.research_table_height*2) + global.offset_tech[player.index]) then
							local frame = rq_table.add{type = "frame", name = "rqtextframe"..name, style = "outer_frame_style"}
							frame.add{type = "frame", name = name.."frame", style = "rq-tech"..name.."small"}
							frame.add{type = "button", name = "rq-add"..name, caption = tech.localised_name, style = background2}	
						elseif row == global.offset_tech[player.index] and not player.gui.center.Q.add2q.rqscrolltechup then 
							player.gui.center.Q.add2q.add{type = "button", name = "rqscrolltechup", style = "rq-up-button"}
						elseif row > (rq.research_table_height*2) + global.offset_tech[player.index] and not player.gui.center.Q.add2q.rqscrolltechdown then
							player.gui.center.Q.add2q.add{type = "button", name = "rqscrolltechdown", style = "rq-down-button"}
							break
						end			
					end
				end
			end
		end
	end
end

function drawGrid(force)
	if not set_colspan then set_colspan = define_colspan() end
	for _, player in pairs(force.players) do
		if player.gui.center.Q then
			if player.gui.center.Q.add2q then player.gui.center.Q.add2q.destroy() end
			player.gui.center.Q.add{type = "frame", name = "add2q", caption = "Add to queue", style = "technology_preview_frame_style", direction = "vertical"}	
			options(player)
			if not pcall(technologies, player) 
				then  player.print("Failed to load tech...")
			end
		end
	end
end
