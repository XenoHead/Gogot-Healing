extends CanvasLayer

# Path to your main menu scene
const MAIN_MENU_PATH = "res://MainMenu.tscn"

@onready var logo: TextureRect = $CenterContainer/VBoxContainer/TextureRect
@onready var timer: Timer = $Timer

func _ready() -> void:
	# 1. Start with the logo completely transparent
	logo.modulate.a = 0.0
	
	# 2. Create a smooth fade-in tween over 1.2 seconds
	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Connect the 3-second Timer to trigger the fade-out and scene swap
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	# 4. Create a smooth fade-out to black over 0.8 seconds
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(logo, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# 5. When the fade-out finishes, change scenes instantly
	fade_out_tween.finished.connect(_change_scene)

func _change_scene() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
