# Perfil de la instalación y huecos de partida (S-02). Autoload «Profile».
# El perfil guarda lo que no pertenece a una partida: idioma, capítulos desbloqueados, líneas leídas
# (para saltar lo leído), opciones elegidas alguna vez, logros y galería.
extends Node

const PATH := "user://profile.json"
const LEGACY := "user://planilandia.json"
const SLOTS := 3

var data := {}
var _dirty := false
var _save_t := 0.0

static func blank() -> Dictionary:
	return {v = 1, lang = "", max_chapter = 0, last_slot = 1, seen = {}, picked = {}, ach = {}, gallery = {}, college = {}}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_profile()
	migrate_legacy()

func _process(dt: float) -> void:
	if not _dirty: return
	_save_t -= dt
	if _save_t <= 0.0: save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _dirty: save()

# ---------- perfil ----------
func load_profile() -> void:
	data = blank()
	var d = read_json(PATH)
	if d is Dictionary:
		for k in d: data[k] = d[k]
	data.max_chapter = int(data.max_chapter); data.last_slot = clampi(int(data.last_slot), 1, SLOTS)

func save() -> void:
	_dirty = false
	write_json(PATH, data)

# guardado diferido: muchas líneas leídas seguidas no escriben el disco cada vez
func touch(delay := 2.0) -> void:
	if not _dirty: _save_t = delay
	_dirty = true

func unlock_chapter(i: int) -> void:
	if i > int(data.max_chapter): data.max_chapter = i; touch(0.0)

# ---------- huecos ----------
static func slot_path(n: int) -> String:
	return "user://slot_%d.json" % n

func has_slot(n: int) -> bool:
	return FileAccess.file_exists(slot_path(n))

func read_slot(n: int) -> Dictionary:
	var d = read_json(slot_path(n))
	if d is Dictionary: return migrate(d)
	return {}

func write_slot(n: int, state: Dictionary) -> void:
	state.saved_at = int(Time.get_unix_time_from_system())
	write_json(slot_path(n), state)

func clear_slot(n: int) -> void:
	if has_slot(n): DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(n)))

# [{n, chapter, max, play_s, date, empty}]
func list_slots() -> Array:
	var out := []
	for n in range(1, SLOTS + 1):
		var s := read_slot(n)
		if s.is_empty(): out.append({n = n, empty = true}); continue
		out.append({n = n, empty = false, chapter = int(s.get("chapter", 0)), max = int(s.get("max", 0)),
			play_s = float(s.get("stats", {}).get("play_s", 0.0)), date = int(s.get("saved_at", 0)), frags = (s.get("frags", {}) as Dictionary).size()})
	return out

# ---------- migración ----------
# Un estado sin «v» es de la versión 1 (planilandia.json): se le añaden los campos nuevos con valores
# neutros. Nada se pierde: fragmentos, saberes, banderas y reputaciones se conservan tal cual.
static func migrate(d: Dictionary) -> Dictionary:
	var s := d.duplicate(true)
	if int(s.get("v", 1)) >= 2 and s.has("rel"): return _types(s)
	var base := fresh_state()
	for k in base:
		if not s.has(k): s[k] = base[k]
	for k in base.rel:
		if not s.rel.has(k): s.rel[k] = 0
	s.v = 2
	return _types(s)

static func _types(s: Dictionary) -> Dictionary:
	s.chapter = int(s.get("chapter", 0)); s.max = int(s.get("max", 0))
	if not s.get("stats") is Dictionary: s.stats = {}
	if not s.stats.has("play_s"): s.stats.play_s = 0.0
	return s

static func fresh_state() -> Dictionary:
	return {v = 2, chapter = 0, max = 0, rep = {sac = 0, ciu = 0, aut = 0}, her = 0, know = {}, frags = {}, flags = {},
		rel = {esposa = 0, nieto = 0, hija = 0, hermano = 0, criado = 0, calderero = 0, archivero = 0},
		record = [], margins = {}, ledger = {}, inv = {}, argumentos = [], stats = {play_s = 0.0}}

# la partida de la versión 1 pasa al hueco 1; el fichero antiguo se conserva como copia
func migrate_legacy() -> void:
	if not FileAccess.file_exists(LEGACY): return
	if not has_slot(1):
		var d = read_json(LEGACY)
		if d is Dictionary:
			write_slot(1, migrate(d))
			data.max_chapter = maxi(int(data.max_chapter), int(d.get("max", 0))); data.last_slot = 1; save()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(LEGACY), ProjectSettings.globalize_path("user://planilandia.v1.bak"))

# ---------- lo leído y lo elegido ----------
static func key_of(msgid: String) -> String:
	return "%08x" % (msgid.hash() & 0xffffffff)

func mark_seen(msgid: String) -> void:
	var k := key_of(msgid)
	if data.seen.has(k): return
	data.seen[k] = 1; touch()

func seen(msgid: String) -> bool:
	return data.seen.has(key_of(msgid))

func mark_picked(key: String) -> void:
	if data.picked.has(key): return
	data.picked[key] = 1; touch()

func picked(key: String) -> bool:
	return data.picked.has(key)

# modos que se abren al terminar (C10-09): el modo Colegio
func unlock_mode(id: String) -> void:
	if not data.has("modes"): data.modes = {}
	if data.modes.has(id): return
	data.modes[id] = 1; touch(0.0)

func unlock_gallery(id: String) -> void:
	if data.gallery.has(id): return
	data.gallery[id] = 1; touch(0.0)

# ---------- ficheros ----------
static func read_json(path: String):
	if not FileAccess.file_exists(path): return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return null
	return JSON.parse_string(f.get_as_text())

static func write_json(path: String, d) -> void:
	# se escribe a un temporal y se renombra: un corte de luz no deja el fichero a medias
	if OS.has_feature("web"):
		var w := FileAccess.open(path, FileAccess.WRITE)
		if w: w.store_string(JSON.stringify(d))
		return
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(d)); f.close()
	var g := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path): DirAccess.remove_absolute(g)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), g)
