extends Node3D

@export var mainScene : PackedScene

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(mainScene)
