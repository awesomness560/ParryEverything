extends Node3D
class_name CameraController

# Camera settings
@export var playerNode : CharacterBody3D
@export var camera : Camera3D
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

@export_group("Headbob")
@export var headbobFrequency := 2.0
@export var headBobAmplitude := 0.01
@export var viewBobbingNode : Node3D

@export_group("Camera Tilt")
@export var tiltDegree := 1.0
@export var tiltTime := 0.2
@export var cameraTiltNode : Node3D

@export_group("Dynamic FOV")
@export var min_fov: float = 75.0
@export var max_fov: float = 90.0
@export var fov_lerp_speed: float = 5.0  # How quickly FOV changes
@export var velocity_for_max_fov: float = 10.0  # Velocity at which max FOV is reached

##For keeping tracking of headbob on sine wave
var headbobTime := 0.0
var tiltTween : Tween

# State
var pitch: float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_CameraShake3D._init_camera_shake(camera)
	# Set initial FOV to minimum
	camera.fov = min_fov

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Horizontal rotation (yaw) - rotate the controller node
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Vertical rotation (pitch) - rotate the camera
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		rotation.x = pitch

func _physics_process(delta: float) -> void:
	headbobTime += delta * playerNode.velocity.length() * float(playerNode.is_on_floor())
	viewBobbingNode.transform.origin = headbob(headbobTime)
	
	# Update FOV based on velocity
	update_fov(delta)

func update_fov(delta: float) -> void:
	# Get horizontal velocity (ignoring vertical component)
	var horizontal_velocity = Vector2(playerNode.velocity.x, playerNode.velocity.z).length()
	
	# Calculate target FOV based on velocity (normalized between 0 and 1)
	var velocity_ratio = clamp(horizontal_velocity / velocity_for_max_fov, 0.0, 1.0)
	var target_fov = lerp(min_fov, max_fov, velocity_ratio)
	
	# Smoothly interpolate current FOV to target FOV
	camera.fov = lerp(camera.fov, target_fov, fov_lerp_speed * delta)

func headbob(_headbobTime : float) -> Vector3:
	var headbobPos := Vector3.ZERO
	headbobPos.y = sin(headbobTime * headbobFrequency) * headBobAmplitude
	return headbobPos

var prevInputVector : Vector2

func tilt(inputVector : Vector2):
	if prevInputVector == inputVector:
		return
	if inputVector.x == 0:
		tweenTilt(0)
	if inputVector.x < 0:
		tweenTilt(tiltDegree)
	elif inputVector.x > 0:
		tweenTilt(-tiltDegree)
	
	prevInputVector = inputVector

##Manages tweening (only call if changing sides)
func tweenTilt(degree : float) -> void:
	if tiltTween:
		tiltTween.kill()
	tiltTween = create_tween()
	tiltTween.tween_property(cameraTiltNode, "rotation_degrees:z", degree, tiltTime)
