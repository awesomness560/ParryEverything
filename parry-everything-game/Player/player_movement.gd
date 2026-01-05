extends Node
class_name PlayerMovement

signal tilt(inputVector : Vector2)

# References
@export var body: Player
@export var vignetteColorRect : ColorRect
@export var camera_controller: CameraController
@export var groundParryResource : ParryResource
@export var gravityParryResource : ParryResource
# Movement parameters
@export_group("Ground Movement")
@export var base_speed: float = 7.0
@export var acceleration: float = 10.0
@export var friction: float = 8.0

@export_group("Air Movement")
@export var air_control: float = 0.3
@export var air_resistance: float = 0.5

@export_group("Jumping")
@export var jump_strength: float = 7.0
@export var jump_forward_boost: float = 2.0

# State
var current_velocity: Vector3 = Vector3.ZERO
var was_in_air: bool = false
var previous_y_velocity: float = 0.0

# Boost tracking
var active_boosts: Array[Dictionary] = []  # Each boost has: {velocity: Vector3, decay_rate: float}

# Gravity
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	groundParryResource.successfulParryCallback = apply_ground_parry_boost
	gravityParryResource.successfulParryCallback = apply_gravity_parry_boost

func _physics_process(delta: float) -> void:
	# Get input
	var input_dir = get_input_direction()
	var wish_dir = get_camera_relative_direction(input_dir)
	
	#Handle Effects
	vignetteColorRect.visible = body.velocity.y < 0
	
	# Handle jumping
	if Input.is_action_just_pressed("jump") and body.is_on_floor():
		current_velocity.y = jump_strength
		
		# Add forward boost in current movement direction
		var horizontal_vel = Vector3(current_velocity.x, 0, current_velocity.z)
		if horizontal_vel.length() > 0.1:
			var move_dir = horizontal_vel.normalized()
			add_impulse(move_dir * jump_forward_boost, 5.0)
	
	# Apply gravity
	if not body.is_on_floor():
		current_velocity.y -= gravity * delta
	
	# Detect when vertical velocity switches from positive to negative (apex of jump)
	if previous_y_velocity > 0.0 and current_velocity.y < 0.0:
		SignalBus.dealDamage.emit(gravityParryResource)
	
	# Store current y velocity for next frame
	previous_y_velocity = current_velocity.y
	
	# Update and decay all active boosts
	update_boosts(delta)
	
	# Apply movement forces
	if body.is_on_floor():
		apply_ground_movement(wish_dir, delta)
	else:
		apply_air_movement(wish_dir, delta)
	
	# Calculate total boost velocity
	var total_boost = Vector3.ZERO
	for boost in active_boosts:
		total_boost += boost.velocity
	
	# Combine base velocity with all boosts
	var final_velocity = current_velocity + total_boost
	
	# Apply velocity to body
	body.velocity = final_velocity
	body.move_and_slide()
	
	# Detect landing and trigger ground parry (AFTER move_and_slide)
	if body.is_on_floor() and was_in_air:
		SignalBus.dealDamage.emit(groundParryResource)
	
	# Track air state for next frame
	was_in_air = not body.is_on_floor()

func update_boosts(delta: float) -> void:
	# Decay each boost and remove depleted ones
	for i in range(active_boosts.size() - 1, -1, -1):
		var boost = active_boosts[i]
		boost.velocity = boost.velocity.move_toward(Vector3.ZERO, boost.decay_rate * delta)
		
		# Remove if effectively zero
		if boost.velocity.length() < 0.01:
			active_boosts.remove_at(i)

func get_input_direction() -> Vector2:
	var input := Vector2.ZERO
	input = Input.get_vector("left", "right", "forward", "backward")
	tilt.emit(input)
	return input.normalized()

func get_camera_relative_direction(input: Vector2) -> Vector3:
	if camera_controller == null:
		return Vector3.ZERO
	
	var cam_basis = camera_controller.global_transform.basis
	var direction = (cam_basis * Vector3(input.x, 0, input.y)).normalized()
	return direction

func apply_ground_movement(wish_dir: Vector3, delta: float) -> void:
	var target_velocity = wish_dir * base_speed
	
	# Accelerate toward target velocity
	var horizontal_vel = Vector3(current_velocity.x, 0, current_velocity.z)
	horizontal_vel = horizontal_vel.move_toward(target_velocity, acceleration * delta)
	
	# Apply friction when no input
	if wish_dir.length() < 0.1:
		horizontal_vel = horizontal_vel.move_toward(Vector3.ZERO, friction * delta)
	
	current_velocity.x = horizontal_vel.x
	current_velocity.z = horizontal_vel.z

func apply_air_movement(wish_dir: Vector3, delta: float) -> void:
	var target_velocity = wish_dir * base_speed
	var horizontal_vel = Vector3(current_velocity.x, 0, current_velocity.z)
	
	# Reduced control in air
	horizontal_vel = horizontal_vel.move_toward(target_velocity, acceleration * air_control * delta)
	
	# Light air resistance
	horizontal_vel = horizontal_vel.move_toward(Vector3.ZERO, air_resistance * delta)
	
	current_velocity.x = horizontal_vel.x
	current_velocity.z = horizontal_vel.z

# Public interface for adding boosts
func add_impulse(impulse: Vector3, decay_rate: float = 5.0) -> void:
	"""Add a temporary boost that will decay at the specified rate"""
	active_boosts.append({
		"velocity": impulse,
		"decay_rate": decay_rate
	})

func add_directional_impulse(strength: float, decay_rate: float = 5.0) -> void:
	"""Add a boost in the direction the player is currently moving"""
	var horizontal_vel = Vector3(current_velocity.x, 0, current_velocity.z)
	if horizontal_vel.length() > 0.1:
		var move_dir = horizontal_vel.normalized()
		add_impulse(move_dir * strength, decay_rate)

func add_continuous_force(force: Vector3, delta: float) -> void:
	"""Add a permanent force (call every frame while active)"""
	current_velocity += force * delta

func apply_ground_parry_boost(is_perfect: bool) -> void:
	"""Apply a massive boost when successfully parrying the ground"""
	# Get camera forward direction (no Y component)
	var cam_forward = Vector3.ZERO
	if camera_controller != null:
		cam_forward = -camera_controller.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
	
	# Determine boost strength based on parry type
	var horizontal_boost = 20.0 if is_perfect else 12.0
	var vertical_boost = 15.0 if is_perfect else 10.0
	
	# Apply upward velocity directly
	current_velocity.y = vertical_boost
	
	# Add horizontal boost in camera direction
	if cam_forward.length() > 0.1:
		add_impulse(cam_forward * horizontal_boost, 4.0)
	
	#Effects
	_CameraShake3D._custom_shake(3, 0.2)

func apply_gravity_parry_boost(is_perfect: bool) -> void:
	"""Apply a boost when successfully parrying at the apex of a jump"""
	# Get current horizontal movement direction
	var horizontal_vel = Vector3(current_velocity.x, 0, current_velocity.z)
	var move_dir = Vector3.ZERO
	if horizontal_vel.length() > 0.1:
		move_dir = horizontal_vel.normalized()
	
	# Determine boost strength based on parry type
	# Much more weighted to vertical than horizontal
	var horizontal_boost = 8.0 if is_perfect else 5.0
	var vertical_boost = 18.0 if is_perfect else 12.0
	
	# Apply upward velocity directly
	current_velocity.y = vertical_boost
	
	# Add horizontal boost in current movement direction
	if move_dir.length() > 0.1:
		add_impulse(move_dir * horizontal_boost, 4.0)
	
	#Effects
	_CameraShake3D._custom_shake(2, 0.15)
