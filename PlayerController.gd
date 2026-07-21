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
var stand_position: Vector3 = Vector3.ZERO

# Gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $HeadAssembly
@onready var camera = $HeadAssembly/PlayerCamera
@onready var collision = $PlayerCollision

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
		if is_sitting:
			# Stand up safely
			is_sitting = false
			collision.disabled = false
			global_position = stand_position
			print("Stood up from couch.")
			return

		var ray = get_node_or_null("HeadAssembly/PlayerCamera/InteractionRayCast") as RayCast3D
		if ray and ray.is_colliding():
			var target = ray.get_collider()
			if target:
				var interactable = target.get_node_or_null("Interactable") as Interactable
				if interactable:
					_handle_object_interaction(interactable)

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
	var hud_prompt = get_node_or_null("../HUD_Overlay/InteractionPrompt")
	if not hud_prompt: return
	
	var ray = get_node_or_null("HeadAssembly/PlayerCamera/InteractionRayCast") as RayCast3D
	if ray and ray.is_colliding():
		var target = ray.get_collider()
		if target:
			var interactable = target.get_node_or_null("Interactable") as Interactable
			if interactable and not is_sitting:
				hud_prompt.update_prompt(interactable.prompt_message)
				return
		
	hud_prompt.update_prompt("")

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
				collision.disabled = true # Prevent physical physics clip glitches
				# Snap directly to couch viewing height position
				global_position = interactable.get_parent().global_position + Vector3(0, 0.5, 0)
				velocity = Vector3.ZERO
				print("Sitting down on couch.")
				
		"sarah_door":
			# Freeze player movement physics while dialogue runs
			velocity = Vector3.ZERO
			
			# Verify the Dialogic system is active before initiating the tree branch
			if Engine.has_meta("Dialogic"):
				# Instructs Dialogic to take control and generate the UI layers instantly
				Dialogic.start("apartment_start")
				
				# Free the cursor so player can select dialogue choices with the mouse
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				printerr("Error: Dialogic is missing or timeline path is invalid.")

		"tv":
			velocity = Vector3.ZERO
			if Engine.has_meta("Dialogic"):
				# Triggers the distinct television interaction timeline we mapped
				Dialogic.start("tv_interaction")
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
