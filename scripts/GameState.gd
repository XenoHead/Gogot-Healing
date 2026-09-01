extends Node

# Behavioral metrics tracking
var manipulation_level: int = 0
var house_anxiety: int = 0
var max_sanity_cap: float = 100.0

# Set to true by the TV "Watch Static" branch (Dialogic set-event writes here)
# so PlayerController knows to route Beth to Sarah's door after tv_story ends.
var watch_static_path: bool = false

# Set by the TV "Turn Off Tv" / "Stand Up" branches so PlayerController knows
# what to do when tv_story ends (signal_event is broken in this Dialogic build).
var turn_off_requested: bool = false
var stand_up_requested: bool = false

# Set by the Sarah-door choice (neutral/encourage/punish) for metric routing.
var sarah_choice_path: String = ""

func modify_metrics(action: String) -> void:
	match action:
		"encourage":
			manipulation_level += 2
			max_sanity_cap = clamp(max_sanity_cap - 15.0, 40.0, 100.0)
			print("System Trace: Max Sanity capped at ", max_sanity_cap)
		"punish":
			house_anxiety += 3
			print("System Trace: Environment friction spiked. Anxiety at ", house_anxiety)
		"neutral":
			manipulation_level += 1
			print("System Trace: Neutral path tracked.")

# --- Team or Solo ---
var sarah_alone_points: int = 0
var mother_alone_points: int = 0
var both_together_points: int = 0

func reset_game_state() -> void:
	# Resets tracking flags back to zero when starting a New Game
	sarah_alone_points = 0
	mother_alone_points = 0
	both_together_points = 0
	print("Game State System Initialized: Tracking paths cleared.")

func add_sarah_alone(points: int = 1) -> void:
	sarah_alone_points += points
	print("Metric Shift: Sarah Alone increased to ", sarah_alone_points)

func add_mother_alone(points: int = 1) -> void:
	mother_alone_points += points
	print("Metric Shift: Mother Alone increased to ", mother_alone_points)

func add_both_together(points: int = 1) -> void:
	both_together_points += points
	print("Metric Shift: Both Together increased to ", both_together_points)
