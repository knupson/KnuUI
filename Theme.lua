local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

local function C(hex, a)
	return {
		r = tonumber(hex:sub(1, 2), 16) / 255,
		g = tonumber(hex:sub(3, 4), 16) / 255,
		b = tonumber(hex:sub(5, 6), 16) / 255,
		a = a or 1,
	}
end

-- Temas. 'knunet' sale de las variables CSS de :root de https://knunet.com
-- (--bg #110c08, --bg-2 #18110b, --panel #1f160e, --line #33251a, --amber #ffa82e,
-- --amber-hi #ffc06a, --amber-dim #b07428, --text #ecd9bd), leídas el 2026-11-08.
K.themes = {
	knunet = {
		label = L["Knunet amber"],
		accent = C('ffa82e'), accentHi = C('ffc06a'), accentDim = C('b07428'),
		text = C('ecd9bd'), muted = C('a88f70'),
		backdrop = C('1f160e'), backdropFade = C('110c08', 0.85), border = C('33251a'),
		cast = C('ffa82e'), castNoInterrupt = C('e0523a'), health = C('ffc06a'),
		healthBackdrop = C('18110b'),
	},
	neon = {
		label = L["Neon cyan and magenta"],
		accent = C('00e5ff'), accentHi = C('00e5ff'), accentDim = C('ff2e88'),
		text = C('f5f7ff'), muted = C('9aa3b8'),
		backdrop = C('0e1018'), backdropFade = C('08080f', 0.82), border = C('030308'),
		cast = C('ff2e88'), castNoInterrupt = C('ffc440'), health = C('00e5ff'),
		healthBackdrop = C('0e1018'),
	},
	-- Más naranja que knunet.com (pedido del user): estos tres acentos los eligió KnuUI, no salen
	-- de la web; el fondo y los textos son los de knunet.
	knunetIntense = {
		label = L["Knunet intense orange"],
		-- v2: el primer naranja (#ff8c1a) casi no se distinguía del ámbar (#ffa82e). Este es naranja puro
		-- (#ff6a00, matiz 25° contra 35° del ámbar, saturación 100 %) y los bordes también van en naranja, no en marrón.
		accent = C('ff6a00'), accentHi = C('ff8c33'), accentDim = C('d95500'),
		text = C('f2e0c8'), muted = C('b08a68'),
		backdrop = C('1f140b'), backdropFade = C('120b06', 0.85), border = C('7a3a08'),
		cast = C('ff6a00'), castNoInterrupt = C('e0523a'), health = C('ff8c33'),
		healthBackdrop = C('18110b'),
	},
	-- Paletas populares con sus valores oficiales (leídos el 2026-11-08):
	-- Dracula: github.com/dracula/dracula-theme README (Background, Current Line, Comment, Purple...).
	dracula = {
		label = 'Dracula',
		accent = C('bd93f9'), accentHi = C('ff79c6'), accentDim = C('6272a4'),
		text = C('f8f8f2'), muted = C('6272a4'),
		backdrop = C('282a36'), backdropFade = C('282a36', 0.9), border = C('44475a'),
		cast = C('bd93f9'), castNoInterrupt = C('ff5555'), health = C('50fa7b'),
		healthBackdrop = C('282a36'),
	},
	-- Nord: github.com/nordtheme/nord src/nord.css (--nord0 a --nord15).
	nord = {
		label = 'Nord',
		accent = C('88c0d0'), accentHi = C('8fbcbb'), accentDim = C('5e81ac'),
		text = C('eceff4'), muted = C('81a1c1'),
		backdrop = C('3b4252'), backdropFade = C('2e3440', 0.9), border = C('434c5e'),
		cast = C('88c0d0'), castNoInterrupt = C('bf616a'), health = C('a3be8c'),
		healthBackdrop = C('2e3440'),
	},
	-- Catppuccin Mocha: github.com/catppuccin/palette palette.json (mocha).
	catppuccin = {
		label = 'Catppuccin Mocha',
		accent = C('cba6f7'), accentHi = C('f5c2e7'), accentDim = C('7f849c'),
		text = C('cdd6f4'), muted = C('a6adc8'),
		backdrop = C('1e1e2e'), backdropFade = C('181825', 0.9), border = C('313244'),
		cast = C('cba6f7'), castNoInterrupt = C('f38ba8'), health = C('a6e3a1'),
		healthBackdrop = C('11111b'),
	},
	-- Gruvbox Dark: github.com/morhetz/gruvbox colors/gruvbox.vim.
	gruvbox = {
		label = 'Gruvbox',
		accent = C('fe8019'), accentHi = C('fabd2f'), accentDim = C('d65d0e'),
		text = C('ebdbb2'), muted = C('928374'),
		backdrop = C('282828'), backdropFade = C('1d2021', 0.9), border = C('3c3836'),
		cast = C('fe8019'), castNoInterrupt = C('fb4934'), health = C('b8bb26'),
		healthBackdrop = C('1d2021'),
	},
	-- Tokyo Night Storm: github.com/folke/tokyonight.nvim lua/tokyonight/colors/storm.lua.
	tokyonight = {
		label = 'Tokyo Night',
		accent = C('7aa2f7'), accentHi = C('7dcfff'), accentDim = C('565f89'),
		text = C('c0caf5'), muted = C('a9b1d6'),
		backdrop = C('24283b'), backdropFade = C('1f2335', 0.9), border = C('292e42'),
		cast = C('bb9af7'), castNoInterrupt = C('f7768e'), health = C('9ece6a'),
		healthBackdrop = C('1f2335'),
	},
}
-- Orden en el menú de opciones.
K.themeOrder = { 'knunet', 'knunetIntense', 'neon', 'dracula', 'nord', 'catppuccin', 'gruvbox', 'tokyonight' }
K.palette = K.themes.knunet -- compatibilidad con el código que lee K.palette

function K:GetTheme()
	return self.themes[E.db.KnuUITheme or 'knunet'] or self.themes.knunet
end

function K:ApplyTheme(classHealth, themeName)
	if not self:CanApply() then return false end
	-- Preferencias propias dentro del perfil (ElvUI las conserva al guardar).
	if classHealth == nil then classHealth = E.db.KnuUIClassHealth ~= false end
	E.db.KnuUIClassHealth = classHealth
	if themeName and self.themes[themeName] then E.db.KnuUITheme = themeName end
	local t = self:GetTheme()
	K.palette = t

	-- _ref/ElvUI/Game/Shared/Defaults/Profile.lua:77,138-141,2075-2156.
	-- UpdateClassColor usa RGB de clase como señal: _ref/ElvUI/Game/Shared/General/Core.lua:261-283,361-369.
	self.Set(E.db.general, {
		font = 'Expressway',
		backdropcolor = t.backdrop,
		backdropfadecolor = t.backdropFade,
		bordercolor = t.border,
		valuecolor = t.accent,
		afk = true, -- Profile.lua:67: pantalla de ausente de ElvUI, la viste Afk.lua
	})
	-- Registros LSM: _ref/ElvUI/Game/Shared/Media/SharedMedia.lua:85,104.
	self.Set(E.db.unitframe, {
		font = 'Expressway', statusbar = 'Melli',
		colors = {
			borderColor = t.border,
			healthclass = classHealth, colorhealthbyvalue = false,
			healthselection = false, forcehealthreaction = false,
			health = t.health,
			customhealthbackdrop = true, healthbackdropbyvalue = false,
			classbackdrop = false, health_backdrop = t.healthBackdrop,
			castClassColor = false, castReactionColor = false,
			castColor = t.cast, castNoInterrupt = t.castNoInterrupt,
		},
	})
	-- ElvUI decide el color desde el override de la unidad: Elements/Health.lua:87-110.
	for _, unit in ipairs({ 'player', 'target' }) do
		E.db.unitframe.units[unit].colorOverride = 'USE_DEFAULT' -- Profile.lua:2266,2326.
	end
	-- La pantalla AFK de S&L reemplaza a la de ElvUI (ElvUI_SLE/modules/afk.lua:419);
	-- se apaga para que se vea la de KnuUI.
	if E.db.sle and E.db.sle.afk then E.db.sle.afk.enable = false end
	-- Números de enfriamiento estilo OmniCC con el sistema nativo de ElvUI
	-- (P.cooldown.<módulo>: Profile.lua:3533-3640). Rojo al vencer, acento en segundos.
	if E.db.cooldown then
		for _, key in ipairs({ 'global', 'actionbar' }) do
			local cd = E.db.cooldown[key]
			if type(cd) == 'table' then
				self.Set(cd, {
					enable = true, hideNumbers = false, hideBling = false,
					font = 'Expressway', fontOutline = 'OUTLINE', fontSize = key == 'actionbar' and 16 or 18,
					thresholdText = {
						override = true, expireThreshold = 4, secondsThreshold = 11,
						colors = {
							expiring = { r = 1, g = 0.25, b = 0.2 },
							seconds = { r = t.accent.r, g = t.accent.g, b = t.accent.b },
							minutes = { r = t.text.r, g = t.text.g, b = t.text.b },
						},
					},
				})
			end
		end
	end
	if self.StyleButtons then self:StyleButtons() end
	if self.RefreshDecor then self:RefreshDecor() end
	if self.SkinWoWPro then self:SkinWoWPro() end
	if self.SkinBNToast then self:SkinBNToast() end
	if self.StyleRaidMarkers then self:StyleRaidMarkers() end
	if self.StyleFlightTimer then self.StyleFlightTimer() end
	if self.StyleFadeButtons then self:StyleFadeButtons() end
	if self.StyleMotionFrames then self:StyleMotionFrames() end
	if self.ApplyIntegratedPanels then self:ApplyIntegratedPanels() end
	return true
end
