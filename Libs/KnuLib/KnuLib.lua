local MAJOR, MINOR = 'KnuLib-1.0', 6
local lib = LibStub:NewLibrary(MAJOR, MINOR); if not lib then return end

function lib:ApplyDefaults(db, defaults)
    assert(type(db) == 'table' and type(defaults) == 'table', 'Se esperaban dos tablas')
    for key, value in pairs(defaults) do
        if type(value) == 'table' then
            if type(db[key]) ~= 'table' then db[key] = {} end
            self:ApplyDefaults(db[key], value)
        elseif db[key] == nil then
            db[key] = value
        end
    end
    return db
end

lib.EventsMethods = lib.EventsMethods or {}
lib.EventsMeta = lib.EventsMeta or { __index = lib.EventsMethods }

local function AddEvent(obj, event, fn, once)
    assert(type(event) == 'string', 'Se esperaba un evento de texto')
    assert(type(fn) == 'function', 'Se esperaba una función')
    local handlers = obj.handlers[event]
    if not handlers then
        local success, err = pcall(obj.frame.RegisterEvent, obj.frame, event)
        if not success then obj.invalid[event] = tostring(err); return false end
        handlers = {}
        obj.handlers[event] = handlers
    end
    for _, entry in ipairs(handlers) do
        if entry.fn == fn then return true end
    end
    handlers[#handlers + 1] = { fn = fn, once = once }
    return true
end

function lib.EventsMethods:On(event, fn)
    return AddEvent(self, event, fn, false)
end

function lib.EventsMethods:Once(event, fn)
    return AddEvent(self, event, fn, true)
end

-- Quitar por identidad evita borrar un registro nuevo de la misma función.
local function RemoveEvent(obj, event, entry)
    local handlers = obj.handlers[event]
    if not handlers then return end
    for i = #handlers, 1, -1 do
        if handlers[i] == entry then table.remove(handlers, i) end
    end
    if #handlers == 0 then
        pcall(obj.frame.UnregisterEvent, obj.frame, event)
        obj.handlers[event] = nil
    end
end

function lib.EventsMethods:Off(event, fn)
    local handlers = self.handlers[event]
    if not handlers then return end
    for i = #handlers, 1, -1 do
        if handlers[i].fn == fn then RemoveEvent(self, event, handlers[i]) end
    end
end

function lib.EventsMethods:Emit(event, ...)
    local pending = {}
    for i, entry in ipairs(self.handlers[event] or {}) do pending[i] = entry end
    for _, entry in ipairs(pending) do
        -- Un Once ya consumido por un despacho anidado no vuelve a ejecutarse.
        if not entry.fired then
            if entry.once then
                entry.fired = true
                RemoveEvent(self, event, entry)
            end
            entry.fn(...)
        end
    end
end

function lib:NewEvents()
    local obj = setmetatable({ handlers = {}, invalid = {}, frame = CreateFrame('Frame') }, self.EventsMeta)
    obj.frame:SetScript('OnEvent', function(_, event, ...) obj:Emit(event, ...) end)
    return obj
end

local function ReportError(err)
    if print then print(err) end
end

lib.loggedIn = lib.loggedIn or false
lib.loginQueue = lib.loginQueue or {}

function lib:OnLogin(fn)
    assert(type(fn) == 'function', 'Se esperaba una función')
    if self.loggedIn or (IsLoggedIn and IsLoggedIn()) then fn(); return end
    self.loginQueue[#self.loginQueue + 1] = fn
end

function lib:RunLoginQueue()
    if self.loggedIn then return end
    self.loggedIn = true
    self.loginFrame:UnregisterEvent('PLAYER_LOGIN')
    local pending = {}
    for i, fn in ipairs(self.loginQueue) do pending[i] = fn end
    for i = #self.loginQueue, 1, -1 do self.loginQueue[i] = nil end
    for _, fn in ipairs(pending) do xpcall(fn, geterrorhandler and geterrorhandler() or ReportError) end
end

if not lib.loginFrame then
    lib.loginFrame = lib.loginFrame or CreateFrame('Frame')
    lib.loginFrame:RegisterEvent('PLAYER_LOGIN')
    lib.loginFrame:SetScript('OnEvent', function() lib:RunLoginQueue() end)
end

lib.combatQueue = lib.combatQueue or {}
lib.combatKeys = lib.combatKeys or {}

function lib:AfterCombat(fn, key)
    assert(type(fn) == 'function', 'Se esperaba una función')
    if not InCombatLockdown or not InCombatLockdown() then fn(); return true end
    local entry = key ~= nil and self.combatKeys[key]
    if entry then
        entry.fn = fn
    else
        entry = { fn = fn, key = key }
        self.combatQueue[#self.combatQueue + 1] = entry
        if key ~= nil then self.combatKeys[key] = entry end
    end
    return false
end

function lib:CancelAfterCombat(key)
    local entry = key ~= nil and self.combatKeys[key]
    if entry then
        entry.cancelled = true
        self.combatKeys[key] = nil
        -- Sacarla de la cola: cancelar y re-encolar en un combate largo no la hace crecer.
        for i = #self.combatQueue, 1, -1 do
            if self.combatQueue[i] == entry then table.remove(self.combatQueue, i) end
        end
    end
end

function lib:RunCombatQueue()
    local pending = {}
    for i, entry in ipairs(self.combatQueue) do pending[i] = entry end
    for i = #self.combatQueue, 1, -1 do self.combatQueue[i] = nil end
    for key in pairs(self.combatKeys) do self.combatKeys[key] = nil end
    for _, entry in ipairs(pending) do
        if not entry.cancelled then xpcall(entry.fn, geterrorhandler and geterrorhandler() or ReportError) end
    end
end

if not lib.combatFrame then
    lib.combatFrame = lib.combatFrame or CreateFrame('Frame')
    lib.combatFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
    lib.combatFrame:SetScript('OnEvent', function() lib:RunCombatQueue() end)
end

-- en (opcional): textos en inglés para claves que no son texto (p. ej. cod = 'cash on delivery').
function lib:NewLocale(es, en)
    local L = setmetatable({}, { __index = function(t, k) return k end })
    for key, value in pairs(en or {}) do L[key] = value end
    local locale = GetLocale and GetLocale() or 'enUS'
    if locale == 'esES' or locale == 'esMX' then
        for key, value in pairs(es or {}) do L[key] = value end
    end
    return L
end
local L = lib:NewLocale({
    ['Knunet amber'] = 'Knunet ámbar',
    ['Neon cyan and magenta'] = 'Neón cian y magenta',
    ['Knunet intense orange'] = 'Knunet naranja intenso',
    ['Class colour'] = 'Color de clase',
})

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
lib.themes = lib.themes or {}
lib.themes.knunet = {
		label = L["Knunet amber"],
		accent = C('ffa82e'), accentHi = C('ffc06a'), accentDim = C('b07428'),
		text = C('ecd9bd'), muted = C('a88f70'),
		backdrop = C('1f160e'), backdropFade = C('110c08', 0.85), border = C('33251a'),
		cast = C('ffa82e'), castNoInterrupt = C('e0523a'), health = C('ffc06a'),
		healthBackdrop = C('18110b'),
	}
lib.themes.neon = {
		label = L["Neon cyan and magenta"],
		accent = C('00e5ff'), accentHi = C('00e5ff'), accentDim = C('ff2e88'),
		text = C('f5f7ff'), muted = C('9aa3b8'),
		backdrop = C('0e1018'), backdropFade = C('08080f', 0.82), border = C('030308'),
		cast = C('ff2e88'), castNoInterrupt = C('ffc440'), health = C('00e5ff'),
		healthBackdrop = C('0e1018'),
	}
	-- Más naranja que knunet.com (pedido del user): estos tres acentos los eligió KnuUI, no salen
	-- de la web; el fondo y los textos son los de knunet.
lib.themes.knunetIntense = {
		label = L["Knunet intense orange"],
		-- v2: el primer naranja (#ff8c1a) casi no se distinguía del ámbar (#ffa82e). Este es naranja puro
		-- (#ff6a00, matiz 25° contra 35° del ámbar, saturación 100 %) y los bordes también van en naranja, no en marrón.
		accent = C('ff6a00'), accentHi = C('ff8c33'), accentDim = C('d95500'),
		text = C('f2e0c8'), muted = C('b08a68'),
		backdrop = C('1f140b'), backdropFade = C('120b06', 0.85), border = C('7a3a08'),
		cast = C('ff6a00'), castNoInterrupt = C('e0523a'), health = C('ff8c33'),
		healthBackdrop = C('18110b'),
	}
	-- Paletas populares con sus valores oficiales (leídos el 2026-11-08):
	-- Dracula: github.com/dracula/dracula-theme README (Background, Current Line, Comment, Purple...).
lib.themes.dracula = {
		label = L["Dracula"],
		accent = C('bd93f9'), accentHi = C('ff79c6'), accentDim = C('6272a4'),
		text = C('f8f8f2'), muted = C('6272a4'),
		backdrop = C('282a36'), backdropFade = C('282a36', 0.9), border = C('44475a'),
		cast = C('bd93f9'), castNoInterrupt = C('ff5555'), health = C('50fa7b'),
		healthBackdrop = C('282a36'),
	}
	-- Nord: github.com/nordtheme/nord src/nord.css (--nord0 a --nord15).
lib.themes.nord = {
		label = L["Nord"],
		accent = C('88c0d0'), accentHi = C('8fbcbb'), accentDim = C('5e81ac'),
		text = C('eceff4'), muted = C('81a1c1'),
		backdrop = C('3b4252'), backdropFade = C('2e3440', 0.9), border = C('434c5e'),
		cast = C('88c0d0'), castNoInterrupt = C('bf616a'), health = C('a3be8c'),
		healthBackdrop = C('2e3440'),
	}
	-- Catppuccin Mocha: github.com/catppuccin/palette palette.json (mocha).
lib.themes.catppuccin = {
		label = L["Catppuccin Mocha"],
		accent = C('cba6f7'), accentHi = C('f5c2e7'), accentDim = C('7f849c'),
		text = C('cdd6f4'), muted = C('a6adc8'),
		backdrop = C('1e1e2e'), backdropFade = C('181825', 0.9), border = C('313244'),
		cast = C('cba6f7'), castNoInterrupt = C('f38ba8'), health = C('a6e3a1'),
		healthBackdrop = C('11111b'),
	}
	-- Gruvbox Dark: github.com/morhetz/gruvbox colors/gruvbox.vim.
lib.themes.gruvbox = {
		label = L["Gruvbox"],
		accent = C('fe8019'), accentHi = C('fabd2f'), accentDim = C('d65d0e'),
		text = C('ebdbb2'), muted = C('928374'),
		backdrop = C('282828'), backdropFade = C('1d2021', 0.9), border = C('3c3836'),
		cast = C('fe8019'), castNoInterrupt = C('fb4934'), health = C('b8bb26'),
		healthBackdrop = C('1d2021'),
	}
	-- Tokyo Night Storm: github.com/folke/tokyonight.nvim lua/tokyonight/colors/storm.lua.
lib.themes.tokyonight = {
		label = L["Tokyo Night"],
		accent = C('7aa2f7'), accentHi = C('7dcfff'), accentDim = C('565f89'),
		text = C('c0caf5'), muted = C('a9b1d6'),
		backdrop = C('24283b'), backdropFade = C('1f2335', 0.9), border = C('292e42'),
		cast = C('bb9af7'), castNoInterrupt = C('f7768e'), health = C('9ece6a'),
		healthBackdrop = C('1f2335'),
	}
-- Mismos doce colores que los temas originales. La asignación a elementos y el alfa son de KnuUI.
local function Palette(label, accent, hi, dim, text, muted, bg, fade, border, danger, health)
	return { label = label, accent = C(accent), accentHi = C(hi), accentDim = C(dim),
		text = C(text), muted = C(muted), backdrop = C(bg), backdropFade = C(fade, 0.9),
		border = C(border), cast = C(accent), castNoInterrupt = C(danger),
		health = C(health), healthBackdrop = C(fade) }
end
lib.Palette = Palette

-- Valores oficiales consultados el 2026-11-12; fuentes y tokens originales:
-- https://github.com/altercation/solarized/blob/master/README.md#the-values
-- blue, cyan, base01, base0, base00, base03, base03, base02, red, green.
lib.themes.solarized = Palette(L["Solarized Dark"], '268bd2', '2aa198', '586e75', '839496', '657b83', '002b36', '002b36', '073642', 'dc322f', '859900')
-- https://github.com/atom/one-dark-syntax/blob/master/styles/colors.less
-- hue-2, hue-1, mono-3, mono-1, mono-2, syntax-bg (HSL oficiales convertidos a RGB).
-- Borde: mismo syntax-bg; fondo atenuado: mismo syntax-bg. hue-5 y hue-4 para peligro/vida.
lib.themes.onedark = Palette(L["One Dark"], '61afef', '56b6c2', '5c6370', 'abb2bf', '828997', '282c34', '282c34', '282c34', 'e06c75', '98c379')
-- https://github.com/rose-pine/neovim/blob/main/lua/rose-pine/palette.lua (main y moon).
-- iris, foam, pine, text, subtle, base, surface, overlay, love, rose.
lib.themes.rosepine = Palette(L["Rosé Pine"], 'c4a7e7', '9ccfd8', '31748f', 'e0def4', '908caa', '191724', '1f1d2e', '26233a', 'eb6f92', 'ebbcba')
lib.themes.rosepinemoon = Palette(L["Rosé Pine Moon"], 'c4a7e7', '9ccfd8', '3e8fb0', 'e0def4', '908caa', '232136', '2a273f', '393552', 'eb6f92', 'ea9a97')
-- https://github.com/catppuccin/palette/blob/main/palette.json (macchiato y frappe).
-- mauve, pink, overlay1, text, subtext0, base, mantle, surface0, red, green.
lib.themes.macchiato = Palette(L["Catppuccin Macchiato"], 'c6a0f6', 'f5bde6', '8087a2', 'cad3f5', 'a5adcb', '24273a', '1e2030', '363a4f', 'ed8796', 'a6da95')
lib.themes.frappe = Palette(L["Catppuccin Frappé"], 'ca9ee6', 'f4b8e4', '838ba7', 'c6d0f5', 'a5adce', '303446', '292c3c', '414559', 'e78284', 'a6d189')
-- https://github.com/rebelot/kanagawa.nvim/blob/master/lua/kanagawa/colors.lua
-- Wave: crystalBlue, springBlue, waveBlue2, fujiWhite, fujiGray, sumiInk3/0/4, samuraiRed, springGreen.
lib.themes.kanagawa = Palette(L["Kanagawa Wave"], '7e9cd8', '7fb4ca', '2d4f67', 'dcd7ba', '727169', '1f1f28', '16161d', '2a2a37', 'e82424', '98bb6c')
-- Dragon: dragonViolet/Blue2/Gray3/White/Gray2/Black3/Black0/Black4/Red/Green2.
lib.themes.kanagawadragon = Palette(L["Kanagawa Dragon"], '8992a7', '8ba4b0', '7a8382', 'c5c9c5', '9e9b93', '181616', '0d0c0c', '282727', 'c4746e', '8a9a7b')
-- Base oscura propia de KnuUI; el acento se resuelve con la clase de Blizzard.
lib.themes.class = Palette(L["Class colour"], 'ffa82e', 'ffa82e', 'ffa82e', 'ecd9bd', 'a88f70', '1f160e', '110c08', '33251a', 'e0523a', 'ffa82e')

-- Orden en el menú de opciones.
lib.themeOrder = { 'knunet', 'knunetIntense', 'neon', 'class', 'dracula', 'nord', 'catppuccin', 'gruvbox', 'tokyonight',
	'solarized', 'onedark', 'rosepine', 'rosepinemoon', 'macchiato', 'frappe', 'kanagawa', 'kanagawadragon' }

lib.C = C

lib.MOTION = { fade = 0.25, enter = 0.22, hover = 0.12, slide = 18 }

local function EaseOut(t) local u = 1 - t return 1 - u * u * u * u * u end

lib.tweens = lib.tweens or {}
lib.driver = lib.driver or CreateFrame('Frame')
local tweens, driver = lib.tweens, lib.driver
local function Step(_, elapsed)
	for key, tw in pairs(tweens) do
		tw.elapsed = tw.elapsed + elapsed
		local t = math.min(tw.elapsed / tw.duration, 1)
		if t >= 1 then
			tweens[key] = nil
			tw.apply(tw.to)
			if tw.done then tw.done() end
		else
			tw.apply(tw.from + (tw.to - tw.from) * EaseOut(t))
		end
	end
	if not next(tweens) then driver:SetScript('OnUpdate', nil) end
end

-- Anima un valor numérico. key identifica la animación (una nueva con la misma key la reemplaza,
-- desde el valor actual: interrumpible sin saltos).
function lib:Tween(key, from, to, duration, apply, done)
	tweens[key] = nil
	if duration <= 0 or from == to then apply(to) if done then done() end return end
	tweens[key] = { from = from, to = to, duration = duration, elapsed = 0, apply = apply, done = done }
	driver:SetScript('OnUpdate', Step)
end

-- Termina todas las animaciones en su valor final (para los tests y al recargar estados).
function lib:FlushTweens()
	local passes = 0
	while next(tweens) and passes < 100 do
		passes = passes + 1
		local pending = {}
		for key, tw in pairs(tweens) do pending[key] = tw end
		for key, tw in pairs(pending) do
			if tweens[key] == tw then
				tweens[key] = nil
				tw.apply(tw.to)
				if tw.done then tw.done() end
			end
		end
	end
	if not next(tweens) then driver:SetScript('OnUpdate', nil) end
end

function lib:FadeTo(frame, alpha, duration, done)
	if not frame then return end
	self:Tween(frame, frame:GetAlpha(), alpha, duration or self.MOTION.fade, function(v) frame:SetAlpha(v) end, done)
end

-- Entrada: aparece y se desliza desde la derecha hasta su punto. point = { punto, ancla, punto relativo, x, y }.
function lib:SlideIn(frame, point, duration, done)
	local p, rel, rp = point[1], point[2], point[3]
	local x, y = point[4] or 0, point[5] or 0
	frame:SetAlpha(0)
	frame:Show()
	self:Tween(frame, 0, 1, duration or self.MOTION.enter, function(v)
		frame:ClearAllPoints()
		frame:SetPoint(p, rel, rp, x + (1 - v) * self.MOTION.slide, y)
		frame:SetAlpha(v)
	end, done)
end

-- Respuesta al mouse: el borde pasa al color de acento y aparece un brillo suave; vuelve al salir.
-- Sólo colores y alfa de texturas propias: sirve también en botones seguros y en combate.
function lib:Hoverable(button)
	if not button or button.KnuHover then return end
	button.KnuHover = true
	local glow = button:CreateTexture(nil, 'HIGHLIGHT')
	glow:SetAllPoints()
	glow:SetBlendMode('ADD')
	button.KnuGlow = glow
	-- Los controles estilizados vuelven al borde del tema actual; los demás, a su color previo.
	local base
	local function Paint(v)
		local t = lib:GetTheme()
		local hi = t.accentHi or t.accent
		local r, g, b = t.border.r, t.border.g, t.border.b
		if not lib.frames[button] and base then r, g, b = unpack(base) end
		if button.SetBackdropBorderColor then
			button:SetBackdropBorderColor(r + (hi.r - r) * v, g + (hi.g - g) * v, b + (hi.b - b) * v)
		end
		glow:SetColorTexture(t.accent.r, t.accent.g, t.accent.b, 0.18 * v)
	end
	button.KnuHoverLevel = 0
	local function To(target)
		if target > 0 and button.KnuHoverLevel == 0 and not lib.frames[button] then
			base = nil
			if button.GetBackdropBorderColor then
				local r, g, b = button:GetBackdropBorderColor()
				if r then base = { r, g, b } end
			end
		end
		lib:Tween(button, button.KnuHoverLevel, target, lib.MOTION.hover, function(v) button.KnuHoverLevel = v; Paint(v) end)
	end
	button:HookScript('OnEnter', function() To(1) end)
	button:HookScript('OnLeave', function() To(0) end)
	glow:SetColorTexture(0, 0, 0, 0)
end


if next(tweens) then driver:SetScript('OnUpdate', Step) end

lib.callbacks = lib.callbacks or {}
lib.frames = lib.frames or setmetatable({}, { __mode = 'k' })
lib.themeKey = lib.themeKey or 'knunet'

local classToken
local classFallback = C('ffa82e')
local classFields = { 'accent', 'accentHi', 'accentDim', 'cast', 'health' }
local function ClassTheme()
    local _, token
    if UnitClass then _, token = UnitClass('player') end
    if token and token == classToken then return end
    classToken = token
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    c = c or classFallback
    for _, field in ipairs(classFields) do
        local color = lib.themes.class[field]
        color.r, color.g, color.b, color.a = c.r, c.g, c.b, 1
    end
end
ClassTheme()

function lib:GetTheme()
    ClassTheme()
    if self.provider then
        local theme = self.provider()
        if type(theme) == 'table' then return theme end
    end
    return self.themes[self.themeKey] or self.themes.knunet
end

function lib:RegisterCallback(fn)
    assert(type(fn) == 'function', 'Se esperaba una función')
    self.callbacks[#self.callbacks + 1] = fn
end

function lib:RefreshTheme()
    local theme = self:GetTheme()
    for frame, styles in pairs(self.frames) do
        for style in pairs(styles) do
            if self[style] then pcall(self[style], self, frame) end
        end
    end
    for i = 1, #self.callbacks do pcall(self.callbacks[i], theme) end
end

function lib:SetThemeKey(key)
    if not self.themes[key] or self.themeKey == key then return end
    self.themeKey = key
    self:RefreshTheme()
end

function lib:SetThemeProvider(fn)
    assert(fn == nil or type(fn) == 'function', 'Se esperaba una función o nil')
    self.provider = fn
    self:RefreshTheme()
end

function lib:GetFont()
    local lsm = LibStub('LibSharedMedia-3.0', true)
    if lsm and lsm.Fetch then
        local valid = not lsm.IsValid or lsm:IsValid('font', 'Expressway')
        if valid then
            local path = lsm:Fetch('font', 'Expressway', true)
            if path then return path end
        end
    end
    return STANDARD_TEXT_FONT
end

function lib:NewPrinter(name)
    local prefix = '|cffecd9bdKNU|r|cffffa82e' .. name .. '|r: '
    return function(...)
        local args = {}
        for i = 1, select('#', ...) do args[i] = tostring(select(i, ...)) end
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. table.concat(args, ' '))
    end
end

-- Estado compartido entre copias embebidas y upgrades de LibStub.
lib.commands = lib.commands or {}
lib.commandAliases = lib.commandAliases or {}
lib.defaultCommand = lib.defaultCommand or nil
lib.legacySlash = lib.legacySlash or nil

function lib:RegisterCommand(name, handler, help, aliases)
    assert(type(name) == 'string' and strtrim(name) ~= '', 'Se esperaba un nombre no vacío')
    assert(type(handler) == 'function', 'Se esperaba una función')
    assert(help == nil or type(help) == 'string', 'Se esperaba un texto de ayuda o nil')
    assert(aliases == nil or type(aliases) == 'table', 'Se esperaba una tabla de alias')
    local normalized = {}
    for _, alias in ipairs(aliases or {}) do
        assert(type(alias) == 'string', 'Se esperaba un alias de texto')
        normalized[#normalized + 1] = string.lower(strtrim(alias))
    end
    name = string.lower(strtrim(name))
    local previous, freed = self.commands[name], {}
    for _, alias in ipairs(previous and previous.aliases or {}) do
        if self.commandAliases[alias] == name then
            self.commandAliases[alias] = nil
            freed[#freed + 1] = alias
        end
    end
    self.commandAliases[name] = nil -- Los nombres siempre ganan frente a los alias.
    if help == '' then help = nil end
    local command = { name = name, handler = handler, help = help, aliases = {}, wanted = normalized }
    self.commands[name] = command
    -- Un alias es del primer comando que lo pidió; no se roba ni se repite.
    for _, alias in ipairs(normalized) do
        if alias ~= '' and not self.commands[alias] and not self.commandAliases[alias] then
            self.commandAliases[alias] = name
            command.aliases[#command.aliases + 1] = alias
        end
    end
    -- Los alias que este comando soltó pasan al primero (por nombre) que también los pidió
    -- (en comandos heredados de minor 3, sin `wanted`, se usa su lista `aliases`).
    local names = {}
    for other in pairs(self.commands) do names[#names + 1] = other end
    table.sort(names)
    for _, alias in ipairs(freed) do
        for _, other in ipairs(names) do
            local candidate = self.commands[other]
            if self.commandAliases[alias] or self.commands[alias] then break end
            for _, wanted in ipairs(candidate.wanted or candidate.aliases or {}) do
                if wanted == alias then
                    self.commandAliases[alias] = other
                    candidate.aliases[#candidate.aliases + 1] = alias
                    break
                end
            end
        end
    end
end

function lib:SetDefaultCommand(handler)
    assert(handler == nil or type(handler) == 'function', 'Se esperaba una función o nil')
    self.defaultCommand = handler
end

function lib:PrintCommands()
    local Print, names = self:NewPrinter(''), {}
    for name in pairs(self.commands) do names[#names + 1] = name end
    table.sort(names)
    if #names == 0 then Print('No hay comandos registrados.') return end
    for _, name in ipairs(names) do
        local command, aliases, seen = self.commands[name], {}, {}
        for _, alias in ipairs(command.aliases) do
            if self.commandAliases[alias] == name and not seen[alias] then
                seen[alias] = true
                aliases[#aliases + 1] = alias
            end
        end
        local suffix = #aliases > 0 and (' (alias: ' .. table.concat(aliases, ', ') .. ')') or ''
        local help = type(command.help) == 'string' and command.help ~= '' and (' - ' .. command.help) or ''
        Print('/knu ' .. name .. suffix .. help)
    end
end

function lib:Dispatch(msg, editBox)
    msg = strtrim(msg or '')
    local name, rest = msg:match('^(%S+)%s*(.*)$')
    name = string.lower(name or '')
    local command = self.commands[name] or self.commands[self.commandAliases[name]]
    if command then return command.handler(strtrim(rest or ''), editBox) end
    if name == 'help' or name == 'ayuda' then return self:PrintCommands() end
    if self.defaultCommand then return self.defaultCommand(msg, editBox) end
    if self.legacySlash then return self.legacySlash(msg, editBox) end
    return self:PrintCommands()
end

lib.slashHandler = lib.slashHandler or function(msg, editBox) return lib:Dispatch(msg, editBox) end

function lib:ClaimSlash()
    if hash_SlashCmdList then
        local cur = hash_SlashCmdList['/KNU']
        if cur and cur ~= self.slashHandler then self.legacySlash = cur end
        hash_SlashCmdList['/KNU'] = self.slashHandler
    end
    if not self.legacySlash and type(SlashCmdList.KNUUI) == 'function' then
        local i = 1
        while _G['SLASH_KNUUI' .. i] do
            if string.lower(_G['SLASH_KNUUI' .. i]) == '/knu' then
                self.legacySlash = SlashCmdList.KNUUI
                break
            end
            i = i + 1
        end
    end
end

if not lib.slashRegistered then
    SLASH_KNULIB1 = '/knu'
    SlashCmdList.KNULIB = lib.slashHandler
    lib.slashRegistered = true
end
-- Después de cada importación de Blizzard, /knu vuelve a KnuLib. Se reintenta en PLAYER_LOGIN
-- por si ChatFrameUtil todavía no existía cuando cargó la librería.
function lib:HookSlashImport()
    if not self.slashHooked and ChatFrameUtil and ChatFrameUtil.ImportAllListsToHash then
        hooksecurefunc(ChatFrameUtil, 'ImportAllListsToHash', function() lib:ClaimSlash() end)
        self.slashHooked = true
    end
end
lib:HookSlashImport()
if not lib.commandFrame then
    lib.commandFrame = CreateFrame('Frame')
    lib.commandFrame:RegisterEvent('PLAYER_LOGIN')
    lib.commandFrame:SetScript('OnEvent', function() lib:HookSlashImport(); lib:ClaimSlash() end)
end
lib:ClaimSlash()

local backdrop = { bgFile = 'Interface\\Buttons\\WHITE8X8',
    edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1 }
local function Prepare(frame, style)
    local styles = lib.frames[frame]
    if not styles then
        styles = {}; lib.frames[frame] = styles
        if not frame.SetBackdrop and Mixin and BackdropTemplateMixin then
            Mixin(frame, BackdropTemplateMixin)
        end
        if frame.SetBackdrop then frame:SetBackdrop(backdrop) end
    end
    local first = not styles[style]
    styles[style] = true
    return first
end
local function Color(frame, method, c)
    if frame and frame[method] then frame[method](frame, c.r, c.g, c.b, c.a or 1) end
end
local function Text(frame)
    return frame.GetFontString and frame:GetFontString() or frame.Text or frame.text
end
local function PaintText(text, c)
    if type(text) ~= 'table' and type(text) ~= 'userdata' then return end
    Color(text, 'SetTextColor', c)
    if text.SetFont then
        local _, size, flags
        if text.GetFont then _, size, flags = text:GetFont() end
        text:SetFont(lib:GetFont(), size or 12, flags or '')
    end
end

function lib:StylePanel(frame)
    Prepare(frame, 'StylePanel')
    local t = self:GetTheme()
    Color(frame, 'SetBackdropColor', t.backdropFade or t.backdrop)
    Color(frame, 'SetBackdropBorderColor', t.border)
    return frame
end

function lib:StyleButton(button)
    local first = Prepare(button, 'StyleButton')
    local t = self:GetTheme()
    local function HideTexture(texture)
        if texture then
            if texture.SetAlpha then texture:SetAlpha(0) elseif texture.Hide then texture:Hide() end
        end
    end
    local buttonName = button.GetName and button:GetName()
    for _, name in ipairs({ 'Left', 'Middle', 'Right' }) do
        HideTexture(button[name])
        if buttonName then HideTexture(_G[buttonName .. name]) end
    end
    for _, name in ipairs({ 'Normal', 'Pushed', 'Highlight', 'Disabled' }) do
        local getter = button['Get' .. name .. 'Texture']
        if getter then HideTexture(getter(button)) end
    end
    local enabled = not button.IsEnabled or button:IsEnabled()
    Color(button, 'SetBackdropColor', t.backdrop)
    Color(button, 'SetBackdropBorderColor', enabled and button.KnuLibInside and t.accent or t.border)
    PaintText(Text(button), enabled and t.text or t.muted)
    if first then
        button:HookScript('OnEnter', function(b) b.KnuLibInside = true; lib:StyleButton(b) end)
        button:HookScript('OnLeave', function(b) b.KnuLibInside = nil; lib:StyleButton(b) end)
        for _, method in ipairs({ 'Enable', 'Disable', 'SetEnabled' }) do
            if button[method] and hooksecurefunc then
                hooksecurefunc(button, method, function() lib:StyleButton(button) end)
            end
        end
    end
    return button
end

function lib:StyleCheck(check)
    Prepare(check, 'StyleCheck')
    local t = self:GetTheme()
    Color(check, 'SetBackdropColor', t.backdrop)
    Color(check, 'SetBackdropBorderColor', t.border)
    local texture = check.GetCheckedTexture and check:GetCheckedTexture()
    Color(texture, 'SetVertexColor', t.accent)
    local name = check.GetName and check:GetName()
    PaintText(Text(check) or (name and _G[name .. 'Text']), t.text)
    return check
end

-- Los hooks ya instalados consultan siempre las funciones actuales de la misma tabla.
lib:RefreshTheme()

