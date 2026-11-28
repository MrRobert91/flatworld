# Plataforma (§7): Steam a través de GodotSteam si la extensión está cargada; si no, nada salvo el espejo
# local de los logros en el perfil. La versión web y las pruebas no cargan la extensión.
extends Node

const APP_ID := 0          # el de Steamworks, cuando exista (0: sin Steam)
var steam = null
var _overlay := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("Steam") and not App.args.has("nosteam"):
		steam = Engine.get_singleton("Steam")
		var r = steam.call("steamInitEx", false, APP_ID) if steam.has_method("steamInitEx") else steam.call("steamInit")
		var ok: bool = (r is Dictionary and int(r.get("status", 1)) == 0) or (r is bool and r)
		if not ok: steam = null
		elif steam.has_signal("overlay_toggled"): steam.connect("overlay_toggled", func(on, _a = null, _b = null): _overlay = on)
	# los logros ya guardados en el perfil se suben (por si se ganaron sin conexión)
	if steam != null:
		for id in Profile.data.get("ach", {}): unlock(id)

func _process(_dt: float) -> void:
	if steam != null: steam.call("run_callbacks")

func is_steam() -> bool:
	return steam != null

func cloud_enabled() -> bool:
	return steam != null and bool(steam.call("isCloudEnabledForApp"))

func overlay_active() -> bool:
	return _overlay

func unlock(id: String) -> void:
	if steam == null: return
	steam.call("setAchievement", id)
	steam.call("storeStats")

func set_stat(key: String, v: int) -> void:
	if steam == null: return
	steam.call("setStatInt", key, v)
	steam.call("storeStats")

# demo de Steam y versión web (§7): se detiene al terminar el bloque III
func is_demo() -> bool:
	return OS.has_feature("demo") or App.args.has("demo")
