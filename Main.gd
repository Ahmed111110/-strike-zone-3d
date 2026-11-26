extends Node3D

var player: CharacterBody3D
var cam: Camera3D
var rpg_gun: Node3D
var tank: CharacterBody3D
var tank_hp := 100
var tank_dir := 1.0

var mode := 0 # 0=RPG, 1=Shuwaz, 2=Mortar
var names := ["RPG", "شواظ", "هاون"]
var ammo := [3, 3, 3]
var fwd := 0.0
var right := 0.0

var lbl_hp: Label
var lbl_ammo: Label
var btn_mode: Button

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.55, 0.65)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)

	add_child(_box(Vector3(100, 1, 120), Vector3(0, -0.5, 0), Color(0.58, 0.50, 0.36), true, true))
	add_child(_box(Vector3(9, 0.05, 110), Vector3(4, 0.02, 0), Color(0.25, 0.25, 0.27), false, true))
	for p in [Vector3(-3, 1, 16), Vector3(1, 1, 9), Vector3(-5, 1, 0)]:
		add_child(_box(Vector3(3, 2, 1), p, Color(0.45, 0.42, 0.38), true, true))

	player = CharacterBody3D.new()
	player.position = Vector3(-1.5, 1.8, 22)
	add_child(player)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.7
	col.shape = cap
	player.add_child(col)

	cam = Camera3D.new()
	cam.position = Vector3(0, 0.65, 0)
	player.add_child(cam)

	rpg_gun = Node3D.new()
	rpg_gun.position = Vector3(0.3, -0.25, -0.5)
	cam.add_child(rpg_gun)
	rpg_gun.add_child(_box(Vector3(0.1, 0.1, 1.1), Vector3.ZERO, Color(0.2, 0.26, 0.18), false, true))

	tank = _box(Vector3(3.2, 2.0, 5.2), Vector3(4, 1, -8), Color(0.28, 0.34, 0.22), true, false) as CharacterBody3D
	tank.add_child(_box(Vector3(1.9, 0.8, 2.0), Vector3(0, 1.3, 0.2), Color(0.24, 0.29, 0.19), false, true))
	add_child(tank)

	_ui()
	_hud()

func _box(sz: Vector3, pos: Vector3, col: Color, body: bool, static_b: bool) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mi.material_override = mat
	if not body:
		mi.position = pos
		return mi
	var pb: PhysicsBody3D = StaticBody3D.new() if static_b else CharacterBody3D.new()
	pb.position = pos
	pb.add_child(mi)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = sz
	c.shape = s
	pb.add_child(c)
	return pb

func _ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var cross := Label.new()
	cross.text = "[ + ]"
	cross.position = Vector2(335, 520)
	cross.add_theme_font_size_override("font_size", 28)
	ui.add_child(cross)

	lbl_hp = Label.new()
	lbl_hp.position = Vector2(24, 40)
	lbl_hp.add_theme_font_size_override("font_size", 24)
	ui.add_child(lbl_hp)

	lbl_ammo = Label.new()
	lbl_ammo.position = Vector2(24, 78)
	lbl_ammo.add_theme_font_size_override("font_size", 22)
	ui.add_child(lbl_ammo)

	var b_fwd := _btn("تقدم", Vector2(30, 960), Vector2(120, 80))
	b_fwd.button_down.connect(func(): fwd = 1.0)
	b_fwd.button_up.connect(func(): fwd = 0.0)
	ui.add_child(b_fwd)

	var b_back := _btn("تراجع", Vector2(30, 1055), Vector2(120, 80))
	b_back.button_down.connect(func(): fwd = -1.0)
	b_back.button_up.connect(func(): fwd = 0.0)
	ui.add_child(b_back)

	var b_l := _btn("يسار", Vector2(160, 1008), Vector2(105, 80))
	b_l.button_down.connect(func(): right = -1.0)
	b_l.button_up.connect(func(): right = 0.0)
	ui.add_child(b_l)

	var b_r := _btn("يمين", Vector2(275, 1008), Vector2(105, 80))
	b_r.button_down.connect(func(): right = 1.0)
	b_r.button_up.connect(func(): right = 0.0)
	ui.add_child(b_r)

	btn_mode = _btn("RPG", Vector2(450, 860), Vector2(230, 75))
	btn_mode.pressed.connect(func():
		mode = (mode + 1) % 3
		rpg_gun.visible = (mode == 0)
		_hud()
	)
	ui.add_child(btn_mode)

	var b_rel := _btn("تلقيم", Vector2(450, 948), Vector2(230, 70))
	b_rel.pressed.connect(func():
		ammo[mode] = 3
		_hud()
	)
	ui.add_child(b_rel)

	var b_fire := _btn("إطلاق", Vector2(450, 1030), Vector2(230, 115))
	b_fire.pressed.connect(_fire)
	ui.add_child(b_fire)

func _btn(t: String, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = sz
	b.add_theme_font_size_override("font_size", 22)
	return b

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenDrag and e.position.y < 840.0:
		player.rotate_y(-e.relative.x * 0.004)
		cam.rotate_x(-e.relative.y * 0.0035)
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-65), deg_to_rad(65))

func _physics_process(delta: float) -> void:
	var f := -player.global_transform.basis.z
	f.y = 0.0
	f = f.normalized()
	var r := player.global_transform.basis.x
	r.y = 0.0
	r = r.normalized()
	var d := (f * fwd + r * right).limit_length(1.0)
	player.velocity.x = d.x * 6.5
	player.velocity.z = d.z * 6.5
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta
	player.move_and_slide()

	if tank_hp > 0:
		tank.velocity = Vector3(0, 0, tank_dir * 4.0)
		tank.move_and_slide()
		if tank.position.z > 12.0:
			tank_dir = -1.0
		elif tank.position.z < -22.0:
			tank_dir = 1.0

func _fire() -> void:
	if ammo[mode] <= 0:
		return
	ammo[mode] -= 1
	var pos := Vector3.ZERO
	if mode == 0:
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_transform.basis.z * 80.0)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		pos = hit["position"] if not hit.is_empty() else (cam.global_position - cam.global_transform.basis.z * 40.0)
		_hit_at(pos, 7.0, 50)
	elif mode == 1:
		pos = player.global_position - player.global_transform.basis.z * 3.0
		pos.y = 0.4
		add_child(_box(Vector3(0.4, 0.4, 0.4), pos, Color(0.9, 0.2, 0.1), false, true))
		_hit_at(pos, 8.0, 65)
	else:
		pos = cam.global_position - cam.global_transform.basis.z * 24.0
		pos.y = 0.2
		_hit_at(pos, 9.5, 55)
	_hud()

func _hit_at(pos: Vector3, rad: float, dmg: int) -> void:
	var blast := _box(Vector3(2.2, 2.2, 2.2), pos, Color(1.0, 0.45, 0.05), false, true)
	add_child(blast)
	get_tree().create_timer(0.35).timeout.connect(func():
		if is_instance_valid(blast):
			blast.queue_free()
	)
	if tank_hp > 0 and tank.global_position.distance_to(pos) <= rad + 2.5:
		tank_hp = max(0, tank_hp - dmg)
		if tank_hp == 0:
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.12, 0.12, 0.12)
			for ch in tank.get_children():
				if ch is MeshInstance3D:
					ch.material_override = m
	_hud()

func _hud() -> void:
	lbl_hp.text = "الآلية: %d%%" % tank_hp if tank_hp > 0 else "الآلية مُدمّرة"
	btn_mode.text = "الوسيلة: " + names[mode]
	lbl_ammo.text = "الذخيرة: %d" % ammo[mode]
