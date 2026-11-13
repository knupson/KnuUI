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
L["Knunet intense orange"] = "Knunet naranja intenso"

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
L["Shortest Path: open the AddOns tab and choose \"Shortest Path Forever\"."] = "Shortest Path: Esc > Opciones > pestaña AddOns > «Shortest Path Forever» (este cliente no deja que un addon abra esas opciones)."
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
L["Each button applies right away to the current profile; a few details finish showing after a reload."] = "Cada botón se aplica en el momento al perfil actual; algunos detalles se terminan de ver al recargar."
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
L["Always hidden"] = "Siempre oculto"
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
L["KnuUI: alert skin turned on; reload to see it."] = "KnuUI: se prendió la skin de alertas; recargá para verla."
L["%d min"] = "%d min"
L["%d h %d min"] = "%d h %d min"
L["KnuUI: estimate after a minute of gaining experience"] = "KnuUI: la estimación aparece tras un minuto ganando experiencia"
L["Experience per hour"] = "Experiencia por hora"
L["Next level in"] = "Próximo nivel en"
L["KnuUI: this character's role is %s; reload to see it."] = "KnuUI: el rol de este personaje es %s; recargá para verlo."
L["Cinema mode (hide the interface and orbit the camera)"] = "Modo cine (oculta la interfaz y gira la cámara)"
L["Combat glow on the screen edges"] = "Aviso de combate en los bordes de la pantalla"

-- RaidMarkers.lua
L["Raid marker bar"] = "Barra de marcas"
L["Left click marks your target, right click places a ground marker. Move it with /moveui."] = "Clic izquierdo marca a tu objetivo, clic derecho pone una marca en el suelo. Se mueve con /moveui."
L["Only in a group"] = "Sólo en grupo"
L["Always"] = "Siempre"
L["Off"] = "Apagada"
L["Left click: mark your target. Right click: place or remove the ground marker."] = "Clic izquierdo: marca a tu objetivo. Clic derecho: pone o saca la marca de suelo."
L["Clear markers"] = "Borrar marcas"
L["Left click: clear your target's marker. Right click: clear all ground markers."] = "Clic izquierdo: borra la marca de tu objetivo. Clic derecho: borra todas las marcas de suelo."
L["Ready check"] = "Comprobar listos"
L["Pull timer"] = "Cuenta atrás de pull"
L["Starts a 10 second countdown for the group."] = "Inicia una cuenta atrás de 10 segundos para el grupo."
L["KnuUI: raid markers"] = "KnuUI: marcas"

-- Camera.lua (zoom de combate)
L["Maximum camera distance and zoom out in combat"] = "Distancia máxima de cámara y alejar en combate"
L["Raises the camera limit to the maximum and, with DynamicCam, zooms out when combat starts and back when it ends."] = "Sube el límite de la cámara al máximo y, con DynamicCam, la aleja al entrar en combate y la devuelve al salir."

-- Fade.lua
L["Details always visible (click to fade out of combat)"] = "Details siempre visible (clic para que se transparente fuera de combate)"
L["Details fades out of combat (click to keep it visible)"] = "Details se transparenta fuera de combate (clic para dejarlo siempre visible)"
L["Chat faded (click to show it)"] = "Chat transparente (clic para mostrarlo)"
L["Chat visible (click to fade it)"] = "Chat visible (clic para transparentarlo)"
L["Details very transparent out of combat (eye button above the panel keeps it visible)"] = "Details muy transparente fuera de combate (el botón del ojo sobre el panel lo deja visible)"

-- LootMonitor.lua
L["KnuUI: loot monitor"] = "KnuUI: monitor de botín"
L["Loot monitor: what you and your group loot, above the right panel"] = "Monitor de botín: lo que saqueás vos y tu grupo, arriba del panel derecho"
L["Your loot from"] = "Tu botín desde"
L["Group loot from"] = "Botín del grupo desde"
L["Grey"] = "Gris"
L["White"] = "Blanco"
L["Green"] = "Verde"
L["Blue"] = "Azul"
L["Purple"] = "Violeta"

-- Buttons.lua (accesos fijos)
L["Minimap buttons always visible next to the K"] = "Botones del minimapa siempre a la vista junto a la K"
L["The rest stay inside the K launcher."] = "El resto queda adentro del lanzador K."

-- MinimapZoom.lua
L["Minimap: double size"] = "Minimapa: tamaño doble"
L["Minimap: normal size"] = "Minimapa: tamaño normal"

-- Installer.lua (aplicar en el momento)
L["KnuUI: %s applied. Anything that does not change yet shows after a reload."] = "KnuUI: %s aplicado. Lo que todavía no cambie se ve al recargar."
L["KnuUI: applied. Anything that does not change yet shows after a reload."] = "KnuUI: aplicado. Lo que todavía no cambie se ve al recargar."

-- Share.lua
L["Share"] = "Compartir"
L["Your whole interface in one text: ElvUI profile, role and KnuUI settings. Also /knu export and /knu import."] = "Toda tu interfaz en un texto: perfil de ElvUI, rol y opciones de KnuUI. También /knu exportar y /knu importar."
L["Export KnuUI"] = "Exportar KnuUI"
L["Import KnuUI"] = "Importar KnuUI"
L["ElvUI profile, role and KnuUI settings in one text. Ctrl+C to copy."] = "Perfil de ElvUI, rol y opciones de KnuUI en un texto. Ctrl+C para copiar."
L["Paste a KnuUI text (Ctrl+V). It is imported into a new profile; yours is not overwritten."] = "Pegá un texto de KnuUI (Ctrl+V). Se importa en un perfil nuevo; el tuyo no se pisa."
L["Select all"] = "Seleccionar todo"
L["Import"] = "Importar"
L["Close"] = "Cerrar"
L["This client cannot encode the text."] = "Este cliente no puede codificar el texto."
L["Could not read the ElvUI profile."] = "No se pudo leer el perfil de ElvUI."
L["Could not encode the text."] = "No se pudo codificar el texto."
L["This is not a KnuUI text."] = "Esto no es un texto de KnuUI."
L["The text is damaged or incomplete."] = "El texto está dañado o incompleto."
L["KnuUI: imported into the profile \"%s\". Reloading is recommended."] = "KnuUI: importado en el perfil \"%s\". Conviene recargar."

-- Ranks.lua
L["KnuUI: %s rank %d placed on %d action buttons."] = "KnuUI: %s rango %d puesto en %d botones."
L["Replace old spell ranks on your bars when you learn a new one"] = "Reemplazar los rangos viejos de tus barras al aprender uno nuevo"

-- Flight.lua
L["KnuUI: flight timer"] = "KnuUI: temporizador de vuelo"
L["%s (learning)"] = "%s (aprendiendo)"
L["Flight time: %s"] = "Tiempo de vuelo: %s"
L["Flight time: not learned yet"] = "Tiempo de vuelo: todavía sin datos"
L["Flight timer (learns each route the first time you fly it)"] = "Temporizador de vuelo (aprende cada ruta la primera vez que la volás)"

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
L["401×180 chats, edit box above, and panels with the same background and tabs."] = "Chats de 401×180, edición arriba y paneles con el mismo fondo y pestañas."
L["Central 1102×22 bar with eight data points; time and coordinates on the minimap."] = "Barra central de 1102×22 con ocho datos; hora y coordenadas en minimapa."
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

-- Offhand.lua / Diag.lua
L["Offhand: ElvUI on the game monitor, %.0fx%.0f at scale %.4f."] = "Offhand: ElvUI en el monitor de juego, %.0fx%.0f a escala %.4f."
L["Disable the OffhandElvFix addon: KnuUI does its job now."] = "Desactivá el addon OffhandElvFix: ahora KnuUI hace ese trabajo."
L["Offhand is not loaded."] = "Offhand no está cargado."
L["Offhand is loaded but Companion has not written the monitor layout yet."] = "Offhand está cargado pero Companion todavía no escribió la disposición de los monitores."
L["Window %dx%d, game %dx%d at %d,%d, workspace %dx%d at %d,%d. Spanned now: %s."] = "Ventana %dx%d, juego %dx%d en %d,%d, espacio de trabajo %dx%d en %d,%d. Estirada ahora: %s."
L["Offhand spans the game window over two monitors. KnuUI keeps ElvUI on the game monitor with the same size and 1 px borders as on a single screen."] = "Offhand estira la ventana del juego sobre dos monitores. KnuUI deja ElvUI en el monitor de juego con el mismo tamaño y bordes de 1 px que en una sola pantalla."
L["Fit ElvUI to the game monitor when Offhand spans the window"] = "Encajar ElvUI en el monitor de juego cuando Offhand estira la ventana"
L["Take a diagnostic snapshot (/knudiag)"] = "Tomar una foto de diagnóstico (/knudiag)"
L["Saves the size and position of every KnuUI block to KnuUI's SavedVariables on the next reload."] = "Guarda el tamaño y la posición de cada bloque de KnuUI en las SavedVariables de KnuUI al próximo reload."
L["Diagnostic snapshot taken; /reload writes it to disk."] = "Foto de diagnóstico tomada; /reload la escribe en disco."
L["Diagnostic saved (written to disk on /reload or logout)."] = "Diagnóstico guardado (se escribe en disco con /reload o al salir)."

-- Builds.lua y menú final: claves inglesas, textos del cliente esES/esMX.
L["Builds"] = "Builds"
L["Recommended interface builds"] = "Builds de interfaz recomendados"
L["Recommended build"] = "Build recomendado"
L["Apply build"] = "Aplicar build"
L["Tank build"] = "Tanque"
L["Melee build"] = "DPS cuerpo a cuerpo"
L["Ranged build"] = "DPS a distancia"
L["Healer build"] = "Sanador"
L["Columns, both compact blocks, threat borders and plates, group markers, combat glow, Details always visible. Loot: green for you, blue for the group."] = "Columnas, ambos bloques compactos, amenaza en bordes y placas, marcas en grupo, brillo de combate y Details siempre visible. Botín: verde para vos, azul para el grupo."
L["Base layout without columns or compact blocks, group markers, combat glow, Details fades outside combat. Loot: white for you, green for the group."] = "Diseño base sin columnas ni bloques compactos, marcas en grupo, brillo de combate y Details atenuado fuera de combate. Botín: blanco para vos, verde para el grupo."
L["Base layout without columns or compact blocks, larger cast bar and target debuffs, group markers, no combat glow, Details fades. Loot: white for you, green for the group."] = "Diseño base sin columnas ni bloques compactos, lanzamientos y perjuicios del objetivo más grandes, marcas en grupo, sin brillo de combate y Details atenuado. Botín: blanco para vos, verde para el grupo."
L["Columns, compact right block, centred party and raid with incoming heals and HoTs, group markers, no combat glow, Details fades. Loot: green for you, blue for the group."] = "Columnas, bloque derecho compacto, grupo y banda centrados con curas entrantes e indicadores de curación periódica, marcas en grupo, sin brillo de combate y Details atenuado. Botín: verde para vos, azul para el grupo."
L["Reapplies KnuUI nameplates; threat indicator only for tanks. Resets the Details eye override. Bars for other classes are disabled; class resources only appear when supported by Forever."] = "Reaplica las placas de KnuUI; indicador de amenaza sólo para tanques. Restablece el botón del ojo de Details. Apaga las barras de otras clases; los recursos de clase aparecen cuando Forever los admite."
L["Pet bar enabled, without mouseover hiding."] = "Barra de mascota activada, visible sin pasar el mouse."
L["Stance, form, stealth or aura bar enabled, without mouseover hiding."] = "Barra de actitudes, formas, sigilo o auras activada, visible sin pasar el mouse."
L["Totem bar enabled, without mouseover hiding."] = "Barra de tótems activada, visible sin pasar el mouse."
L["Class resource bar enabled."] = "Barra de recursos de clase activada."
L["Recommendations for your class and role, not talent builds. Selection alone does not apply changes. Applying replaces layout, nameplates and the listed settings in this ElvUI profile."] = "Recomendaciones de interfaz para tu clase y rol, sin cambiar talentos. Elegir no aplica cambios. Al aplicar se reemplazan el diseño, las placas y los ajustes indicados en este perfil de ElvUI."
L["Defaults to your class and selected role. Only builds for your current class are listed."] = "Sugiere según tu clase y el rol elegido. Sólo muestra builds para tu clase actual."
L["No recommended build for this class."] = "No hay un build recomendado para esta clase."
L["Confirm to apply the selected interface build and reload. Leave combat first."] = "Confirmá para aplicar el build de interfaz elegido y recargar. Salí de combate primero."
L["Apply the selected interface build to this profile and reload?"] = "¿Aplicar el build de interfaz elegido a este perfil y recargar?"
L["Class colour"] = "Color de clase"
L["Installation"] = "Instalación"
L["Palette and decoration"] = "Paleta y decoración"
L["Palette previews"] = "Vista previa de paletas"
L["Combat and panels"] = "Combate y paneles"
L["Loot and travel"] = "Botín y viajes"
L["Launcher and skins"] = "Accesos y skins"
L["Camera settings"] = "Ajustes de cámara"
L["Open the step-by-step installer without applying settings."] = "Abrí el asistente paso a paso sin aplicar ajustes."
L["Rebuild the base layout with the selected role overlay; reload to see it."] = "Reconstruí el diseño base con los ajustes del rol elegido; recargá para verlo."
L["Switch between the base player frame and vertical health and mana columns."] = "Alterná entre el marco base del jugador y las columnas verticales de vida y maná."
L["Restore KnuUI cast bars, auras and quest indicators on nameplates."] = "Restablecé los lanzamientos, auras e indicadores de misión de KnuUI en las placas."
L["Choose a palette. Preview shows accent, highlight, health, text, background and border."] = "Elegí una paleta. Las muestras muestran acento, resaltado, vida, texto, fondo y borde."
L["Use each unit's class colour for health instead of the palette health colour."] = "Usá el color de clase de cada unidad para su vida en lugar del color de la paleta."
L["Show themed corners, stripes and shadows around KnuUI panels."] = "Mostrá esquinas, franjas y sombras del tema alrededor de los paneles de KnuUI."
L["Show a coloured glow at the screen edges during combat."] = "Mostrá un brillo de color en los bordes de la pantalla durante el combate."
L["Fade Details outside combat; the eye button can keep it visible. Requires Details."] = "Atenuá Details fuera de combate; el botón del ojo permite dejarlo visible. Requiere Details."
L["Display recent personal and group loot above the right panel."] = "Mostrá el botín reciente tuyo y del grupo arriba del panel derecho."
L["Replace learned spell ranks on action bars outside combat."] = "Reemplazá los rangos de hechizos aprendidos en las barras fuera de combate."
L["Show route duration after learning a complete flight."] = "Mostrá la duración de la ruta después de aprender un vuelo completo."
L["Restore the themed chat and Details panels; reload to see changes."] = "Restablecé los paneles de chat y Details con el tema; recargá para ver los cambios."
L["Apply KnuUI colours and borders to supported addons after reloading."] = "Aplicá los colores y bordes de KnuUI a los addons compatibles al recargar."
L["Apply the KnuUI appearance to WoW-Pro after reloading. Requires WoW-Pro."] = "Aplicá la apariencia de KnuUI a WoW-Pro al recargar. Requiere WoW-Pro."
L["Choose whether WoW-Pro replaces the Blizzard quest tracker."] = "Elegí si WoW-Pro reemplaza el rastreador de misiones de Blizzard."
L["Apply a DynamicCam preset to its KnuUI profile. Requires DynamicCam."] = "Aplicá un preset de DynamicCam a su perfil KnuUI. Requiere DynamicCam."
L["Hide the interface and orbit the camera until combat starts; run again to stop."] = "Ocultá la interfaz y girá la cámara hasta entrar en combate; ejecutalo otra vez para detenerlo."
L["Requires health and mana columns."] = "Requiere activar las columnas de vida y maná."
L["Minimum item quality shown in the loot monitor."] = "Calidad mínima de los objetos que muestra el monitor de botín."
L["Enable the loot monitor first."] = "Activá primero el monitor de botín."
L["Requires loaded addon: %s."] = "Requiere tener cargado el addon: %s."

-- Centro de comando: el menú también funciona antes de cargar su API.
L["Command center loads with Offhand"] = "El centro de comando se carga con Offhand"
L["Command center loads with Offhand. Enable spanning over two monitors and leave combat to change blocks. Missing API methods stay disabled."] = "El centro de comando se carga con Offhand. Activá la ventana estirada sobre dos monitores y salí de combate para cambiar bloques. Las funciones ausentes de la API quedan deshabilitadas."
L["Command center: %s · %s · %s"] = "Centro de comando: %s · %s · %s"
L["Active"] = "Activo"
L["Inactive"] = "Inactivo"
L["Unknown"] = "Sin datos"
L["horizontal"] = "horizontal"
L["vertical"] = "vertical"
L["bottom"] = "abajo"
L["top"] = "arriba"
L["left"] = "izquierda"
L["right"] = "derecha"
L["Workspace preset"] = "Preset del espacio de trabajo"
L["Assign blocks with a command center preset."] = "Distribuí los bloques con un preset del centro de comando."
L["Block destination"] = "Destino de cada bloque"
L["Guide"] = "Guía"
L["Chat"] = "Chat"
L["Data"] = "Datos"
L["Map"] = "Mapa"
L["Bags"] = "Bolsas"
L["Game monitor"] = "Monitor de juego"
L["Workspace"] = "Espacio de trabajo"
L["Choose the game monitor or the adjacent workspace for this block."] = "Elegí el monitor de juego o el espacio de trabajo contiguo para este bloque."
L["Workspace tools"] = "Herramientas del espacio de trabajo"
L["Unlock workspace blocks"] = "Desbloquear bloques del espacio de trabajo"
L["Allow dragging command center blocks; turn off to lock them again."] = "Permití arrastrar los bloques del centro de comando; desactivá para volver a bloquearlos."
L["Reset workspace"] = "Restablecer espacio de trabajo"
L["Restore command center block assignments and positions."] = "Restablecé los destinos y las posiciones de los bloques del centro de comando."
L["Reset command center assignments and positions?"] = "¿Restablecer los destinos y las posiciones del centro de comando?"
L["Open Offhand options"] = "Abrir opciones de Offhand"
L["Open Offhand wizard"] = "Abrir asistente de Offhand"
L["Gather off-screen windows"] = "Recuperar ventanas fuera de pantalla"
L["Open the selected Offhand tool. Requires the loaded addon API and leaving combat."] = "Abrí la herramienta de Offhand elegida. Requiere la API del addon cargada y estar fuera de combate."
L["Diagnostics"] = "Diagnóstico"
L["Diagnostic API is not loaded."] = "La API de diagnóstico no está cargada."

-- Workspace.lua (centro de comando)
L["WoW-Pro guide + PallyPower"] = "Guía de WoW-Pro + PallyPower"
L["Details"] = "Details"
L["Data bar"] = "Barra de datos"
L["Command center (recommended)"] = "Centro de comando (recomendado)"
L["Guide, chat, Details, data, map and bags on the workspace; the game monitor keeps only combat."] = "Guía, chat, Details, datos, mapa y bolsas en el monitor de trabajo; el de juego queda sólo con el combate."
L["Social and guide up"] = "Social y guía arriba"
L["Guide, chat and Details on the workspace; data bar, map and bags stay with the game."] = "Guía, chat y Details en el monitor de trabajo; barra de datos, mapa y bolsas quedan con el juego."
L["Only map and bags up"] = "Sólo mapa y bolsas arriba"
L["The single-screen layout stays on the game monitor; map and bags open on the workspace."] = "El diseño de una pantalla queda en el monitor de juego; mapa y bolsas abren en el de trabajo."
L["Raid: meters up"] = "Banda: medidores arriba"
L["Details and chat on the workspace next to the game monitor; guide stays with the game."] = "Details y chat en el monitor de trabajo, pegados al de juego; la guía queda con el juego."
L["Everything on the game monitor"] = "Todo en el monitor de juego"
L["Like a single screen; the workspace is left to Offhand."] = "Como una sola pantalla; el monitor de trabajo queda para Offhand."

-- Segunda pasada del menú: resumen, acciones y funciones.
L["Palette"] = "Paleta"
L["Features"] = "Funciones"
L["Loot"] = "Botín"
L["Combat"] = "Combate"
L["Travel"] = "Viajes"
L["Panels"] = "Paneles"
L["Combat glow"] = "Brillo de combate"
L["Current status"] = "Estado actual"
L["Quick actions"] = "Acciones rápidas"
L["KnuUI version: %s"] = "Versión de KnuUI: %s"
L["Current role: %s"] = "Rol actual: %s"
L["Selected build: %s"] = "Build seleccionada: %s"
L["Current palette: %s"] = "Paleta actual: %s"
L["Offhand: %s"] = "Offhand: %s"
L["Workspace preset: %s · Orientation: %s"] = "Preset del espacio de trabajo: %s · Orientación: %s"
L["Addon skins: %s"] = "Skins de addons: %s"
L["Enabled"] = "Activadas"
L["Disabled"] = "Desactivadas"
L["Apply recommended build"] = "Aplicar build recomendada"
L["Confirm to apply the recommended interface build for your class and role and reload. Leave combat first."] = "Confirmá para aplicar la build de interfaz recomendada para tu clase y rol y recargar. Salí de combate primero."
L["Choose a palette. Preview shows accent, highlight, dim accent, text, background and border."] = "Elegí una paleta. La muestra incluye acento, resaltado, acento tenue, texto, fondo y borde."
L["Diagnostic on from the next reload (/reload). /knudiag off turns it off."] = "Diagnóstico prendido desde la próxima recarga (/reload). /knudiag off lo apaga."
L["Diagnostic off from the next reload."] = "Diagnóstico apagado desde la próxima recarga."
