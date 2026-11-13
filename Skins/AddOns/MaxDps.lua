local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

local bound = setmetatable({}, { __mode = 'k' })
local function Apply()
	local frame = _G.MaxDpsSpellFrame
	if not frame then return end
	K:RunAddonSkin('MaxDps', frame, function()
		-- MaxDps/SpellFrame.lua:23,86-104: fondo/borde, icono y cooldown en el mismo marco.
		-- WatchAddonFrame llama SkinFrame/StripTextures: borraría el icono. Sólo se recolorea
		-- el backdrop existente; no se recorren hijos ni se toca el brillo de MaxDps.
		if not bound[frame] then
			frame:HookScript('OnShow', Apply)
			bound[frame] = true
		end
		local t = K:GetTheme()
		frame:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
		frame:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	end)
end

K:RegisterSkin('MaxDps', function()
	Apply()
	-- SpellFrame.lua:6-23 lo crea en ADDON_LOADED; esperar al final de esa creación.
	hooksecurefunc('CreateFrame', function(_, name)
		if name == 'MaxDpsSpellFrame' then C_Timer.After(0, Apply) end
	end)
end)
