extends Control

# Component references linked directly to your text-defined .tscn nodes
@onready var intro_transition_layer: CanvasLayer = $IntroTransitionLayer
@onready var fire_tree_logo: TextureRect = $IntroTransitionLayer/CenterContainer/FireTreeLogo
@onready var fire_wav_player: AudioStreamPlayer = $IntroTransitionLayer/FireWavPlayer
@onready var prompt_label: Label = $IntroTransitionLayer/PromptLabel
@onready var menu_ui: CanvasLayer = $MenuUILayer

# Cache UI elements
@onready var play_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/PlayButton
@onready var quit_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/QuitButton

var can_continue: bool = false
var pulse_tween: Tween = null

func _ready() -> void:
	menu_ui.hide()
	prompt_label.hide()
	intro_transition_layer.show()
	fire_tree_logo.modulate.a = 0.0
	
	_connect_menu_signals()
	
	await get_tree().create_timer(0.5).timeout
	
	var intro_tween = create_tween()
	intro_tween.tween_property(fire_tree_logo, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	_play_burning_sound()
	
	await intro_tween.finished
	_show_prompt()

func _play_burning_sound() -> void:
	if fire_wav_player.stream != null:
		fire_wav_player.play()

func _show_prompt() -> void:
	prompt_label.show()
	can_continue = true
	
	# Create a continuous, ping-ponging loop for a rhythmic text pulse effect
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(prompt_label, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _input(event: InputEvent) -> void:
	# Catch any keyboard event or mouse strike
	if can_continue and (event is InputEventKey or event is InputEventMouseButton):
		if event.is_pressed():
			_on_continue_triggered()

func _on_continue_triggered() -> void:
	if not can_continue:
		return
		
	can_continue = false # Lock immediately to drop double-triggering inputs
	
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		
	# Reset alpha back to normal solid values for the fade-out look
	prompt_label.modulate.a = 1.0 
	
	var fade_out_tween = create_tween()
	fade_out_tween.set_parallel(true)
	fade_out_tween.tween_property(fire_tree_logo, "modulate:a", 0.0, 0.5)
	fade_out_tween.tween_property(prompt_label, "modulate:a", 0.0, 0.4)
	
	await fade_out_tween.finished
	await get_tree().create_timer(0.5).timeout
	
	intro_transition_layer.hide()
	menu_ui.show()
	
	var menu_container = $MenuUILayer/MarginContainer
	menu_container.modulate.a = 0.0
	
	var menu_tween = create_tween()
	menu_tween.tween_property(menu_container, "modulate:a", 1.0, 0.8)

func _connect_menu_signals() -> void:
	if play_button and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	print("Execution Trace: Initialize game universe configurations.")

func _on_quit_pressed() -> void:
	get_tree().quit()