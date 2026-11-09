local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('Questie', function()
	-- Questie/Modules/Options/QuestieOptionsWindow.lua:11,17: ventana propia de Forever.
	K:WatchAddonFrame('Questie', 'QuestieStandaloneSettings')
	local function AceWindows()
		-- Modules/Journey/QuestieJourney.lua:124,179 y Options/QuestieOptions.lua:61,89:
		-- los globals son widgets AceGUI; el marco WoW está en .frame.
		for _, widget in ipairs({ _G.QuestieJourneyFrame or false, _G.QuestieConfigFrame or false }) do
			if widget then K:StyleAddonFrame('Questie', widget.frame) end
		end
	end
	-- ImportModule: Modules/Journey/QuestieJourney.lua:5,14,24.
	if _G.QuestieLoader then
		local journey = QuestieLoader:ImportModule('QuestieJourney')
		local options = QuestieLoader:ImportModule('QuestieOptions')
		K:HookAddonSkin('Questie', journey, 'BuildMainFrame', AceWindows)
		K:HookAddonSkin('Questie', journey, 'ToggleJourneyWindow', AceWindows)
		K:HookAddonSkin('Questie', options, 'ToggleConfigWindow', AceWindows)
	end
	AceWindows()
end)
