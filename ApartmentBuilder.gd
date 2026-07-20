extends Node3D

# --- THE MODULAR APARTMENT GALLERY ---
var wall_gallery: Array = [
	# --- EXTERIOR BOUNDARY WALLS ---
	{"pos": Vector3(0.0, 1.5, 7.7), "dims": Vector3(13.6, 3.0, 0.2), "texture": "wall2.png", "has_door": false, "has_window": false},
	{"pos": Vector3(6.7, 1.5, 0.0), "dims": Vector3(0.2, 3.0, 15.6), "texture": "wall2.png", "has_door": false, "has_window": false},
	{"pos": Vector3(0.0, 1.5, -7.7), "dims": Vector3(13.6, 3.0, 0.2), "texture": "wall2.png", "has_door": false, "has_window": true, "window_pos": Vector3(3.0, 1.3, -7.7), "window_dims": Vector3(3.0, 1.2, 0.4)},
	{"pos": Vector3(6.7, 1.5, 0.0), "dims": Vector3(0.2, 3.0, 15.6), "texture": "wall2.png", "has_door": true, "door_pos": Vector3(6.7, 1.0, 2.0), "door_dims": Vector3(0.4, 2.1, 1.2), "has_window": false, "door_texture": "outdoor1.png"},
	
	# --- INTERNAL ROOM PARTITIONS ---
	{"pos": Vector3(-1.0, 1.5, -3.5), "dims": Vector3(11.4, 3.0, 0.2), "texture": "wall2.png", "has_door": true, "door_pos": Vector3(-0.25, 1.5, -3.5), "door_dims": Vector3(4.0, 3.1, 0.4), "has_window": false},
	{"pos": Vector3(-2.5, 1.5, -5.6), "dims": Vector3(0.2, 3.0, 4.2), "texture": "wall3.png", "has_door": true, "door_pos": Vector3(-2.5, 1.0, -4.5), "door_dims": Vector3(0.2, 2.1, 0.9), "door_texture": "beddoor.png"},
	{"pos": Vector3(1.5, 1.5, 1.0), "dims": Vector3(0.2, 3.0, 9.0), "texture": "wall1.png", "has_door": false, "has_window": false},
	{"pos": Vector3(-2.0, 1.5, 1.0), "dims": Vector3(0.2, 3.0, 9.0), "texture": "wall4.png", "has_door": false, "has_window": false},
	{"pos": Vector3(-3.2, 1.5, 0.5), "dims": Vector3(0.2, 3.0, 4.0), "texture": "wall4.png", "has_door": true, "door_pos": Vector3(-3.2, 1.0, 1.5), "door_dims": Vector3(0.4, 2.1, 0.9), "has_window": false, "door_texture": "beddoor.png"},
	{"pos": Vector3(-4.35, 1.5, 2.5), "dims": Vector3(4.5, 3.0, 0.2), "texture": "wall4.png", "has_door": true, "door_pos": Vector3(-3.0, 1.0, 2.5), "door_dims": Vector3(1.0, 2.1, 0.4), "has_window": false, "door_texture": "beddoor.png"},
	{"pos": Vector3(-3.5, 1.5, 6.1), "dims": Vector3(0.2, 3.0, 3.0), "texture": "wall4.png", "has_door": false, "has_window": false},
	{"pos": Vector3(-5.1, 1.5, 4.6), "dims": Vector3(3.2, 3.0, 0.2), "texture": "wall4.png", "has_door": true, "door_pos": Vector3(-4.5, 1.0, 4.6), "door_dims": Vector3(1.0, 2.1, 0.4), "has_window": false, "door_texture": "bathhdoor.png"}
]

var ui_prompt: Label = null

func _ready() -> void:
	generate_apartment_layout()

func generate_apartment_layout() -> void:
	var building_root = CSGCombiner3D.new()
	building_root.use_collision = true
	building_root.set_collision_mask_value(1, true)
	add_child(building_root)
	
	var living_floor_mat = _load_horror_material("floor1.png", Color(0.1, 0.07, 0.05), Vector3(6.0, 6.0, 6.0), 0.85)
	var floor_mat = living_floor_mat
	var kitchen_floor_mat = _load_horror_material("kittile.png", Color(0.2, 0.2, 0.2), Vector3(4.0, 4.0, 4.0), 0.5) 
	var bathroom_floor_mat = _load_horror_material("bathtile.png", Color(0.25, 0.25, 0.25), Vector3(3.0, 3.0, 3.0), 0.4)
	
	var ceiling_mat = StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.13, 0.13, 0.13)
	ceiling_mat.roughness = 0.95
	
	_add_plane(building_root, Vector3(2.6, 0.05, -1.0), Vector3(8.2, 0.1, 13.0), living_floor_mat)
	_add_plane(building_root, Vector3(2.6, 0.05, 6.6), Vector3(8.2, 0.1, 2.2), kitchen_floor_mat)
	_add_plane(building_root, Vector3(-1.8, 0.05, -1.0), Vector3(4.2, 0.1, 13.4), living_floor_mat)
	_add_plane(building_root, Vector3(-5.1, 0.05, 6.1), Vector3(3.2, 0.1, 3.0), bathroom_floor_mat)
	
	_add_plane(building_root, Vector3(0.0, 2.95, 0.0), Vector3(14.0, 0.1, 16.0), ceiling_mat)
	_add_plane(building_root, Vector3(0.0, 0.05, 0.0), Vector3(14.0, 0.1, 16.0), floor_mat)
	_add_plane(building_root, Vector3(0.0, 2.95, 0.0), Vector3(14.0, 0.1, 16.0), ceiling_mat)

	var glass_mat = _load_horror_material("window01.png", Color(0.05, 0.1, 0.15), Vector3(1, 1, 1), 0.2)

	for wall_data in wall_gallery:
		var current_mat = _load_horror_material(wall_data["texture"], Color(0.2, 0.2, 0.2))
		var wall = CSGBox3D.new()
		wall.position = wall_data["pos"]
		wall.size = wall_data["dims"]
		wall.material = current_mat
		building_root.add_child(wall)
		
		if wall_data.get("has_door", false):
			var door_cut = CSGBox3D.new()
			door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
			door_cut.position = wall_data["door_pos"]
			door_cut.size = wall_data["door_dims"]
			building_root.add_child(door_cut)
			
		if wall_data.get("has_window", false):
			_punch_absolute_window(building_root, wall_data["window_pos"], wall_data["window_dims"], glass_mat)

	print("Structure Gallery Build: All modular wall segments loaded seamlessly.")
	
	var room_lights: Array = [
		{"name": "Mom_Bedroom_Light", "pos": Vector3(2.5, 2.3, -5.6), "color": Color(0.9, 0.85, 0.75), "energy": 1.5, "range": 8.0},
		{"name": "Mom_Closet_Light",  "pos": Vector3(-4.5, 2.3, -5.6), "color": Color(0.85, 0.85, 0.9), "energy": 1.0, "range": 5.0},
		{"name": "Sarah_Bedroom_Light","pos": Vector3(-4.5, 2.3, -0.5), "color": Color(0.9, 0.8, 0.8), "energy": 1.5, "range": 8.0},
		{"name": "Sarah_Closet_Light", "pos": Vector3(-2.6, 2.3, 1.5), "color": Color(0.7, 0.7, 0.8), "energy": 0.8, "range": 4.0},
		{"name": "Bathroom_Light",    "pos": Vector3(-5.1, 2.3, 6.1), "color": Color(0.75, 0.9, 0.8), "energy": 1.2, "range": 6.0},
		{"name": "Main_Hallway_Light", "pos": Vector3(-0.5, 2.3, 2.0), "color": Color(0.85, 0.8, 0.7), "energy": 1.2, "range": 7.0},
		{"name": "Living_Room_Light",  "pos": Vector3(4.0, 2.3, 1.0), "color": Color(0.95, 0.9, 0.8), "energy": 2.0, "range": 10.0},
		{"name": "Kitchen_Light",      "pos": Vector3(4.0, 2.3, 6.5), "color": Color(0.9, 0.95, 1.0), "energy": 1.8, "range": 8.0}
	]

	for light_data in room_lights:
		var light = OmniLight3D.new()
		light.name = light_data["name"]
		light.position = light_data["pos"]
		light.light_color = light_data["color"]
		light.light_energy = light_data["energy"]
		light.omni_range = light_data["range"]
		light.shadow_enabled = true
		light.shadow_blur = 1.5
		add_child(light)
		
	# --- LIVING ROOM FURNITURE SUITE ---
	# 1. The Couch (Dark fabric finish)
	var couch = CSGBox3D.new()
	couch.name = "LivingRoomCouch"
	couch.position = Vector3(4.0, 0.45, -1.0) 
	couch.size = Vector3(2.4, 0.8, 0.9)
	var couch_mat = StandardMaterial3D.new()
	couch_mat.albedo_color = Color(0.15, 0.15, 0.18) 
	couch_mat.roughness = 0.9
	couch.material = couch_mat
	building_root.add_child(couch)
	
	var couch_back = CSGBox3D.new()
	couch_back.position = Vector3(4.0, 0.85, -1.35)
	couch_back.size = Vector3(2.4, 0.6, 0.2)
	couch_back.material = couch_mat
	building_root.add_child(couch_back)

	var couch_interact = Node3D.new()
	couch_interact.set_script(load("res://Interactable.gd"))
	couch_interact.name = "Interactable"
	couch_interact.set("prompt_message", "[E] Sit on Couch")
	couch_interact.set("interaction_type", "couch")
	couch.add_child(couch_interact)

	# 2. Coffee Table
	var coffee_table = CSGBox3D.new()
	coffee_table.name = "CoffeeTable"
	coffee_table.position = Vector3(4.0, 0.25, 0.5)
	coffee_table.size = Vector3(1.6, 0.4, 0.8)
	var table_mat = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.08, 0.05, 0.03) 
	table_mat.roughness = 0.7
	coffee_table.material = table_mat
	building_root.add_child(coffee_table)

	# 3. TV Stand & Television Set
	var tv_stand = CSGBox3D.new()
	tv_stand.name = "TVStand"
	tv_stand.position = Vector3(4.0, 0.3, 2.5)
	tv_stand.size = Vector3(2.0, 0.5, 0.5)
	tv_stand.material = table_mat
	building_root.add_child(tv_stand)

	var tv_screen = CSGBox3D.new()
	tv_screen.name = "Television"
	tv_screen.position = Vector3(4.0, 1.1, 2.5)
	tv_screen.size = Vector3(1.6, 1.0, 0.1)
	var tv_mat = StandardMaterial3D.new()
	tv_mat.albedo_color = Color(0.02, 0.02, 0.02) 
	tv_mat.roughness = 0.2
	tv_screen.material = tv_mat
	building_root.add_child(tv_screen)
	
	var tv_interact = Node3D.new()
	tv_interact.set_script(load("res://Interactable.gd"))
	tv_interact.name = "Interactable"
	tv_interact.set("prompt_message", "[E] Use Television")
	tv_interact.set("interaction_type", "tv")
	tv_screen.add_child(tv_interact)
# 4. Music Collection Rack
	var music_shelf = CSGBox3D.new()
	music_shelf.name = "MusicInventoryRack"
	music_shelf.position = Vector3(6.4, 1.2, -1.0)
	music_shelf.size = Vector3(0.4, 2.2, 3.0)
	var shelf_mat = StandardMaterial3D.new()
	shelf_mat.albedo_color = Color(0.05, 0.05, 0.05)
	var music_texture_path = "res://images/places/wall1.png" 
	if ResourceLoader.exists(music_texture_path):
		shelf_mat.albedo_texture = load(music_texture_path)
		shelf_mat.uv1_scale = Vector3(3.0, 2.0, 1.0)
	music_shelf.material = shelf_mat
	building_root.add_child(music_shelf)

	# --- AMBIENT APARTMENT MUSIC PLAYER ---
	var music_player = AudioStreamPlayer3D.new()
	music_player.name = "ApartmentMusic"
	# Update this line with your target track:
	var track_path = "res://audio/ap2.wav" 
	if ResourceLoader.exists(track_path):
		music_player.stream = load(track_path)
		music_player.autoplay = true
		music_player.max_distance = 15.0 # Fades out naturally as you walk to other rooms
		music_player.bus = &"Master"
		music_shelf.add_child(music_player)

	# --- YARD EXIT PORTAL INTERACTION ZONE ---
	var load_zone = Area3D.new()
	load_zone.name = "YardLoadZone"
	load_zone.position = Vector3(6.6, 1.0, 2.0)
	
	var zone_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 2.0, 1.6)
	zone_collision.shape = box_shape
	
	load_zone.add_child(zone_collision)
	add_child(load_zone)
	
	load_zone.body_entered.connect(_on_yard_zone_entered)
	load_zone.body_exited.connect(_on_yard_zone_exited)
	load_zone.set_meta("player_inside", false)
	print("Interaction Zone Initialized: Approach door and press E to exit to Yard.")

func _on_yard_zone_entered(body: Node) -> void:
	if body.name == "PlayerRoot":
		var zone = get_node("YardLoadZone")
		if zone:
			zone.set_meta("player_inside", true)
			if not ui_prompt:
				ui_prompt = Label.new()
				ui_prompt.text = "[ E ] EXIT TO YARD"
				ui_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ui_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				ui_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
				ui_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
				ui_prompt.position.y -= 60
				add_child(ui_prompt)

func _on_yard_zone_exited(body: Node) -> void:
	if body.name == "PlayerRoot":
		var zone = get_node("YardLoadZone")
		if zone:
			zone.set_meta("player_inside", false)
			if ui_prompt:
				ui_prompt.queue_free()
				ui_prompt = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed:
		var zone = get_node_or_null("YardLoadZone")
		if zone and zone.get_meta("player_inside") == true:
			_load_yard_scene()

func _load_yard_scene() -> void:
	print("Interacted. Safely shifting context to Yard environment...")
	var target_yard = "res://yard.tscn"
	if ResourceLoader.exists(target_yard):
		var player = get_node_or_null("PlayerRoot")
		if player:
			player.get_parent().remove_child(player)
			
			var new_scene = load(target_yard).instantiate()
			get_tree().root.add_child(new_scene)
			get_tree().current_scene = new_scene
			
			var sun = DirectionalLight3D.new()
			sun.position = Vector3(0, 10, 0)
			sun.rotation_degrees = Vector3(-45, 45, 0)
			sun.light_energy = 1.0
			new_scene.add_child(sun)
			
			var env_node = WorldEnvironment.new()
			var new_env = Environment.new()
			new_env.background_mode = Environment.BG_COLOR
			new_env.background_color = Color(0.4, 0.5, 0.6)
			env_node.environment = new_env
			new_scene.add_child(env_node)
			
			new_scene.add_child(player)
			player.position = Vector3(0.0, 0.2, 0.0) 
			
			var yard_floor = new_scene.get_node_or_null("YardFloor")
			if yard_floor:
				yard_floor.scale = Vector3(50.0, 1.0, 50.0) 
				
				var footstep_tag = Node3D.new()
				footstep_tag.set_script(load("res://addons/footstepper/footstepper_tag.gd")) 
				footstep_tag.name = "FootstepperTag"
				footstep_tag.set("material_name", "grass") 
				yard_floor.add_child(footstep_tag)
				
				var noise_tex1 = NoiseTexture2D.new()
				var noise_tex2 = NoiseTexture2D.new()
				var wind_tex = NoiseTexture2D.new()
				
				var base_noise = FastNoiseLite.new()
				base_noise.frequency = 0.05
				noise_tex1.noise = base_noise
				noise_tex2.noise = base_noise
				wind_tex.noise = base_noise
				
				var mat = yard_floor.material_override as ShaderMaterial
				if not mat:
					mat = ShaderMaterial.new()
					if ResourceLoader.exists("res://grass.gdshader"):
						mat.shader = load("res://grass.gdshader")
					yard_floor.material_override = mat
				
				if mat and mat.shader:
					mat.set_shader_parameter("bottom_color", Color(0.05, 0.1, 0.05))
					mat.set_shader_parameter("top_color", Color(0.1, 0.25, 0.1))
					mat.set_shader_parameter("color_variation_1", Color(0.08, 0.2, 0.08))
					mat.set_shader_parameter("color_variation_2", Color(0.12, 0.3, 0.12))
					mat.set_shader_parameter("noise_variation_1", noise_tex1)
					mat.set_shader_parameter("noise_variation_2", noise_tex2)
					mat.set_shader_parameter("wind_noise", wind_tex)
				else:
					var debug_mat = StandardMaterial3D.new()
					debug_mat.albedo_color = Color(0.1, 0.25, 0.1)
					debug_mat.roughness = 0.9
					yard_floor.material_override = debug_mat
			
			queue_free()
	else:
		printerr("Error: Could not locate scene file at: ", target_yard)

# --- ENGINE UTILITY HELPER FUNCTIONS ---
func _load_horror_material(file_name: String, fallback_color: Color, uv_scale: Vector3 = Vector3(1,1,1), rough: float = 0.95) -> Material:
	var mat = StandardMaterial3D.new()
	var full_path = "res://images/places/" + file_name
	if ResourceLoader.exists(full_path):
		mat.albedo_texture = load(full_path)
	else:
		mat.albedo_color = fallback_color
	mat.uv1_scale = uv_scale
	mat.roughness = rough
	return mat

func _add_plane(root: Node3D, pos: Vector3, dims: Vector3, mat: Material) -> void:
	var plane = CSGBox3D.new()
	plane.position = pos
	plane.size = dims
	plane.material = mat
	root.add_child(plane)

func _punch_absolute_window(root: Node3D, pos: Vector3, dims: Vector3, glass_mat: Material) -> void:
	var window_cut = CSGBox3D.new()
	window_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	window_cut.position = pos
	window_cut.size = dims
	root.add_child(window_cut)
	
	var glass_pane = CSGBox3D.new()
	glass_pane.position = pos
	glass_pane.size = Vector3(dims.x - 0.05, dims.y - 0.05, 0.05) if dims.x > dims.z else Vector3(0.05, dims.y - 0.05, dims.z - 0.05)
	glass_pane.material = glass_mat
	root.add_child(glass_pane)
