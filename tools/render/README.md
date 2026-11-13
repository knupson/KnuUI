# Renderizador offline de KnuUI

Desde la raíz del repositorio, con LuaJIT 2.1 o Lua 5.1:

```powershell
luajit addons/KnuUI/tools/render/render.lua --sv '<WoW>/_forever_/WTF/Account/<cuenta>/SavedVariables/ElvUI.lua' --char '<Personaje>' --out addons/KnuUI/tools/render/layout.html
```

Abrí `layout.html` en un navegador. `--res WxH` elige la resolución física (por defecto `1920x1080`). El lienzo usa unidades de UIParent: `alto = 768 / escala`, `ancho = alto × anchoFísico / altoFísico`. HTML usa `top = altoLienzo - bottom - height`. El JSON contiguo incluye escala, resolución, lienzo, rectángulos, intersecciones, salidas de pantalla, omisiones y advertencias.

Se conserva `ElvDB.global.general.UIScale` guardada (también si es una cadena numérica). Sin ese ajuste explícito se usa la escala automática solicitada: `clamp(768 / altoFísico, 0.4, 1.15)`. El default distribuido `G.general.UIScale = 0.64` (`Defaults/Global.lua:5`) no se toma como elección guardada. ElvUI configura la escala global, no una escala por perfil.

Referencias bajo `_ref/ElvUI/Game/Shared/`: `General/Core.lua:75-78` deriva la resolución y `perfect`; `General/PixelPerfect.lua:52` deriva `mult`, `:59-62` aplica la escala y consulta las dimensiones lógicas, `:76-80` dimensiona E.UIParent, `:92-100` define la escala automática. La normalización WoW de 768 unidades de alto antes de aplicar escala se modela con la fórmula anterior; la implementación nativa de GetScreenHeight no está en `_ref`. `General/Install.lua:1386` aplica Auto Scale. Esta referencia no contiene `PixelClip`: el límite está directamente en PixelBestSize.

KnuUI no asigna UIScale general. `addons/KnuUI/Offhand.lua:35-53` sólo deriva una escala alternativa cuando existe una topología Companion estirada; ese escenario queda fuera de esta simulación de una pantalla.

`--profile` elige directamente un perfil y prevalece sobre `--char`. Conviene pasar también `--char` para cargar su perfil de `ElvPrivateDB`. Sin ninguno, sólo se permite selección automática si existe un único personaje. Las SavedVariables se ejecutan con `loadfile`/`setfenv` en una tabla vacía; se leen, nunca se escriben. Como cualquier archivo Lua, deben ser de confianza: el entorno vacío no impone límites de CPU o memoria.

Las referencias `archivo:línea` junto a las fórmulas en `models.lua` corresponden al código local de `_ref/ElvUI/Game/Shared/` y de KnuUI. Los defaults P/G/V y los temas se cargan del código existente en entornos separados; las posiciones KnuUI se leen de su tabla `movers` sin ejecutar Layout.lua.

## Alcance y aproximaciones

- Party y raid se representan por el header de grupos completos según `Configure_Groups`, incluyendo `infoPanel`, espacios y dirección. No se conoce el roster real ni se agregan mascotas o elementos externos al bloque.
- Las auras muestran la capacidad máxima `wrapAfter × maxWraps`, con espacios del contenedor Modern. `moverWidth`/`moverHeight` conservan la fila inicial usada para resolver cadenas. La cantidad real de auras y su reflujo requieren el cliente.
- El minimapa incluye el tamaño del holder y el panel inferior si está habilitado. `Minimap` y `ElvUI_MinimapHolder` tienen geometrías distintas al resolver referencias.
- Las barras usan hasta 12 botones por barra, altura configurable, espacios, backdrop y sus multiplicadores. Los rectángulos representan el mover, sin iconos que sobresalgan o decoraciones.
- Los cinco movers creados por KnuUI tienen tamaños conocidos. Vuelo y botín se muestran en su tamaño reservado aunque en juego se creen al usarlos. La barra de marcas se incluye salvo modo `off`; el tanque sólo con `KnuUITanks`.
- Los movers restantes son marcadores de 20×20 y llevan `(size unknown)`, borde discontinuo y `unknown: true` en JSON. Las intersecciones que involucran esos marcadores son indicativas; `uncertain` también identifica grupos y auras aproximados.
- No se evalúan visibilidad, combate, mouseover ni escalas añadidas por plugins. Party/raid/arena/jefes se excluyen mutuamente al buscar solapes. No se simula el redondeo de `E:Scale`, ni los recortes opcionales eyefinity/ultrawide (`PixelPerfect.lua:24-48,64-78`). El tema `class` usa su acento de respaldo porque la clase no se deduce de estas SavedVariables.
- Se informa cada borde que sobresale más de 1 unidad, también para marcadores desconocidos (con `uncertain = true`). Ancho y alto describen la franja fuera de pantalla. HTML los marca en rojo; stdout y JSON los enumeran como `bloque/pantalla:borde`.
- Una referencia ausente o un ciclo omite el bloque y se informa en stdout, HTML y JSON. Los bloques conocidos deshabilitados no se convierten en marcadores.

## Verificación

```powershell
luajit addons/KnuUI/tools/render/tests.lua '<WoW>/_forever_/WTF/Account/<cuenta>/SavedVariables/ElvUI.lua'
```

Prueba selección de perfil, aislamiento, merge, geometría de los nueve anclajes, cadenas, ciclos, referencias ausentes, umbral de intersección, escapes JSON y variantes de tamaños. También compara las SavedVariables antes y después.

Sin argumento ejecuta las pruebas independientes de SavedVariables, incluyendo escala y bordes. `luajit addons/KnuUI/tests/render-roles.lua` ejecuta 20 configuraciones en ocho resoluciones (160 casos), con escala automática y sin excepciones. Arma cada perfil y sus modelos una vez por configuración. Falla ante solapes, salidas de pantalla o referencias sin resolver; al final imprime la tabla por resolución y todos los pares distintos con tamaños y frecuencias. Los solapes de auras y grupos representan su capacidad máxima, no un roster observado.

`layout.html`, `layout.html.json` y `stdout.txt` son los resultados de la corrida de referencia; no contienen la base completa de SavedVariables.
