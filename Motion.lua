local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Movimiento y terminación comunes para todo lo que dibuja KnuUI.
-- Valores (reglas de motion del user, criterio Emil Kowalski): curva de salida suave, el equivalente
-- en Lua de cubic-bezier(0.23,1,0.32,1) aproximado con ease-out quíntica; interfaz <= 300 ms.
--   Fundidos de bloques 250 ms · entrada de avisos 220 ms · respuesta al mouse 120 ms.
-- Todo es SetAlpha / SetPoint / colores sobre marcos propios o no protegidos: vale en combate y no
-- contamina nada. Un solo marco propio maneja todas las animaciones (nunca el OnUpdate de otro).
K.MOTION = { fade = 0.25, enter = 0.22, hover = 0.12, slide = 18 }

local function EaseOut(t) local u = 1 - t return 1 - u * u * u * u * u end

local tweens, driver = {}, CreateFrame('Frame')
local function Step(_, elapsed)
	local any
	for key, tw in pairs(tweens) do
		tw.elapsed = tw.elapsed + elapsed
		local t = math.min(tw.elapsed / tw.duration, 1)
		tw.apply(tw.from + (tw.to - tw.from) * EaseOut(t))
		if t >= 1 then
			tweens[key] = nil
			if tw.done then tw.done() end
		else
			any = true
		end
	end
	if not any then driver:SetScript('OnUpdate', nil) end
end

-- Anima un valor numérico. key identifica la animación (una nueva con la misma key la reemplaza,
-- desde el valor actual: interrumpible sin saltos).
function K:Tween(key, from, to, duration, apply, done)
	if duration <= 0 or from == to then apply(to) if done then done() end return end
	tweens[key] = { from = from, to = to, duration = duration, elapsed = 0, apply = apply, done = done }
	driver:SetScript('OnUpdate', Step)
end

-- Termina todas las animaciones en su valor final (para los tests y al recargar estados).
function K:FlushTweens()
	for key, tw in pairs(tweens) do
		tweens[key] = nil
		tw.apply(tw.to)
		if tw.done then tw.done() end
	end
end

function K:FadeTo(frame, alpha, duration, done)
	if not frame then return end
	self:Tween(frame, frame:GetAlpha(), alpha, duration or self.MOTION.fade, function(v) frame:SetAlpha(v) end, done)
end

-- Entrada: aparece y se desliza desde la derecha hasta su punto. point = { punto, ancla, punto relativo, x, y }.
function K:SlideIn(frame, point, duration)
	local p, rel, rp, x, y = unpack(point)
	frame:SetAlpha(0)
	frame:Show()
	self:Tween(frame, 0, 1, duration or self.MOTION.enter, function(v)
		frame:ClearAllPoints()
		frame:SetPoint(p, rel, rp, x + (1 - v) * self.MOTION.slide, y)
		frame:SetAlpha(v)
	end)
end

-- Respuesta al mouse: el borde pasa al color de acento y aparece un brillo suave; vuelve al salir.
-- Sólo colores y alfa de texturas propias: sirve también en botones seguros y en combate.
function K:Hoverable(button)
	if not button or button.KnuHover then return end
	button.KnuHover = true
	local glow = button:CreateTexture(nil, 'HIGHLIGHT')
	glow:SetAllPoints()
	glow:SetBlendMode('ADD')
	button.KnuGlow = glow
	-- El borde vuelve al color que tenía ese botón (la K y los accesos usan el acento, otros el borde).
	local base
	local function Paint(v)
		local t = K:GetTheme()
		local hi = t.accentHi or t.accent
		if base and button.SetBackdropBorderColor then
			button:SetBackdropBorderColor(base[1] + (hi.r - base[1]) * v, base[2] + (hi.g - base[2]) * v, base[3] + (hi.b - base[3]) * v)
		end
		glow:SetColorTexture(t.accent.r, t.accent.g, t.accent.b, 0.18 * v)
	end
	button.KnuHoverLevel = 0
	local function To(target)
		if target > 0 and button.KnuHoverLevel == 0 and button.GetBackdropBorderColor then
			local r, g, b = button:GetBackdropBorderColor()
			if r then base = { r, g, b } end
		end
		K:Tween(button, button.KnuHoverLevel, target, K.MOTION.hover, function(v) button.KnuHoverLevel = v; Paint(v) end)
	end
	button:HookScript('OnEnter', function() To(1) end)
	button:HookScript('OnLeave', function() To(0) end)
	glow:SetColorTexture(0, 0, 0, 0)
end

-- Marco con identidad KnuUI: línea de acento de 1 px arriba y la sombra suave de Decor.lua
-- (CreateShadow(3, true), alfa 0.25). Se recolorea con el tema en K:StyleMotionFrames.
local framed = {}
function K:KnuFrame(frame)
	if not frame or framed[frame] then return end
	framed[frame] = true
	local line = frame:CreateTexture(nil, 'OVERLAY')
	line:SetPoint('TOPLEFT', frame, 'TOPLEFT', 1, -1)
	line:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, -1)
	line:SetHeight(1)
	frame.KnuAccentLine = line
	if type(frame.CreateShadow) == 'function' and not frame.KnuShadow then
		frame.KnuShadow = frame:CreateShadow(3, true)
		if frame.KnuShadow then frame.KnuShadow:SetAlpha(0.25) end
	end
	self:StyleMotionFrame(frame)
end

function K:StyleMotionFrame(frame)
	local t = self:GetTheme()
	if frame.KnuAccentLine then frame.KnuAccentLine:SetColorTexture(t.accent.r, t.accent.g, t.accent.b, 0.7) end
end

function K:StyleMotionFrames()
	for frame in pairs(framed) do self:StyleMotionFrame(frame) end
end
