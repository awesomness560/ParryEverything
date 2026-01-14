extends MeshInstance3D
class_name ShockwaveEffect

## Duration of the entire shockwave effect in seconds
@export var duration: float = 0.5

## Starting scale of the shockwave (small burst)
@export var start_scale: Vector3 = Vector3(0.1, 0.1, 0.1)

## Ending scale of the shockwave (maximum expansion)
@export var end_scale: Vector3 = Vector3(10.0, 10.0, 10.0)

## Time when the fade begins (0.0 = start, 1.0 = end). Values between 0-1 represent normalized time.
@export_range(0.0, 1.0) var fade_start_time: float = 0.6

@export_group("Advanced Settings")

## Initial thickness of the shockwave ring (dense energy)
@export var start_ring_width: float = 3.0

## Final thickness of the shockwave ring (thin ripple)
@export var end_ring_width: float = 8.0

## Easing value for the scale expansion (lower = more ease out)
@export_range(0.0, 2.0) var scale_easing: float = 0.5


var tween: Tween
var material: ShaderMaterial


func _ready() -> void:
	# Get the material from the first surface
	material = get_surface_override_material(0) as ShaderMaterial
	
	if material == null:
		push_error("MeshInstance3D does not have a ShaderMaterial on surface 0")
		return
	
	# Set initial state
	scale = start_scale
	if material.get_shader_parameter("fade") != null:
		material.set_shader_parameter("fade", 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fling_me"):
		play_shockwave()

## Starts the shockwave burst effect
func play_shockwave() -> void:
	if material == null:
		push_error("Cannot play shockwave: material not found")
		return
	
	# Kill existing tween if playing (makes it interruptible)
	if tween:
		tween.kill()
	
	# Reset to initial state
	scale = start_scale
	material.set_shader_parameter("fade", 1.0)
	material.set_shader_parameter("ring_width", start_ring_width)
	
	# Create new tween
	tween = create_tween()
	tween.set_parallel(true)  # All animations run simultaneously
	
	# Track 1: Scale expansion with ease out
	tween.tween_property(self, "scale", end_scale, duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CIRC if scale_easing <= 0.5 else Tween.TRANS_QUAD)
	
	# Track 2: Fade dissipation
	var fade_delay = duration * fade_start_time
	var fade_duration = duration - fade_delay
	tween.tween_property(material, "shader_parameter/fade", 0.0, fade_duration)\
		.set_delay(fade_delay)
	
	# Track 3: Ring width thinning
	tween.tween_property(material, "shader_parameter/ring_width", end_ring_width, duration)
	
	# Reset when complete
	tween.finished.connect(_on_shockwave_finished)


func _on_shockwave_finished() -> void:
	# Reset to initial state
	scale = start_scale
	material.set_shader_parameter("fade", 0.0)
	material.set_shader_parameter("ring_width", start_ring_width)
