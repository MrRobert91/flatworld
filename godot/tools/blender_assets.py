# Genera los modelos de Espaciolandia y el icono del juego con Blender.
#
#   blender --background --python godot/tools/blender_assets.py
#
# Salida:
#   godot/assets/models/espacio.glb   (Esfera, Cubo y los Sólidos del firmamento)
#   godot/tools/espacio.blend         (fuente editable)
#   godot/icon.png                    (render Cycles)
import bpy, bmesh, math, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def link(name, bm, smooth=False):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    scene.collection.objects.link(ob)
    for p in me.polygons:
        p.use_smooth = smooth
    return ob


def hull(name, verts):
    bm = bmesh.new()
    for v in verts:
        bm.verts.new(v)
    bmesh.ops.convex_hull(bm, input=bm.verts)
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(1), verts=bm.verts, edges=bm.edges)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return link(name, bm)


def wire(ob, thickness):
    """Convierte las aristas en un armazón macizo: un Sólido «dibujado»."""
    m = ob.modifiers.new("armazon", "WIREFRAME")
    m.thickness = thickness
    m.use_even_offset = True
    m.use_replace = True
    b = ob.modifiers.new("bisel", "BEVEL")
    b.width = thickness * 0.18
    b.segments = 1
    return ob


# ---------- la Esfera ----------
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=64, v_segments=32, radius=1.0)
esfera = link("Esfera", bm, smooth=True)

# ---------- el Cubo (UV 0..1 por cara: el sombreador dibuja las aristas) ----------
bm = bmesh.new()
bmesh.ops.create_cube(bm, size=1.0)
uv = bm.loops.layers.uv.new("UVMap")
for f in bm.faces:
    for loop, co in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
        loop[uv].uv = co
cubo = link("Cubo", bm)

# ---------- los Sólidos del firmamento ----------
phi = (1 + 5 ** 0.5) / 2
solids = []

bm = bmesh.new()
bmesh.ops.create_icosphere(bm, subdivisions=1, radius=14)
solids.append(wire(link("Icosaedro", bm), 0.5))

bm = bmesh.new()
bmesh.ops.create_cube(bm, size=18)
solids.append(wire(link("Hexaedro", bm), 0.55))

s = 16 / 3 ** 0.5
solids.append(wire(hull("Tetraedro", [(s, s, s), (s, -s, -s), (-s, s, -s), (-s, -s, s)]), 0.55))

solids.append(wire(hull("Octaedro", [(13, 0, 0), (-13, 0, 0), (0, 13, 0), (0, -13, 0), (0, 0, 13), (0, 0, -13)]), 0.5))

k = 12 / 3 ** 0.5
dv = [(x * k, y * k, z * k) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
for a in (-1, 1):
    for b in (-1, 1):
        dv += [(0, a / phi * k, b * phi * k), (a / phi * k, b * phi * k, 0), (a * phi * k, 0, b / phi * k)]
solids.append(wire(hull("Dodecaedro", dv), 0.45))

bm = bmesh.new()
bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=10, radius2=0, depth=22)
bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=__import__("mathutils").Matrix.Rotation(math.radians(-90), 3, "X"))
solids.append(wire(link("Cono", bm), 0.4))

bm = bmesh.new()
bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=8, radius2=8, depth=20)
bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=__import__("mathutils").Matrix.Rotation(math.radians(-90), 3, "X"))
solids.append(wire(link("Cilindro", bm), 0.4))

for i, ob in enumerate(solids):
    ob.location = (i * 40.0, 60, 0)  # separados en el .blend; Godot los recoloca

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "espacio.blend"))

for ob in solids:
    ob.location = (0, 0, 0)
os.makedirs(os.path.join(ROOT, "assets", "models"), exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=os.path.join(ROOT, "assets", "models", "espacio.glb"),
    export_format="GLB", export_apply=True, export_materials="NONE",
    export_yup=True, export_normals=True, export_texcoords=True)
print("GLB ok")

# ---------- icono: una Esfera sobre el Plano, y su sección ----------
for ob in solids + [cubo]:
    ob.hide_render = True


def emit(name, color, strength):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    e = nt.nodes.new("ShaderNodeEmission")
    e.inputs["Color"].default_value = (*color, 1)
    e.inputs["Strength"].default_value = strength
    nt.links.new(e.outputs["Emission"], out.inputs["Surface"])
    return m


def glossy(name, color, rough):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    return m


bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=30)
plano = link("Plano", bm)
plano.data.materials.append(glossy("plano", (0.012, 0.03, 0.036), 0.35))

# el Cuadrado: un marco luminoso tendido en el Plano
bm = bmesh.new()
bmesh.ops.create_cube(bm, size=1.0)
bmesh.ops.scale(bm, vec=(2.6, 2.6, 0.02), verts=bm.verts)
cuad = link("Cuadrado", bm)
wire(cuad, 0.09)
cuad.location = (0, 0, 0.02)
cuad.rotation_euler = (0, 0, math.radians(18))
cuad.data.materials.append(emit("hueso", (0.93, 0.86, 0.66), 9))

esfera.location = (0.25, 0.2, 1.75)
esfera.scale = (1.15, 1.15, 1.15)
esfera.data.materials.append(glossy("esfera", (0.35, 0.85, 0.8), 0.18))

sun = bpy.data.objects.new("luz", bpy.data.lights.new("luz", "AREA"))
sun.data.energy = 900
sun.data.size = 6
sun.data.color = (0.75, 1.0, 0.96)
sun.location = (-4, -5, 8)
sun.rotation_euler = (math.radians(38), 0, math.radians(-35))
scene.collection.objects.link(sun)

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.location = (0, -7.2, 5.6)
cam.data.lens = 50
scene.collection.objects.link(cam)
tr = cam.constraints.new("TRACK_TO")
empty = bpy.data.objects.new("mira", None)
empty.location = (0.1, 0.1, 0.95)
scene.collection.objects.link(empty)
tr.target = empty
scene.camera = cam

world = bpy.data.worlds.new("mundo")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.004, 0.009, 0.012, 1)
scene.world = world

scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 96
scene.cycles.use_denoising = False
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.film_transparent = False
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = os.path.join(ROOT, "icon.png")
bpy.ops.render.render(write_still=True)
print("ICON ok")
