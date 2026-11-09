"""Genera el logo y los íconos de KnuUI en TGA (32 bits, sin compresión).

Uso desde la raíz del repo:  python addons/KnuUI/tools/generar_media.py
Salida: addons/KnuUI/media/*.tga (+ vistas previas .png en tools/preview/).
"""
import math
import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE = pathlib.Path(__file__).resolve().parent.parent
MEDIA = BASE / "media"
PREVIEW = BASE / "tools" / "preview"

# Paleta KnuUI = identidad de knunet.com (variables CSS de :root, leídas 2026-11-08):
# --amber-hi #ffc06a, --amber #ffa82e, --amber-dim #b07428, --bg #110c08, --text #ecd9bd.
# Los nombres CIAN/MAGENTA quedan por compatibilidad: son los extremos del degradé.
CIAN = (255, 192, 106)     # amber-hi
MAGENTA = (176, 116, 40)   # amber-dim
DORADO = (255, 168, 46)    # amber
FONDO = (17, 12, 8)        # bg
BLANCO = (236, 217, 189)   # text

FUENTE_NEGRA = r"C:\Windows\Fonts\bahnschrift.ttf"  # condensada, parecida a Barlow Condensed de knunet


def fuente_condensada(tam):
    f = ImageFont.truetype(FUENTE_NEGRA, tam)
    try:
        f.set_variation_by_name("Bold Condensed")
    except Exception:
        pass
    return f


def franjas(ancho=64, alto=16, paso=16):
    """Franjas de peligro ámbar/negro en diagonal, repetibles en horizontal."""
    img = Image.new("RGBA", (ancho, alto), (*FONDO, 255))
    d = ImageDraw.Draw(img)
    for x in range(-alto, ancho + alto, paso):
        d.polygon([(x, alto), (x + paso // 2, alto), (x + paso // 2 + alto, 0), (x + alto, 0)], fill=(*DORADO, 255))
    return img


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def degradado(size, c1, c2, angulo=35):
    """Degradado lineal c1 -> c2 en RGBA."""
    w, h = size
    img = Image.new("RGBA", size)
    px = img.load()
    rad = math.radians(angulo)
    dx, dy = math.cos(rad), math.sin(rad)
    largo = abs(w * dx) + abs(h * dy)
    for y in range(h):
        for x in range(w):
            t = ((x * dx + y * dy) / largo) % 1.0
            px[x, y] = (*lerp(c1, c2, t), 255)
    return img


def hexagono(cx, cy, r, rot=90):
    return [
        (cx + r * math.cos(math.radians(rot + 60 * i)), cy + r * math.sin(math.radians(rot + 60 * i)))
        for i in range(6)
    ]


def emblema(lado):
    """Hexágono con borde neón y una K geométrica adentro."""
    s = 4  # supermuestreo para bordes suaves
    L = lado * s
    cx = cy = L / 2
    r = L * 0.46

    mascara_borde = Image.new("L", (L, L), 0)
    d = ImageDraw.Draw(mascara_borde)
    d.polygon(hexagono(cx, cy, r), fill=255)
    d.polygon(hexagono(cx, cy, r * 0.84), fill=0)

    relleno = Image.new("L", (L, L), 0)
    ImageDraw.Draw(relleno).polygon(hexagono(cx, cy, r * 0.84), fill=255)

    # K: asta vertical + dos brazos diagonales.
    k = Image.new("L", (L, L), 0)
    dk = ImageDraw.Draw(k)
    g = L * 0.085  # grosor
    x0, y0, y1 = cx - L * 0.17, cy - L * 0.24, cy + L * 0.24
    dk.rectangle([x0, y0, x0 + g, y1], fill=255)
    # Brazos como polígonos que nacen del asta, sin huecos en la unión.
    xa, xb = x0 + g * 0.6, cx + L * 0.21
    dk.polygon([(xa, cy - g * 0.55), (xb - g * 1.1, y0), (xb + g * 0.15, y0), (xa + g * 0.9, cy + g * 0.35)], fill=255)
    dk.polygon([(xa + g * 0.35, cy - g * 0.35), (xa + g * 1.5, cy - g * 0.9), (xb + g * 0.15, y1), (xb - g * 1.1, y1)], fill=255)

    capa = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    capa.paste(Image.new("RGBA", (L, L), (*FONDO, 235)), (0, 0), relleno)
    grad = degradado((L, L), CIAN, MAGENTA)
    capa.paste(grad, (0, 0), mascara_borde)
    capa.paste(Image.new("RGBA", (L, L), (*BLANCO, 255)), (0, 0), k)

    # Brillo exterior del borde.
    brillo = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    brillo.paste(grad, (0, 0), mascara_borde)
    brillo = brillo.filter(ImageFilter.GaussianBlur(L * 0.03))
    salida = Image.alpha_composite(brillo, capa)
    return salida.resize((lado, lado), Image.LANCZOS)


def logo(ancho=512, alto=256):
    s = 2
    W, H = ancho * s, alto * s
    lienzo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    em = emblema(int(H * 0.78 / s) * s).resize((int(H * 0.78), int(H * 0.78)), Image.LANCZOS)
    ey = (H - em.height) // 2
    lienzo.alpha_composite(em, (int(W * 0.03), ey))

    tx = int(W * 0.03) + em.width + int(W * 0.03)
    base_y = H // 2
    d = ImageDraw.Draw(lienzo)
    # Ajusta el tamaño para que "KNUUI" entre en el ancho disponible.
    disponible = W - tx - int(W * 0.04)
    tam = int(H * 0.42)
    while True:
        fuente = fuente_condensada(tam)
        if d.textlength("KNUUI", font=fuente) <= disponible:
            break
        tam -= 4

    knu_bbox = d.textbbox((0, 0), "KNU", font=fuente, anchor="ls")
    ui_bbox = d.textbbox((0, 0), "UI", font=fuente, anchor="ls")
    alto_txt = knu_bbox[3] - knu_bbox[1]
    y = base_y + alto_txt // 2

    # Sombra suave para leerse sobre cualquier fondo.
    sombra = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ds = ImageDraw.Draw(sombra)
    ds.text((tx + 6, y + 6), "KNU", font=fuente, fill=(0, 0, 0, 200), anchor="ls")
    ds.text((tx + 6 + knu_bbox[2] - knu_bbox[0], y + 6), "UI", font=fuente, fill=(0, 0, 0, 200), anchor="ls")
    lienzo.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(8)))

    d.text((tx, y), "KNU", font=fuente, fill=(*BLANCO, 255), anchor="ls")
    ui_x = tx + knu_bbox[2] - knu_bbox[0]
    mascara = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mascara).text((ui_x, y), "UI", font=fuente, fill=255, anchor="ls")
    lienzo.paste(degradado((W, H), CIAN, DORADO, 0), (0, 0), mascara)

    # Subrayado de acento dorado.
    sub_y = y + int(H * 0.07)
    alto_f = max(int(H * 0.035), 6)
    ancho_f = ui_x + ui_bbox[2] - ui_bbox[0] - tx
    tira = franjas(ancho_f, alto_f, paso=alto_f * 2)
    lienzo.alpha_composite(tira, (tx, sub_y))

    ancho_marca = ui_x + ui_bbox[2] - ui_bbox[0] - tx
    texto = "WOW FOREVER · KNUNET"
    tam = int(H * 0.085)
    while True:
        fuente_chica = ImageFont.truetype(r"C:\Windows\Fonts\bahnschrift.ttf", tam)
        if d.textlength(texto, font=fuente_chica) <= ancho_marca:
            break
        tam -= 2
    d.text((tx, sub_y + int(H * 0.06)), texto, font=fuente_chica, fill=(*BLANCO, 190), anchor="lt")
    return lienzo.resize((ancho, alto), Image.LANCZOS)


def guardar(img, nombre):
    MEDIA.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    img.save(MEDIA / f"{nombre}.tga", compression=None)
    img.save(PREVIEW / f"{nombre}.png")
    print("ok", nombre, img.size)


if __name__ == "__main__":
    guardar(logo(), "logo")              # asistente: 256×128 en pantalla
    guardar(emblema(256), "icono")       # lista de AddOns (IconTexture)
    guardar(emblema(64), "icono64")      # botón de minimapa / opciones
    guardar(franjas(), "franjas")        # borde de la pantalla AFK (se repite en X)
