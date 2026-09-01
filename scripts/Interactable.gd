extends Node3D
class_name Interactable

@export var prompt_message: String = "[E] Interact"
@export var interaction_type: String = "" # "tv", "couch", "door_table"
@export var interact_range: float = 1.0 # meters: how close the PLAYER must stand for the prompt to show
