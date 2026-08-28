extends Node3D

var ui_prompt: Label = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# If we spawned directly (not via backstory transition), place player inside the house
	if not has_meta("backstory_transitioned"):
		if has_node("PlayerRoot"):
			get_node("PlayerRoot").global_position = Vector3(-2.0, 0.0, 3.0)
	
	if Engine.has_meta("Dialogic"):
		Dialogic.timeline_ended.connect(_on_dialogue_timeline_ended)
		
	# Comment this line out:
	# generate_apartment_layout()


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
	var target_yard = "res://scenes/yard.tscn"
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
					if ResourceLoader.exists("res://scenes/grass.gdshader"):
						mat.shader = load("res://scenes/grass.gdshader")
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
	
func _on_dialogue_timeline_ended() -> void:
	# Snap the mouse pointer back into full 3D viewport capture mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("Dialogue concluded. Gameplay control restored.")
