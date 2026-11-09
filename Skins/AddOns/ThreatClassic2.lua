local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('ThreatClassic2', function()
	local function Bars(frame)
		-- ThreatClassic2/core/init.lua:12 y core/core.lua:1430: ThreatClassic2BarFrame.
		-- core/core.lua:150,183-187,1118-1123: barras hijas, con name/val/perc/tps.
		-- :1069,1148,1155-1158: setters reales de textura y fuentes.
		local t = K:GetTheme()
		-- :1607-1608: fondo propio que TC2 crea durante PLAYER_LOGIN.
		if frame.bg then frame.bg:SetColorTexture(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a) end
		for _, bar in ipairs({ frame:GetChildren() }) do
			if bar:IsObjectType('StatusBar') then
				bar:SetStatusBarTexture(E.Libs.LSM:Fetch('statusbar', 'Melli'))
				bar:SetTemplate('Transparent')
				bar:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
				if bar.edgeBackdrop then
					bar.edgeBackdrop:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
				end
				for _, field in ipairs({ 'name', 'val', 'perc', 'tps', 'text' }) do
					K:SkinFont(bar[field], field == 'text')
				end
			end
		end
	end
	K:WatchAddonFrame('ThreatClassic2', 'ThreatClassic2BarFrame', Bars)
	-- :1433-1434: PLAYER_LOGIN arma las barras; el post-hook corre después del addon.
	local frame = _G.ThreatClassic2BarFrame
	if frame then
		frame:HookScript('OnEvent', function()
			K:RunAddonSkin('ThreatClassic2', Bars, function() Bars(frame) end)
		end)
	end
end)
