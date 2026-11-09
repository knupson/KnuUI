local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('GearQuestForever', function()
	-- GearQuestForever/Log.lua:12384-12410: GearQuestLogFrame, reutilizado o creado
	-- por el log; :16057,17056: Show/Toggle abren la misma ventana principal.
	-- Sólo el marco exterior: adentro GearQuest usa pergamino con textos oscuros, algunos dentro de
	-- botones (Log.lua:10771-10780, labelHit); el fondo de HandleButton los dejaba negros sobre negro.
	K:WatchAddonFrame('GearQuestForever', 'GearQuestLogFrame', nil, true)
end)
