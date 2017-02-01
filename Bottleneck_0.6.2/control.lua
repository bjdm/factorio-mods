--Generate event ID's for custom events
local events ={}
events.bottleneck_toggle = script.generate_event_name()
events.rebuild_overlays = script.generate_event_name()

--Message Everyone
local function msg(message)
  game.print(message)
end

--[[ Remove the light]]
local function remove_signal(event)
  local entity = event.entity
  local index = entity.unit_number
  local overlays = global.overlays
  local data = overlays[index]
  if not data then return end
  local signal = data.signal
  if signal and signal.valid then
    signal.destroy()
  end
  overlays[index] = nil
  --table.remove(overlays, index)
end

--[[ Calculates bottom center of the entity to place bottleneck there ]]
local function get_signal_position_from(entity, shift_x, shift_y)
  local left_top = entity.prototype.selection_box.left_top
  local right_bottom = entity.prototype.selection_box.right_bottom
  --Calculating center of the selection box
  shift_x = shift_x or (right_bottom.x + left_top.x) / 2
  shift_y = shift_y or right_bottom.y
  --Calculating bottom center of the selection box
  return {x = entity.position.x + shift_x, y = entity.position.y + shift_y}
end

--[[ code modified from AutoDeconstruct mod by mindmix https://mods.factorio.com/mods/mindmix ]]
local function check_drill_depleted(data)
  local drill = data.entity
  local position = drill.position
  local range = drill.prototype.mining_drill_radius
  local top_left = {x = position.x - range, y = position.y - range}
  local bottom_right = {x = position.x + range, y = position.y + range}
  local resources = drill.surface.find_entities_filtered{area={top_left, bottom_right}, type='resource'}
  for _, resource in pairs(resources) do
    if resource.prototype.resource_category == 'basic-solid' and resource.amount > 0 then
      return false
    end
  end
  data.drill_depleted = true
  return true
end

local function has_fluid_output_available(entity)
  local fluidbox = entity.fluidbox
  if (not fluidbox) or (#fluidbox == 0) then return false end
  local recipe = entity.recipe
  if not recipe then return false end
  for _, product in pairs(recipe.products) do
    if product.type == 'fluid' then
      local name = product.name
      for i = 1, #fluidbox do
        local fluid = fluidbox[i]
        if fluid and (fluid.type == name) and (fluid.amount > 0) then
          return true
        end
      end
    end
  end
  return false
end

local light = {
  off = defines.direction.north,
  green = defines.direction.east,
  red = defines.direction.south,
  yellow = defines.direction.west,
}

--Faster to just change the color than it is to check it first.
local function change_signal(signal, signal_color)
  signal_color = light[signal_color] or "red"
  signal.direction = signal_color
end

local update = {}
function update.drill(data)
  if data.drill_depleted then return end
  local entity = data.entity
  local progress = data.progress
  if (entity.energy == 0) or (entity.mining_target == nil and check_drill_depleted(data)) then
    change_signal(data.signal, "red")
  elseif (entity.mining_progress == progress) then
    change_signal(data.signal, "yellow")
  else
    change_signal(data.signal, "green")
    data.progress = entity.mining_progress
  end
end

function update.machine(data)
  local entity = data.entity
  if entity.energy == 0 then
    change_signal(data.signal, "red")
  elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
    change_signal(data.signal, "green")
  elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
    change_signal(data.signal, "yellow")
  else
    change_signal(data.signal, "red")
  end
end

function update.furnace(data)
  local entity = data.entity
  if entity.energy == 0 then
    change_signal(data.signal, "red")
  elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
    change_signal(data.signal, "green")
  elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
    change_signal(data.signal, "yellow")
  else
    change_signal(data.signal, "red")
  end
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
local function built(event)
  local entity = event.created_entity
  --local surface = entity.surface
  local data

  -- If the entity that's been built is an assembly machine or a furnace...
  if entity.type == "assembling-machine" then
    data = { update = "machine" }
  elseif entity.type == "furnace" then
    data = { update = "furnace" }
  elseif entity.type == "mining-drill" then
    data = { update = "drill" }
  end
  if data then
    data.entity = entity
    data.position = get_signal_position_from(entity)
    local name = (global.high_contrast and "bottleneck-stoplight-high") or "bottleneck-stoplight"
    local signal = entity.surface.create_entity{name=name, position=data.position, direction=light.off, force=entity.force}
    signal.active = false
    signal.operable = false
    signal.destructible = false
    data.signal=signal

    if global.show_bottlenecks == 1 then
      update[data.update](data)
    end
    global.overlays[entity.unit_number] = data
    -- if we are in the process of removing lights, we need to restart
    -- that, since inserting into the overlays table may mess up the
    -- iteration order.
    if global.show_bottlenecks == -1 then
      global.update_index = nil
    end
  end
end

local function rebuild_overlays()
  --[[Setup the global overlays table This table contains the machine entity, the signal entity and the freeze variable]]--
  global.overlays = {}
  global.update_index = nil
  msg("Bottleneck: Rebuilding data from scratch")

  --[[Find all assembling machines on the map. Check each surface]]--
  for _, surface in pairs(game.surfaces) do
    --find-entities-filtered with no area argument scans for all entities in loaded chunks and should
    --be more effiecent then scanning through all chunks like in previous version

    --[[destroy any existing bottleneck-signals]]--
    for _, stoplight in pairs(surface.find_entities_filtered{type="storage-tank"}) do
      if stoplight.name == "bottleneck-stoplight" or stoplight.name == "bottleneck-stoplight-high" then
        stoplight.destroy()
      end
    end

    --[[Find all assembling machines within the bounds, and pretend that they were just built]]--
    for _, am in pairs(surface.find_entities_filtered{type="assembling-machine"}) do
      built({created_entity = am})
    end

    --[[Find all furnaces within the bounds, and pretend that they were just built]]--
    for _, am in pairs(surface.find_entities_filtered{type="furnace"}) do
      built({created_entity = am})
    end

    --[[Find all mining-drills within the bounds, and pretend that they were just built]]--
    for _, am in pairs(surface.find_entities_filtered{type="mining-drill"}) do
      built({created_entity = am})
    end
    game.raise_event(events.rebuild_overlays, {})
  end
end

local next = next --very slight perfomance improvment
local function on_tick()
  if global.show_bottlenecks == 1 then
    local signals_per_tick = global.signals_per_tick or 40
    local overlays = global.overlays
    local index, data = global.update_index
    --check for existing data at index
    if index and overlays[index] then
      data = overlays[index]
    else
      index, data = next(overlays, index)
    end
    local numiter = 0
    while index and (numiter < signals_per_tick) do
      local entity = data.entity
      local signal = data.signal

      -- if entity is valid, update it, otherwise remove the signal and the associated data
      if entity.valid and signal.valid then
        update[data.update](data)
      elseif entity.valid and not signal.valid then
        -- Rebuild the icon something broke it!
        local name = (global.high_contrast and "bottleneck-stoplight-high") or "bottleneck-stoplight"
        signal = entity.surface.create_entity{name=name, position=data.position, direction=light.off, force=entity.force}
        data.signal = signal
      elseif not entity.valid and signal.valid then
        signal.destroy()
        overlays[index] = nil
      end
      numiter = numiter + 1

      index, data = next(overlays, index)
    end
    global.update_index = index
  elseif global.show_bottlenecks < 0 then
    local show, signals_per_tick = global.show_bottlenecks, global.signals_per_tick or 40
    local overlays = global.overlays
    local index, data = global.update_index
    --Check for existing index and associated data
    if index and overlays[index] then
      data = overlays[index]
    else
      index, data = next(overlays, index)
    end
    local numiter = 0
    while index and (numiter < signals_per_tick) do
      local signal = data.signal
      if signal and signal.valid then
        if show == -1 then
          change_signal(signal, "off")
        elseif show == -2 then
          local name = (global.high_contrast and "bottleneck-stoplight-high") or "bottleneck-stoplight"
          local signal2 = signal.surface.create_entity{name=name, position=data.position, direction=signal.direction, force=signal.force}
          signal.destroy()
          data.signal = signal2
        end
      else
        overlays[index] = nil
      end
      numiter = numiter + 1
      index, data = next(overlays, index)
    end
    global.update_index = index
    -- if we have reached the end of the list (i.e., have removed all lights),
    -- pause updating until enabled by hotkey next
    if not index then
      global.show_bottlenecks = (show == -2 and 1) or (show == -1 and 0)
    end
  end
end

-------------------------------------------------------------------------------
--[[HOTKEYS]]--
local function on_hotkey(event)
  local player = game.players[event.player_index]
  if not player.admin then
    player.print('Bottleneck: You do not have privileges to toggle bottleneck')
    return
  end
  global.update_index = nil
  if global.show_bottlenecks == 1 then
    game.raise_event(events.bottleneck_toggle, {tick=event.tick, player_index=event.player_index, enable=false})
    global.show_bottlenecks = -1
  else
    game.raise_event(events.bottleneck_toggle, {tick=event.tick, player_index=event.player_index, enable=true})
    global.show_bottlenecks = 1
  end
end

local function toggle_highcontrast(event) --luacheck: ignore
  local player = game.players[event.player_index]
  if not player.admin then
    player.print('Bottleneck: You do not have privileges to toggle contrast')
    return
  end
  global.high_contrast = not global.high_contrast
  msg('Bottleneck: Using '..(global.high_contrast and 'high' or 'normal')..' contrast mode')
  global.show_bottlenecks = -2
  global.update_index = nil
  --Toggling high contrast will turn bottlenecks back on if they are off
  --This is better then saving and comparing "old_show_bottlenecks"
end

-------------------------------------------------------------------------------
--[[Init Events]]
local function init()
  --seperate out init and config changed
  global = {}
  global.show_bottlenecks = 1
  global.signals_per_tick = 40
  global.high_contrast = false
  rebuild_overlays()
end

local function on_configuration_changed(event)
  --Any MOD has been changed/added/removed, including base game updates.
  if event.mod_changes ~= nil then --should never be nil
    msg("Bottleneck: Game or mod version changes detected")

    --This mod has changed
    local changes = event.mod_changes["Bottleneck"]
    if changes ~= nil then -- THIS Mod has changed
      msg("Bottleneck: Updated from ".. tostring(changes.old_version) .. " to " .. tostring(changes.new_version))
    end
  end
  global.show_bottlenecks = global.showbottlenecks or 1
  global.signals_per_tick = global.lights_per_tick or 40
  global.lights_per_tick = nil
  global.showbottlenecks = nil
  global.output_idle_signal = nil
  global.high_contrast = global.high_contrast or false
  rebuild_overlays()
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(on_configuration_changed)
local e=defines.events
local remove_events = {e.on_preplayer_mined_item, e.on_robot_pre_mined, e.on_entity_died}
local add_events = {e.on_built_entity, e.on_robot_built_entity}

script.on_event(remove_events, remove_signal)
script.on_event(add_events, built)
script.on_event(defines.events.on_tick, on_tick)
script.on_event("bottleneck-hotkey", on_hotkey)
script.on_event("bottleneck-highcontrast", toggle_highcontrast)

--[[ Setup remote interface]]--
local interface = {}
--get_ids, return the table of event ids
interface.get_ids = function() return events end
--is_enabled - return show_bottlenecks
interface.enabled = function() return global.show_bottlenecks == 1 end
--print the global to a file
interface.print_global = function () game.write_file("logs/Bottleneck/global.lua",serpent.block(global, {comment=false}),false) end
--rebuild all icons
interface.rebuild = rebuild_overlays
--change signals per tick calculation
interface.signals_per_tick = function(count) global.signals_per_tick = tonumber(count) or 40 return global.signals_per_tick end
--allow other mods to interact with bottlneck
interface.change_signal = change_signal --function(data, color) change_signal(signal, color) end
--get a place position for a signal
interface.get_position_for_signal = get_signal_position_from
--get the signal data associated with an entity
interface.get_signal_data = function(unit_number) return global.overlays[unit_number] end

remote.add_interface("Bottleneck", interface)
