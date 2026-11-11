# KnuUI changelog

## 3.4.3 (2026-11-11)

- TomTom arrow along Shortest Path Forever's route: when a guide (WoW-Pro, Questie, /way) points
  TomTom's arrow at a destination, KnuUI asks Shortest Path for the shortest route (public API) and
  points TomTom's arrow at each bend or stop of it, then back at the destination at the end.
  Shortest Path's own arrow, compass, tracker section and the game's in-world pin are turned off
  once (they can be turned back on in its options).

- Pawn: the upgrade arrow on bag items (Pawn and Baganator) only counts the scale of your active
  specialization, the talent tree with the most points. Tooltips still show every scale.
- OpenMap skin: its windows, panels, dropdowns and menu use the KnuUI theme (dark background,
  theme border, accent line and shadow) instead of the metal frame and rock background. Its red
  buttons and search boxes use ElvUI's style. With OpenMap loaded, ElvUI's and TomTom's coordinates
  on the world map are hidden (OpenMap shows its own), without changing their settings.
- PallyPower strip follows the WoW-Pro guide when it opens or closes after login (it stayed in the
  top-left corner, under the guide), starts in that place after a reload (its saved position is
  updated), and its drag handle no longer takes the mouse (dragging it in combat raised
  ADDON_ACTION_BLOCKED on PallyPowerFrame:StopMovingOrSizing).
- Shortest Path Forever skin: its "Nearby services" panel in the quest log uses the KnuUI theme
  (ElvUI search box and scroll bar), and its settings open from the K launcher (on clients without
  CreateSecureDelegate, where Shortest Path cannot open them, the launcher says where to find them). ForeverCore's tracker
  column (Shortest Path's "Journey" section and other Forever addons) gets a KnuUI frame and theme text,
  and once per profile it is detached and locked where Blizzard's hidden quest tracker starts (it sat
  over Details). Compass text uses the theme font. Its optional "Journey"
  button under the minimap is hidden for the session, like other minimap buttons.

## 3.4.2 (2026-11-10)

- PallyPower reworked as a compact one-row strip right of the WoW-Pro guide: your own buttons
  (auto, aura, Righteous Fury + seal), then one 31 px tile per class present; it grows to the
  right and player lists open downwards under their class. Theme border and Expressway text
  inside a KnuUI frame, the state colour on a bar at the bottom. A "!" on the aura tile when
  another paladin in your subgroup has the same aura.

## 3.4.1 (2026-11-10)

- WoW-Pro on non-English clients: auto accept, select and turn in work again. WoW-Pro compares the
  quest title with the guide's English title; KnuUI now puts the client's title on the steps with the
  same quest ID before WoW-Pro checks, and retries the NPC dialog WoW-Pro skipped when its quests
  arrived late. Survives WoW-Pro updates (no WoW-Pro file is changed).
- Hearthstone camera (DynamicCam situation 200) fixed: its old start script is replaced by
  DynamicCam's own.
- Flight timer stays visible when DynamicCam hides the interface during the flight, and sits lower
  (120 px from the top) so it no longer overlaps TomTom's arrow.
- The "leave flight" button no longer stays on screen after landing (DynamicCam showed it again
  when restoring the interface).
- WhatsTraining: readable text on the dark skin (its parchment colours are swapped for its own
  dark-theme colours).
- Clock in 24-hour format; minimap panel: clock on the left, coordinates on the right.

## 3.4.0 (2026-11-09)

- Raid marker bar under the launcher: left click marks your target, right click places a ground
  marker, plus clear, ready check and a 10 s pull. Uses Blizzard's secure actions, so it works on
  Forever. Shown in a group, always or never (ElvUI > KnuUI > Appearance).
- Flight timer: learns each route the first time you fly it, then shows a countdown bar and the
  flight time in the flight map tooltip.
- Loot monitor: small notices with icon for what you and your group loot (minimum quality per case).
- Spell ranks: when you learn a new rank, the action buttons with the old rank are updated.
- Details and chat transparency: Details fades out of combat (eye button keeps it visible), the chat
  fades only from its own eye button. The whole block fades, not only its background.
- Combat zoom: the camera zooms out slowly when combat starts and comes back slowly after.
  DynamicCam situation transitions are slowed down, and two situations that fail on Forever are
  turned off.
- Motion and finish: 250 ms fades, loot notices slide in, accent hover on KnuUI buttons, accent
  line and soft shadow on KnuUI frames.
- Pinned launcher buttons: choose addons in ElvUI > KnuUI > Addons to keep them as buttons left of K.
- The launcher sits 2 px under the minimap's orange glow (measured in game at load).
- Health and mana columns wider, with the same border on both.
- New skins: spellbook and talents, RareScanner, WIM (windows and minimap entry in the launcher)
  and PallyPower (dark bar placed under the WoW-Pro guide).

## 3.3.4 (2026-11-09)

- Fixed Lua taint errors from the quest tracker (`GetAuraDataByIndex(): Auras cannot be accessed
  when secret while tainted by 'KnuUI'`, also inside Edit Mode, and the Edit Mode error when
  dragging the tracker). KnuUI no longer collapses the tracker from code; while WoW-Pro is loaded
  it is only made transparent and click-through. Collapse it with its own button if you want.

## 3.3.3 (2026-11-09)

- TomTom arrow: theme panel behind its texts and arrow colours from the theme palette (set once per
  profile in TomTom's own settings).
- TomTom arrow moved next to the WoW-Pro guide (once per profile): at the top centre it collided with
  Blizzard's duration bars, which Edit Mode places on Forever.
- Quest tracker +/- buttons moved 10 px inside its background.
- Quest tracker hidden by default while WoW-Pro is loaded (on Forever Blizzard stretches it to the
  bottom of the screen); it stays collapsed so the invisible quests don't catch clicks.
- Breath / fatigue bars with the KnuUI look (Melli texture, colour per type, theme border). Their
  position on Forever comes from Blizzard's Edit Mode (Duration Bars).
- Placement for 13 Blizzard elements that ElvUI can move on Forever (zone state, below-minimap
  widgets, banners, alternate power, loss of control, alerts, loot, GM ticket, friend toast, boss and
  zone buttons, queue status): nothing piles up at the top centre any more. ElvUI's alert skin is turned on.
- Chat tabs: the first added window (e.g. a loot tab) sat 0.7 px lower; its label is now aligned
  with General (measured in game).
- Battle.net friend notifications with the KnuUI theme, moved above the left chat.
- Knunet intense orange is now a clearly different orange (#ff6a00).
- GearQuest skin only styles its outer frame (the parchment titles were turning black).
- More themes: Knunet intense orange, Dracula, Nord, Catppuccin Mocha, Gruvbox and Tokyo Night
  (official palette values), selectable in ElvUI > KnuUI > Appearance.
- Quest tracker background 8 px from the screen edge, like the minimap; the empty tab bar above
  docked Details is hidden; chat tab labels forced to one line.

## 3.3.2 (2026-11-08)

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
