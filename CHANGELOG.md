# KnuUI changelog

## 3.3.2 (2026-11-08)

- More themes: Knunet intense orange, Dracula, Nord, Catppuccin Mocha, Gruvbox and Tokyo Night
  (official palette values), selectable in ElvUI > KnuUI > Appearance.
- Quest tracker background 8 px from the screen edge, like the minimap; the empty tab bar above
  docked Details is hidden; chat tab labels forced to one line.
- New options menu in ElvUI > KnuUI: tabs (General, Layout, Appearance, Addons, Camera), a short
  explanation per tab, full-width options so no label is cut, and dependent options greyed out.
- Details on Forever: right text in Details' simple format ("total (per second, percent)" in one string at
  the right edge). The aligned columns sat 60 px apart and covered the name, which Details cannot trim
  on Forever because text widths are secret values.
- Column mode: compact side blocks (3×4) selectable per side in ElvUI > KnuUI. Each compact side gives
  129 px to its chat/Details panel and the data bar shrinks the same.

## 3.3.1 (2026-11-08)

- The expanded quest tracker never covers the tooltip (tracker in MEDIUM strata, tooltip raised on show).
- TomTom skin re-applied after TomTom repaints its coordinate block (it reset colours and font).
- Action buttons no longer stay grey after their cooldown: "Desaturate Cooldowns" is turned off
  (ElvUI evaluates it once with secret values on Forever; the cooldown numbers remain).

## 3.3.0 — extras (2026-11-08)

- Combat glow: thin amber gradient on the screen edges while in combat (150 ms in, 300 ms out).
  Toggle in ElvUI > KnuUI.
- Experience bar tooltip: session experience per hour and time to the next level.
- Per-character role: each character remembers its role; logging in with a shared profile
  applies it and offers a reload.
- Cinema mode: hides the interface and slowly orbits the camera; ends on entering combat.
  Key binding (Key Bindings > AddOns > KnuUI), `/knu cine` or the ElvUI option.
- Test suite updated (7 installer pages, opt-in DBM, roles and extras).

## 3.2.0 — role profiles (2026-11-08)

- New installer page and ElvUI option: **Tank, MDPS, RDPS and Healer**, applied on top of the
  base layout and the column mode (switching roles does not touch the rest of the profile).
- Tank: threat borders on player, party and raid frames, threat icon on nameplates.
- MDPS: the base layout.
- RDPS: 340×32 cast bar and 32 px target debuffs.
- Healer: party and raid in the centre above the main bars (as Eltruism and LuckyoneUI do),
  incoming heals and HoT indicators on, small debuffs on party frames.
- The old "Tanks on/off" buttons are now "Columns on/off" (vertical health/mana columns).

## 3.1.0 — skins de addons (2026-11-08)

- Motor de skins con registro por addon, carga tardía, pcall y cola fuera de combate.
- Auctionator, BugSack, opciones de Leatrix Plus, Pawn, WhatsTraining, ThreatClassic2,
  log de GearQuestForever, Journey/opciones de Questie y opciones de GTFO con estética KnuUI.
- DBM usa exclusivamente `DBT:SetOption` para Melli y Expressway.
- Toggle general en asistente/opciones, exclusiones por addon y recarga para aplicar.
- Fade ease-out de 150 ms sólo al abrir el desplegable del lanzador; cierre inmediato.
- Pruebas locales con stubs; sin pruebas dentro del juego.
- Correcciones del dock detectadas por la suite: alias local de `math.min` y ocultación
  del separador vertical cuando queda una sola ventana.
- GatherMate2 y Syndicator omitidos: configuración AceConfig y panel local sin acceso
  al frame verificado, respectivamente.

## 3.0.0 — first public build (2026-11-08)

- Compact bottom-centred ElvUI layout for WoW Forever with a guided installer (`/knu`).
- Amber "knunet" theme and an optional neon theme; custom logo, icons and AFK screen.
- Optional "tank" mode: vertical health/mana columns next to the main bars, larger target block.
- Quartz-style cast bar, OmniCC-style cooldown text, community-style nameplates (ElvUI only).
- Single launcher button that collects minimap buttons (LibDBIcon and GearQuest).
- Integrated chat/Details panels, Details docking (replaces ForeverDock), skins for WoW-Pro,
  the quest tracker, TomTom and Baganator's title.
- DynamicCam presets from the addon's own bundle (cinematic / immersive / classic).
- Positions are anchored to the screen centre so the layout stays centred on any width
  (tuned for 1920×1080).
- Only hard dependency: ElvUI.
