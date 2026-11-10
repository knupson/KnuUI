local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Libro de hechizos y talentos (Blizzard_PlayerSpells, variante Forever "Camelot").
-- ElvUI ya skinea marco, botones y pestañas (Skins/PlayerSpells.lua:162-330) pero deja el arte:
-- el pergamino del libro y la ilustración de cada rama de talentos. KnuUI lo saca para que quede
-- con el fondo oscuro del tema, como el resto de la interfaz. Rutas de la rama forever:
--   Libro: BookBGLeft/Right/Halved y Bookmark (SpellBook/Blizzard_SpellBookFrame.xml:11-27).
--   Cada hechizo: Backplate "spellbook-item-backplate" (SpellBook/Blizzard_SpellBookItem.xml:57).
--   Título de categoría: Text, Border "spellbook-divider" y Backplate "spellbook-list-backplate"
--     (SpellBook/Blizzard_SpellBookTemplates.xml:11-27), armado en SpellBookHeaderMixin:Init.
--   Talentos: ClassBackground y el array specBackgrounds
--     (Camelot/ClassTalents/Blizzard_ClassTalentsFrame.xml:186-215). Tienen animaciones de alfa,
--     por eso se ocultan con Kill (ElvUI: Hide y Show anulado) en vez de SetAlpha(0).
-- Los textos vienen en marrón oscuro para el pergamino (SPELLBOOK_FONT_COLOR): pasan a los
-- colores del tema después de cada UpdateVisuals / Init.

local function Kill(region)
	if region and region.Kill then region:Kill() elseif region and region.SetAlpha then region:SetAlpha(0) end
end

local function StyleItem(item)
	local t = K:GetTheme()
	if item.Backplate then item.Backplate:SetAlpha(0) end
	if item.Name then item.Name:SetTextColor(t.text.r, t.text.g, t.text.b) end
	if item.SubName then item.SubName:SetTextColor(t.muted.r, t.muted.g, t.muted.b) end
	if item.RequiredLevel then item.RequiredLevel:SetTextColor(t.accent.r, t.accent.g, t.accent.b) end
end

local function StyleHeader(header)
	local t = K:GetTheme()
	if header.Backplate then header.Backplate:SetAlpha(0) end
	if header.Border then header.Border:SetVertexColor(t.accentDim.r, t.accentDim.g, t.accentDim.b) end
	if header.Text then header.Text:SetTextColor(t.accent.r, t.accent.g, t.accent.b) end
end

local function Style()
	local frame = _G.PlayerSpellsFrame
	if not frame then return end
	local book = frame.SpellBookFrame
	if book then
		for _, key in ipairs({ 'BookBGLeft', 'BookBGRight', 'BookBGHalved', 'Bookmark' }) do Kill(book[key]) end
	end
	local talents = frame.TalentsFrame
	if talents then
		Kill(talents.ClassBackground)
		for _, region in ipairs(talents.specBackgrounds or {}) do Kill(region) end
	end
end

K:RegisterSkin('Blizzard_PlayerSpells', function()
	-- Antes de que el libro cree sus ítems (se crean al mostrarse por primera vez).
	if _G.SpellBookItemMixin and not K.spellBookHooked then
		K.spellBookHooked = true
		hooksecurefunc(_G.SpellBookItemMixin, 'UpdateVisuals', function(item) pcall(StyleItem, item) end)
	end
	if _G.SpellBookHeaderMixin and not K.spellBookHeaderHooked then
		K.spellBookHeaderHooked = true
		hooksecurefunc(_G.SpellBookHeaderMixin, 'Init', function(header) pcall(StyleHeader, header) end)
	end
	-- El gancho al mixin del título no alcanzó («General» seguía marrón): además, después de que
	-- el marco paginado arma cada página (Blizzard_PagedContentFrame.lua:494, DisplayViewsForCurrentPage)
	-- se recorren sus marcos (:194-204, EnumerateFrames) y se pinta cada título e ítem.
	local paged = _G.PlayerSpellsFrame and _G.PlayerSpellsFrame.SpellBookFrame and _G.PlayerSpellsFrame.SpellBookFrame.PagedSpellsFrame
	if paged and type(paged.DisplayViewsForCurrentPage) == 'function' and not K.spellBookPagesHooked then
		K.spellBookPagesHooked = true
		hooksecurefunc(paged, 'DisplayViewsForCurrentPage', function(self)
			if type(self.EnumerateFrames) ~= 'function' then return end
			for _, f in self:EnumerateFrames() do
				if f.Border and f.Text then pcall(StyleHeader, f) elseif f.Name then pcall(StyleItem, f) end
			end
		end)
	end
	Style()
	local frame = _G.PlayerSpellsFrame
	if frame and not K.playerSpellsShowHooked then
		K.playerSpellsShowHooked = true
		frame:HookScript('OnShow', function() C_Timer.After(0, function() pcall(Style) end) end)
	end
end)
