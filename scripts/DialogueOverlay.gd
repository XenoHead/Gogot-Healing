extends Control

signal dialogue_finished

# --- Node References ---
# --- REPLACE AT THE TOP OF DIALOGUEOVERLAY.GD ---
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var narrative_label: RichTextLabel = $DialoguePanel/RichTextLabel
@onready var choice_vbox: VBoxContainer = $DialoguePanel/VBoxContainer

var current_node_key: String = "start"
var choices_active: bool = false


# Standardized key to 'dialogue_nodes' to perfectly resolve your line 75 error
var dialogue_nodes: Dictionary = {
	"start": {
		"text": "Sarah's room is completely dark. A low, rhythmic scratching sounds from behind the locked bedroom door panels.\n\nMother: 'Sarah? What are you doing in there?'",
		"choices": [
			{"text": "[ 1 ] Just keep things quiet. (Neutral)", "action": "neutral", "next": "end_neutral"},
			{"text": "[ 2 ] That's my girl. Meticulous. (Encourage)", "action": "encourage", "next": "end_encourage"},
			{"text": "[ 3 ] Drop that immediately! Go to your closet! (Punish)", "action": "punish", "next": "end_punish"}
		]
	},
	"end_neutral": {
		"text": "The scratching stops briefly, but the thick silence remains.\n\nMother: 'Just... clean up when you're done. Let's keep things quiet.'",
		"choices": []
	},
	"end_encourage": {
		"text": "A cold breeze catches under the door frame. The scratching rhythm syncs up faster.\n\nMother: 'Meticulous. Just like your father used to be.'",
		"choices": []
	},
	"end_punish": {
		"text": "A heavy, violent thud rattles the wood framework from the inside, followed by complete stillness.\n\nMother: 'Drop that immediately! Go to your closet. Now!'",
		"choices": []
	},
	# Add these nodes alongside your existing "start" and bedroom door entries
	"tv_start": {
		"text": "The television frame thrums under a heavy skin of dust. The screen hums with thick, radioactive energy.",
		"choices": [
			{"text": "[ 1 ] Watch Static", "action": "watch_static", "next": "tv_static"},
			{"text": "[ 2 ] Change Channel", "action": "change_channel", "next": "tv_channel"},
			{"text": "[ 3 ] Turn Off", "action": "turn_off", "next": "tv_off"},
			{"text": "[ 4 ] Stand Up", "action": "stand_up", "next": "tv_off"}
		]
	},
	"tv_static": {
		"text": "White noise fills the apartment. The cascading patterns begin to form shapes moving behind the glass surface...",
		"choices": []
	},
	"tv_channel": {
		"text": "The dial clicks roughly, but the static stays. Only the pitch of the screeching speaker changes.",
		"choices": []
	},
	"tv_off": {
		"text": "The screen collapses into a small white dot, leaving a high-frequency whistle piercing the dark.",
		"choices": []
	}
	}

func start_door_interaction() -> void:
	show()
	current_node_key = "start"
	_display_current_node()

func start_tv_interaction() -> void:
	show()
	current_node_key = "tv_start"
	_display_current_node()


func _display_current_node() -> void:
	# Fixes choice_vbox scope error (Line 41)
	for child in choice_vbox.get_children():
		child.queue_free()
		
	var node_data = dialogue_nodes[current_node_key]
	# Fixes narrative_label scope error (Line 45)
	narrative_label.text = node_data["text"]
	
	var branch_choices = node_data["choices"]
	if branch_choices.size() > 0:
		choices_active = true
		for choice in branch_choices:
			var btn = Button.new()
			btn.text = choice["text"]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_override("font", load("res://fonts/GrotleyRegular-mLEWv.otf"))
			btn.add_theme_font_size_override("font_size", 20)
			btn.pressed.connect(func(): _process_choice_selection(choice))
			# Fixes choice_vbox scope error (Line 57)
			choice_vbox.add_child(btn)
	else:
		choices_active = false
		await get_tree().create_timer(4.0).timeout
		_close_dialogue()

func _process_choice_selection(chosen_branch: Dictionary) -> void:
	var action = chosen_branch["action"]
	var player = get_parent().get_node_or_null("PlayerRoot")
	# TV-specific actions that touch the shader / player state.
	if action == "turn_off":
		if player and player.has_method("set_tv_on"):
			player.set_tv_on(false)   # kill static, stay seated
	elif action == "stand_up":
		if player and player.has_method("stand_up"):
			player.stand_up()         # kill static + stand up
		_close_dialogue()
		return
	if GameState.has_method("modify_metrics"):
		GameState.modify_metrics(action)
	current_node_key = chosen_branch["next"]
	_display_current_node()

func _input(event: InputEvent) -> void:
	if not choices_active:
		return
		
	if event is InputEventKey and event.is_pressed():
		# Fixes dialogue_nodes mapping error (Line 75)
		var node_data = dialogue_nodes[current_node_key]
		var index = -1
		
		if event.keycode == KEY_1: index = 0
		elif event.keycode == KEY_2: index = 1
		elif event.keycode == KEY_3: index = 2
		elif event.keycode == KEY_4: index = 3
		
		if index >= 0 and index < node_data["choices"].size():
			get_viewport().set_input_as_handled()
			_process_choice_selection(node_data["choices"][index])

func _close_dialogue() -> void:
	hide()
	dialogue_finished.emit()
