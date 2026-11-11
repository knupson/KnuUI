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
| `/knu cine` | Toggle cinema mode (also bindable in Key Bindings → AddOns → KnuUI). |
| `/knudock` | Show the Details! dock status. Also `/knudock on`, `/knudock off`, `/knudock split <0.2-0.8>`. |

You can also open the installer, re-apply the layout or the theme, switch the camera preset and
toggle the decoration from **ElvUI → KnuUI**. Every installer page has its own buttons and saves only
its own settings; the last page reloads the interface.

## Features

- Compact bottom-centred ElvUI layout for WoW Forever with a guided installer (`/knu`).
- Role profiles: **Tank** (threat borders on frames, threat icon on nameplates), **MDPS** (the base
  layout), **RDPS** (bigger cast bar and target debuffs) and **Healer** (party and raid in the centre,
  incoming heals and HoT indicators). Each character remembers its role.
- Optional column mode: vertical health/mana columns next to the main bars and a larger target block.
- Amber "Knunet" theme and an optional neon theme; custom logo, icons and AFK screen.
- Quartz-style cast bar, OmniCC-style cooldown text, community-style nameplates (ElvUI only).
- Combat glow on the screen edges, experience-per-hour and time-to-level in the experience bar tooltip,
  and a cinema mode that hides the interface and orbits the camera (`/knu cine` or a key binding).
- Single launcher button that collects minimap buttons (LibDBIcon and GearQuest).
- Integrated chat/Details panels, Details docking, skins for WoW-Pro, the quest tracker, TomTom and
  Baganator's title.
- Addon skins: Auctionator, BugSack, Leatrix Plus (options), OpenMap, Pawn, WhatsTraining, ThreatClassic2,
  GearQuestForever (log), Questie (Journey and options), GTFO (options) and, if you enable it, DBM bars.
  Turn them all off from the installer's Addons page or **ElvUI → KnuUI**, or exclude one addon with
  `E.db.KnuUIAddonSkinsOff["AddonName"] = true`. Changes wait until you leave combat.
- DynamicCam presets from the addon's own bundle (cinematic / immersive / classic), slow combat zoom.
- Raid marker bar, flight timer, loot monitor, automatic spell rank update on action buttons, and
  Details/chat transparency with eye buttons.
- Skins for the spellbook and talents, RareScanner, WIM and PallyPower.
- Positions are anchored to the screen centre so the layout stays centred on any width
  (tuned for 1920×1080).

See [CHANGELOG.md](CHANGELOG.md) for the release history.

## Optional integrations

KnuUI works with ElvUI alone. If any of these addons are installed it can also adjust or skin them:
Details!, Baganator, DBM, Questie, WoW-Pro, TomTom, DynamicCam, GearQuestForever, Pawn, PallyPower,
OpenMap and Shortest Path Forever.
Each integration only touches the addon it belongs to.

## What KnuUI changes in other addons

KnuUI only touches other addons when you ask for it, and never sends anything outside the game.

- **Details!:** besides texture and font, turns on Details' simple right-text format (a global Details
  setting) so the numbers do not cover the player name in narrow docked windows on Forever.
- **DynamicCam:** creates and selects its own profile `KnuUI` (your profiles are untouched) and loads one of DynamicCam's bundled presets. Applied once by "Apply all", or from ElvUI > KnuUI. In that profile it also slows down situation transitions and turns off two situations that fail on Forever.
- **PallyPower:** redraws its bar as a compact one-row strip right of the WoW-Pro guide (size, position and look only; clicks, spells and PallyPower's settings are unchanged). Its drag anchor is hidden; open its windows from its minimap button or `/pp`.
- **WoW-Pro:** moves the guide window 8 px from the top-left corner once per ElvUI profile (stored in WoW-Pro's own position setting); its notes can be localized at load time if the private `KnuUI_WoWProES` data addon is installed. On non-English clients, before WoW-Pro checks a quest dialog, KnuUI copies the client's quest titles into the guide steps with the same quest ID, so auto accept, select and turn in work (no WoW-Pro file is modified).
- **TomTom + Shortest Path Forever:** when a guide points TomTom's arrow at a destination, KnuUI asks Shortest Path (public API) for the shortest route and points TomTom's arrow at each bend or stop of it. Once, it turns off Shortest Path's own arrow, compass and tracker sections, its "Follow TomTom's arrow" option and the game's in-world navigation pin (CVar `showInGameNavigation`); all can be turned back on in Shortest Path's options. Turn the bridge off with `E.db.KnuUITomTomRoute = false`.
- **Pawn:** the upgrade arrow on bag items only counts the scale of your active talent tree (the one with the most points); tooltips still show every scale. No Pawn setting is changed.
- **OpenMap:** with OpenMap loaded, ElvUI's and TomTom's world map coordinates are hidden (OpenMap shows its own); their settings are not changed.
- **ForeverCore tracker column (Shortest Path and other Forever addons):** once per profile it is detached and locked where Blizzard's hidden quest tracker starts, through ForeverCore's public `ForeverTrackerHost` API.
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
- **Integraciones opcionales:** Details!, Baganator, DBM, Questie, WoW-Pro, TomTom, DynamicCam, GearQuestForever, Pawn, PallyPower, OpenMap y Shortest Path Forever (la flecha de TomTom sigue su ruta más corta).
- **Traducción de WoW-Pro:** las traducciones de las guías **no** vienen incluidas, porque las guías de WoW-Pro tienen licencia CC BY-NC-ND 3.0 (sin obras derivadas).
- **Idioma:** los clientes esES y esMX ven el addon en castellano; el resto, en inglés.
- **Licencia:** MIT.
