extends Node3D
class_name LaserEnemy

enum State {
	IDLE,
	ATTACKING
}

@export var visualsNode : Node3D
@export var spinningCenterNode : Node3D
@export var amountGatheringParticles : GPUParticles3D

var player : Player
var current_state : State = State.IDLE

#Tweens
var idleTween : Tween
var visualsSpinTween : Tween
var attackingTween : Tween

func _ready() -> void:
	change_state(State.IDLE)

func _process(delta: float) -> void:
	match current_state:
		State.IDLE:
			if player:
				change_state(State.ATTACKING)
		State.ATTACKING:
			if player:
				look_at(player.global_position)
			else:
				change_state(State.IDLE)

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	# Handle exiting current state
	match current_state:
		State.IDLE:
			# Stop idle tweens
			if idleTween:
				idleTween.kill()
			if visualsSpinTween:
				visualsSpinTween.kill()
			visualsNode.rotation_degrees.y = 90.0
		State.ATTACKING:
			# Stop attacking tweens
			if attackingTween:
				attackingTween.kill()
			# Stop particles
			if amountGatheringParticles:
				amountGatheringParticles.emitting = false
				amountGatheringParticles.amount_ratio = 0.0
	
	current_state = new_state
	
	# Handle entering new state
	match current_state:
		State.IDLE:
			playIdle()
		State.ATTACKING:
			playAttacking()

func playIdle():
	# Continuous spin for visualsNode
	visualsSpinTween = create_tween()
	visualsSpinTween.set_loops()
	visualsSpinTween.tween_property(visualsNode, "rotation_degrees:y", 360.0, 8.0).from(0.0)
	
	# Twitching rotation for spinningCenterNode around X axis
	idleTween = create_tween()
	idleTween.set_loops()
	
	for i in range(6): # 6 steps per loop cycle
		var random_angle = randf_range(-90.0, 90.0) # Random angle between -90 and 90 degrees
		var is_slow = randf() > 0.5 # 50% chance to be slow
		var duration = randf_range(0.8, 1.5) if is_slow else randf_range(0.1, 0.3)
		var trans_type = Tween.TRANS_SINE if is_slow else Tween.TRANS_QUAD
		var ease_type = Tween.EASE_IN_OUT if is_slow else Tween.EASE_OUT
		
		idleTween.tween_property(
			spinningCenterNode, 
			"rotation_degrees:x", 
			random_angle, 
			duration
		).set_trans(trans_type).set_ease(ease_type)

func playAttacking():
	playAttackingSpin()

func playAttackingSpin():
	attackingTween = create_tween()
	attackingTween.set_parallel(true)
	
	# Store original rotation
	var original_rotation = spinningCenterNode.rotation_degrees.x
	
	# Accelerating spins
	var num_spins = 5
	var total_duration = 3.0
	
	attackingTween.tween_property(
		spinningCenterNode,
		"rotation_degrees:x",
		original_rotation + (360.0 * num_spins),
		total_duration
	).set_custom_interpolator(func(v): return ease(v, 3.0))
	
	# Tween particles amount ratio from 0 to 1
	if amountGatheringParticles:
		amountGatheringParticles.emitting = true
		amountGatheringParticles.amount_ratio = 0.0
		attackingTween.tween_property(
			amountGatheringParticles,
			"amount_ratio",
			1.0,
			total_duration
		).set_custom_interpolator(func(v): return ease(v, 3.0))
	
	# Connect to the tween finished signal
	attackingTween.finished.connect(playAttackingCooldown.bind(original_rotation))

func playAttackingCooldown(original_rotation: float):
	# Check if we should continue attacking or go to idle
	if not player:
		change_state(State.IDLE)
		return
	
	# Stop particles
	if amountGatheringParticles:
		amountGatheringParticles.emitting = false
		amountGatheringParticles.amount_ratio = 0.0
	
	# Create new tween for cooldown
	attackingTween = create_tween()
	
	# Cooldown: one last smooth circle back to original rotation
	attackingTween.tween_property(
		spinningCenterNode,
		"rotation_degrees:x",
		original_rotation,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# After cooldown, attack again if player still present
	attackingTween.finished.connect(func():
		if player and current_state == State.ATTACKING:
			playAttacking()
	)

#region Signals
func _on_targeting_range_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body

func _on_targeting_range_body_exited(body: Node3D) -> void:
	if body is Player:
		player = null
#endregion
