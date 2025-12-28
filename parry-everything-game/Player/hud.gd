extends CanvasLayer

@export var blackBars : ColorRect

func _ready() -> void:
	awaken()

func awaken():
	var material : ShaderMaterial = blackBars.material
	var tween := create_tween()
	tween.tween_property(material, "shader_parameter/offset", 1.5, 1.3)
