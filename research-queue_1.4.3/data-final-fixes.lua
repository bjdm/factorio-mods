require("prototypes.gui")

if not rq then rq = {} end
if not rq.labs then rq.labs = {} end
for k,v in pairs(data.raw.lab) do
	rq.labs[v.name] = {
		name = v.name,
		energy_usage = v.energy_usage,
		researching_speed = v.researching_speed}
end

for i,v in ipairs(rq.big_icons) do log("[Research queue] "..v..": No need to register big icons anymore!") end