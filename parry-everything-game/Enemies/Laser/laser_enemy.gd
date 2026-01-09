extends Node3D
class_name LaserEnemy

enum State {
	IDLE,
	ATTACKING,
	COOLDOWN
}

##Resource containing parry timing and damage information
@export var parryResource : ParryResource

@export_group("Node References")
##Main visual container that spins continuously during idle
@export var visualsNode : Node3D
##Center node that performs twitching/spinning animations
@export var spinningCenterNode : Node3D
##Particles that gather during attack charge-up
@export var amountGatheringParticles : GPUParticles3D
##Particles that emit when laser fires
@export var laserFinishParticles : GPUParticles3D
##The charge up sound node
@export var chargeUpAudio : AudioStreamPlayer3D
##Health Bar reference
@export var healthBar : HealthBar

@export_group("Health")
##Maximum health for this enemy
@export var maxHealth : float = 100.0
##Damage taken on regular parry
@export var parryDamage : float = 20.0
##Damage taken on perfect parry
@export var perfectParryDamage : float = 50.0

@export_group("Aiming Laser")
##Starting color of the aiming laser during charge-up
@export var aimingLaserInitialColor : Color = Color.ORANGE
##Final color of the aiming laser when fully charged
@export var aimingLaserFinalColor : Color = Color.RED
##Root node for the aiming laser
@export var aimingLaser : Node3D
##Mesh instance for the aiming laser visual
@export var aimingLaserMesh : MeshInstance3D

@export_group("Attack Timing")
##Duration of the attack charge-up phase in seconds
@export var attack_charge_duration : float = 3.0
##Duration of the cooldown after firing in seconds
@export var attack_cooldown_duration : float = 1.2
##Number of full rotations during attack charge-up
@export var attack_spin_count : int = 5

@export_group("Idle Animation")
##Duration for one complete idle spin rotation in seconds
@export var idle_spin_duration : float = 8.0
##Number of twitch movements per idle animation loop
@export_range(2, 10) var idle_twitch_steps : int = 6
##Min and max angles for idle twitching (x = min, y = max)
@export var idle_twitch_angle_range : Vector2 = Vector2(-90.0, 90.0)

@export_group("Animation Curves")
##Power value for spin acceleration easing (higher = more acceleration)
@export_range(0.5, 5.0) var spin_acceleration_power : float = 3.0

var player : Player
var current_state : State = State.IDLE

#Tweens
var idleTween : Tween
var visualsSpinTween : Tween
var attackingTween : Tween

func _ready() -> void:
	# Initialize health bar
	assert(healthBar)
	healthBar.maxHealth = maxHealth
	healthBar.health = maxHealth
	
	parryResource.successfulParryCallback = onSuccesfullyParried
	playIdle()

func _process(delta: float) -> void:
	aimingLaserMesh.visible = current_state == State.ATTACKING
	match current_state:
		State.IDLE:
			if player:
				change_state(State.ATTACKING)
		State.ATTACKING:
			if player:
				look_at(player.inFrontCameraNode.global_position)
				# Update extender scale to match distance
				if aimingLaser:
					var distance = global_position.distance_to(player.inFrontCameraNode.global_position)
					aimingLaser.scale.z = distance
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

#region Animations
func playIdle():
	# Continuous spin for visualsNode
	visualsSpinTween = create_tween()
	visualsSpinTween.set_loops()
	visualsSpinTween.tween_property(visualsNode, "rotation_degrees:y", 360.0, idle_spin_duration).from(0.0)
	
	# Twitching rotation for spinningCenterNode around X axis
	idleTween = create_tween()
	idleTween.set_loops()
	
	for i in range(idle_twitch_steps):
		var random_angle = randf_range(idle_twitch_angle_range.x, idle_twitch_angle_range.y)
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
	
	#Play audio
	chargeUpAudio.play()
	
	# Store original rotation
	var original_rotation = spinningCenterNode.rotation_degrees.x
	
	# Accelerating spins
	attackingTween.tween_property(
		spinningCenterNode,
		"rotation_degrees:x",
		original_rotation + (360.0 * attack_spin_count),
		attack_charge_duration
	).set_custom_interpolator(func(v): return ease(v, spin_acceleration_power))
	
	# Tween particles amount ratio from 0 to 1
	if amountGatheringParticles:
		amountGatheringParticles.emitting = true
		amountGatheringParticles.amount_ratio = 0.0
		attackingTween.tween_property(
			amountGatheringParticles,
			"amount_ratio",
			1.0,
			attack_charge_duration
		).set_custom_interpolator(func(v): return ease(v, spin_acceleration_power))
	
	#Tween extender laser
	var aimingLaserMaterial : StandardMaterial3D = aimingLaserMesh.get_surface_override_material(0)
	aimingLaserMaterial.albedo_color = aimingLaserInitialColor
	aimingLaserMaterial.emission = aimingLaserInitialColor
	
	attackingTween.tween_property(aimingLaserMaterial, "albedo_color", aimingLaserFinalColor, attack_charge_duration)
	attackingTween.parallel().tween_property(aimingLaserMaterial, "emission", aimingLaserFinalColor, attack_charge_duration)
	
	# Connect to the tween finished signal
	attackingTween.finished.connect(playAttackingCooldown.bind(original_rotation))

func playAttackingCooldown(original_rotation: float):
	change_state(State.COOLDOWN)
	#Finish attack
	laserFinishParticles.emitting = true
	SignalBus.dealDamage.emit(parryResource)
	# Check if we should continue attacking or go to idle
	if not player:
		change_state(State.IDLE)
		return
	
	# Stop particles
	if amountGatheringParticles:
		amountGatheringParticles.emitting = false
		amountGatheringParticles.amount_ratio = 0.0
	
	aimingLaserMesh.hide()
	
	# Create new tween for cooldown
	attackingTween = create_tween()
	
	# Cooldown: one last smooth circle back to original rotation
	attackingTween.tween_property(
		spinningCenterNode,
		"rotation_degrees:x",
		original_rotation,
		attack_cooldown_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# After cooldown, attack again if player still present
	attackingTween.finished.connect(func():
		if player and (current_state == State.ATTACKING or current_state == State.COOLDOWN):
			change_state(State.ATTACKING)
		elif not player:
			change_state(State.IDLE)
	)
#endregion

func onSuccesfullyParried(isPerfectParry : bool):
	if not healthBar:
		return
	
	# Apply damage based on parry type
	var damage = perfectParryDamage if isPerfectParry else parryDamage
	healthBar.health -= damage
	
	# Check if enemy is defeated
	if healthBar.health <= 0:
		# Enemy is defeated, queue for deletion
		doDie()

func doDie():
	queue_free()

#region Signals
func _on_targeting_range_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body

func _on_targeting_range_body_exited(body: Node3D) -> void:
	if body is Player:
		player = null
		chargeUpAudio.stop()
#endregion
