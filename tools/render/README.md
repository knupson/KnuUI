# Renderizador offline de KnuUI

Desde la raíz del repositorio, con LuaJIT 2.1 o Lua 5.1:

```powershell
luajit addons/KnuUI/tools/render/render.lua --sv '<WoW>/_forever_/WTF/Account/<cuenta>/SavedVariables/ElvUI.lua' --char '<Personaje>' --out addons/KnuUI/tools/render/layout.html
```

Abrí `layout.html` en un navegador. El lienzo mide 1920×1080, con desplazamiento horizontal si hace falta. El JSON contiguo es `layout.html.json`: incluye rectángulos, posiciones originales, intersecciones, omisiones y advertencias. El origen de `left`/`bottom` está abajo a la izquierda; HTML usa `top = 1080 - bottom - height`.

`--profile` elige directamente un perfil y prevalece sobre `--char`. Conviene pasar también `--char` para cargar su perfil de `ElvPrivateDB`. Sin ninguno, sólo se permite selección automática si existe un único personaje. Las SavedVariables se ejecutan con `loadfile`/`setfenv` en una tabla vacía; se leen, nunca se escriben. Como cualquier archivo Lua, deben ser de confianza: el entorno vacío no impone límites de CPU o memoria.

Las referencias `archivo:línea` junto a las fórmulas en `models.lua` corresponden al código local de `_ref/ElvUI/Game/Shared/` y de KnuUI. Los defaults P/G/V y los temas se cargan del código existente en entornos separados; las posiciones KnuUI se leen de su tabla `movers` sin ejecutar Layout.lua.

## Alcance y aproximaciones

- Party y raid se representan por el header de grupos completos según `Configure_Groups`, incluyendo `infoPanel`, espacios y dirección. No se conoce el roster real ni se agregan mascotas o elementos externos al bloque.
- Las auras muestran la capacidad máxima `wrapAfter × maxWraps`, con espacios del contenedor Modern. `moverWidth`/`moverHeight` conservan la fila inicial usada para resolver cadenas. La cantidad real de auras y su reflujo requieren el cliente.
- El minimapa incluye el tamaño del holder y el panel inferior si está habilitado. `Minimap` y `ElvUI_MinimapHolder` tienen geometrías distintas al resolver referencias.
- Las barras usan hasta 12 botones por barra, altura configurable, espacios, backdrop y sus multiplicadores. Los rectángulos representan el mover, sin iconos que sobresalgan o decoraciones.
- Los cinco movers creados por KnuUI tienen tamaños conocidos. Vuelo y botín se muestran en su tamaño reservado aunque en juego se creen al usarlos. La barra de marcas se incluye salvo modo `off`; el tanque sólo con `KnuUITanks`.
- Los movers restantes son marcadores de 20×20 y llevan `(size unknown)`, borde discontinuo y `unknown: true` en JSON. Las intersecciones que involucran esos marcadores son indicativas; `uncertain` también identifica grupos y auras aproximados.
- No se evalúan visibilidad, combate, mouseover, exclusión entre party/raid/arena ni escalas añadidas por plugins. Se usa la equivalencia solicitada de 1 unidad = 1 píxel, sin simular el redondeo de `E:Scale`. El tema `class` usa su acento de respaldo porque la clase no se deduce de estas SavedVariables.
- Una referencia ausente o un ciclo omite el bloque y se informa en stdout, HTML y JSON. Los bloques conocidos deshabilitados no se convierten en marcadores.

## Verificación

```powershell
luajit addons/KnuUI/tools/render/tests.lua '<WoW>/_forever_/WTF/Account/<cuenta>/SavedVariables/ElvUI.lua'
```

Prueba selección de perfil, aislamiento, merge, geometría de los nueve anclajes, cadenas, ciclos, referencias ausentes, umbral de intersección, escapes JSON y variantes de tamaños. También compara las SavedVariables antes y después.

`layout.html`, `layout.html.json` y `stdout.txt` son los resultados de la corrida de referencia; no contienen la base completa de SavedVariables.
