# Pruebas unitarias sin interfaz (SDD §8.1):  godot --headless --path godot -- --test
# Se lanzan desde main.gd (así los autoloads Snd y Profile existen). Sale con código 1 si alguna falla.
extends Node

const P := preload("res://scripts/sys/profile.gd")

var fails := 0
var count := 0

func ok(cond: bool, what: String) -> void:
	count += 1
	if not cond:
		fails += 1; printerr("  FALLO: ", what)

func _ready() -> void:
	print("== test_save"); test_save()
	print("== test_profile"); test_profile()
	print("== test_i18n"); test_i18n()
	print("== test_keys"); test_keys()
	print("== test_cine"); test_cine()
	print("%d comprobaciones, %d fallos" % [count, fails])
	get_tree().quit(1 if fails > 0 else 0)

# migración v1 → v2: nada se pierde y los campos nuevos aparecen con valores neutros
func test_save() -> void:
	var v1 := {chapter = 3, max = 5, rep = {sac = 1, ciu = -2, aut = 0}, her = 2, know = {vista = 1, tacto = 1},
		frags = {"1": 1, "2": 1, "6": 1}, flags = {irregularChoice = "d", dictamen = "irr", aciertos = 4}}
	var s: Dictionary = P.migrate(JSON.parse_string(JSON.stringify(v1)))
	ok(int(s.v) == 2, "v = 2")
	ok(int(s.chapter) == 3 and int(s.max) == 5, "capítulo y máximo conservados")
	ok(s.frags.size() == 3 and s.frags.has("6"), "fragmentos conservados")
	ok(s.know.has("tacto"), "saberes conservados")
	ok(s.flags.dictamen == "irr" and int(s.flags.aciertos) == 4, "banderas conservadas")
	ok(int(s.rep.ciu) == -2 and int(s.her) == 2, "reputación y herejía conservadas")
	for k in ["rel", "record", "margins", "ledger", "inv", "argumentos", "stats"]: ok(s.has(k), "campo nuevo: " + k)
	ok(s.rel.size() == 7 and int(s.rel.nieto) == 0, "siete relaciones a cero")
	ok(s.record is Array and s.record.is_empty(), "expediente vacío")
	ok(float(s.stats.play_s) == 0.0, "tiempo de juego a cero")
	# idempotente
	var s2: Dictionary = P.migrate(s)
	ok(JSON.stringify(s2) == JSON.stringify(s), "migrar dos veces no cambia nada")
	# un v2 con relaciones parciales recibe las que faltan
	var part := s.duplicate(true); part.v = 1; part.rel = {nieto = 2}
	var s3: Dictionary = P.migrate(part)
	ok(int(s3.rel.nieto) == 2 and s3.rel.has("hermano"), "relaciones parciales completadas")
	# ida y vuelta por disco
	var path := "user://test_slot.json"
	P.write_json(path, s)
	var back = P.read_json(path)
	ok(back is Dictionary and (back.frags as Dictionary).size() == 3, "escritura y lectura de un hueco")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	ok(not FileAccess.file_exists(path + ".tmp"), "no queda el temporal")

func test_profile() -> void:
	var a: String = P.key_of("Hola, abuelo.")
	ok(a.length() == 8, "clave de 8 cifras hexadecimales")
	ok(a == P.key_of("Hola, abuelo."), "la clave es estable")
	ok(a != P.key_of("Hola, abuela."), "textos distintos, claves distintas")
	ok(P.slot_path(2) == "user://slot_2.json", "ruta del hueco")
	var b: Dictionary = P.blank()
	ok(b.has("seen") and b.has("picked") and int(b.last_slot) == 1, "perfil en blanco")

# todo msgid del .pot existe en en.po, y las traducciones hechas conservan los formatos (%d, %s)
func test_i18n() -> void:
	var pot := _po("res://data/i18n/planilandia.pot")
	var en := _po("res://data/i18n/en.po")
	ok(pot.size() > 500, "el .pot tiene los textos del juego (%d)" % pot.size())
	var tres = load("res://data/i18n/en.po")
	ok(tres is Translation, "en.po se carga como traducción")
	var miss := 0
	var fmt := RegEx.new(); fmt.compile("%[-+0-9.]*[sdf]")
	var bad := 0
	for k in pot:
		if not en.has(k): miss += 1; continue
		var t: String = en[k]
		if t != "" and fmt.search_all(t).size() != fmt.search_all(k).size(): bad += 1
	ok(miss == 0, "en.po contiene todos los msgid (faltan %d)" % miss)
	ok(bad == 0, "los formatos coinciden en las traducciones (%d distintos)" % bad)
	var book = JSON.parse_string(FileAccess.get_file_as_string("res://data/book.es.json"))
	ok(book is Dictionary and book.fragments.size() == 22, "book.es.json: 22 secciones")
	ok(book.has("record") and book.record.has("gate_protest"), "book.es.json: expediente")
	ok(book.has("people") and book.people.size() == 7, "book.es.json: siete personas")
	for id in book.people:
		ok(book.people[id].lv.size() == 5, "cinco frases para " + id)

func _po(path: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return out
	var mid = null
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("msgid "): mid = line.substr(7, line.length() - 8).c_unescape()
		elif line.begins_with("msgstr ") and mid != null:
			if mid != "": out[mid] = line.substr(8, line.length() - 9).c_unescape()
			mid = null
	return out

func test_keys() -> void:
	Keys.setup()
	for a in Keys.MAP: ok(InputMap.has_action(a), "acción " + a)
	for a in Keys.REBIND: ok(Keys.LABEL.has(a), "rótulo de " + a)
	ok(Keys.key_name("act") == "E", "E para interactuar (%s)" % Keys.key_name("act"))
	Glyphs.last = "kb"
	ok(Glyphs.fill("{act} y {view}") == "E y V", "glifos de teclado")
	ok(Glyphs.fill("{move}") == "WASD", "WASD")
	Glyphs.last = "xbox"
	ok(Glyphs.fill("{act} y {view}") == "A y Y", "glifos de Xbox")
	Glyphs.last = "ps"
	ok(Glyphs.fill("{act}") == "Cruz", "glifos de PlayStation")
	ok(Glyphs.family("Sony DualSense Wireless Controller") == "ps", "familia PlayStation")
	ok(Glyphs.family("Steam Deck") == "deck", "familia Steam Deck")
	ok(Glyphs.family("Xbox Series Controller") == "xbox", "familia Xbox")
	Glyphs.last = "kb"
	# reasignar y restablecer
	App.cfg.bindings = {act = [KEY_G]}; Keys.apply_bindings()
	ok(Keys.key_name("act") == "G", "reasignar E → G")
	App.cfg.bindings = {}; Keys.setup()
	ok(Keys.key_name("act") == "E", "restablecer")

func test_cine() -> void:
	App.cfg.reduce_motion = false
	var keys := [{t = 0.0}, {t = 1.0, fast = true}, {t = 3.0}]
	ok(Cine._times(keys) == [0.0, 1.0, 3.0], "tiempos normales")
	App.cfg.reduce_motion = true
	ok(Cine._times(keys) == [0.0, 2.0, 4.0], "reducir movimiento: las llaves rápidas duran el doble")
	App.cfg.reduce_motion = false
	ok(absf(Cine._ease({ease = "linear"}, 0.3) - 0.3) < 1e-6, "interpolación lineal")
