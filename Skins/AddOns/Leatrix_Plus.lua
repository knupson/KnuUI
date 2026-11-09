local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('Leatrix_Plus', function()
	local function FindPanel()
		-- Leatrix_Plus/Leatrix_Plus.lua:16: tabla privada; :77-86: nombre aleatorio.
		-- :17161,17167: PageF es hijo de UIParent; :17201-17203: mt identifica el panel.
		-- No se adivina el global: se identifica por el título constante del código.
		for _, frame in ipairs({ UIParent:GetChildren() }) do
			local title = frame.mt and frame.mt.GetText and frame.mt:GetText()
			if title and not E:IsSecretValue(title) and title == 'Leatrix Plus' then
				K:StyleAddonFrame('Leatrix_Plus', frame, function(panel) K:SkinFont(panel.mt, true) end)
				return true
			end
		end
	end
	if FindPanel() then return end
	-- El panel también puede terminar de armarse durante el inicio del personaje.
	local events = CreateFrame('Frame')
	events:RegisterEvent('PLAYER_ENTERING_WORLD')
	events:SetScript('OnEvent', function()
		K:RunAddonSkin('Leatrix_Plus', events, function()
			if FindPanel() then events:UnregisterEvent('PLAYER_ENTERING_WORLD') end
		end)
	end)
end)
