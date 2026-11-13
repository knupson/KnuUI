-- Ejecutar desde la raíz del repo con Lua 5.1 (LuaJIT). Sin WoW.
-- Exportar/importar (Share.lua): el texto lleva las opciones KnuUI* del perfil aunque el exportador de ElvUI
-- las descarte (pasó en el juego 2026-11-13), no lleva el estado interno del centro de comando, y al importar
-- se crea un perfil nuevo sin pisar el existente.
local K = {}
local D = { blacklistedKeys = { profile = {} } }
E = { global = { KnuUIClock = true, datatexts = { customPanels = { KnuUI_Data = { width = 971 } } } }, private = { KnuUIRole = 'tank' } }
function E:GetModule(name) if name == 'KnuUI' then return K end if name == 'Distributor' then return D end return {} end
function E:CopyTable(dst, src) for k, v in pairs(src) do dst[k] = type(v) == 'table' and self:CopyTable({}, v) or v end return dst end
function E:FilterTableFromBlacklist(t) return t end
ElvUI = { E }
local u = unpack; function unpack(t) if t == ElvUI then return E end return u(t) end
format = string.format
InCombatLockdown = function() return false end
ElvDB = { profiles = { Default = {
	general = { font = 'Expressway' }, KnuUILayoutVersion = 29, KnuUITanks = true,
	KnuUICC = { preset = 'full', sizeOrig = { panelWidth = 1 }, questLogOpen = '1', autoresizeFixed = true },
} } }
-- ElvUI devuelve el perfil sin las claves que no conoce (Core.lua:859-860).
function D:GetProfileData() return 'Default', { general = { font = 'Expressway' } } end
-- Codificación de identidad: el texto es la tabla misma, así se puede revisar.
local store
C_EncodingUtil = {
	SerializeCBOR = function(t) store = t return 'x' end, DeserializeCBOR = function() return store end,
	CompressString = function(s) return s end, DecompressString = function(s) return s end,
	EncodeBase64 = function(s) return s end, DecodeBase64 = function(s) return s end,
}
local switched
E.data = { SetProfile = function(_, name) switched = name end }
local ns = { L = setmetatable({}, { __index = function(_, k) return k end }) }
loadfile('addons/KnuUI/Share.lua')('KnuUI', ns)

local text = assert(K:ExportString())
assert(text:sub(1, 6) == '!KNU1!', 'prefijo')
local p = store.profile
assert(p.KnuUILayoutVersion == 29 and p.KnuUITanks == true, 'faltan opciones KnuUI del perfil')
assert(p.KnuUICC and p.KnuUICC.preset == 'full', 'falta KnuUICC')
assert(p.KnuUICC.sizeOrig == nil and p.KnuUICC.questLogOpen == nil and p.KnuUICC.autoresizeFixed == nil, 'exporta estado interno')
assert(ElvDB.profiles.Default.KnuUICC.sizeOrig, 'tocó el perfil original al exportar')
assert(store.private.KnuUIRole == 'tank' and store.global.KnuUIClock == true and store.panels.KnuUI_Data.width == 971)

-- Importar en otra PC: valores globales vacíos también se copian y el perfil no pisa el existente.
E.global.KnuUIClock = false
store.global.KnuUIClock = nil
local name = assert(K:ImportString(text))
assert(name == 'Default (2)' and switched == 'Default (2)', 'nombre de perfil: '..tostring(name))
assert(ElvDB.profiles.Default.KnuUICC.sizeOrig, 'pisó el perfil existente')
assert(E.global.KnuUIClock == nil, 'no copió el valor global vacío')
assert(not K:ImportString('basura'), 'aceptó un texto inválido')
print('COMPARTIR OK')
