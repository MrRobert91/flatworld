#!/usr/bin/env python3
"""Extrae los textos traducibles del juego a data/i18n/planilandia.pot y actualiza en.po (S-10).

El msgid es el texto español tal cual aparece en el guion. Se extraen:
  * los argumentos de tr("...") en cualquier script;
  * en los capítulos (scripts/content) y en la interfaz, todo literal que parezca texto para personas
    (lleva un espacio, una mayúscula inicial o letras no ASCII) y no sea un identificador o una ruta.

  python3 godot/tools/extract_strings.py           genera el .pot y fusiona en.po (conserva lo traducido)
  python3 godot/tools/extract_strings.py --check   falla si el .pot está desactualizado o si hay textos
                                                    con formato (%) sin tr(): '…%d…' % x no se traduciría.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(ROOT, "scripts")
I18N = os.path.join(ROOT, "data", "i18n")
POT = os.path.join(I18N, "planilandia.pot")
LANGS = ["en"]

# ficheros cuyos literales de texto se extraen enteros (además de tr() en todos)
TEXT_FILES = ("scripts/content/", "scripts/minigames/", "scripts/ui.gd", "scripts/ui/", "scripts/main.gd", "scripts/game.gd", "scripts/sys/keys.gd")
LIT = re.compile(r"""(?P<q>['"])(?P<s>(?:\\.|(?!(?P=q)).)*)(?P=q)""")
TR = re.compile(r"""\b(?:tr|T|I18n\.t)\(\s*(?P<q>['"])(?P<s>(?:\\.|(?!(?P=q)).)*)(?P=q)""")
FMT = re.compile(r"%[-+0-9.]*[sdf]")
NOT_TEXT = re.compile(r"^(res|user)://|^#[0-9a-fA-F]{3,8}$|^[a-z0-9_]+$|^[A-Za-z]+[A-Z][A-Za-z0-9]*$|^[A-Z_0-9]+$|^\[/?[a-z=#0-9 ]+\]$")
# argumentos que nunca son texto visible aunque lo parezcan
SKIP_CALLS = re.compile(r"\b(print|push_error|push_warning|load|preload|has_meta|set_meta|get_meta|connect|emit_signal|call|has|get|erase|flag|sfx|sfx_at|drone|note_id|record|rel|learn|knows|frag|is_action_pressed|is_action_just_pressed|InputMap\.\w+|set_shader_parameter|add_theme_\w+|get_theme_\w+|ResourceLoader\.exists|FileAccess\.\w+|JSON\.\w+|split|replace|begins_with|ends_with|find|match|compile|sub|search)\(\s*$")


def unescape(s):
    return s.encode("utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in s else s


def is_text(s):
    if len(s) < 2 or NOT_TEXT.search(s):
        return False
    bare = FMT.sub("", re.sub(r"\[/?[a-z_]+(=[^\]]*)?\]", "", s))
    if not re.search(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{2,}", bare):
        return False
    return " " in s or s[0].isupper() or re.search(r"[^\x00-\x7f]", s) is not None


def code_part(line):
    """La línea sin el comentario final (respetando las comillas)."""
    q = None
    for i, c in enumerate(line):
        if q:
            if c == "\\":
                continue
            if c == q:
                q = None
        elif c in "'\"":
            q = c
        elif c == "#":
            return line[:i]
    return line


def scan():
    found = {}   # msgid -> [refs]
    issues = []
    for dirpath, _, files in os.walk(SCRIPTS):
        for fn in sorted(files):
            if not fn.endswith(".gd"):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            whole = rel.startswith(TEXT_FILES)
            with open(path, encoding="utf-8") as f:
                for n, raw in enumerate(f, 1):
                    if "# notr" in raw:
                        continue
                    line = code_part(raw.rstrip("\n"))
                    if re.search(r"\bprint\(|push_(error|warning)\(", line):
                        continue
                    trs = {m.start("q") for m in TR.finditer(line)}
                    for m in TR.finditer(line):
                        found.setdefault(unescape(m.group("s")), []).append(f"{rel}:{n}")
                    if not whole:
                        continue
                    for m in LIT.finditer(line):
                        s = m.group("s")
                        if m.start() in trs or not is_text(s):
                            continue
                        before = line[: m.start()]
                        if SKIP_CALLS.search(before):
                            continue
                        found.setdefault(unescape(s), []).append(f"{rel}:{n}")
                        after = line[m.end():].lstrip()
                        if FMT.search(s) and after.startswith("%") and not re.search(r"(\btr|\bT|I18n\.t)\(\s*$", before):
                            issues.append(f"{rel}:{n}: texto con formato sin tr(): {s[:60]!r}")
    return found, issues


def po_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def render_pot(found):
    out = ['msgid ""', 'msgstr ""', '"Content-Type: text/plain; charset=UTF-8\\n"', '"Project-Id-Version: Planilandia\\n"', '"X-Source-Language: es\\n"', ""]
    for msgid in sorted(found, key=lambda k: found[k][0]):
        refs = found[msgid]
        out.append("#: " + " ".join(refs[:4]) + (" …" if len(refs) > 4 else ""))
        out.append(f'msgid "{po_escape(msgid)}"')
        out.append('msgstr ""')
        out.append("")
    return "\n".join(out)


def read_po(path):
    """msgid -> msgstr (lectura sencilla: una línea por campo, como las que escribe esta herramienta)."""
    out = {}
    if not os.path.exists(path):
        return out
    mid = None
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("msgid "):
            mid = bytes(line[7:-1], "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")
        elif line.startswith("msgstr ") and mid is not None:
            out[mid] = bytes(line[8:-1], "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")
            mid = None
    return out


def render_po(found, old, lang):
    out = ['msgid ""', 'msgstr ""', '"Content-Type: text/plain; charset=UTF-8\\n"', f'"Language: {lang}\\n"', ""]
    for msgid in sorted(found, key=lambda k: found[k][0]):
        out.append("#: " + found[msgid][0])
        out.append(f'msgid "{po_escape(msgid)}"')
        out.append(f'msgstr "{po_escape(old.get(msgid, ""))}"')
        out.append("")
    return "\n".join(out)


def main():
    check = "--check" in sys.argv
    found, issues = scan()
    found.pop("", None)
    pot = render_pot(found)
    if check:
        ok = True
        for i in issues:
            print(i)
            ok = False
        cur = open(POT, encoding="utf-8").read() if os.path.exists(POT) else ""
        if cur != pot:
            print("planilandia.pot está desactualizado: ejecuta tools/extract_strings.py")
            ok = False
        for lang in LANGS:
            po = read_po(os.path.join(I18N, f"{lang}.po"))
            miss = [k for k in found if k not in po]
            if miss:
                print(f"{lang}.po no tiene {len(miss)} msgid del .pot (p. ej. {miss[0][:50]!r})")
                ok = False
        print(f"{len(found)} textos · {'OK' if ok else 'ERRORES'}")
        sys.exit(0 if ok else 1)
    for i in issues:
        print("AVISO", i)
    os.makedirs(I18N, exist_ok=True)
    with open(POT, "w", encoding="utf-8") as f:
        f.write(pot)
    for lang in LANGS:
        path = os.path.join(I18N, f"{lang}.po")
        old = read_po(path)
        with open(path, "w", encoding="utf-8") as f:
            f.write(render_po(found, old, lang))
        done = sum(1 for k in found if old.get(k))
        print(f"{lang}.po: {done}/{len(found)} traducidos")
    print(f"{len(found)} textos → {os.path.relpath(POT, ROOT)}")


if __name__ == "__main__":
    main()
