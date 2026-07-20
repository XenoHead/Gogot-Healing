extends Control

# --- Node References ---
@onready var intro_transition_layer: CanvasLayer = $IntroTransitionLayer
@onready var fire_tree_logo: TextureRect = $IntroTransitionLayer/CenterContainer/IntroVBox/FireTreeLogo
@onready var fire_wav_player: AudioStreamPlayer = $IntroTransitionLayer/FireWavPlayer
@onready var start_button_prompt: TextureButton = $IntroTransitionLayer/CenterContainer/IntroVBox/StartButtonPrompt
@onready var intro_select_player: AudioStreamPlayer = $IntroTransitionLayer/IntroSelectPlayer

@onready var menu_ui: CanvasLayer = $MenuUILayer
@onready var menu_loop_player: AudioStreamPlayer = $MenuUILayer/MenuLoopPlayer
@onready var crying_player: AudioStreamPlayer = $MenuUILayer/CryingPlayer
@onready var title_logo: TextureRect = $MenuUILayer/MarginContainer/MainVBox/TitleBoxContainer/TitleLogo
@onready var button_vbox: VBoxContainer = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox

# Audio players for dynamic horror feedback
@onready var ui_hover_player: AudioStreamPlayer = $MenuUILayer/UIHoverPlayer
@onready var ui_select_player: AudioStreamPlayer = $MenuUILayer/UISelectPlayer

# Main Menu Buttons
@onready var play_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/PlayButton
@onready var options_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/OptionsButton
@onready var quit_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/QuitButton

# --- Settings Panel Nodes ---
@onready var settings_layer: CanvasLayer = $SettingsLayer
@onready var main_slider: HSlider = $SettingsLayer/MarginContainer/SettingsVBox/VolumeControls/MainSlider
@onready var music_slider: HSlider = $SettingsLayer/MarginContainer/SettingsVBox/VolumeControls/MusicSlider
@onready var voice_slider: HSlider = $SettingsLayer/MarginContainer/SettingsVBox/VolumeControls/VoiceSlider
@onready var fullscreen_check: CheckBox = $SettingsLayer/MarginContainer/SettingsVBox/DisplayControls/FullscreenCheck
@onready var save_button: Button = $SettingsLayer/MarginContainer/SettingsVBox/ActionButtons/SaveButton
@onready var cancel_button: Button = $SettingsLayer/MarginContainer/SettingsVBox/ActionButtons/CancelButton

var can_interact: bool = false
var last_hover_time: int = 0
const HOVER_COOLDOWN_MS: int = 150

# Fallback volume state cache to revert to on cancel
var saved_main_db: float = -6.0
var saved_music_db: float = -6.0
var saved_voice_db: float = -6.0
var saved_fullscreen: bool = false

func _ready() -> void:
	menu_ui.hide()
	settings_layer.hide()
	
	start_button_prompt.show()
	start_button_prompt.modulate.a = 0.0
	start_button_prompt.disabled = true
	
	intro_transition_layer.show()
	fire_tree_logo.modulate.a = 0.0
	
	var add_material = CanvasItemMaterial.new()
	add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	if title_logo:
		title_logo.material = add_material
	
	_connect_menu_signals()
	_setup_button_effects()
	_setup_settings_signals()
	
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
	start_button_prompt.modulate.a = 1.0
	start_button_prompt.disabled = false
	can_interact = true

func _on_start_button_prompt_pressed() -> void:
	_on_continue_triggered()

func _input(event: InputEvent) -> void:
	if can_interact and (event is InputEventKey):
		if event.is_pressed():
			_on_continue_triggered()

func _on_continue_triggered() -> void:
	if not can_interact:
		return
		
	if intro_select_player and intro_select_player.stream:
		intro_select_player.play()
		
	can_interact = false 
	start_button_prompt.disabled = true
	
	var fade_out_tween = create_tween()
	fade_out_tween.set_parallel(true)
	
	fade_out_tween.tween_property(fire_tree_logo, "modulate:a", 0.0, 0.5)
	fade_out_tween.tween_property(start_button_prompt, "modulate:a", 0.0, 0.4)
	
	if fire_wav_player.is_playing():
		fade_out_tween.tween_property(fire_wav_player, "volume_db", -80.0, 0.4)
	
	await fade_out_tween.finished
	fire_wav_player.stop() 
	
	await get_tree().create_timer(0.5).timeout
	
	intro_transition_layer.hide()
	menu_ui.show()
	
	if menu_loop_player.stream != null:
		menu_loop_player.volume_db = -80.0
		menu_loop_player.play()
	
	if crying_player and crying_player.stream != null:
		crying_player.volume_db = -80.0
		crying_player.play()
		
	var main_music_fade = create_tween()
	main_music_fade.set_parallel(true)
	if menu_loop_player.is_playing():
		main_music_fade.tween_property(menu_loop_player, "volume_db", -6.0, 1.5).set_trans(Tween.TRANS_SINE)
	if crying_player.is_playing():
		main_music_fade.tween_property(crying_player, "volume_db", -12.0, 2.0).set_trans(Tween.TRANS_SINE)
	
	var menu_container = $MenuUILayer/MarginContainer
	menu_container.modulate.a = 0.0
	
	var menu_tween = create_tween()
	menu_tween.tween_property(menu_container, "modulate:a", 1.0, 0.8)


func _setup_button_effects() -> void:
	if not button_vbox:
		return
		
	for child in button_vbox.get_children():
		if child is Button:
			if child.mouse_entered.is_connected(_on_button_hover):
				child.mouse_entered.disconnect(_on_button_hover)
			if child.mouse_exited.is_connected(_on_button_unhover):
				child.mouse_exited.disconnect(_on_button_unhover)
			if child.pressed.is_connected(_on_button_pressed_sound):
				child.pressed.disconnect(_on_button_pressed_sound)
				
			child.mouse_entered.connect(_on_button_hover.bind(child))
			child.mouse_exited.connect(_on_button_unhover.bind(child))
			child.pressed.connect(_on_button_pressed_sound)

func _connect_menu_signals() -> void:
	if play_button and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if options_button and not options_button.pressed.is_connected(_on_options_pressed):
		options_button.pressed.connect(_on_options_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect the Load Button so it doesn't stand out or cause issues
	var load_btn = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/LoadButton
	if load_btn and not load_btn.pressed.is_connected(_on_load_pressed):
		load_btn.pressed.connect(_on_load_pressed)

func _on_button_hover(btn: Button) -> void:
	if not btn.text.begins_with("> "):
		btn.text = "> " + btn.text
	
	# Bypasses the Nil check by using an explicit method tween
	var shift_tween = create_tween()
	shift_tween.tween_method(
		func(val: int): btn.add_theme_constant_override("outline_size", val),
		0, # Start size
		6, # Target thickness for your horror font display
		0.1
	)
	
	if ui_hover_player and ui_hover_player.stream:
		if not ui_hover_player.is_playing():
			ui_hover_player.volume_db = -80.0
			ui_hover_player.play()
			
		var audio_fade_in = create_tween()
		audio_fade_in.tween_property(ui_hover_player, "volume_db", -1.563, 0.08).set_trans(Tween.TRANS_SINE)

func _on_button_unhover(btn: Button) -> void:
	if btn.text.begins_with("> "):
		btn.text = btn.text.replace("> ", "")
		
	# Bypasses the Nil check to cleanly strip out the override constant on exit
	var shift_tween = create_tween()
	shift_tween.tween_method(
		func(val: int): btn.add_theme_constant_override("outline_size", val),
		6, # Current thickness
		0, # Remove outline
		0.1
	)
	
	if ui_hover_player and ui_hover_player.is_playing():
		var audio_fade_out = create_tween()
		audio_fade_out.tween_property(ui_hover_player, "volume_db", -80.0, 0.05)
		audio_fade_out.connect("finished", func(): if ui_hover_player: ui_hover_player.stop())

# Fallback method placeholder for the load button signal connection
func _on_load_pressed() -> void:
	print("Load Game triggered. Functionality pending save architecture integration.")
		
func _on_button_pressed_sound() -> void:
	if ui_select_player and ui_select_player.stream:
		ui_select_player.play()

func _on_play_pressed() -> void:
	# Capture the running track data so it never stops playing
	var track_stream = menu_loop_player.stream
	var track_pos = menu_loop_player.get_playback_position()
	var track_vol = menu_loop_player.volume_db
	
	# Stop the crying audio overlay immediately as we leave the menu
	if crying_player and crying_player.is_playing():
		crying_player.stop()
		
	menu_loop_player.stop()
	
	# Instantiate the backstory scene directly so we can execute the audio handoff
	var backstory_scene = load("res://Backstory.tscn")
	var backstory_instance = backstory_scene.instantiate()
	
	get_tree().root.add_child(backstory_instance)
	get_tree().current_scene = backstory_instance
	
	# Pass the menu variables straight over to the new node player
	backstory_instance.init_story_audio(track_stream, track_pos, track_vol)
	
	# Delete the old main menu layout from memory safely
	queue_free()

func _on_options_pressed() -> void:
	menu_ui.hide()
	settings_layer.show()
	
	# Cache current values in case the user cancels changes
	saved_main_db = main_slider.value
	saved_music_db = music_slider.value
	saved_voice_db = voice_slider.value
	saved_fullscreen = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.button_pressed = saved_fullscreen

func _on_quit_pressed() -> void:
	# Let the audio play, then wait for it to finish before shutting down
	if ui_select_player and ui_select_player.stream:
		await ui_select_player.finished
	get_tree().quit()

# --- Settings Logic ---
func _setup_settings_signals() -> void:
	save_button.pressed.connect(_on_settings_save)
	cancel_button.pressed.connect(_on_settings_cancel)
	
	# Route visual highlights to save/cancel choices
	for btn in [save_button, cancel_button]:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		btn.pressed.connect(_on_button_pressed_sound)
	
	# Dynamically capture slider adjustments
	main_slider.value_changed.connect(func(val): _apply_volume("Master", val))
	music_slider.value_changed.connect(func(val): _apply_volume("Music", val)) # Maps to MenuLoopPlayer/CryingPlayer
	voice_slider.value_changed.connect(func(val): _apply_volume("Voice", val))

func _apply_volume(bus_name: String, db_value: float) -> void:
	# If slider is dragged to the far left floor value (-40), completely mute it
	if db_value <= -39.0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db_value)

func _on_settings_save() -> void:
	# Commit window preferences
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	settings_layer.hide()
	menu_ui.show()

func _on_settings_cancel() -> void:
	# Revert audio buses back to cached entry parameters
	_apply_volume("Master", saved_main_db)
	_apply_volume("Music", saved_music_db)
	_apply_volume("Voice", saved_voice_db)
	
	# Revert slider positions
	main_slider.value = saved_main_db
	music_slider.value = saved_music_db
	voice_slider.value = saved_voice_db
	
	settings_layer.hide()
	menu_ui.show()
