-- Localization for KnuUI. English is the key and the default: a missing key returns itself.
-- Only the Spanish (esES / esMX) values are defined here; every other client locale shows English.
-- Localización de KnuUI: el inglés es la clave y el valor por defecto; el castellano va abajo.
local _, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

local locale = GetLocale and GetLocale() or 'enUS'
if locale ~= 'esES' and locale ~= 'esMX' then return end

-- Core.lua
L["KnuUI requires World of Warcraft: Forever."] = "KnuUI requiere World of Warcraft: Forever."
L["Leave combat before applying KnuUI."] = "Salí de combate antes de aplicar KnuUI."
L["KnuUI: %s failed: %s"] = "KnuUI: falló %s: %s"

-- Theme.lua
L["Knunet amber"] = "Knunet ámbar"
L["Neon cyan and magenta"] = "Neón cian y magenta"

-- Camera.lua
L["KnuUI: DynamicCam is not installed."] = "KnuUI: DynamicCam no está instalado."
L["KnuUI: leave combat to apply the camera."] = "KnuUI: salí de combate para aplicar la cámara."
L["KnuUI: the DynamicCam API was not found."] = "KnuUI: no se encontró la API de DynamicCam."
L["KnuUI: could not apply the camera: %s"] = "KnuUI: no se pudo aplicar la cámara: %s"
L['KnuUI: camera "%s" applied to DynamicCam profile "%s".'] = 'KnuUI: cámara "%s" aplicada en el perfil "%s" de DynamicCam.'

-- Compat.lua
L["not installed or not loaded"] = "no instalado o no cargado"
L["incompatible API; the adjustment could not be completed"] = "API incompatible; no se pudo completar el ajuste"
L["texture and font applied; the dock keeps its anchors"] = "textura y fuente aplicadas; el dock conserva los anclajes"
L["no existing windows; no windows were created"] = "sin ventanas existentes; no se crearon ventanas"
L["includes its own ElvUI skin; pick it in Baganator. Your bags are kept"] = "incluye skin ElvUI propia; elegila en Baganator. Se conservan sus bolsas"
L["position saved below the minimap; reload to see it"] = "posición guardada bajo el minimapa; recargá para verla"
L["position saved to the left of WoW-Pro; reload to see it"] = "posición guardada a la izquierda de WoW-Pro; recargá para verla"

-- Decor.lua
L["World map"] = "Mapa del mundo"
L["KnuUI: could not refresh the decoration: %s"] = "KnuUI: no se pudo actualizar la decoración: %s"

-- Skins/Panels.lua
L["KnuUI: could not update the panels: %s"] = "KnuUI: no se pudieron actualizar los paneles: %s"

-- Tanks.lua
L["KnuUI: mana tank"] = "KnuUI: tanque de maná"

-- Buttons.lua (launcher)
L["ElvUI settings"] = "Configuración de ElvUI"
L["Addon list"] = "Lista de addons"
L["Toggle AFK"] = "Alternar ausente"
L["Roll dice from 1 to 100"] = "Tirar dados de 1 a 100"
L["Reload UI"] = "Recargar interfaz"
L["KnuUI installer"] = "Asistente de KnuUI"
L["‹ Previous"] = "‹ Anterior"
L["%d/%d · Next ›"] = "%d/%d · Siguiente ›"
L["KnuUI: could not open that action; check the corresponding addon."] = "KnuUI: no se pudo abrir esa acción; revisá el addon correspondiente."
L["KnuUI launcher"] = "Lanzador KnuUI"

-- Dock.lua
L["could not complete the docking: %s"] = "no se pudo completar el acoplamiento: %s"
L["Details skin: %s"] = "skin de Details: %s"
L["enabled"] = "activo"
L["disabled"] = "inactivo"
L["active"] = "activa"
L["inactive"] = "inactiva"
L["Status: %s | Split: %.2f (%d%%) | ElvUI or Details! is missing."] = "Estado: %s | División: %.2f (%d%%) | Falta ElvUI o Details!."
L["Status: %s | Window 1 split: %.2f (%d%%) | Window 1: %s | Window 2: %s."] = "Estado: %s | División ventana 1: %.2f (%d%%) | Ventana 1: %s | Ventana 2: %s."
L["Usage: /knudock on | /knudock off | /knudock split <0.2-0.8>"] = "Uso: /knudock on | /knudock off | /knudock split <0.2-0.8>"
L["ElvUI or Details! was not found. Docking is unavailable."] = "No se encontró ElvUI o Details!. El acoplamiento no está disponible."
L["Docking enabled in the ElvUI right panel."] = "Acoplamiento activado en el panel derecho de ElvUI."
L["Docking disabled and windows restored."] = "Acoplamiento desactivado y ventanas restauradas."
L["Invalid value. Use a number between 0.2 and 0.8 (example: /knudock split 0.6)."] = "Valor inválido. Usá un número entre 0.2 y 0.8 (ejemplo: /knudock split 0.6)."
L["Width split for window 1 saved at %.2f (%d%%)."] = "División de ancho para la ventana 1 guardada en %.2f (%d%%)."
L["Unknown subcommand. Usage: /knudock [on | off | split <0.2-0.8>]"] = "Subcomando desconocido. Uso: /knudock [on | off | split <0.2-0.8>]"
L["ForeverDock is loaded: the built-in dock stays inactive. You can disable ForeverDock."] = "ForeverDock está cargado: el dock propio queda inactivo. Podés deshabilitar ForeverDock."

-- Installer.lua: general
L["yes"] = "sí"
L["no"] = "no"
L["KnuUI: settings saved. Reload from the Done page to see them."] = "KnuUI: ajustes guardados. Recargá desde la página Listo para verlos."
L["Welcome"] = "Bienvenida"
L["Layout"] = "Diseño"
L["Theme"] = "Tema"
L["Chat and data"] = "Chat y datos"
L["Addons"] = "Addons"
L["Done"] = "Listo"

-- Installer.lua: page 1
L["Your interface, with KnuUI identity"] = "Tu interfaz, con identidad KnuUI"
L["Compact layout for Forever: combat in the centre and chats in the corners."] = "Diseño compacto para Forever: combate al centro y chats en las esquinas."
L["Apply each section with its buttons or install everything with a confirmation."] = "Aplicá cada sección con sus botones o instalá todo con confirmación."
L["Changes are saved to the current profile and show up after a reload."] = "Los cambios se guardan en el perfil actual y se ven al recargar."
L["Apply all"] = "Aplicar todo"
L["Go to Layout"] = "Ir a Diseño"

-- Installer.lua: page 2
L["Compact layout · sketch v4"] = "Diseño compacto · boceto v4"
L["Keeps the coordinates and measurements of the current design for 1920×1080."] = "Conserva las coordenadas y medidas del diseño actual para 1920×1080."
L["Bars, units, auras, party, raid, minimap and experience."] = "Barras, unidades, auras, grupo, banda, minimapa y experiencia."
L["Chat and colours are applied on their own pages."] = "El chat y los colores se aplican en sus propias páginas."
L["Nameplates"] = "Placas"

-- Installer.lua: role page (Roles.lua)
L["Role"] = "Rol"
L["Role: %s"] = "Rol: %s"
L["Tank: threat borders on frames and plates. MDPS: the base layout."] = "Tank: bordes de amenaza en marcos y placas. MDPS: el diseño base."
L["RDPS: bigger cast bar and target debuffs. Healer: party and raid in the centre."] = "RDPS: barra de lanzamiento y perjuicios del objetivo más grandes. Healer: grupo y banda al centro."
L["Healer turns on incoming heals and HoT indicators. Reload to see it."] = "Healer activa la curación entrante y los indicadores de HoT. Recargá para verlo."
L["Columns on"] = "Columnas sí"
L["Columns off"] = "Columnas no"

-- Installer.lua: menú de opciones en pestañas
L["Compact layout for WoW Forever. Changes are saved to the current ElvUI profile and most of them show after a reload."] = "Diseño compacto para WoW Forever. Los cambios se guardan en el perfil actual de ElvUI y la mayoría se ve al recargar."
L["General"] = "General"
L["Install or reapply KnuUI. The installer walks you through every section."] = "Instalá o reaplicá KnuUI. El asistente te lleva por cada sección."
L["Apply layout, theme, chat and addon settings, then reload."] = "Aplica diseño, tema, chat y ajustes de addons, y recarga."
L["Tank: threat borders. MDPS: the base layout. RDPS: bigger cast bar and target debuffs. Healer: party and raid in the centre with incoming heals."] = "Tank: bordes de amenaza. MDPS: el diseño base. RDPS: barra de lanzamiento y perjuicios del objetivo más grandes. Healer: grupo y banda al centro con curación entrante."
L["Health and mana columns"] = "Columnas de vida y maná"
L["Vertical health and mana bars next to the main bars, with larger side blocks of buttons."] = "Barras verticales de vida y maná junto a las barras principales, con bloques laterales de botones más grandes."
L["Use health and mana columns"] = "Usar columnas de vida y maná"
L["Compact left block (3×4): wider left chat"] = "Bloque izquierdo compacto (3×4): chat izquierdo más ancho"
L["Compact right block (3×4): wider Details"] = "Bloque derecho compacto (3×4): Details más ancho"
L["Positions"] = "Posiciones"
L["Puts bars, frames and panels back in their KnuUI positions."] = "Devuelve barras, marcos y paneles a sus posiciones de KnuUI."
L["Reapply nameplates"] = "Reaplicar placas de nombre"
L["Appearance"] = "Apariencia"
L["Colours, decoration and visual effects."] = "Colores, decoración y efectos visuales."
L["Health bars in class colour"] = "Barras de vida con el color de la clase"
L["Decoration: minimap corners, stripes and shadows"] = "Decoración: esquinas del minimapa, franjas y sombras"
L["Reapply chat and Details panels"] = "Reaplicar paneles de chat y Details"
L["How KnuUI looks after other addons. Skins need a reload."] = "Cómo integra KnuUI a otros addons. Las skins necesitan recargar."
L["Skins for supported addons (Auctionator, BugSack, Pawn, Questie...)"] = "Skins para addons compatibles (Auctionator, BugSack, Pawn, Questie...)"
L["DBM bars with KnuUI texture and font"] = "Barras de DBM con la textura y la letra de KnuUI"
L["This writes DBM's own settings."] = "Esto cambia la configuración propia de DBM."
L["Quest tracker"] = "Rastreador de misiones"
L["Always show"] = "Mostrar siempre"
L["Hide when WoW-Pro is loaded"] = "Ocultar si WoW-Pro está cargado"
L["Camera"] = "Cámara"
L["DynamicCam presets (needs DynamicCam). Applied to a DynamicCam profile called KnuUI."] = "Configuraciones de DynamicCam (hace falta DynamicCam). Se aplican en un perfil de DynamicCam llamado KnuUI."
L["Camera preset"] = "Configuración de cámara"
L["Cinematic (Shushudaa)"] = "Cinematográfica (Shushudaa)"
L["Soft immersive"] = "Inmersiva suave"
L["Classic (almost no ActionCam)"] = "Clásica (casi sin ActionCam)"
L["Cinema mode"] = "Modo cine"
L["Hides the interface and slowly orbits the camera; it ends when you enter combat. Also /knu cine or a key binding (Key Bindings > AddOns > KnuUI)."] = "Oculta la interfaz y gira la cámara despacio; se corta al entrar en combate. También con /knu cine o una tecla (Teclado > AddOns > KnuUI)."
L["Start cinema mode"] = "Activar modo cine"

-- Tanks.lua: bloques compactos
L["Frees 129 px for the left chat; the data bar shrinks the same."] = "Libera 129 px para el chat izquierdo; la barra de datos se achica lo mismo."
L["Frees 129 px for Details; the data bar shrinks the same."] = "Libera 129 px para Details; la barra de datos se achica lo mismo."

-- Extras.lua
L["%d min"] = "%d min"
L["%d h %d min"] = "%d h %d min"
L["KnuUI: estimate after a minute of gaining experience"] = "KnuUI: la estimación aparece tras un minuto ganando experiencia"
L["Experience per hour"] = "Experiencia por hora"
L["Next level in"] = "Próximo nivel en"
L["KnuUI: this character's role is %s; reload to see it."] = "KnuUI: el rol de este personaje es %s; recargá para verlo."
L["Cinema mode (hide the interface and orbit the camera)"] = "Modo cine (oculta la interfaz y gira la cámara)"
L["Combat glow on the screen edges"] = "Aviso de combate en los bordes de la pantalla"

-- Installer.lua: page 3
L["Theme: Knunet amber or Neon"] = "Tema: Knunet ámbar o Neón"
L["Dark backgrounds, thin borders, Expressway font and Melli texture."] = "Fondos oscuros, bordes finos, fuente Expressway y textura Melli."
L["Knunet: amber on warm black, like knunet.com. Neon: cyan and magenta."] = "Knunet: ámbar sobre negro cálido, como knunet.com. Neón: cian y magenta."
L["Includes the AFK screen with the KnuUI logo. Class health or theme health."] = "Incluye la pantalla de ausente con logo KnuUI. Salud por clase o del tema."
L["Neon"] = "Neón"
L["Class health"] = "Salud por clase"
L["Theme health"] = "Salud del tema"
L["Decoration: %s"] = "Decoración: %s"

-- Installer.lua: page 4
L["Chat and data, hand-tuned"] = "Chat y datos a mano"
L["400×180 chats, edit box above, and panels with the same background and tabs."] = "Chats de 400×180, edición arriba y paneles con el mismo fondo y pestañas."
L["Central 1100×22 bar with eight data points; time and coordinates on the minimap."] = "Barra central de 1100×22 con ocho datos; hora y coordenadas en minimapa."
L["Replaces the previous data panels, including ForeverUI_Data."] = "Reemplaza los paneles de datos anteriores, incluido ForeverUI_Data."
L["Apply chat and data"] = "Aplicar chat y datos"
L["Integrated panels"] = "Paneles integrados"

-- Installer.lua: page 5
L["Your addons, integrated"] = "Tus addons, integrados"
L["Details!: font and texture. Baganator and DBM: compatibility information."] = "Details!: fuente y textura. Baganator y DBM: información de compatibilidad."
L["WoW-Pro and Questie: save their position below the minimap on reload."] = "WoW-Pro y Questie: guardan su posición bajo el minimapa al recargar."
L["Each button only affects the addon shown."] = "Cada botón actúa sólo sobre el addon indicado."
L["WoW-Pro skin"] = "Skin WoW-Pro"
L["WoW-Pro skin: %s"] = "Skin WoW-Pro: %s"
L["KnuUI: WoW-Pro skin enabled."] = "KnuUI: skin WoW-Pro activada."
L["KnuUI: WoW-Pro skin disabled; reload to restore its appearance."] = "KnuUI: skin WoW-Pro desactivada; recargá para restaurar su apariencia."
L[" · not installed"] = " · no instalado"

-- Installer.lua: page 6
L["Ready to play"] = "Listo para jugar"
L["Reload to activate the sections you chose."] = "Recargá para activar las secciones que elegiste."
L["You can come back with /knu or from ElvUI → KnuUI."] = "Podés volver con /knu o desde ElvUI → KnuUI."
L["Reloading marks this installer version as reviewed."] = "La recarga marca esta versión del asistente como revisada."
L["Finish and reload"] = "Terminar y recargar"

-- Installer.lua: ElvUI options
L["Open installer"] = "Abrir asistente"
L["Reapply layout"] = "Reaplicar diseño"

-- Installer.lua: popup
L["Do you want to apply the layout, theme, chat/data and compatible addon settings to the current profile and reload?"] = "¿Querés aplicar diseño, tema, chat/datos y ajustes compatibles de addons al perfil actual y recargar?"
L["Apply and reload"] = "Aplicar y recargar"
L["Cancel"] = "Cancelar"

-- Skins/Engine.lua e Installer.lua: integraciones opcionales.
L["Addon skins: %s"] = "Skins de addons: %s"
L["Reload the UI to apply addon skins."] = "Recargá la interfaz para aplicar las skins de addons."
L["DBM bars follow the addon skins setting; reload to apply it"] = "las barras de DBM siguen el ajuste de skins de addons; recargá para aplicarlo"
