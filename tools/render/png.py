import json, sys
from PIL import Image, ImageDraw
src, out = sys.argv[1], sys.argv[2]
d = json.load(open(src, encoding='utf-8'))
W, H = 1920, 1080
im = Image.new('RGB', (W, H), (18, 14, 10))
dr = ImageDraw.Draw(im, 'RGBA')
skip = ('SLE_', 'Raid2', 'Raid3', 'Arena', 'Boss', 'Azerite', 'Honor', 'Torghast', 'Garrison', 'PetBattle', 'VOICECHAT', 'Reputation')
for r in d['rects']:
    if r.get('unknown') or any(s in r['name'] for s in skip):
        continue
    x0, y0 = r['left'], H - r['bottom'] - r['height']
    x1, y1 = x0 + r['width'], y0 + r['height']
    dr.rectangle([x0, y0, x1, y1], fill=(255, 140, 26, 40), outline=(255, 140, 26, 255))
    dr.text((x0 + 3, y0 + 2), f"{r['name']} {r['width']}x{r['height']}", fill=(255, 230, 200, 255))
im.save(out)
print('ok', out)
