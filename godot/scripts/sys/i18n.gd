# Localización (S-10): gettext con el texto español como msgid. La interfaz traduce por dentro todo lo
# que muestra (say, narrate, choose, note, panel, objective, title, toast), así que los capítulos se
# escriben en español sin tocarlos. Las traducciones viven en data/i18n/<idioma>.po.
class_name I18n extends RefCounted

const LANGS := ["es", "en"]
const SOURCE := "es"

static var lang := "es"
static var missing := {}     # msgid sin traducir que han llegado a la pantalla (para --lang=en)

static func setup(want := "") -> void:
	lang = want if want in LANGS else SOURCE
	if lang != SOURCE:
		var path := "res://data/i18n/%s.po" % lang
		if ResourceLoader.exists(path):
			var tr_res = load(path)
			if tr_res is Translation: TranslationServer.add_translation(tr_res)
	TranslationServer.set_locale(lang)

# traduce un texto de interfaz; en español devuelve el mismo
static func t(s: String) -> String:
	if lang == SOURCE or s == "": return s
	var r := String(TranslationServer.translate(s))
	if r == s: missing[s] = 1
	return r

# el libro (secciones, saberes, expediente, personas) en el idioma actual, con el español de respaldo
static func book() -> Dictionary:
	var base := _read("res://data/book.es.json")
	if lang == SOURCE: return base
	var loc := _read("res://data/book.%s.json" % lang)
	return _merge(base, loc)

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}

static func _merge(base: Dictionary, over: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for k in over:
		if out.has(k) and out[k] is Dictionary and over[k] is Dictionary: out[k] = _merge(out[k], over[k])
		else: out[k] = over[k]
	return out
