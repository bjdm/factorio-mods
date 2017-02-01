


 -- Start OnLoad/OnInit/OnConfig events
script.on_configuration_changed( function(data)
  if data.mod_changes ~= nil and data.mod_changes["GDIW"] ~= nil and data.mod_changes["GDIW"].old_version == nil then
   -- Mod added 
    for _,force in pairs(game.forces) do
      force.reset_recipes()
      force.reset_technologies()

      local techs=force.technologies
      local recipes=force.recipes

      if techs["oil-processing"].researched then
        recipes["basic-oil-processing-GDIW-3"].enabled=true
      end
      if techs["advanced-oil-processing"].researched then
        recipes["advanced-oil-processing-GDIW"].enabled=true
        recipes["advanced-oil-processing-GDIW-2"].enabled=true
        recipes["advanced-oil-processing-GDIW-3"].enabled=true
        recipes["heavy-oil-cracking-GDIW"].enabled=true
        recipes["light-oil-cracking-GDIW"].enabled=true
        if recipes["bob-oil-processing-GDIW"] then
          recipes["bob-oil-processing-GDIW"].enabled=true
        end
      end
      if techs["sulfur-processing"].researched then
        recipes["sulfur-GDIW"].enabled=true
      end
      if techs["flame-thrower"].researched then
        recipes["flame-thrower-ammo-GDIW"].enabled=true
      end

    end
    
  end 

  if data.mod_changes ~= nil and data.mod_changes["GDIW"] ~= nil and data.mod_changes["GDIW"].old_version ~= nil then
   -- Mod updated or removed
    for _,force in pairs(game.forces) do
      force.reset_recipes()
      force.reset_technologies()

      local techs=force.technologies
      local recipes=force.recipes

      if techs["oil-processing"].researched then
        recipes["basic-oil-processing-GDIW-3"].enabled=true
      end
      if techs["advanced-oil-processing"].researched then
        recipes["advanced-oil-processing-GDIW"].enabled=true
        recipes["advanced-oil-processing-GDIW-2"].enabled=true
        recipes["advanced-oil-processing-GDIW-3"].enabled=true
        recipes["heavy-oil-cracking-GDIW"].enabled=true
        recipes["light-oil-cracking-GDIW"].enabled=true
        if recipes["bob-oil-processing-GDIW"] then
          recipes["bob-oil-processing-GDIW"].enabled=true
        end
      end
      if techs["sulfur-processing"].researched then
        recipes["sulfur-GDIW"].enabled=true
      end
      if techs["flame-thrower"].researched then
        recipes["flame-thrower-ammo-GDIW"].enabled=true
      end      
      
    end

  end

end)


script.on_init(function()
  -- Nothing to do now
end)   
  
script.on_load(function()
  --Nothing to Do Now  
end)
-- End OnLoad/OnInit/OnConfig events

