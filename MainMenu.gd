extends Control

# Component references linked directly to your text-defined .tscn nodes
@onready var intro_transition_layer: CanvasLayer = $IntroTransitionLayer
@onready var fire_tree_logo: TextureRect = $IntroTransitionLayer/CenterContainer/FireTreeLogo
@onready var fire_wav_player: AudioStreamPlayer = $IntroTransitionLayer/FireWavPlayer
# We are now grabbing the TextureButton by its new text-defined name
@onready var start_button_prompt: TextureButton = $IntroTransitionLayer/StartButtonPrompt
@onready var menu_ui: CanvasLayer = $MenuUILayer

# Cache main menu button references
@onready var play_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/PlayButton
@onready var quit_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/QuitButton

var can_interact: bool = false
var pulse_tween: Tween = null

func _ready() -> void:
	# 1. Hide all prompt/UI elements for the boot sequence
	menu_ui.hide()
	start_button_prompt.hide()
	# Pre-emptively disable interaction so clicks don't fire early
	start_button_prompt.disabled = true
	
	intro_transition_layer.show()
	fire_tree_logo.modulate.a = 0.0
	
	# Connect main menu signals
	_connect_menu_signals()
	
	# Connect the new prompt button's signal explicitly
	# This uses Godot's built-in UI press signal, replacing our custom input check
	if not start_button_prompt.pressed.is_connected(_on_start_button_prompt_pressed):
		start_button_prompt.pressed.connect(_on_start_button_prompt_pressed)
	
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
	# Enable the button and make it visible so it can receive hover/clicks
	start_button_prompt.disabled = false
	start_button_prompt.show()
	can_interact = true
	
	# Re-implement the rhythmic pulse effect, applying it to the entire button image
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(start_button_prompt, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(start_button_prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

# The built-in pressed signal from TextureButton handles mouse clicks for us!
func _on_start_button_prompt_pressed() -> void:
	_on_continue_triggered()

# Optional: We can still capture any keypress for accessibility, linking it to the same action [cite: 2]
func _input(event: InputEvent) -> void:
	# This catches ANY keyboard button (not mouse clicks, which the prompt button handles) [cite: 2]
	if can_interact and (event is InputEventKey):
		if event.is_pressed():
			# Programmatically trigger the action associated with the prompt button [cite: 2]
			_on_continue_triggered()

func _on_continue_triggered() -> void:
	if not can_interact:
		return
		
	can_interact = false 
	# Lock the button again immediately to prevent double-triggers
	start_button_prompt.disabled = true
	
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		
	# Ensure the button is solid before the final fade
	start_button_prompt.modulate.a = 1.0 
	
	var fade_out_tween = create_tween()
	fade_out_tween.set_parallel(true)
	fade_out_tween.tween_property(fire_tree_logo, "modulate:a", 0.0, 0.5)
	# Fade out the image button smoothly
	fade_out_tween.tween_property(start_button_prompt, "modulate:a", 0.0, 0.4)
	
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
