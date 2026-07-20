extends Control

@onready var story_bg: TextureRect = $StoryBG
@onready var story_text_label: Label = $MarginContainer/StoryText
@onready var story_music_player: AudioStreamPlayer = $StoryMusicPlayer
@onready var step_sfx_player: AudioStreamPlayer = $StepSFXPlayer

var story_index: int = 0

# Array maps text layouts, backgrounds, and localized sound effects together
var story_slides: Array = [
	{
		"text": "For nine years, it had just been Beth and her daughter, Sarah. They carved out a quiet, solitary life together after Sarah turned one—the exact year the state stepped in and dragged Sarah's father away for the brutal murders of three college girls.",
		"image": "res://images/stairs_1.png",
		"audio": "res://audio/Environment/steps.wav"
	},
	{
		"text": "Survival required long, grueling shifts, and Beth took whatever hours the local hospital would give her. It meant leaving a young Sarah to fend for herself in the quiet of an empty house. No babysitter would ever cross their threshold—not once they whispered the family name, and remembered the blood on her father's hands.",
		"image": "res://images/stairs_2.png",
		"audio": "res://audio/Environment/steps-2.wav"
	},
	{
		"text": "Left to the silence, Sarah didn't just grow; she adapted. She possessed a terrifying intelligence, far too advanced and sharp for a ten-year-old child. But that brilliant mind weaponized itself in severe, unpredictable behavioral outbursts at school. After the final suspension, when the teachers could no longer handle the flashes of malice, the system gave up. Sarah was sent home—permanently—to learn alone in the dark.",
		"image": "res://images/stairs_3.png",
		"audio": "res://audio/Environment/steps-3.wav"
	},
	{
		"text": "In the quiet hours of her night shifts, Beth was consumed by a suffocating dread. She saw the flashes of her husband’s calculated rage mirroring behind Sarah’s eyes, a genetic rot she couldn't contain. Beth watched her daughter’s escalating impulses and knew, with terrifying certainty, that she was failing to hold back the dark. Her greatest fear wasn't just losing her child; it was the looming certainty that Sarah was destined to inherit her father's cage.",
		"image": "res://images/stairs_door_302.png",
		"audio": "res://audio/Environment/steps-4.wav"
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
	# Handshake function to capture and loop the active music flawlessly
	if story_music_player and menu_stream:
		story_music_player.stream = menu_stream
		story_music_player.volume_db = current_volume
		story_music_player.play(playback_position)

func _display_slide() -> void:
	if story_index >= story_slides.size():
		_end_backstory()
		return
		
	var current_slide = story_slides[story_index]
	
	# Swap backdrops safely
	if ResourceLoader.exists(current_slide["image"]):
		story_bg.texture = load(current_slide["image"])
	else:
		story_bg.texture = null
		
	# Trigger the matching footstep sound wave for this slide choice
# Trigger the matching footstep sound wave for this slide choice
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

@onready var intro_video_player: VideoStreamPlayer = $IntroVideoContainer/IntroVideoPlayer
@onready var sarah_texture: TextureRect = $SarahTexture
@onready var prompt_label: Label = $PromptLabel

var is_cinematic_playing: bool = false

func _advance_story() -> void:
	if is_cinematic_playing:
		return # Block inputs during video/cinematic playback
		
	story_index += 1
	_display_slide()

func _end_backstory() -> void:
	is_cinematic_playing = true
	
	# Fade out text and press-key prompt instantly
	story_text_label.hide()
	prompt_label.hide()
	
	# Smoothly fade the menu music down before video starts
	var music_fade_out = create_tween()
	music_fade_out.tween_property(story_music_player, "volume_db", -80.0, 0.5)
	await music_fade_out.finished
	story_music_player.stop()
	
	# 1. Play the first cinematic video clip if it exists
	var video_path = "res://video/start_game.ogv"
	if ResourceLoader.exists(video_path):
		intro_video_player.stream = load(video_path)
		
		# Correct aspect scaling: Let the player scale, but don't force bad properties
		intro_video_player.expand = true
		
		intro_video_player.show()
		intro_video_player.play()
		await intro_video_player.finished
	else:
		print("Warning: Cinematic video file not found at: ", video_path)
		
	# 2. Play the second intro video sequence and show the subtitle immediately
	var intro_vid_path = "res://video/aboutimemother.ogv"
	if ResourceLoader.exists(intro_vid_path):
		intro_video_player.stream = load(intro_vid_path)
		
		# Clear layout behaviors
		intro_video_player.expand = true
		
		# BOOST VOLUME HERE: Raise the decibels before playing (e.g., +6.0 dB to +10.0 dB)
		intro_video_player.volume_db = 8.0
		
		# Position and format the subtitle text
		story_text_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		story_text_label.text = "It's about time you woke up, Mother."
		story_text_label.modulate.a = 1.0 
		
		# Show both at the exact same moment
		intro_video_player.show()
		story_text_label.show()
		
		intro_video_player.play()
		await intro_video_player.finished
		intro_video_player.hide()
	else:
		print("Critical Error: Intro video asset missing at: ", intro_vid_path)

	# 3. Smoothly fade Sarah's portrait up from the dark now that the video is done
	sarah_texture.modulate.a = 0.0
	sarah_texture.show()
	
	var dramatic_reveal = create_tween()
	dramatic_reveal.tween_property(sarah_texture, "modulate:a", 1.0, 1.5)
	await dramatic_reveal.finished
	
	await get_tree().create_timer(2.0).timeout

	# 4. Use the existing DimOverlay node to fade the full screen to solid black
	var fade_overlay_tween = create_tween()
	fade_overlay_tween.tween_property(
		$DimOverlay, 
		"color", 
		Color(0.0, 0.0, 0.0, 1.0), 
		1.5
	)
	await fade_overlay_tween.finished
	
	# 5. Final handoff to the gameplay scene
	print("Execution Trace: Transitioning to 3D Apartment Space.")
	get_tree().change_scene_to_file("res://apartment.tscn")
