extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Noclip & Crouch variables
var is_noclip: bool = false
@export var noclip_speed: float = 10.0
var is_crouching: bool = false
var normal_height: float = 1.8
var crouch_height: float = 0.9
# TV & Interaction States
var tv_state: int = 0 # 0: Static, 1: Change Channel, 2: Off
var is_sitting: bool = false
var tv_mesh: MeshInstance3D = null
var tv_hiss_player: AudioStreamPlayer3D = null
var tv_light: SpotLight3D = null
var stand_position: Vector3 = Vector3.ZERO
var _dialogue_overlay: Node = null

# Robust lookup for the dialogue UI — searches the tree by name so it works
# regardless of the player's exact parent path (the relative "../DialogueOverlay"
# form broke in the live run when the path didn't resolve).
func get_dialogue_overlay() -> Node:
	if _dialogue_overlay != null and is_instance_valid(_dialogue_overlay):
		return _dialogue_overlay
	# search upward from self, then whole tree, by node name
	var n: Node = self
	while n != null:
		var found = n.find_child("DialogueOverlay", true, false)
		if found != null:
			_dialogue_overlay = found
			return _dialogue_overlay
		n = n.get_parent()
	_dialogue_overlay = get_tree().root.find_child("DialogueOverlay", true, false)
	return _dialogue_overlay

# Gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $HeadAssembly
@onready var camera = $HeadAssembly/PlayerCamera
@onready var collision = $PlayerCollision

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# TV now uses a procedural static shader (res://shaders/tv_static.gdshader) — no video pipeline.
	# Grab the TV mesh so we can toggle its `tv_on` uniform on sit/stand.
	var tv = get_parent().get_node_or_null("Television")
	if tv:
		tv_mesh = tv.get_node_or_null("MeshInstance3D")
	# TV hiss audio (plays only while the static is showing).
	tv_hiss_player = get_parent().get_node_or_null("TV_hiss_point/TV_hiss")
	if tv_hiss_player and tv_hiss_player.stream:
		tv_hiss_player.stream.loop = true   # MP3 imported with loop=false; loop in code so the hiss is continuous
	# TV spotlight (on only while the static is showing, matches the hiss).
	tv_light = get_parent().get_node_or_null("TV_hiss_point/TV_light")

func set_tv_on(on: bool) -> void:
	if tv_mesh and tv_mesh.material_override is ShaderMaterial:
		tv_mesh.material_override.set_shader_parameter("tv_on", 1.0 if on else 0.0)
	if tv_hiss_player:
		if on and not tv_hiss_player.playing:
			tv_hiss_player.play()
		elif not on and tv_hiss_player.playing:
			tv_hiss_player.stop()
	if tv_light:
		tv_light.visible = on   # spotlight glows only while the static/hiss is on

func stand_up() -> void:
	if not is_sitting:
		return
	is_sitting = false
	collision.disabled = false
	global_position = stand_position
	set_tv_on(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("Stood up from couch.")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event is InputEventKey and event.keycode == KEY_V and event.pressed:
		is_noclip = !is_noclip
		collision.disabled = is_noclip
		velocity = Vector3.ZERO
		if not is_noclip:
			collision.shape.height = normal_height
		print("Noclip mode: ", "ON" if is_noclip else "OFF")

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	# E KEY: Handle Object Interactions
	if event is InputEventKey and event.keycode == KEY_E and event.pressed:
		var ray = get_node_or_null("HeadAssembly/PlayerCamera/InteractionRayCast") as RayCast3D
		var interactable = null
		if ray and ray.is_colliding():
			interactable = _find_interactable(ray)
		if is_sitting:
			# While sitting, E uses the TV (if looking at it) instead of standing up.
			if interactable and interactable.interaction_type == "tv":
				_handle_object_interaction(interactable)   # opens TV dialogue, stays seated, static stays on
			else:
				stand_up()   # stand up safely (not looking at the TV)
			return

		if interactable:
			_handle_object_interaction(interactable)

func _find_interactable(ray: RayCast3D) -> Interactable:
	# The ray usually hits `our_home` (a CSGCombiner3D with combined collision),
	# so get_collider() returns the whole apartment, not the specific furniture.
	# Also, the Television is a SIBLING of our_home (not inside its subtree), so a
	# subtree search would miss it. Solution: walk up to the top-level scene root and
	# search the whole tree, but only accept an Interactable if the PLAYER is standing
	# within that Interactable's own `interact_range` (so "Sit on Couch" only shows when
	# you're right next to the couch, not across the room).
	var hit = ray.get_collider()
	if hit == null:
		return null
	# Walk up to the player root to measure how close the player is standing.
	var player_node = ray
	while player_node != null and not player_node is CharacterBody3D:
		player_node = player_node.get_parent()
	var player_pos = player_node.global_position if player_node != null else Vector3.ZERO
	var root = hit
	while root.get_parent() != null:
		root = root.get_parent()
	var best: Interactable = null
	var best_dist := INF
	var stack := [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is Interactable:
			# While sitting on the couch, ignore couch interactables (you're already on it)
			# so the TV/door prompts can win when you look away from the couch.
			if player_node != null and player_node.is_sitting and n.interaction_type == "couch":
				continue
			var d = n.global_position.distance_to(player_pos)
			if d <= n.interact_range and d < best_dist:
				best_dist = d
				best = n
		for c in n.get_children():
			stack.push_back(c)
	return best

func _physics_process(delta: float) -> void:
	if is_noclip:
		_process_noclip_movement(delta)
	else:
		_process_standard_movement(delta)
		
	var grass_mesh = get_node_or_null("../YardFloor")
	if grass_mesh and grass_mesh.material_override:
		grass_mesh.material_override.set_shader_parameter("interracting_object_pos", global_position)
	_evaluate_interaction_raycast()

func _evaluate_interaction_raycast() -> void:
	var hud_parent = get_node_or_null("../HUD_Overlay")
	if not hud_parent:
		hud_parent = CanvasLayer.new()
		hud_parent.name = "HUD_Overlay"
		hud_parent.layer = 10
		get_parent().add_child(hud_parent)

	var hud_prompt = hud_parent.get_node_or_null("InteractionPrompt")
	if not hud_prompt:
		hud_prompt = Label.new()
		hud_prompt.name = "InteractionPrompt"
		hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hud_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hud_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		hud_prompt.position.y = -40
		hud_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		hud_parent.add_child(hud_prompt)

	var ray = get_node_or_null("HeadAssembly/PlayerCamera/InteractionRayCast") as RayCast3D
	if ray and ray.is_colliding():
		var interactable = _find_interactable(ray)
		if interactable:
			# TV prompt only shows while sitting on the couch; other prompts only while standing.
			if interactable.interaction_type == "tv":
				hud_prompt.text = "Use Television" if is_sitting else ""
			elif not is_sitting:
				hud_prompt.text = interactable.prompt_message
			else:
				hud_prompt.text = ""
			return

	hud_prompt.text = ""

func _process_standard_movement(delta: float) -> void:
	
	if is_sitting:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	if Input.is_key_pressed(KEY_X):
		is_crouching = true
		collision.shape.height = crouch_height
		head.position.y = 0.9
	else:
		is_crouching = false
		collision.shape.height = normal_height
		head.position.y = 1.6

	var current_speed = run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	if is_crouching:
		current_speed *= 0.5

	var forward_back = 0.0
	var left_right = 0.0
	
	if Input.is_key_pressed(KEY_W): forward_back -= 1.0
	if Input.is_key_pressed(KEY_S): forward_back += 1.0
	if Input.is_key_pressed(KEY_A): left_right -= 1.0
	if Input.is_key_pressed(KEY_D): left_right += 1.0

	var direction = (transform.basis * Vector3(left_right, 0, forward_back)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func _process_noclip_movement(delta: float) -> void:
	var forward_back = 0.0
	var left_right = 0.0
	
	if Input.is_key_pressed(KEY_W): forward_back -= 1.0
	if Input.is_key_pressed(KEY_S): forward_back += 1.0
	if Input.is_key_pressed(KEY_A): left_right -= 1.0
	if Input.is_key_pressed(KEY_D): left_right += 1.0
	
	var direction = (camera.global_transform.basis * Vector3(left_right, 0, forward_back)).normalized()
	
	var vertical_dir = 0.0
	if Input.is_key_pressed(KEY_SPACE):
		vertical_dir += 1.0
	if Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_CTRL):
		vertical_dir -= 1.0
		
	if direction or vertical_dir != 0.0:
		velocity = direction * noclip_speed
		velocity.y += vertical_dir * noclip_speed
	else:
		velocity = velocity.move_toward(Vector3.ZERO, noclip_speed * 0.2)
		
	global_position += velocity * delta

func _handle_object_interaction(interactable: Interactable) -> void:
	match interactable.interaction_type:
		
		"couch":
			if not is_sitting:
				stand_position = global_position
				is_sitting = true
				collision.disabled = true
				global_position = interactable.get_parent().global_position + Vector3(0, 0.5, 0)
				velocity = Vector3.ZERO
				# Turn on TV static when sitting (shader toggle). Future: animated arm+remote pops in view here.
				set_tv_on(true)
				print("Sitting down on couch.")
				
		"sarah_door":
			velocity = Vector3.ZERO
			var dialogue_overlay = get_dialogue_overlay()
			if dialogue_overlay and dialogue_overlay.has_method("start_door_interaction"):
				dialogue_overlay.start_door_interaction()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				printerr("Error: DialogueOverlay missing or start_door_interaction() not found.")

		"tv":
			velocity = Vector3.ZERO
			var dialogue_overlay = get_dialogue_overlay()
			if dialogue_overlay and dialogue_overlay.has_method("start_tv_interaction"):
				dialogue_overlay.start_tv_interaction()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				printerr("Error: DialogueOverlay missing or start_tv_interaction() not found.")
