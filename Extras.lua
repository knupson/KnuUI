local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Extras de KnuUI: aviso de combate, experiencia estimada, rol por personaje y modo cine.

local function Secret(value)
	return E.IsSecretValue and E:IsSecretValue(value)
end

-- Fundido propio con ease-out (cubic-bezier(0.23,1,0.32,1) aproximada por 1-(1-t)^3).
-- Un marco propio maneja los fundidos (nunca el OnUpdate de UIParent u otro marco ajeno);
-- se apaga cuando no queda ninguno y un fundido nuevo reemplaza al anterior sin saltos.
local fades, driver = {}, CreateFrame('Frame')
local function Step(_, dt)
	local any = false
	for frame, f in pairs(fades) do
		f.elapsed = f.elapsed + dt
		local t = math.min(f.elapsed / f.duration, 1)
		frame:SetAlpha(f.from + (f.to - f.from) * (1 - (1 - t) ^ 3))
		if t >= 1 then fades[frame] = nil else any = true end
	end
	if not any then driver:SetScript('OnUpdate', nil) end
end
local function Fade(frame, to, duration)
	fades[frame] = { from = frame:GetAlpha(), to = to, duration = duration, elapsed = 0 }
	driver:SetScript('OnUpdate', Step)
end

-- 1. Aviso de combate: un borde ámbar degradado de 28 px en los cuatro lados.
-- Entra en 150 ms y sale en 300 ms. SetAlpha está permitido en combate.
local glow
local function CreateGlow()
	glow = CreateFrame('Frame', 'KnuUI_CombatGlow', E.UIParent)
	glow:SetAllPoints(E.UIParent)
	glow:SetFrameStrata('BACKGROUND')
	glow:EnableMouse(false)
	glow:SetAlpha(0)
	local t = K:GetTheme().accent
	local solid, clear = CreateColor(t.r, t.g, t.b, 0.32), CreateColor(t.r, t.g, t.b, 0)
	local size = 28
	local sides = {
		{ 'TOPLEFT', 'TOPRIGHT', 0, size, 'VERTICAL', clear, solid },     -- arriba
		{ 'BOTTOMLEFT', 'BOTTOMRIGHT', 0, size, 'VERTICAL', solid, clear }, -- abajo
		{ 'TOPLEFT', 'BOTTOMLEFT', size, 0, 'HORIZONTAL', solid, clear },   -- izquierda
		{ 'TOPRIGHT', 'BOTTOMRIGHT', size, 0, 'HORIZONTAL', clear, solid }, -- derecha
	}
	for _, s in ipairs(sides) do
		local tex = glow:CreateTexture(nil, 'BACKGROUND')
		tex:SetTexture(E.media.blankTex)
		tex:SetPoint(s[1]); tex:SetPoint(s[2])
		if s[3] > 0 then tex:SetWidth(s[3]) else tex:SetHeight(s[4]) end
		-- Toolkit de Blizzard moderno: SetGradient(orientación, color mínimo, color máximo).
		tex:SetGradient(s[5], s[6], s[7])
	end
	glow:RegisterEvent('PLAYER_REGEN_DISABLED')
	glow:RegisterEvent('PLAYER_REGEN_ENABLED')
	glow:SetScript('OnEvent', function(self, event)
		if E.db.KnuUICombatGlow == false then self:SetAlpha(0) return end
		if event == 'PLAYER_REGEN_DISABLED' then Fade(self, 1, 0.15) else Fade(self, 0, 0.3) end
	end)
end

-- 2. Experiencia estimada: tasa de la sesión y tiempo hasta el próximo nivel en el tooltip
-- de la barra de experiencia de ElvUI (Modules/DataBars/Experience.lua:288).
local xp = { gained = 0 }
local function ReadXP()
	local cur, max = UnitXP('player'), UnitXPMax('player')
	if Secret(cur) or Secret(max) then return end
	return cur, max
end

local function TrackXP()
	local cur, max = ReadXP()
	if not cur then return end
	if not xp.start then
		xp.start, xp.last, xp.lastMax = GetTime(), cur, max
		return
	end
	if cur >= xp.last then
		xp.gained = xp.gained + (cur - xp.last)
	else -- subió de nivel: lo que faltaba del nivel anterior más lo ganado en el nuevo
		xp.gained = xp.gained + (xp.lastMax - xp.last) + cur
	end
	xp.last, xp.lastMax = cur, max
end

local function Duration(seconds)
	local minutes = math.floor(seconds / 60 + 0.5)
	if minutes < 60 then return format(L["%d min"], math.max(minutes, 1)) end
	return format(L["%d h %d min"], math.floor(minutes / 60), minutes % 60)
end

local function XPTooltip()
	local cur, max = ReadXP()
	if not cur or not xp.start then return end
	local elapsed = GetTime() - xp.start
	GameTooltip:AddLine(' ')
	if xp.gained <= 0 or elapsed < 60 then
		GameTooltip:AddLine(L["KnuUI: estimate after a minute of gaining experience"], 0.66, 0.56, 0.44)
	else
		local perHour = xp.gained / elapsed * 3600
		local t = K:GetTheme().accent
		GameTooltip:AddDoubleLine(L["Experience per hour"], E:ShortValue(perHour), 1, 1, 1, t.r, t.g, t.b)
		GameTooltip:AddDoubleLine(L["Next level in"], Duration((max - cur) / perHour * 3600), 1, 1, 1, t.r, t.g, t.b)
	end
	GameTooltip:Show()
end

local function SetupXP()
	local events = CreateFrame('Frame')
	events:RegisterEvent('PLAYER_ENTERING_WORLD')
	events:RegisterEvent('PLAYER_XP_UPDATE')
	events:SetScript('OnEvent', TrackXP)
	local bar = _G.ElvUI_ExperienceBar
	if bar then bar:HookScript('OnEnter', XPTooltip) end
end

-- 3. Rol por personaje: E.private es de cada personaje; E.db puede ser un perfil compartido.
-- Al entrar con un rol distinto al del perfil, lo aplica y ofrece recargar.
local function SyncRole()
	local mine = E.private.KnuUIRole
	if not mine or mine == (E.db.KnuUIRole or 'mdps') or InCombatLockdown() then return end
	if K:ApplyRole(mine) then
		E:Print(format(L["KnuUI: this character's role is %s; reload to see it."], K:RoleName()))
		E:StaticPopup_Show('CONFIG_RL')
	end
end

-- 4. Modo cine: oculta toda la interfaz (alfa 0, válido en combate) y gira la cámara despacio,
-- como la pantalla de ausente de ElvUI (Modules/Misc/AFK.lua:31,69). Se corta al entrar en combate.
local cinema = false
local CAMERA_SPEED = 0.035
function K:ToggleCinema(force)
	local on = force
	if on == nil then on = not cinema end
	if on == cinema then return end
	cinema = on
	if on then
		Fade(UIParent, 0, 0.3)
		MoveViewRightStart(CAMERA_SPEED)
	else
		MoveViewRightStop()
		Fade(UIParent, 1, 0.15)
	end
end

-- Global documentado para Bindings.xml (Teclado → AddOns → KnuUI).
function KnuUI_ToggleCinema() K:ToggleCinema() end
_G.BINDING_HEADER_KNUUI = 'KnuUI'
_G.BINDING_NAME_KNUUI_CINEMA = L["Cinema mode (hide the interface and orbit the camera)"]

-- Alertas: posición de KnuUI una vez por perfil y skin de ElvUI prendida (requiere recargar).
local function SetupAlerts()
	-- Distribución de elementos de Blizzard (Layout.lua, K.blizzardMovers), una vez por perfil.
	if not E.db.KnuUIBlizzardPlaced then
		E.db.KnuUIBlizzardPlaced = true
		E.db.movers = E.db.movers or {}
		for name, position in pairs(K.blizzardMovers or {}) do
			E.db.movers[name] = position
			if E.SetMoverPoints then pcall(E.SetMoverPoints, E, name) end
		end
	end
	if E.db.KnuUIAlertsPlaced then return end
	E.db.KnuUIAlertsPlaced = true
	local skins = E.private.skins and E.private.skins.blizzard
	if skins and skins.alertframes == false then
		skins.alertframes = true
		E:Print(L["KnuUI: alert skin turned on; reload to see it."])
	end
end

-- Barras de aire / fatiga / fingir muerte (MirrorTimerContainer). En Forever las ubica el Modo
-- edición ("Barras de duración"; ElvUI Modules/Misc/Misc.lua:447-451) y ElvUI las viste dejando la
-- textura de Blizzard recortada (Skins/MirrorTimers.lua:18-52). Acá: textura Melli, color por tipo,
-- letra Expressway y borde del tema, después de ElvUI y en cada barra nueva.
local MIRROR_COLORS = {
	BREATH = { 0.25, 0.6, 1 }, EXHAUSTION = { 1, 0.55, 0.1 }, FEIGNDEATH = { 1, 0.85, 0.2 },
}
local function StyleMirror(container, timer)
	local bar = container and container.GetAvailableTimer and container:GetAvailableTimer(timer)
	if not bar or not bar.StatusBar then return end
	local t = K:GetTheme()
	local status = bar.StatusBar
	status:SetStatusBarTexture(E.Libs.LSM:Fetch('statusbar', 'Melli'))
	local c = MIRROR_COLORS[timer] or { t.accent.r, t.accent.g, t.accent.b }
	status:SetStatusBarColor(c[1], c[2], c[3])
	if bar.SetBackdropBorderColor then
		bar:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, 0.9)
		bar:SetBackdropBorderColor(t.accentDim.r, t.accentDim.g, t.accentDim.b)
	end
	for _, text in ipairs({ bar.Text, status.TimerText }) do
		if text and text.FontTemplate then text:FontTemplate('Expressway', 12, 'OUTLINE') end
	end
end

local function SetupMirrorTimers()
	local container = _G.MirrorTimerContainer
	if not container or type(container.SetupTimer) ~= 'function' or K.mirrorHooked then return end
	K.mirrorHooked = true
	hooksecurefunc(container, 'SetupTimer', function(self, timer) pcall(StyleMirror, self, timer) end)
end

function K:SetupExtras()
	pcall(SetupAlerts)
	pcall(SetupMirrorTimers)
	if E.db.KnuUICombatGlow == nil then E.db.KnuUICombatGlow = true end
	if not glow then CreateGlow() end
	SetupXP()
	local events = CreateFrame('Frame')
	events:RegisterEvent('PLAYER_REGEN_DISABLED')
	events:RegisterEvent('PLAYER_ENTERING_WORLD')
	events:SetScript('OnEvent', function(self, event)
		if event == 'PLAYER_REGEN_DISABLED' then
			K:ToggleCinema(false)
		else
			self:UnregisterEvent('PLAYER_ENTERING_WORLD')
			C_Timer.After(2, SyncRole)
		end
	end)
end
