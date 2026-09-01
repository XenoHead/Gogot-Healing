extends Control

# --- Node References ---
@onready var intro_transition_layer: CanvasLayer = $IntroTransitionLayer
@onready var fire_tree_logo: TextureRect = $IntroTransitionLayer/CenterContainer/IntroVBox/FireTreeLogo
@onready var fire_wav_player: AudioStreamPlayer = $IntroTransitionLayer/FireWavPlayer
@onready var start_button_prompt: TextureButton = $IntroTransitionLayer/CenterContainer/IntroVBox/StartButtonPrompt
@onready var intro_select_player: AudioStreamPlayer = $IntroTransitionLayer/IntroSelectPlayer

@onready var disclaimer_container: MarginContainer = $IntroTransitionLayer/DisclaimerContainer
@onready var i_agree_button: Button = $IntroTransitionLayer/DisclaimerContainer/DisclaimerText/Iagreelabel

@onready var menu_ui: CanvasLayer = $MenuUILayer
@onready var menu_loop_player: AudioStreamPlayer = $MenuUILayer/MenuLoopPlayer
@onready var crying_player: AudioStreamPlayer = $MenuUILayer/CryingPlayer
@onready var title_logo: TextureRect = $MenuUILayer/MarginContainer/MainVBox/TitleBoxContainer/TitleLogo
@onready var button_vbox: VBoxContainer = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox

@onready var ui_hover_player: AudioStreamPlayer = $MenuUILayer/UIHoverPlayer
@onready var ui_select_player: AudioStreamPlayer = $MenuUILayer/UISelectPlayer

@onready var play_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/PlayButton
@onready var options_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/OptionsButton
@onready var quit_button: Button = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/QuitButton

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
var _i_agree_pressed_flag: bool = false

var saved_main_db: float = -6.0
var saved_music_db: float = -6.0
var saved_voice_db: float = -6.0
var saved_fullscreen: bool = false

func _ready() -> void:
	menu_ui.hide()
	settings_layer.hide()
	
	$IntroTransitionLayer/CenterContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	$IntroTransitionLayer/CenterContainer/IntroVBox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if has_node("IntroTransitionLayer/DisclaimerContainer"):
		disclaimer_container.hide()
		disclaimer_container.modulate.a = 0.0
		
	start_button_prompt.show()
	start_button_prompt.modulate.a = 0.0
	start_button_prompt.disabled = true
	start_button_prompt.mouse_filter = Control.MOUSE_FILTER_STOP
	
	intro_transition_layer.show()
	fire_tree_logo.modulate.a = 0.0
	
	var add_material = CanvasItemMaterial.new()
	add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	if title_logo:
		title_logo.material = add_material
	
	_connect_menu_signals()
	_setup_button_effects()
	_setup_settings_signals()

	if i_agree_button:
		i_agree_button.pressed.connect(_on_i_agree_pressed)
	
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
	print("DEBUG: _show_prompt called — button enabled")
	start_button_prompt.modulate.a = 1.0
	start_button_prompt.disabled = false
	can_interact = true

func _on_start_button_prompt_pressed() -> void:
	print("DEBUG: StartButtonPrompt SIGNAL fired")
	_on_continue_triggered()

func _input(event: InputEvent) -> void:
	if can_interact and (event is InputEventKey) and event.is_pressed():
		print("DEBUG: Key press detected, triggering continue")
		_on_continue_triggered()
	
	if can_interact and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("DEBUG: Left mouse click at", event.global_position)
		if start_button_prompt:
			var rect = start_button_prompt.get_global_rect()
			var hit = rect.has_point(event.global_position)
			print("DEBUG: Button rect:", rect, "hit?", hit)
			if hit:
				print("DEBUG: Click on button — triggering continue")
				_on_continue_triggered()

func _on_continue_triggered() -> void:
	print("DEBUG: _on_continue_triggered called")
	if not can_interact:
		print("DEBUG: can_interact is false, returning")
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
	
	if disclaimer_container:
		disclaimer_container.modulate.a = 0.0
		disclaimer_container.show()
		
		var warning_fade_in = create_tween()
		warning_fade_in.tween_property(disclaimer_container, "modulate:a", 1.0, 0.6)
		await warning_fade_in.finished
		
		await _wait_for_i_agree()
		
		var warning_fade_out = create_tween()
		warning_fade_out.tween_property(disclaimer_container, "modulate:a", 0.0, 0.6)
		await warning_fade_out.finished
		disclaimer_container.hide()
	else:
		await get_tree().create_timer(0.5).timeout

	_advance_to_menu()

func _on_i_agree_pressed() -> void:
	print("DEBUG: I AGREE pressed")
	_i_agree_pressed_flag = true

func _wait_for_i_agree() -> void:
	_i_agree_pressed_flag = false
	if i_agree_button:
		i_agree_button.grab_focus()
	while not _i_agree_pressed_flag:
		await get_tree().process_frame

func _advance_to_menu() -> void:
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
	
	var load_btn = $MenuUILayer/MarginContainer/MainVBox/ButtonVBox/LoadButton
	if load_btn and not load_btn.pressed.is_connected(_on_load_pressed):
		load_btn.pressed.connect(_on_load_pressed)

func _on_button_hover(btn: Button) -> void:
	if not btn.text.begins_with("> "):
		btn.text = "> " + btn.text
	
	var shift_tween = create_tween()
	shift_tween.tween_method(
		func(val: int): btn.add_theme_constant_override("outline_size", val),
		0,
		6,
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
		
	var shift_tween = create_tween()
	shift_tween.tween_method(
		func(val: int): btn.add_theme_constant_override("outline_size", val),
		6,
		0,
		0.1
	)
	
	if ui_hover_player and ui_hover_player.is_playing():
		var audio_fade_out = create_tween()
		audio_fade_out.tween_property(ui_hover_player, "volume_db", -80.0, 0.05)
		audio_fade_out.connect("finished", func(): if ui_hover_player: ui_hover_player.stop())

func _on_load_pressed() -> void:
	print("Load Game triggered — pending save integration")

func _on_button_pressed_sound() -> void:
	if ui_select_player and ui_select_player.stream:
		ui_select_player.play()

func _on_play_pressed() -> void:
	print("DEBUG: NEW GAME button pressed")
	GameState.reset_game_state()
	var track_stream = menu_loop_player.stream
	var track_pos = menu_loop_player.get_playback_position()
	var track_vol = menu_loop_player.volume_db
		
	if crying_player and crying_player.is_playing():
		crying_player.stop()
	
	menu_loop_player.stop()
	
	var backstory_scene = load("res://scenes/backstory.tscn")
	var backstory_instance = backstory_scene.instantiate()
	
	get_tree().root.add_child(backstory_instance)
	get_tree().current_scene = backstory_instance
	
	backstory_instance.init_story_audio(track_stream, track_pos, track_vol)
	queue_free()

func _on_options_pressed() -> void:
	menu_ui.hide()
	settings_layer.show()
	
	saved_main_db = main_slider.value
	saved_music_db = music_slider.value
	saved_voice_db = voice_slider.value
	saved_fullscreen = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.button_pressed = saved_fullscreen

func _on_quit_pressed() -> void:
	if ui_select_player and ui_select_player.stream:
		await ui_select_player.finished
	get_tree().quit()

func _setup_settings_signals() -> void:
	save_button.pressed.connect(_on_settings_save)
	cancel_button.pressed.connect(_on_settings_cancel)
	
	for btn in [save_button, cancel_button]:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		btn.pressed.connect(_on_button_pressed_sound)
	
	main_slider.value_changed.connect(func(val): _apply_volume("Master", val))
	music_slider.value_changed.connect(func(val): _apply_volume("Music", val))
	voice_slider.value_changed.connect(func(val): _apply_volume("Voice", val))

func _apply_volume(bus_name: String, db_value: float) -> void:
	if db_value <= -39.0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db_value)

func _on_settings_save() -> void:
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	settings_layer.hide()
	menu_ui.show()

func _on_settings_cancel() -> void:
	_apply_volume("Master", saved_main_db)
	_apply_volume("Music", saved_music_db)
	_apply_volume("Voice", saved_voice_db)
	
	main_slider.value = saved_main_db
	music_slider.value = saved_music_db
	voice_slider.value = saved_voice_db
	
	settings_layer.hide()
	menu_ui.show()
