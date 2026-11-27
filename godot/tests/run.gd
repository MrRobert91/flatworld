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
	print("== test_refs"); test_refs()
	print("== test_geom3"); test_geom3()
	print("== test_sketch"); test_sketch()
	print("== test_lens"); test_lens()
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

# todo id que usa el guion (notas al margen, expediente, logros) tiene su texto en el libro
func test_refs() -> void:
	var book = JSON.parse_string(FileAccess.get_file_as_string("res://data/book.es.json"))
	var margins := {}
	for m in book.margins: margins[m.id] = m
	var code := ""
	for dir in ["res://scripts/content/", "res://scripts/minigames/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"): code += FileAccess.get_file_as_string(dir + f)
	var re := RegEx.new()
	re.compile("\\['(m_[a-z0-9_]+)'")
	var n := 0
	for m in re.search_all(code):
		n += 1; ok(margins.has(m.get_string(1)), "nota al margen con texto: " + m.get_string(1))
	ok(n >= 12, "el guion declara notas al margen (%d)" % n)
	re.compile("g\\.note\\('([a-z_]+)'")
	for m in re.search_all(code): ok(book.record.has(m.get_string(1)), "anotación con texto: " + m.get_string(1))
	re.compile("g\\.achieve\\('([A-Z_]+)'")
	for m in re.search_all(code): ok(book.achievements.has(m.get_string(1)), "logro con nombre: " + m.get_string(1))
	for m in book.margins: ok(m.has("title") and m.has("text") and m.has("ch"), "nota completa: " + m.id)

# S-12 (parte 2D): la sección de un polígono por la Recta y la de una esfera por el Plano
func test_geom3() -> void:
	var r := 0.78
	var sq := func(rot: float, cy: float) -> Array:
		var out := []
		for i in 4: out.append(Vector2(r * cos(rot + TAU * i / 4.0), cy + r * sin(rot + TAU * i / 4.0)))
		return out
	ok(absf(Geom3.line_len(sq.call(PI / 2, 0.0)) - 2.0 * r) < 1e-4, "diagonal sobre la Recta: 2r")
	ok(absf(Geom3.line_len(sq.call(PI / 4, 0.0)) - 2.0 * r * sin(PI / 4)) < 1e-4, "un lado paralelo: el lado")
	ok(absf(Geom3.line_len(sq.call(PI / 2, -(r - 0.125))) - 0.25) < 1e-4, "por un vértice: 0,25")
	ok(Geom3.line_len(sq.call(0.3, 2.0)) == 0.0, "lejos de la Recta: nada")
	var s := Geom3.line_section([Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)])
	ok(s.is_equal_approx(Vector2(-1, 1)), "rombo: de -1 a 1 (%s)" % s)
	ok(absf(Geom3.sphere_section(1.0, 0.5) - sqrt(0.75)) < 1e-6, "esfera a media altura: raíz de tres cuartos")
	ok(Geom3.sphere_section(1.0, 1.2) == 0.0, "esfera por encima: no corta")
	ok(Geom3.sphere_section(2.0, 0.0) == 2.0, "esfera centrada: su radio")
	# S-12 (3D): secciones del cubo
	var C := Geom3.cube(2.0)
	var face := Geom3.section(C, Transform3D(Basis(), Vector3(0, 0.3, 0)))
	ok(face.size() == 4 and absf(Geom3.area(face) - 4.0) < 1e-3, "cubo de cara: un cuadrado de área l² (%d, %.3f)" % [face.size(), Geom3.area(face)])
	var up := Vector3(1, 1, 1).normalized()
	var vb := Basis(up.cross(Vector3.UP).normalized(), up.angle_to(Vector3.UP))   # la diagonal, vertical
	var hexa := Geom3.section(C, Transform3D(vb, Vector3.ZERO))
	var sides := []
	for i in hexa.size(): sides.append(hexa[i].distance_to(hexa[(i + 1) % hexa.size()]))
	ok(hexa.size() == 6 and sides.max() - sides.min() < 1e-3, "cubo de vértice, a media altura: hexágono regular")
	var dg := 2.0 * sqrt(3.0)
	var tri := Geom3.section(C, Transform3D(vb, Vector3(0, dg / 2.0 - dg / 6.0, 0)))
	var ts := []
	for i in tri.size(): ts.append(tri[i].distance_to(tri[(i + 1) % tri.size()]))
	ok(tri.size() == 3 and ts.max() - ts.min() < 1e-3, "cubo de vértice, a 1/6 de la diagonal: triángulo equilátero")
	ok(Geom3.section(C, Transform3D(Basis(), Vector3(0, 5, 0))).is_empty(), "por encima del Plano: no corta")
	var sh := Geom3.shadow(C, Transform3D(Basis(), Vector3(0, 3, 0)), Vector4(0, 10, 0, 1))
	ok(sh.size() == 12, "la sombra de un cubo: doce rayas")

# S-11: lo que reconoce la pizarra
func test_sketch() -> void:
	var cyc := func(vs: Array) -> Array:
		var out := []
		for i in vs.size(): out.append(Vector2i(vs[i], vs[(i + 1) % vs.size()]))
		return out
	var cube: Array = cyc.call([0, 1, 2, 3]) + cyc.call([4, 5, 6, 7]) + [Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7)]
	ok(Sketch.classify(cube) == "cube_shadow", "sombra de un cubo")
	var cube2: Array = cyc.call([10, 3, 8, 1]) + cyc.call([2, 9, 4, 7]) + [Vector2i(10, 2), Vector2i(3, 9), Vector2i(8, 4), Vector2i(1, 7)]
	cube2.append(Vector2i(4, 8))   # un trazo repetido al revés no cuenta
	ok(Sketch.classify(cube2) == "cube_shadow", "sombra de un cubo en otra perspectiva")
	ok(Sketch.classify(cyc.call([0, 1, 2, 3, 4, 5])) == "hexagon", "hexágono")
	ok(Sketch.classify(cyc.call([5, 6, 9, 8])) == "square", "cuadrado")
	ok(Sketch.classify(cyc.call([5, 6, 9, 8]) + [Vector2i(5, 9)]) == "other", "cuadrado con una diagonal")
	ok(Sketch.classify([]) == "empty", "pizarra vacía")

# S-06: el botón de vista recorre las lentes del mundo
func test_lens() -> void:
	var e := Eye.new()
	e.set_lens("point", true)
	ok(e.squeeze == 1.0 and e.grow == 0.0, "punto: la línea encogida del todo")
	e.set_lens("flood", true)
	ok(e.grow == 1.0, "inundación: el punto crecido")
	e.set_lens("line", true)
	ok(e.squeeze == 0.0 and e.grow == 0.0, "línea")
	e.view.free(); e.free()
