local E, _, _, P = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Monitor de botín, implementación propia de KnuUI: avisos con ícono de lo que saqueás vos y tu
-- grupo, que se desvanecen solos. La ventana de botín y las tiradas ya las da ElvUI
-- (Modules/Misc/Loot.lua y LootRoll.lua, activas por defecto: Defaults/Private.lua:7-8).
-- Fuente: CHAT_MSG_LOOT. En Forever el texto y el nombre pueden llegar secretos
-- (rama forever, ChatInfoDocumentation.lua:1813-1824): en ese caso el aviso se saltea, nunca se
-- compara ni se recorta un valor secreto (issecretvalue, como oUF init.lua:64).
P.KnuUILootMonitor = true
P.KnuUILootSelfQuality = 1  -- blanco o mejor
P.KnuUILootGroupQuality = 2 -- verde o mejor

local MAX_ROWS, HOLD, FADE = 6, 8, 1
local ROW_H, WIDTH = 22, 260
local holder, rows = nil, {}

local function Secret(value) return issecretvalue and issecretvalue(value) end

local function CreateRow(i)
	local row = CreateFrame('Frame', nil, holder)
	row:SetSize(WIDTH, ROW_H)
	row.home = { 'BOTTOMLEFT', holder, 'BOTTOMLEFT', 0, (i - 1) * (ROW_H + 3) }
	row:SetPoint(unpack(row.home))
	row:SetTemplate('Transparent')
	if K.KnuFrame then K:KnuFrame(row) end
	row.icon = row:CreateTexture(nil, 'ARTWORK')
	row.icon:SetSize(ROW_H - 4, ROW_H - 4)
	row.icon:SetPoint('LEFT', 2, 0)
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	row.text = row:CreateFontString(nil, 'OVERLAY')
	row.text:FontTemplate('Expressway', 12, 'OUTLINE')
	row.text:SetPoint('LEFT', row.icon, 'RIGHT', 6, 0)
	row.text:SetPoint('RIGHT', -6, 0)
	row.text:SetJustifyH('LEFT')
	row.text:SetWordWrap(false)
	row:EnableMouse(true)
	row:SetScript('OnEnter', function(self)
		if not self.link then return end
		self.hover = true
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
		GameTooltip:SetHyperlink(self.link)
		GameTooltip:Show()
	end)
	row:SetScript('OnLeave', function(self) self.hover = nil; GameTooltip:Hide() end)
	row:SetScript('OnUpdate', function(self, elapsed)
		if self.hover then return end
		self.age = self.age + elapsed
		if self.age > HOLD + FADE then
			self:Hide()
		elseif self.age > HOLD then
			self:SetAlpha(1 - (self.age - HOLD) / FADE)
		end
	end)
	row:Hide()
	return row
end

local function Create()
	holder = CreateFrame('Frame', 'KnuUI_LootMonitor', E.UIParent)
	holder:SetSize(WIDTH, MAX_ROWS * (ROW_H + 3))
	-- Arriba del panel derecho (el aviso de amigos va arriba del izquierdo: Layout.lua BNET 4,212).
	-- A la izquierda de las barras 5 y 6 (Layout.lua, bloques 2×6 en x 1776-1916): a -4 las pisaba.
	holder:SetPoint('BOTTOMRIGHT', E.UIParent, 'BOTTOMRIGHT', -148, 240)
	for i = 1, MAX_ROWS do rows[i] = CreateRow(i) end
	holder.rows = rows
	E:CreateMover(holder, 'KnuUI_LootMonitorMover', L["KnuUI: loot monitor"], nil, nil, nil, 'ALL,GENERAL', nil, 'KnuUI')
end

-- Lo nuevo va abajo y empuja hacia arriba lo anterior.
local function Push(link, quantity, who)
	if not holder then Create() end
	for i = MAX_ROWS, 2, -1 do
		local to, from = rows[i], rows[i - 1]
		to.link, to.age = from.link, from.age
		to.icon:SetTexture(from.icon:GetTexture())
		to.text:SetText(from.text:GetText())
		to:SetBackdropBorderColor(from:GetBackdropBorderColor())
		to:SetAlpha(from:GetAlpha())
		to:SetShown(from:IsShown())
	end
	local row, t = rows[1], K:GetTheme()
	local _, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(link)
	row.link, row.age, row.hover = link, 0, nil
	row.icon:SetTexture(icon or C_Item.GetItemIconByID(link) or 134400)
	local label = link .. ((quantity and quantity > 1) and (' x' .. quantity) or '')
	row.text:SetText(who and (who .. ': ' .. label) or label)
	local r, g, b = t.border.r, t.border.g, t.border.b
	if quality and quality >= 2 and C_Item.GetItemQualityColor then r, g, b = C_Item.GetItemQualityColor(quality) end
	row:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, 0.85)
	row:SetBackdropBorderColor(r, g, b)
	-- Entra deslizándose desde la derecha con fundido (Motion.lua, 220 ms).
	if K.SlideIn then K:SlideIn(row, row.home) else row:SetAlpha(1); row:Show() end
end

function K:LootMessage(text, playerName)
	if E.db.KnuUILootMonitor == false or Secret(text) or Secret(playerName) or type(text) ~= 'string' then return end
	local link = text:match('(|c.-|Hitem:.-|h.-|h|r)')
	if not link then return end
	local quantity = tonumber(text:match('|h|r%s*x(%d+)'))
	local short = playerName and playerName ~= '' and Ambiguate(playerName, 'short') or nil
	local mine = not short or short == UnitName('player')
	local quality = select(3, C_Item.GetItemInfo(link))
	local minimum = mine and (E.db.KnuUILootSelfQuality or 1) or (E.db.KnuUILootGroupQuality or 2)
	-- Sin datos de calidad todavía (objeto sin caché) se muestra igual.
	if quality and quality < minimum then return end
	Push(link, quantity, not mine and short or nil)
end

function K:SetupLootMonitor()
	local f = CreateFrame('Frame')
	f:RegisterEvent('CHAT_MSG_LOOT')
	f:SetScript('OnEvent', function(_, _, text, playerName)
		local ok, err = pcall(K.LootMessage, K, text, playerName)
		if not ok and E.db.KnuUIDebug then E:Print(tostring(err)) end
	end)
end
