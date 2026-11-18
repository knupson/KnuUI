# Perfiles de estilo de KnuUI

`/knu perfiles` crea doce perfiles vacíos con cuatro marcas propias; no copia el perfil actual ni cambia de perfil. Repetirlo conserva los existentes. `/knu perfiles rehacer` recrea sólo perfiles con prefijo `KnuUI ` y `KnuUIStyle`, salvo el activo, que siempre se conserva. `/knu probar <número|nombre completo>` guarda el perfil actual y cambia al elegido; `/knu volver` recupera el anterior. Los cuatro comandos rechazan el combate.

## Coordenadas finales

Unidades de ElvUIParent a 1920×1080. Origen arriba a la izquierda; las dos columnas de unidades indican **centros**. La columna de lanzamiento indica **izquierda, arriba, ancho, alto**, incluyendo la reserva del ícono externo. El holder de lanzamiento queda centrado en x=960; el ícono sale hacia la izquierda.

| N.º | Estilo / categoría | Rol | Jugador | Objetivo | Lanzamiento, incluido ícono |
|---|---|---|---|---|---|
| 1 | Bruma / Minimalista | MDPS | 720,790 | 1200,790 | 783,900,327,24 |
| 2 | Bruma / Minimalista | RDPS | 720,790 | 1200,790 | 755,900,375,32 |
| 3 | Bruma / Minimalista | Healer | 620,790 | 1300,790 | 783,900,327,24 |
| 4 | Bruma / Minimalista | Tank | 720,790 | 1200,790 | 783,900,327,24 |
| 5 | Tablero / Utilidad | MDPS | 740,800 | 1180,800 | 783,865,327,24 |
| 6 | Tablero / Utilidad | RDPS | 740,800 | 1180,800 | 755,865,375,32 |
| 7 | Tablero / Utilidad | Healer | 620,800 | 1300,800 | 783,900,327,24 |
| 8 | Tablero / Utilidad | Tank | 740,800 | 1180,800 | 783,865,327,24 |
| 9 | Paréntesis / Combate | MDPS | 700,750 | 1220,750 | 783,845,327,24 |
| 10 | Paréntesis / Combate | RDPS | 700,750 | 1220,750 | 755,845,375,32 |
| 11 | Paréntesis / Combate | Healer | 620,750 | 1300,750 | 783,900,327,24 |
| 12 | Paréntesis / Combate | Tank | 700,750 | 1220,750 | 783,845,327,24 |

Jugador y objetivo miden 210×44 en Bruma, 240×54 en Tablero y 220×48 en Paréntesis, con poder integrado y sin retrato. Foco: 115×24, alineado al borde izquierdo del jugador, 8 unidades arriba. Mascota: 115×24, mismo borde, 8 abajo. Objetivo del objetivo: 92×24, alineado al borde derecho del objetivo, 8 abajo.

Los siguientes rectángulos usan **izquierda, arriba, ancho, alto**:

| Elemento | Bruma | Tablero | Paréntesis |
|---|---|---|---|
| Perjuicios (MDPS/RDPS/Tank) | 619,648,212,74 | 1244,148,476,36 | 594,606,236,82 |
| Perjuicios (Healer) | 519,648,212,74 | 1244,148,476,36 | 514,606,236,82 |
| Grupo (MDPS/RDPS/Tank) | 4,610,200,224 | 320,420,200,224 | 4,610,200,224 |
| Banda 1/2 (MDPS/RDPS/Tank) | 4,710,416,152 | 4,710,416,152 | 4,710,416,152 |
| Banda 3 (MDPS/RDPS/Tank) | 4,614,416,248 | 4,614,416,248 | 4,614,416,248 |
| Barra 3 | Desactivada | 579,928,166,124 | 465,952,310,24 |
| Barra 4 | Desactivada | 1175,928,166,124 | 1145,952,310,24 |

El Healer conserva las dimensiones y los cuatro movers de `Roles.lua`, anclados abajo al centro en y=204: grupo 747,830,426,46; bandas 1/2 752,664,416,212; banda 3 752,596,416,280. Los estilos colocan las unidades a los costados y el lanzamiento debajo de esa grilla. RDPS conserva lanzamiento de 340×32 e ícono de 32; los otros roles usan 300×24 e ícono de 24. Tank conserva los bordes de amenaza y el indicador de placas.

| Elemento común | Rectángulo |
|---|---|
| Barra 1 | 781,992,358,28 |
| Barra 2 | 781,1024,358,28 |
| Barra 5 | 1850,638,66,202 |
| Barra 6 | 1780,638,66,202 |
| Experiencia | 781,934,358,4 |
| Acciones de mascota | 831,940,258,24 |
| Posturas, reserva de diez botones | 851,968,218,20 |
| Beneficios | 1244,8,476,128 |
| Tiradas, reserva de cinco hacia arriba con holder | 1547.5,430,325,200 |
| Monitor de botín | 1512,690,260,150 |
| Arena/jefes, reserva de cinco unidades | 1345,370,180,224 |
| Aviso de Battle.net | 430,870,250,50 |

Las anclas a unidades y a los bordes conservan separaciones en otras resoluciones; las coordenadas anteriores describen el lienzo de referencia, no píxeles físicos de cualquier pantalla. La guía conserva x=8–308 hasta y=600, inclusive frente a los marcadores desconocidos del renderizador.

## Inicialización y datos compartidos

Al cargar o seleccionar un perfil pendiente, se ejecutan `ApplyLayout`, `ApplyChat`, `ApplyNameplates`, `ApplyTracker`, `ApplyTheme`, `ApplyBase`, `ApplyRoleOverlay` y `ApplyStyle`, en ese orden. `ApplyLayout` también llama internamente al overlay existente. Se confirma la versión, se limpia la marca y se recarga una vez. En combate se espera `PLAYER_REGEN_ENABLED` y se vuelve a verificar el perfil activo. El callback de cambio de perfil espera un cuadro para que ElvUI actualice `E.db`, sin depender del orden de callbacks de AceDB.

No se llaman `ApplyCamera`, `ApplyCooldownLayout`, `ApplyAddons`, `ApplyTanks` ni `ApplyRole`. `ApplyTracker` sólo escribe `E.db`. `Extras.SyncRole` ignora perfiles con `KnuUIStyle`.

Las escrituras compartidas que ya hacen los pasos incluidos son idempotentes para una misma pantalla: `E.global.general.UIScale` cuando hace falta reducir la escala; `E.private.skins.blizzard.alertframes=true`; y la definición fija del panel `E.global.datatexts.customPanels.KnuUI_Data` (1102×22, ocho puntos). La prueba repite la inicialización y compara profundamente `E.global` y `E.private`. Eso no implica que la primera aplicación conserve valores compartidos diferentes. Ningún paso del circuito de estilos escribe `E.private.KnuUIRole`. El comando `probar` guarda por separado `E.global.KnuUIPreviousProfile`.

## Validación y alcance

`tests/render-roles.lua`: 32 configuraciones × 14 resoluciones = 448 casos, incluidos los doce estilos; cero solapes detectados, cero salidas, cero referencias sin resolver y cero invasiones de la columna de WoWPro. Sin excepciones agregadas. Además comprueba las posiciones del Healer, el rol privado, las columnas apagadas y los overlays de Tank/RDPS.

Los diez archivos de `tests/`, excluido `addon-skins.lua` como ejecución independiente, pasan con LuaJIT. `tools/render/tests.lua` pasa sus 69 verificaciones independientes; omite integración con SavedVariables reales por falta de archivo proporcionado.

La geometría es una simulación: las auras y grupos representan capacidades máximas; los marcos sin modelo siguen siendo marcadores desconocidos y no se consideran solapes entre bloques. No se probó dentro del juego, ni con SavedVariables reales, ni se escribieron archivos en la instalación del juego. Las alertas de tamaño variable y los subelementos externos de arena/jefes requieren validación en el cliente.
