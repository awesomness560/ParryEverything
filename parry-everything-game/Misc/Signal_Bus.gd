extends Node

signal dealDamage(parryResource : ParryResource)
signal successfullParry(parryResource : ParryResource, isPerfect : bool)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().change_scene_to_file("res://main.tscn")
