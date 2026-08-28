extends Node3D
class_name Interactable

@export var prompt_message: String = "[E] Interact"
@export var interaction_type: String = "" # "tv" or "couch"
@export var interact_range: float = 2.0 # meters: how close the PLAYER must stand for the prompt to show
