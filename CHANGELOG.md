# KnuUI changelog

## 3.6.12 (2026-11-23)

- Chat messages: the "KnuUI:" prefix no longer repeats ("ElvUI: KnuUI: ..." is now "ElvUI: ..."), and the Dock messages
  all start with "KnuUI Dock:". The cooldown manager messages were always in Spanish; they now follow the client language.
- Themes: the muted text color is lighter in Dracula, Nord, Gruvbox, Solarized, One Dark and Kanagawa, so secondary
  text is easier to read on the dark background.
- README: wording cleaned up, and the minimap launcher description now lists what it collects.

## 3.6.11 (2026-11-22)

- Bags: the empty reagent bag slot (the fifth slot in Baganator's bag row) showed no tooltip, so there was no way to
  tell why ordinary bags would not go in. It now says "Equip Reagent Bag", in the game's own words.

## 3.6.10 (2026-11-22)

- Minimap buttons: the KnuUI launcher now takes in the minimap button of any addon, not only those built on
  LibDBIcon. Left and right clicks in the launcher reach the original button. Map pins (TomTom waypoints and other
  HereBeDragons pins) stay on the minimap. Cheap Upgrades' button no longer covers the minimap zoom button.
- WoW-Pro guide: with many "As you go" steps the guide stops above the party frames instead of covering them. It
  shows the end, where the current step is, and the mouse wheel scrolls up to the rest.
- Manners: the prompt sits on a plain KnuUI panel. Manners' painted pane, its white underline and KnuUI's extra
  accent line are gone, so the prompt has a single clean border.

## 3.6.9 (2026-11-22)

- Character sheet: with Pawn installed, ElvUI's character skin stopped halfway with an "attempt to index local 'icon'"
  error on every login, leaving some equipment slots unstyled. Pawn's button now joins the sheet after ElvUI has
  styled it.
- Manners: its prompt uses its own "Minimal" look with KnuUI's colours and font, and sits to the right of the target
  column instead of over the target's auras. Only settings still at Manners' defaults are changed, once per Manners
  profile.
- DynamicCam: every camera situation on the "KnuUI" profile is 50% farther, up to the 39 m maximum.

## 3.6.8 (2026-11-21)

- New KnuUI logo and addon icon: an interface panel instead of the K, matching the other Knu addons.

## 3.6.7 (2026-11-21)

- Small close buttons are easy to click again. ElvUI's close-button style trims the clickable area for its usual
  32 px buttons, which left RareScanner's 16 px close button with a clickable spot of 4 by 2 px. KnuUI now keeps
  at least 22 px clickable on small close buttons it styles.

## 3.6.6 (2026-11-20)

- Loot rolls: ElvUI's roll buttons now show how many players picked Need, Greed, Transmog or Pass, and the
  button tooltip lists who. In Forever ElvUI never got that data; KnuUI reads it from the game's loot history.
  If two rolls for the same item are open at once, those two bars stay blank so votes never land on the wrong one.
- DynamicCam: KnuUI only adjusts camera situations on its own "KnuUI" DynamicCam profile. Before, it also
  softened transitions and turned off views and rotations on whatever profile you had selected, every login.
- Shortest Path + TomTom: the TomTom arrow now follows each bend of the route again. With Shortest Path's
  default settings it never got the bends and kept pointing straight at the destination. Route changes arrive
  through Shortest Path's own notifications instead of a check every half second, and a TomTom waypoint that
  KnuUI did not create is never removed.
- Builds: switching from the Healer build to another column build no longer keeps the healer party frames.
- Command center: a block moved back to the game screen gets its normal font size back.
- Tiny Threat inside Details gets the KnuUI row style (the plugin was looked up by the wrong name).
- Fades: a fade replaced by one that is already at its target no longer keeps running.
- Updated the embedded KnuLib to version 6; out-of-combat retries now use its shared queue.

## 3.6.5 (2026-11-18)

- The WoW-Pro guide keeps its column on the left (x 8 to 308) to itself, since it grows downward as it shows more
  steps. Party and raid frames now sit above the left chat and the Battle.net toast, and grow upward, so a small
  group rests on the chat. Raid frames are narrower so they stop before the focus frame: 5 columns of 72 for
  10 and 25 players, 4 columns of two groups for 40. The GM ticket status and the loot window moved out of the
  guide column too. Profiles that still have the old KnuUI positions are moved once, out of combat; anything you
  placed yourself stays where it is.
- Three optional styles, each one a separate ElvUI profile for every role (MDPS, RDPS, Healer, Tank): Bruma
  (minimal), Tablero (utility) and Paréntesis (combat, player and target on both sides of the character). Try
  them from the new Styles page in the installer, or with /knu perfiles, /knu probar <number> and /knu volver.
  Your own profile is never changed, and you get a reload prompt each time you switch.
- The TomTom arrow sits next to the guide instead of over its right edge. If it is still at the old KnuUI spot,
  it moves once; an arrow you placed yourself is kept.

## 3.6.4 (2026-11-17)

- Spell ranks on action bars: two ranks count as the same spell when they share the icon and the name,
  ignoring case and accents. Hammer of Justice was left at rank 1 because the Spanish client capitalizes
  the two ranks differently. KnuUI now also checks every action button against your spellbook on login and
  whenever the spellbook changes, so a button that is already behind gets the highest rank you know. It
  waits until combat ends or until you drop what you are dragging. Macros are not touched.

## 3.6.3 (2026-11-17)

- The WoW-Pro guide returns to its saved position when WoW-Pro leaves it where it creates it, under the
  minimap. WoW-Pro restores the saved position once per session and skips that step in combat, so KnuUI now
  asks it to restore the guide, waiting until combat ends if needed. A guide you dragged, or one placed by the
  command center, stays where it is.
- Flight timer: on a leg you have not flown yet, the time of the opposite direction is used as an estimate.
  The bar says "(approx.)", the countdown starts with ~, and it switches to + if the flight runs longer. The
  real time is saved when you land.

## 3.6.2 (2026-11-16)

- Blizzard panels move only when they overlap the WoW-Pro guide. A panel goes under the guide if it fits there
  whole, to the right of the guide if it fits there, and otherwise stays where Blizzard put it. The talents
  window no longer opens half off screen. Panels follow the guide when it is resized, moved or hidden, and two
  open panels move together.
- Loot roll bars sit at the center of the screen, just above the target frame, and stack upward. Profiles that
  still have the old KnuUI spot next to the guide are moved; a position you set with /moveui is kept.
- Embeds KnuLib-1.0 minor 4: /knu help lists each alias once, and an alias stays with the first Knu addon that
  registered it.

## 3.6.1 (2026-11-16)

- The flight timer keeps long destination names on one line and widens the bar to fit them.
- When the TomTom arrow or its text box overlaps the flight timer, the bar moves 6 px below them. It checks
  again when the arrow appears, moves, is dragged or changes size, and when the interface comes back.
- The PallyPower strip stays to the right of the WoW-Pro guide instead of ending up behind it. It re-anchors
  when the guide is created, shown or hidden, and when PallyPower puts its bar back at its saved position.

## 3.6.0 (2026-11-15)

- Embeds KnuLib-1.0: KnuMail, KnuSonda and other Knu addons follow the active KnuUI theme live.
- Common /knu command shared with the other Knu addons: /knu alone opens the installer, /knu help lists
  every subcommand (apply, cinema, cooldowns, viewers, export, import). /fui keeps working.
- Loot roll bars are larger (full bar, 325x32, 26 px buttons, 13 pt names) and sit to the right of the
  WoW-Pro guide, moving with it when the guide is resized, shown or hidden.
- Fixed the blocked action on level-up (C_UnitAuras.SetHiddenGroupBuffs): KnuUI no longer calls the
  Cooldown Manager's GetItemCount, which tainted its layout data.
- Cooldown Manager icons keep fixed sizes over the left action block and refit by themselves when the
  number of tracked icons changes.

## 3.5.8 (2026-11-13)

- Cooldown Manager moved off the character: the essential, utility and buff icon viewers now sit above the
  left action block, over columns 2 to 5 (the first and sixth stay free), each sized (icon size in 10 % steps
  and padding) to the width of four block buttons. Buff icons use the utility size, since their count changes.
  Focus and pet frames move 4 px above them, at the block edges; the buff bar sits above the left chat.
  If you learn new abilities the manager tracks, /knu enfriamientos (/knu cooldowns) refits them.

## 3.5.7 (2026-11-13)

- Cooldown Manager skin: icon borders are now four 1 px lines anchored to the icon instead of a Blizzard
  backdrop, which recalculated with the viewers' sizes and raised "attempt to perform arithmetic on a secret
  number value" errors in combat.
- The version shown in the addon list is correct again (3.5.6 showed 3.5.5).

## 3.5.6 (2026-11-13)

- Cooldown Manager placed in the KnuUI layout: "Apply all" saves the viewers' positions in your Edit Mode
  layout (a "KnuUI" copy if you were on a Blizzard preset): essential, utility and buff icons in a centred
  column above the target's buffs and debuffs, 4 px apart, using each viewer's real size; the buff bar to the
  right of the target. Healer gets the column to the left of the central group. Option in Addons.
  /knu enfriamientos (or /knu cooldowns) places only the viewers; /knu visores prints where each one is.
- Cooldown Manager skin: icons no longer overlap each other (2 px inside their slot now that Blizzard's round
  mask is removed) and empty buff slots show no border.
- Blizzard panels (character, spellbook, talents, friends...) and OpenMap's world map open 4 px below the
  WoW-Pro guide, aligned with its left edge, instead of on top of it (out of combat only).

## 3.5.5 (2026-11-13)

- "Apply all" now starts from the author's own setup and then applies your role and class on top: action
  bar, aura, chat, tooltip, nameplate and unit frame fonts and options, the intense amber palette,
  decoration, combat glow, raid markers always visible and the author's frame positions. Default mode:
  health/mana columns with the compact right block.
- Blizzard's Cooldown Manager (Forever's Cooldown Viewer) gets the KnuUI look: cropped icons with the thin
  theme border, Expressway timers and counts, Melli bars. Purely visual: the viewers stay where Edit Mode
  puts them. Option in ElvUI > KnuUI > Addons; "Apply all" also turns on ElvUI's skin for its settings.
- Baganator: the bag window title just says "Bags".

## 3.5.4 (2026-11-13)

- Shortest Path Forever's "Use Hearthstone" prompt (shown when a teleport is the faster route) is now a
  themed row right under TomTom's arrow box: small icon and the text in the theme font and accent colour.
  It used to float under the box in large yellow text, where Shortest Path's own arrow would be.
- Hearthstone/teleport with DynamicCam: the interface fades out and back in 0.5 s instead of 2.5 s. The
  camera keeps its slow 2.5 s transition.

## 3.5.3 (2026-11-13)

- Even spacing on the bottom row with health/mana columns: 4 px between chats, side blocks, columns and
  centre bars, and 4 px to the screen edges (gaps used to range from 2 to 7.5 px). Chats are 401 wide and
  the data bar 1102 so everything closes exactly at 1920. Existing profiles are moved once, only for the
  blocks that were still at KnuUI's previous positions.
- Screens smaller than 1920x1080 units (1280x720, 1366x768, 1600x900, 16:10 and 5:4 screens): applying
  the layout sets the UI scale that gives 1920x1080 units, so nothing overlaps (everything looks smaller).
  With ElvUI's automatic scale chats, bars and frames overlapped on those screens.
- The layout test now covers 14 resolutions and checks the bottom-row spacing.

## 3.5.2 (2026-11-13)

- Default layout (without health/mana columns): action bars 5 and 6 are now two 2x6 blocks at the bottom
  right, above the right panel. As 12-button columns they overlapped the raid marker bar under the
  launcher and the loot monitor. The loot monitor now sits to their left. Applies when you (re)apply the
  layout from the installer.
- Baganator: the bag window title is placed between the real buttons of its top bar (measured each time
  it opens) instead of fixed offsets, so it is no longer covered when Baganator shows more buttons.
- Developer tools: an offline layout renderer (tools/render) that computes every block from ElvUI's
  saved settings and lists overlaps, and a test that checks 20 role and option combinations.

## 3.5.1 (2026-11-13)

- Minimap "+" button above the tracking (magnifier) button: doubles the minimap and moves what it would
  cover (buffs, debuffs and anything else to its left move left; what sits below moves down). Click "-" to
  go back; anything you moved by hand while it was big stays where you left it.
- Export / import your whole interface as one text: ElvUI profile (including every KnuUI option, which
  ElvUI's own exporter leaves out), role, KnuUI global options and data panel definitions. Import always
  creates a new profile and never overwrites yours. ElvUI > KnuUI > General > Share, or /knu export and
  /knu import.
- Installer: every button applies right away (no reload needed for most changes) and says in chat what was
  applied; KnuUI's extra buttons use ElvUI's style, text fits inside every button, the decoration button
  no longer covers the logo and the progress bar uses the theme accent.
- The bottom data bar width is recalculated for the active profile on load (it is shared between ElvUI
  profiles and could overlap chat and Details after using another profile).
- Without Offhand, the world map quest log and WoW-Pro's auto resize come back if the command center had
  turned them off.

## 3.5.0 (2026-11-13)

- Offhand support. When Offhand spans the game window over two monitors, ElvUI is fitted to the game
  monitor with the same size and 1 px borders as on a single screen (container, pixel size, minimap
  frames that ignore their parent's scale, and ElvUI movers). Detected automatically: without Offhand, or
  without a real span, nothing changes.
- Command center (Offhand): the workspace monitor gets guide + PallyPower, chat, Details, data bar, map
  and bags; the game monitor keeps only combat. Zones are computed from the edge the workspace shares with
  the game monitor (above, below, left or right; any resolution or orientation): what you look at most sits
  next to that edge. Presets (command center, social, only map and bags, raid, everything on the game
  monitor), a destination per block, unlock to move and reset, in ElvUI > KnuUI > Offhand. Your
  single-screen layout and OpenMap's saved window are left untouched and come back when Offhand is off.
- While flying with the command center active, DynamicCam hides the game monitor's interface but keeps the
  workspace visible (DynamicCam's profile is not changed).
- ElvUI/KnuUI options open on the workspace monitor with the command center.
- Offhand in the K launcher (click: options, Shift: wizard, Ctrl: gather off-screen UI); its minimap button
  is hidden for the session.
- Recommended UI builds per class and role (Builds tab) and 17 colour palettes with official values and a
  preview, including a class-colour palette.
- Options reorganised: General is a status dashboard with quick actions; new Features tab (loot, combat,
  travel, panels); Appearance keeps palettes and decoration.
- /knudiag diagnostic: saves size, scale, position and anchor of every KnuUI block to KnuUI's
  SavedVariables, plus who moved UIParent/ElvUIParent.
- Command center layout, tuned in game: data bar at the top of the workspace with five more datatexts
  (location, time, experience, quests, mail); WoW-Pro guide, chat and Details share one height next to the
  game monitor; PallyPower sits centred at the bottom of the Tiny Threat block, tiles up to 54 px with
  counters scaled to match; Tiny Threat lists at most 10 players; workspace text 4 px larger; 4 px to
  every edge and 6 px between blocks, never over Offhand's border.
- World map on the workspace is map only (no side extras), zoomed a bit on the player; with the quest log
  open (L) the log is aligned with the map, stays inside the border and its side tabs are hidden.
- Game monitor with the command center: everything 24 px lower (no data bar there), right block back to
  6x4, tooltip in the bottom-right corner. Bags open centred on the workspace; Blizzard panels
  (character and others) open centred over the map, 1.25x larger. The chat/Details fade buttons are hidden (not needed there).
- Blizzard's "All objectives" tracker is never shown, in any mode.
- While flying, the data bar stays visible and 3D portraits are hidden (they ignored the fade).
- WoW-Pro use/target buttons stay inside the guide row instead of floating over the chat.
- Offhand's own chat docking (dockChat) is turned off while the chat is on the workspace (it pulled the
  chat out of its panel, e.g. on level up) and restored afterwards.
- Without Offhand, KnuUI gives back the sizes, fonts, data bar, map and tooltip the command center had
  changed, and PallyPower waits for the WoW-Pro guide before placing itself.
- Performance: the command center only redoes sizes, fonts and skins when the window, preset or a
  destination changes; Offhand's gamepad menu scanner (walks thousands of frames every second) is hidden
  when the gamepad is off.
- Known issue (Offhand, not KnuUI): with Offhand loaded, /reload froze the game 35-39 s after logout in
  our tests; without Offhand the same reload did not freeze.

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

## 3.3.0 (2026-11-08): extras

- Combat glow: thin amber gradient on the screen edges while in combat (150 ms in, 300 ms out).
  Toggle in ElvUI > KnuUI.
- Experience bar tooltip: session experience per hour and time to the next level.
- Per-character role: each character remembers its role; logging in with a shared profile
  applies it and offers a reload.
- Cinema mode: hides the interface and slowly orbits the camera; ends on entering combat.
  Key binding (Key Bindings > AddOns > KnuUI), `/knu cine` or the ElvUI option.
- Test suite updated (7 installer pages, opt-in DBM, roles and extras).

## 3.2.0 (2026-11-08): role profiles

- New installer page and ElvUI option: **Tank, MDPS, RDPS and Healer**, applied on top of the
  base layout and the column mode (switching roles does not touch the rest of the profile).
- Tank: threat borders on player, party and raid frames, threat icon on nameplates.
- MDPS: the base layout.
- RDPS: 340×32 cast bar and 32 px target debuffs.
- Healer: party and raid in the centre above the main bars (as Eltruism and LuckyoneUI do),
  incoming heals and HoT indicators on, small debuffs on party frames.
- The old "Tanks on/off" buttons are now "Columns on/off" (vertical health/mana columns).

## 3.1.0 (2026-11-08): skins de addons

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

## 3.0.0 (2026-11-08): first public build

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
