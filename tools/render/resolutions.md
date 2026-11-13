# KnuUI: matriz de resoluciones

Escala automática, sin SavedVariables: 20 perfiles/opciones, 160 geometrías. ALLOWED vacío. Resultado: 539 solapes, cero salidas de pantalla y cero referencias sin resolver. La prueba termina con código 1 por los problemas reales. Los tamaños son ancho × alto en unidades; [n] indica combinaciones. Auras y grupos usan su capacidad máxima; falta confirmar concurrencia en juego.

| Resolución | Escala | Lienzo | Combinaciones con problemas / 20 |
|---|---:|---|---:|
| 1280x720 | 1.06666667 | 1280x720 | 20 |
| 1366x768 | 1 | 1366x768 | 20 |
| 1600x900 | 0.853333333 | 1600x900 | 20 |
| 1920x1080 | 0.711111111 | 1920x1080 | 0 |
| 2560x1080 | 0.711111111 | 2560x1080 | 0 |
| 2560x1440 | 0.533333333 | 2560x1440 | 0 |
| 3440x1440 | 0.533333333 | 3440x1440 | 0 |
| 3840x2160 | 0.4 | 3413.33x1920 | 0 |

## Pares distintos y tamaños

| Par | 1280×720 | 1366×768 | 1600×900 |
|---|---|---|---|
| `BuffsMover/ElvUF_Raid3Mover` | 244x36 [4] | — | — |
| `BuffsMover/KnuUI_FlightTimerMover` | 156x16 [20] | 113x16 [20] | — |
| `DTPanelKnuUI_DataMover/LeftChatMover` | 314.5x20 [8]; 314x20 [12] | 271.5x20 [8]; 271x20 [12] | 154.5x20 [8]; 154x20 [12] |
| `DTPanelKnuUI_DataMover/RightChatMover` | 313.5x20 [8]; 314x20 [12] | 270.5x20 [8]; 271x20 [12] | 153.5x20 [8]; 154x20 [12] |
| `DebuffsMover/ElvUF_Raid1Mover` | 244x16 [4] | — | — |
| `DebuffsMover/ElvUF_Raid2Mover` | 244x16 [4] | — | — |
| `DebuffsMover/ElvUF_Raid3Mover` | 244x36 [4] | 201x36 [4] | — |
| `ElvAB_1/LeftChatMover` | 114x35 [8] | 71x35 [8] | — |
| `ElvAB_1/RightChatMover` | 114x35 [8] | 71x35 [8] | — |
| `ElvAB_2/LeftChatMover` | 114x35 [8] | 71x35 [8] | — |
| `ElvAB_2/RightChatMover` | 114x35 [8] | 71x35 [8] | — |
| `ElvAB_3/LeftChatMover` | 127x154 [8]; 145x124 [4]; 256x76 [8] | 102x124 [4]; 127x154 [8]; 256x76 [8] | 127x154 [8]; 154x76 [8] |
| `ElvAB_4/RightChatMover` | 127x154 [8]; 145x124 [4]; 256x76 [8] | 102x124 [4]; 127x154 [8]; 256x76 [8] | 127x154 [8]; 152x76 [8] |
| `ElvAB_5/KnuUI_RaidMarkersMover` | 26x202 [4] | 26x196 [4] | 26x64 [4] |
| `ElvAB_5/LeftChatMover` | 256x76 [8] | 256x76 [8] | 154x76 [8] |
| `ElvAB_6/RightChatMover` | 256x76 [8] | 256x76 [8] | 152x76 [8] |
| `ElvUF_FocusMover/ElvUF_PartyMover` | 23.5x4 [15] | — | — |
| `ElvUF_PlayerMover/LeftChatMover` | 219x22 [4]; 53x154 [8]; 66x154 [8] | 10x154 [8]; 176x22 [4]; 66x154 [8] | 22x154 [8]; 59x22 [4] |
| `ElvUF_Raid3Mover/KnuUI_FlightTimerMover` | 240x18 [4] | — | — |
| `ElvUF_TargetMover/RightChatMover` | 219x22 [4] | 176x22 [4] | 59x22 [4] |
| `KnuUI_ManaTankMover/RightChatMover` | 53x154 [8]; 66x154 [8] | 10x154 [8]; 66x154 [8] | 22x154 [8] |

En las otras cinco resoluciones no aparecen problemas. No se encontró ningún par bloque/pantalla:borde.

## Causa y opciones por par

Las causas siguientes explican la intersección geométrica; no prueban que ambos elementos se vean juntos en el cliente. Todas las opciones quedan pendientes de tu decisión; no se modificó el addon. Las rutas de esta sección son relativas a `addons/KnuUI/`.

### `BuffsMover/ElvUF_Raid3Mover`

Auras desde arriba a la derecha (`Layout.lua:70,270-274`); banda Healer centrada creciendo hacia arriba desde y=340 (`Roles.lua:74,92,99`). Al bajar ancho y alto, las capacidades máximas comparten área.

1. Distribuir auras en un lateral con columnas adaptadas al espacio libre: conserva banda, cambia ubicación y lectura de auras. 2. Reducir altura/espaciado de banda en pantallas bajas: conserva ubicación de auras, reduce objetivos de sanación.

### `BuffsMover/KnuUI_FlightTimerMover`

Buffs de 12 iconos por 3 filas (`Layout.lua:270-274`) desde arriba a la derecha (`Layout.lua:70`), frente al temporizador centrado a -120 (`Flight.lua:36,38`). Al reducir ancho, las auras alcanzan el centro.

1. Mover el temporizador debajo del bloque de auras: mantiene iconos, baja la información de vuelo. 2. Reducir wrapAfter según ancho disponible: evita ocupar el centro, agrega filas y exige mover perjuicios.

### `DTPanelKnuUI_DataMover/LeftChatMover`

Panel de datos centrado de 1100 unidades (`Layout.lua:307`) y chat anclado al borde (`Layout.lua:41`, `:42`), con ancho 400 (`Layout.lua:294`). Los compactos ajustan anchos y centro con 129 unidades fijas (`Tanks.lua:35`, `:60`, `:63`, `:64`), sin considerar el ancho del lienzo.

1. Limitar el panel de datos al hueco entre chats: conserva posición, pero aprieta ocho textos. 2. Poner datos en una franja inferior y levantar ambos chats: conserva anchos, pero consume altura.

### `DTPanelKnuUI_DataMover/RightChatMover`

Panel de datos centrado de 1100 unidades (`Layout.lua:307`) y chat anclado al borde (`Layout.lua:41`, `:42`), con ancho 400 (`Layout.lua:294`). Los compactos ajustan anchos y centro con 129 unidades fijas (`Tanks.lua:35`, `:60`, `:63`, `:64`), sin considerar el ancho del lienzo.

1. Limitar el panel de datos al hueco entre chats: conserva posición, pero aprieta ocho textos. 2. Poner datos en una franja inferior y levantar ambos chats: conserva anchos, pero consume altura.

### `DebuffsMover/ElvUF_Raid1Mover`

Auras desde arriba a la derecha (`Layout.lua:71,270-274`); banda Healer centrada creciendo hacia arriba desde y=340 (`Roles.lua:74,92,99`). Al bajar ancho y alto, las capacidades máximas comparten área.

1. Distribuir auras en un lateral con columnas adaptadas al espacio libre: conserva banda, cambia ubicación y lectura de auras. 2. Reducir altura/espaciado de banda en pantallas bajas: conserva ubicación de auras, reduce objetivos de sanación.

### `DebuffsMover/ElvUF_Raid2Mover`

Auras desde arriba a la derecha (`Layout.lua:71,270-274`); banda Healer centrada creciendo hacia arriba desde y=340 (`Roles.lua:74,92,99`). Al bajar ancho y alto, las capacidades máximas comparten área.

1. Distribuir auras en un lateral con columnas adaptadas al espacio libre: conserva banda, cambia ubicación y lectura de auras. 2. Reducir altura/espaciado de banda en pantallas bajas: conserva ubicación de auras, reduce objetivos de sanación.

### `DebuffsMover/ElvUF_Raid3Mover`

Auras desde arriba a la derecha (`Layout.lua:71,270-274`); banda Healer centrada creciendo hacia arriba desde y=340 (`Roles.lua:74,92,99`). Al bajar ancho y alto, las capacidades máximas comparten área.

1. Distribuir auras en un lateral con columnas adaptadas al espacio libre: conserva banda, cambia ubicación y lectura de auras. 2. Reducir altura/espaciado de banda en pantallas bajas: conserva ubicación de auras, reduce objetivos de sanación.

### `ElvAB_1/LeftChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Layout.lua:45; Tanks.lua:26`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvAB_1/RightChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Layout.lua:45; Tanks.lua:26`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvAB_2/LeftChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Layout.lua:46; Tanks.lua:27`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvAB_2/RightChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Layout.lua:46; Tanks.lua:27`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvAB_3/LeftChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Layout.lua:48; Tanks.lua:21,37`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvAB_4/RightChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Layout.lua:49; Tanks.lua:23,38`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvAB_5/KnuUI_RaidMarkersMover`

Barra 5 desde abajo a y=240 (`Layout.lua:52`); marcas colgando del lanzador desde arriba (`Layout.lua:64; RaidMarkers.lua:16,102,106`). La separación entre ambos extremos disminuye al bajar la altura.

1. Pasar marcas a una fila horizontal bajo el minimapa: libera altura, consume ancho. 2. Anclar marcas sobre la barra 5: mantiene columna, cambia su vínculo visual con el lanzador y requiere revisar minimapa.

### `ElvAB_5/LeftChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Tanks.lua:22`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvAB_6/RightChatMover`

Barra centrada con desplazamiento y tamaño fijos (`Tanks.lua:24`), frente a chat pegado al borde (`Layout.lua:41,42,294`). Los compactos ensanchan el chat sin consultar el lienzo (`Tanks.lua:60`).

1. Limitar el ancho del chat al borde de esta barra: mantiene botones, reduce espacio de lectura. 2. Reubicar esta barra sobre el chat con anclas relativas: conserva chat, ocupa altura y puede exigir mover unidades.

### `ElvUF_FocusMover/ElvUF_PartyMover`

Foco a y=226 desde abajo (`Layout.lua:61`); grupo de cinco marcos hacia abajo desde mitad de pantalla +110 (`Layout.lua:65,236-237`). A 720 de alto, el grupo llega al foco.

1. Anclar foco junto al jugador: mantiene el grupo, exige revisar mascota y lanzamiento. 2. Anclar el grupo desde arriba con margen suficiente: estabiliza altura, puede ocupar la guía de WoW-Pro.

### `ElvUF_PlayerMover/LeftChatMover`

Unidad o columna con posición fija desde el centro (`Layout.lua:59; Tanks.lua:168`), mientras el chat ocupa 400 o 529 unidades desde el borde (`Layout.lua:294; Tanks.lua:60`). El hueco horizontal se reduce con el lienzo.

1. Acotar el chat según el borde de la unidad: conserva lectura de salud, reduce chat. 2. Subir la unidad encima del chat: mantiene anchos, cambia la zona de atención y requiere revisar foco/grupos.

### `ElvUF_Raid3Mover/KnuUI_FlightTimerMover`

Banda Healer creciendo hacia arriba desde y=340 con columnas (`Roles.lua:74,92,99`), frente al temporizador a 120 del techo (`Flight.lua:38`). El techo de 720 deja ambos bloques en la misma franja central.

1. Mover el temporizador a un lateral libre: conserva banda, requiere revisar guía/auras. 2. Reducir altura/espaciado de banda según espacio vertical: conserva anclas, reduce legibilidad y tamaño de objetivos.

### `ElvUF_TargetMover/RightChatMover`

Unidad o columna con posición fija desde el centro (`Layout.lua:60`), mientras el chat ocupa 400 o 529 unidades desde el borde (`Layout.lua:294; Tanks.lua:60`). El hueco horizontal se reduce con el lienzo.

1. Acotar el chat según el borde de la unidad: conserva lectura de salud, reduce chat. 2. Subir la unidad encima del chat: mantiene anchos, cambia la zona de atención y requiere revisar foco/grupos.

### `KnuUI_ManaTankMover/RightChatMover`

Unidad o columna con posición fija desde el centro (`Tanks.lua:169`), mientras el chat ocupa 400 o 529 unidades desde el borde (`Layout.lua:294; Tanks.lua:60`). El hueco horizontal se reduce con el lienzo.

1. Acotar el chat según el borde de la unidad: conserva lectura de salud, reduce chat. 2. Subir la unidad encima del chat: mantiene anchos, cambia la zona de atención y requiere revisar foco/grupos.

## Escala y validación

Referencias de ElvUI bajo `_ref/ElvUI/Game/Shared/`: `General/Core.lua:75-78`, `General/PixelPerfect.lua:52,59-81,92-100`, `General/Install.lua:1386`. `alto=768/escala`; `ancho=alto×aspecto`. El alto base 768 es la convención de WoW modelada, no una implementación nativa incluida en la referencia. No hay PixelClip en esta copia: PixelBestSize usa Clamp. Sin escala guardada se usa Auto Scale, no el default distribuido 0.64 (`Defaults/Global.lua:5`).

`verificar.lua`: pasa. `tools/render/tests.lua`: 69 verificaciones; integración con SavedVariables reales omitida por falta de archivo. CLI/HTML/JSON probados con SavedVariables sintéticas a 1280×720, 3840×2160 y 1366×768, incluyendo UIScale guardada como cadena 0.64. Sin git.
