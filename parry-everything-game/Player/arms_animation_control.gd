extends Node3D
class_name ArmsAnimationController

@export var armsAnimationPlayer : AnimationPlayer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("taunt"):
		playAnimation("FP_Stretching_Hands")

func playAnimation(aniName : String):
	armsAnimationPlayer.play(aniName)
