"""Revisa si salieron versiones nuevas de los addons que KnuUI viste o soporta.

Lee .github/addons-check.json, consulta la versión publicada de cada addon y escribe un informe
en Markdown. Sale con código 0 siempre; el workflow decide si abre un issue mirando addons-report.md.

Fuentes:
  tukui      https://api.tukui.org/v1/addon/<slug>  (sin clave)
  github     /repos/<repo>/releases/latest          (GITHUB_TOKEN)
  curseforge https://api.curseforge.com/v1/mods/<id> (CF_CORE_API_KEY); se toma el archivo más
             nuevo de latestFilesIndexes para la versión de juego configurada (Forever 1.60.1).
"""
import json
import os
import re
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG = os.path.join(ROOT, "addons-check.json")


def get_json(url, headers=None):
    req = urllib.request.Request(url, headers={"User-Agent": "KnuUI-addons-check", **(headers or {})})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def digits(text):
    return re.sub(r"\D", "", text or "")


def latest_tukui(addon):
    data = get_json(f"https://api.tukui.org/v1/addon/{addon['slug']}")
    return data.get("version")


def latest_github(addon):
    headers = {"Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = get_json(f"https://api.github.com/repos/{addon['repo']}/releases/latest", headers)
    return data.get("tag_name")


def latest_curseforge(addon, game_version):
    key = os.environ.get("CF_CORE_API_KEY")
    if not key:
        raise RuntimeError("falta CF_CORE_API_KEY")
    headers = {"x-api-key": key, "Accept": "application/json"}
    mod_id = addon.get("id")
    if not mod_id:
        found = get_json(f"https://api.curseforge.com/v1/mods/search?gameId=1&slug={addon['slug']}", headers)
        items = found.get("data") or []
        if not items:
            raise RuntimeError(f"slug {addon['slug']} no encontrado")
        mod_id = items[0]["id"]
    mod = get_json(f"https://api.curseforge.com/v1/mods/{mod_id}", headers)["data"]
    files = [f for f in mod.get("latestFilesIndexes", []) if f.get("gameVersion") == game_version]
    if not files:
        raise RuntimeError(f"sin archivos para {game_version}")
    newest = max(files, key=lambda f: f.get("fileId", 0))
    return newest.get("filename")


def main():
    config = json.load(open(CONFIG, encoding="utf-8"))
    game_version = config.get("gameVersion", "1.60.1")
    changed, same, failed = [], [], []
    for addon in config["addons"]:
        try:
            if addon["source"] == "tukui":
                latest = latest_tukui(addon)
            elif addon["source"] == "github":
                latest = latest_github(addon)
            else:
                latest = latest_curseforge(addon, game_version)
        except (urllib.error.URLError, RuntimeError, KeyError, ValueError) as err:
            failed.append((addon["name"], str(err)))
            continue
        tested = addon["tested"]
        # GitHub y tukui devuelven sólo la versión: se comparan los dígitos. CurseForge devuelve el
        # nombre del archivo: la versión probada tiene que estar contenida en él.
        if addon["source"] == "curseforge":
            is_same = digits(tested) in digits(latest)
        else:
            is_same = digits(tested) == digits(latest)
        (same if is_same else changed).append((addon["name"], tested, latest, addon["source"]))

    lines = []
    if changed:
        lines.append("Salieron versiones nuevas de addons que KnuUI viste o soporta. Revisar la skin en el juego y, si anda bien, actualizar `tested` en `.github/addons-check.json`.\n")
        lines.append("| Addon | Probada | Publicada | Fuente |")
        lines.append("|---|---|---|---|")
        lines += [f"| {n} | {t} | {l} | {s} |" for n, t, l, s in changed]
    if failed:
        lines.append("\nNo se pudieron consultar:\n")
        lines += [f"- {n}: {e}" for n, e in failed]
    lines.append(f"\nSin cambios: {', '.join(n for n, *_ in same) or 'ninguno'}.")
    report = "\n".join(lines)
    print(report)
    with open("addons-report.md", "w", encoding="utf-8") as fh:
        fh.write(report)
    # El workflow abre o actualiza el issue sólo si hay cambios.
    with open(os.environ.get("GITHUB_OUTPUT", os.devnull), "a", encoding="utf-8") as out:
        out.write(f"changed={len(changed)}\nfailed={len(failed)}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
