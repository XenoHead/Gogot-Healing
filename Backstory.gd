extends Control

# FIXED: Reverted from % to standard $ child paths to perfectly match your Backstory.tscn file
@onready var story_bg: TextureRect = $StoryBG
@onready var story_text_label: Label = $MarginContainer/StoryText
@onready var story_music_player: AudioStreamPlayer = $StoryMusicPlayer
@onready var step_sfx_player: AudioStreamPlayer = $StepSFXPlayer
@onready var intro_video_player: VideoStreamPlayer = $IntroVideoContainer/IntroVideoPlayer
@onready var sarah_texture: TextureRect = $SarahTexture
@onready var prompt_label: Label = $PromptLabel

var story_index: int = 0

var story_slides: Array = [
	{
		"text": "For nine years, it had just been Beth and her daughter, Sarah. \n They carved out a quiet, solitary life together, ever since Sarah turned one that is. \n\n That year the state stepped in and dragged Sarah's father, Scott, away for the brutal murders of three young girls.",
		"image": "res://images/stairs_1.png",
		"audio": "res://audio/intro/step_1.wav"
	},
	{
		"text": "Beth took whatever hours the local hospital would give her, survival required long, grueling shifts as a nurses assistant. \n When Sarah was younger babysitters took up the slack. But these days the babysitters never lasted very long, eventually they find out the family legacy and the blood on her father's hands. Beth suspected Sarah was exposing the horrors, freeing her from all over sight.",
		"image": "res://images/stairs_2.png",
		"audio": "res://audio/intro/step_2.wav"
	},
	{
		"text": "Left to the solitude, Sarah didn't just grow; she adapted, she thrived. \n\n She possessed a terrifying intelligence, far too advanced and sharp for a ten-year-old child. \n But that brilliant mind weaponized itself in severe, unpredictable, sometimes violent, behavioral outbursts at school. Last year, came the final suspension. The teachers could no longer handle the flashes of malice, the system gave up. \n Sarah was sent home, permanently, to learn alone. \n\n A laptop her only friend, teacher and school mate.",
		"image": "res://images/stairs_3.png",
		"audio": "res://audio/intro/step_3.wav"
	},
	{
		"text": "In the quiet hours of her night shifts, Beth was consumed by a suffocating dread. \n She saw the flashes of her husband’s calculated rage mirroring behind Sarah’s eyes, a genetic rot she couldn't contain. \n\n Beth watched her daughter’s escalating impulses and knew, with terrifying certainty, that she was failing to hold back the dark inside her. The familial infection passed down from her father. \n Beth's greatest fear was the looming posibilty that Sarah was destined to inherit her father's cage.",
		"image": "res://images/stairs_door_302.png",
		"audio": "res://audio/intro/step_4.wav",
		"cue": "** Rattle-Rattle** "
	}
]

func _ready() -> void:
	_display_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			get_viewport().set_input_as_handled()
			_advance_story()

func init_story_audio(menu_stream: AudioStream, playback_position: float, current_volume: float) -> void:
	if story_music_player and menu_stream:
		story_music_player.stream = menu_stream
		story_music_player.volume_db = current_volume
		story_music_player.play(playback_position)

func _display_slide() -> void:
	if story_index >= story_slides.size():
		_end_backstory()
		return
		
	var current_slide = story_slides[story_index]
	
	if ResourceLoader.exists(current_slide["image"]):
		story_bg.texture = load(current_slide["image"])
	else:
		story_bg.texture = null
		
	if ResourceLoader.exists(current_slide["audio"]):
		print("Success: Found audio file at ", current_slide["audio"])
		step_sfx_player.stream = load(current_slide["audio"])
		step_sfx_player.play()
	else:
		print("ERROR: Audio file NOT found at path: ", current_slide["audio"])
		
	story_text_label.text = current_slide["text"]
	story_text_label.modulate.a = 0.0
	
	var text_fade = create_tween()
	text_fade.tween_property(story_text_label, "modulate:a", 1.0, 0.4)

var is_cinematic_playing: bool = false

func _advance_story() -> void:
	if is_cinematic_playing:
		return 
		
	story_index += 1
	_display_slide()

func _end_backstory() -> void:
	is_cinematic_playing = true
	
	if step_sfx_player.is_playing():
		step_sfx_player.stop()
		
	story_text_label.hide()
	prompt_label.hide()
	
	story_text_label.hide()
	prompt_label.hide()
	
	var music_fade_out = create_tween()
	music_fade_out.tween_property(story_music_player, "volume_db", -80.0, 0.5)
	await music_fade_out.finished
	story_music_player.stop()
	
	var video_path = "res://video/start_game.ogv"
	if ResourceLoader.exists(video_path):
		intro_video_player.stream = load(video_path)
		intro_video_player.expand = true
		intro_video_player.show()
		intro_video_player.play()
		await intro_video_player.finished
	else:
		print("Warning: Cinematic video file not found at: ", video_path)
		
	var intro_vid_path = "res://video/aboutimemother.ogv"
	if ResourceLoader.exists(intro_vid_path):
		intro_video_player.stream = load(intro_vid_path)
		intro_video_player.expand = true
		intro_video_player.volume_db = 8.0
		
		story_text_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		story_text_label.text = "It's about time you woke up, Mother."
		story_text_label.modulate.a = 1.0 
		
		intro_video_player.show()
		story_text_label.show()
		
		intro_video_player.play()
		await intro_video_player.finished
		intro_video_player.hide()
	else:
		print("Critical Error: Intro video asset missing at: ", intro_vid_path)

	sarah_texture.modulate.a = 0.0
	sarah_texture.show()
	
	var dramatic_reveal = create_tween()
	dramatic_reveal.tween_property(sarah_texture, "modulate:a", 1.0, 1.5)
	await dramatic_reveal.finished
	
	await get_tree().create_timer(2.0).timeout

	var fade_overlay_tween = create_tween()
	fade_overlay_tween.tween_property(
		$DimOverlay, 
		"color", 
		Color(0.0, 0.0, 0.0, 1.0), 
		1.5
	)
	await fade_overlay_tween.finished
	
	print("Execution Trace: Transitioning to 3D Apartment Space.")
	get_tree().change_scene_to_file("res://apartment.tscn")
