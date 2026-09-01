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
var walk_target: Vector3 = Vector3.ZERO  # when set, standard movement walks here instead of manual input
var _active_dialogic_timeline := ""  # path of the timeline we last started (timeline_ended has no arg)
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

# Used by the Watch Static branch: stands Beth up (if seated) and moves her
# behind the scenes to the Sarah's-door marker (instant, no visible walk),
# so the door is "shown" and the first major choice pops there.
func move_to_sarah_door() -> void:
	if is_sitting:
		is_sitting = false
		collision.disabled = false
	set_tv_on(true)  # static stays on as she goes to the door
	var marker: Node3D = null
	# Robust recursive lookup — works regardless of how the scenes are nested.
	if get_tree().current_scene != null:
		marker = get_tree().current_scene.find_child("SarahDoorMarker", true, false)
	if marker == null:
		marker = get_tree().root.find_child("SarahDoorMarker", true, false)
	if marker != null:
		# The marker sits AT the door (floating, offset y=1.2) and inside the
		# door collision, which shoves a CharacterBody3D away. Instead, stand a
		# clean ~2.0 units in FRONT of the door (along its local -Z) at floor level.
		var door_node = marker.get_parent()  # sarah_door CSGBox
		var stand_pos: Vector3 = marker.global_position
		if door_node != null:
			var fwd: Vector3 = -door_node.global_transform.basis.z  # door's forward (into room)
			fwd.y = 0.0
			if fwd.length() > 0.001:
				fwd = fwd.normalized()
				stand_pos = door_node.global_position + fwd * 2.0
		stand_pos.y = global_position.y  # keep current floor height (no floating)
		# Defer the actual move so it happens AFTER Dialogic's signal callback
		# finishes (avoids the teleport being overwritten this frame).
		var look_node: Node3D = door_node if door_node != null else marker
		call_deferred("_apply_door_teleport", stand_pos, look_node)
	else:
		printerr("Error: SarahDoorMarker not found for move_to_sarah_door.")

func _apply_door_teleport(stand_pos: Vector3, look_node: Node3D) -> void:
	velocity = Vector3.ZERO
	global_position = stand_pos
	var lt := look_node.global_position
	look_at(Vector3(lt.x, global_position.y, lt.z))
	rotation.x = 0.0
	rotation.z = 0.0
	walk_target = Vector3.ZERO  # cancel any in-progress auto-walk
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("Moved to Sarah's door (behind the scenes): ", stand_pos)

# Handles signals emitted from the TV Dialogic timeline (tv_story.dtl).
# Use a "Send Signal" event in Dialogic with these argument strings:
#   "watch_static"  -> correct path: keep static, route player to Sarah's door
#   "change_channel"-> turn the static off (wrong/branch path)
#   "turn_off"      -> turn the static off (wrong/branch path)
#   "stand_up"      -> stand up off the couch
func _on_dialogic_signal(argument: Variant) -> void:
	var sig := str(argument)
	match sig:
		"change_channel", "turn_off":
			set_tv_on(false)
		"stand_up":
			stand_up()
		"neutral", "encourage", "punish":
			# Sarah-door choice outcomes -> apply metrics.
			if GameState.has_method("modify_metrics"):
				GameState.modify_metrics(sig)

# Called when a Dialogic timeline ends. Bridges Dialogic's broken signal_event
# plumbing: tv_story's branches set GameState flags via "set {GameState.x}"
# events, then we act on them here when tv_story ends.
#   watch_static_path -> teleport Beth to Sarah's door (the jump already
#                         started first-big-choice, so we only teleport)
#   turn_off_requested-> turn the TV off, stay on couch
#   stand_up_requested -> stand up off the couch, TV stays on
#
# IMPORTANT: after first-big-choice.dtl ends, Dialogic returns to tv_story
# (after the jump event). If we don't stop it here, tv_story resumes and
# re-shows the TV choice screen — Beth loops back to the TV. The final
# cleanup block below prevents that.
func _on_tv_timeline_ended(_timeline_resource: Variant) -> void:
	if _active_dialogic_timeline != "res://dilogic/timelines/tv_story.dtl":
		return
	_active_dialogic_timeline = ""

	if GameState.watch_static_path:
		GameState.watch_static_path = false  # reset (fire once)
		set_tv_on(true)
		move_to_sarah_door()  # behind-the-scenes teleport to the door marker
		return

	if GameState.turn_off_requested:
		GameState.turn_off_requested = false
		set_tv_on(false)  # screen off, Beth stays seated
		return

	if GameState.stand_up_requested:
		GameState.stand_up_requested = false
		stand_up()  # get up off the couch, TV stays on
		return

	# No branch matched: tv_story ended on its own (most likely after
	# first-big-choice.dtl returned via the jump event). Stop Dialogic so
	# it doesn't loop back to the TV choice screen.
	var dlg_root = Engine.get_main_loop().root.get_node_or_null("Dialogic")
	if dlg_root and dlg_root.has_method("stop"):
		dlg_root.stop()


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

	# Auto-walk toward a scripted target (e.g. Sarah's door after Watch Static).
	if walk_target != Vector3.ZERO:
		var to_target = walk_target - global_position
		to_target.y = 0.0
		var dist = to_target.length()
		if dist < 0.15:
			walk_target = Vector3.ZERO
			velocity.x = move_toward(velocity.x, 0, walk_speed)
			velocity.z = move_toward(velocity.z, 0, walk_speed)
		else:
			var dir = to_target.normalized()
			velocity.x = dir.x * walk_speed
			velocity.z = dir.z * walk_speed
			look_at(Vector3(walk_target.x, global_position.y, walk_target.z))
			rotation.x = 0.0
			rotation.z = 0.0
		move_and_slide()
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
				# Snap to face the TV (yaw only) so the player looks at it when sitting.
				var tv = get_parent().get_node_or_null("Television")
				if tv:
					var target = tv.global_position
					target.y = global_position.y
					look_at(target)
					rotation.x = 0.0
					rotation.z = 0.0
					if head:
						head.rotation.x = 0.0
				# Turn on TV static when sitting (shader toggle). Future: animated arm+remote pops in view here.
				set_tv_on(true)
				print("Sitting down on couch.")
				
		"door_table":
			# Open Beth's inventory. On first open, seed a starter note so the
			# drawer isn't empty (swap for real item art later).
			if Inventory.is_open:
				return
			Inventory.ensure_drawer_note()
			Inventory.ensure_keys()
			Inventory.toggle()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		"sarah_door":
			# GATED: the first-big-choice dialogue is ONLY reachable via the TV
			# "Watch Static" branch (which jumps to first-big-choice from within
			# tv_story.dtl). Pressing E at the door directly must NOT open it.
			# Show a brief teaser so the player learns to look elsewhere.
			velocity = Vector3.ZERO
			var dialogic_root = Engine.get_main_loop().root.get_node_or_null("Dialogic")
			if dialogic_root != null:
				dialogic_root.start("res://dilogic/timelines/sarah_door_locked.dtl")
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				printerr("Error: Dialogic unavailable for sarah_door locked prompt.")

		"tv":
			velocity = Vector3.ZERO
			# Launch the TV story through Dialogic (text + narrator audio per branch).
			# The Watch Static branch sets the Dialogic variable "watch_static"=true,
			# and when tv_story ends we read that var to route Beth to the door.
			var dialogic_root = Engine.get_main_loop().root.get_node_or_null("Dialogic")
			if dialogic_root != null and ResourceLoader.exists("res://dilogic/timelines/tv_story.dtl"):
				if not dialogic_root.timeline_ended.is_connected(_on_tv_timeline_ended):
					dialogic_root.timeline_ended.connect(_on_tv_timeline_ended)
				_active_dialogic_timeline = "res://dilogic/timelines/tv_story.dtl"
				dialogic_root.start("res://dilogic/timelines/tv_story.dtl")
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				# Fallback while tv_story.dtl isn't created yet, or Dialogic unavailable.
				var dialogue_overlay = get_dialogue_overlay()
				if dialogue_overlay and dialogue_overlay.has_method("start_tv_interaction"):
					dialogue_overlay.start_tv_interaction()
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				else:
					printerr("Error: tv_story.dtl missing and DialogueOverlay.start_tv_interaction() not found. Create res://dilogic/timelines/tv_story.dtl.")
