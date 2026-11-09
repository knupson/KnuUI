local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('DBM-Core', function()
	local function Options()
		-- DBM-StatusBarTimers/DBT.lua:7 exporta DBT; :163-164 define Texture/Font.
		-- :815-838: SetOption guarda y actualiza las barras con las opciones de DBT.
		-- Cambia la configuración guardada de DBM: sólo si el usuario lo activó (opción en ElvUI > KnuUI).
		if not E.db.KnuUISkinDBM then return end
		if not _G.DBT or not DBT.Options or type(DBT.SetOption) ~= 'function' then return end
		DBT:SetOption('Texture', E.Libs.LSM:Fetch('statusbar', 'Melli'), true)
		DBT:SetOption('Font', E.Libs.LSM:Fetch('font', 'Expressway'))
	end
	-- DBM-Core/DBM-Core.lua:1819 y DBT.lua:659,663: el perfil se carga con LoadOptions.
	K:HookAddonSkin('DBM-Core', _G.DBT, 'LoadOptions', Options)
	Options()
end)
