# KnuUI

A compact, amber-themed layout and installer for **ElvUI** on **World of Warcraft: Forever**
(Interface 16001). KnuUI is an ElvUI plugin: it places your action bars, unit frames, chat and
data panels in a tidy block at the bottom centre of the screen, applies a dark amber theme and
ships its own logo, icons and AFK screen.

Available in English and Spanish (esES / esMX clients show Spanish, every other client shows English).

## Requirements

- World of Warcraft: Forever (Interface 16001)
- [ElvUI](https://www.tukui.org/) — the only hard dependency

## Installation

1. Copy the `KnuUI` folder to `Interface/AddOns/KnuUI`.
2. Make sure ElvUI is installed and enabled.
3. Log in. The installer opens by itself the first time (and again when KnuUI ships a new layout version).

Settings are written to your current ElvUI profile, so make a copy of the profile first if you want
to keep your old values. Nothing is applied during combat.

## Usage

| Command | What it does |
|---|---|
| `/knu` (alias `/fui`) | Open the installer. |
| `/knu aplicar` | Ask for confirmation, apply everything and reload. |
| `/knudock` | Show the Details! dock status. Also `/knudock on`, `/knudock off`, `/knudock split <0.2-0.8>`. |

You can also open the installer, re-apply the layout or the theme, switch the camera preset and
toggle the decoration from **ElvUI → KnuUI**. Every installer page has its own buttons and saves only
its own settings; the last page reloads the interface.

## Features

- Skins de addons integradas: Auctionator, BugSack, Leatrix Plus (opciones), Pawn,
  WhatsTraining, ThreatClassic2, GearQuestForever (log), Questie (Journey y opciones),
  DBM (textura/fuente vía DBT) y GTFO (opciones). Fondos/bordes del tema, Expressway y Melli.
- Activación en la página **Addons** del asistente o **ElvUI → KnuUI → Skins de addons**;
  requiere recarga. Se habilitan por defecto. Para excluir un addon, guardá
  `E.db.KnuUIAddonSkinsOff["NombreDelAddon"] = true` en el perfil de ElvUI y recargá.
- Carga tardía, errores aislados por integración y cambios diferidos hasta salir de combate.
  El desplegable del lanzador aparece con un fade ease-out de 150 ms y se cierra al instante.
- GatherMate2 queda fuera: su configuración usa AceConfig. Syndicator tiene un panel local
  sin un acceso al frame verificado; no se modifica ni se aplica una skin global a Settings/AceGUI.
- Compact bottom-centred ElvUI layout for WoW Forever with a guided installer (`/knu`).
- Amber "Knunet" theme and an optional neon theme; custom logo, icons and AFK screen.
- Optional "tank" mode: vertical health/mana columns next to the main bars, larger target block.
- Quartz-style cast bar, OmniCC-style cooldown text, community-style nameplates (ElvUI only).
- Single launcher button that collects minimap buttons (LibDBIcon and GearQuest).
- Integrated chat/Details panels, Details docking (replaces ForeverDock), skins for WoW-Pro,
  the quest tracker, TomTom and Baganator's title.
- DynamicCam presets from the addon's own bundle (cinematic / immersive / classic).
- Positions are anchored to the screen centre so the layout stays centred on any width
  (tuned for 1920×1080).

See [CHANGELOG.md](CHANGELOG.md) for the release history.

## Optional integrations

KnuUI works with ElvUI alone. If any of these addons are installed it can also adjust or skin them:
Details!, Baganator, DBM, Questie, WoW-Pro, TomTom, DynamicCam and GearQuestForever.
Each integration only touches the addon it belongs to.

## What KnuUI changes in other addons

KnuUI only touches other addons when you ask for it, and never sends anything outside the game.

- **DynamicCam:** creates and selects its own profile `KnuUI` (your profiles are untouched) and loads one of DynamicCam's bundled presets. Applied once by "Apply all", or from ElvUI > KnuUI.
- **WoW-Pro:** moves the guide window 8 px from the top-left corner once per ElvUI profile (stored in WoW-Pro's own position setting); its notes can be localized at load time if the private `KnuUI_WoWProES` data addon is installed.
- **Questie / WoW-Pro tracker position:** only from their buttons on the installer's Addons page.
- **DBM:** bar texture and font are changed only if you enable "DBM bars" in ElvUI > KnuUI (this writes DBM's own settings).
- **Minimap buttons (LibDBIcon, GearQuest):** hidden for the session and moved into the KnuUI launcher; their saved settings are not modified.
- **"Toggle AFK"** in the launcher sends the standard `/afk` chat command only when you click it.

## WoW-Pro guide translations

KnuUI contains the code that can translate WoW-Pro guide notes on load, but **the translations
themselves are not included**. WoW-Pro guides are licensed CC BY-NC-ND 3.0 (no derivatives), so
translated guide text cannot be redistributed with this addon.

## License

MIT. See [LICENSE](LICENSE).

---

# KnuUI (castellano)

Diseño compacto con tema ámbar y asistente de instalación para **ElvUI** en **World of Warcraft: Forever**
(Interface 16001). Es un plugin de ElvUI: acomoda barras, marcos, chat y paneles de datos en un bloque
abajo al centro de la pantalla, aplica un tema oscuro ámbar y trae logo, íconos y pantalla de ausente propios.

- **Requisito:** ElvUI (única dependencia obligatoria).
- **Instalación:** copiá la carpeta `KnuUI` a `Interface/AddOns/KnuUI` y entrá al juego; el asistente se abre solo la primera vez.
- **Comandos:** `/knu` (alias `/fui`) abre el asistente; `/knu aplicar` aplica todo con confirmación y recarga; `/knudock` maneja el acople de Details!.
- **Opciones:** también están en ElvUI → KnuUI (reaplicar diseño o tema, presets de cámara, decoración).
- **Funciones:** diseño compacto centrado, tema Knunet ámbar y Neón, modo tanques opcional, barra de lanzamiento tipo Quartz, placas de nombre con ElvUI, un solo botón lanzador para los botones del minimapa, paneles integrados, acople de Details!, skins para WoW-Pro, rastreador de misiones, TomTom y Baganator, y presets de DynamicCam.
- **Integraciones opcionales:** Details!, Baganator, DBM, Questie, WoW-Pro, TomTom, DynamicCam y GearQuestForever.
- **Traducción de WoW-Pro:** las traducciones de las guías **no** vienen incluidas, porque las guías de WoW-Pro tienen licencia CC BY-NC-ND 3.0 (sin obras derivadas).
- **Idioma:** los clientes esES y esMX ven el addon en castellano; el resto, en inglés.
- **Licencia:** MIT.
