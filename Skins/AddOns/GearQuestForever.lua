local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('GearQuestForever', function()
	-- GearQuestForever/Log.lua:12384-12410: GearQuestLogFrame, reutilizado o creado
	-- por el log; :16057,17056: Show/Toggle abren la misma ventana principal.
	K:WatchAddonFrame('GearQuestForever', 'GearQuestLogFrame')
end)
