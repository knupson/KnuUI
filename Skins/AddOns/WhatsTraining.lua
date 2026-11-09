local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('WhatsTraining', function()
	-- WhatsTraining/Forever/SpellBook.lua:593,596,636: wt.CreateFrame crea ambos marcos.
	-- Se observa la creación real; wt es privado (WhatsTraining.lua:1).
	K:WatchAddonFrame('WhatsTraining', 'WhatsTrainingOverlay')
	K:WatchAddonFrame('WhatsTraining', 'WhatsTrainingFrame')
end)
