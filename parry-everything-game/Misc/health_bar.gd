extends MeshInstance3D
class_name HealthBar

## Configuration
@export var maxHealth : float = 100 : set = setMaxHealth
@export_group("Animation Settings")
@export var healthTweenDuration : float = 0.3
@export var healthTweenTransition : Tween.TransitionType = Tween.TRANS_CUBIC
@export var healthTweenEase : Tween.EaseType = Tween.EASE_OUT
@export var damageBarDelay : float = 0.5
@export var damageBarTweenDuration : float = 0.6
@export var damageBarTweenTransition : Tween.TransitionType = Tween.TRANS_CUBIC
@export var damageBarTweenEase : Tween.EaseType = Tween.EASE_IN_OUT
@export_group("Max Health Change Behavior")
@export var clampHealthToNewMax : bool = true ## If false, health can exceed new max temporarily
@export var updateDamageBarOnMaxChange : bool = true ## Update damage bar immediately when max health changes

@onready var damageBarTimer: Timer = $DamageBarTimer

var shaderMaterial : ShaderMaterial
var healthTween : Tween
var damageBarTween : Tween
var health : float : set = setHealth

func _ready() -> void:
	shaderMaterial = get_surface_override_material(0)
	damageBarTimer.timeout.connect(onDamageBarTimerTimeout)
	damageBarTimer.wait_time = damageBarDelay
	
	# Initialize both bars to full
	shaderMaterial.set_shader_parameter("health", 1.0)
	shaderMaterial.set_shader_parameter("damage", 1.0)
	
	# Set initial health
	health = maxHealth

func setMaxHealth(newMaxHealth : float):
	var previousMaxHealth = maxHealth
	maxHealth = max(newMaxHealth, 0.1) # Prevent division by zero
	
	# If max health changed after initialization
	if shaderMaterial and previousMaxHealth > 0:
		if clampHealthToNewMax:
			# Clamp current health to new max
			health = clamp(health, 0, maxHealth)
		
		# Update visual bars to reflect new percentages
		updateBarsVisual(updateDamageBarOnMaxChange)

func setHealth(newHealth : float):
	var previousHealth = health
	health = clamp(newHealth, 0, maxHealth)
	
	# Don't update visuals if nothing changed
	if is_equal_approx(previousHealth, health):
		return
	
	var healthPercent = health / maxHealth
	var previousHealthPercent = previousHealth / maxHealth
	
	# Tween the health bar
	if healthTween:
		healthTween.kill()
	
	healthTween = create_tween()
	healthTween.set_trans(healthTweenTransition)
	healthTween.set_ease(healthTweenEase)
	healthTween.tween_property(
		shaderMaterial,
		"shader_parameter/health",
		healthPercent,
		healthTweenDuration
	)
	
	# Handle damage bar based on whether health increased or decreased
	if newHealth < previousHealth:
		# Health decreased - delay damage bar update
		damageBarTimer.stop()
		damageBarTimer.start()
		
		# Cancel any existing damage bar tween
		if damageBarTween:
			damageBarTween.kill()
	elif newHealth > previousHealth:
		# Health increased - immediately update damage bar to match
		if damageBarTween:
			damageBarTween.kill()
		
		damageBarTween = create_tween()
		damageBarTween.set_trans(damageBarTweenTransition)
		damageBarTween.set_ease(damageBarTweenEase)
		damageBarTween.tween_property(
			shaderMaterial,
			"shader_parameter/damage",
			healthPercent,
			healthTweenDuration  # Use faster duration for healing
		)
		
		# Stop the timer since we're updating immediately
		damageBarTimer.stop()

func onDamageBarTimerTimeout():
	var healthPercent = health / maxHealth
	
	# Tween damage bar to match current health
	if damageBarTween:
		damageBarTween.kill()
	
	damageBarTween = create_tween()
	damageBarTween.set_trans(damageBarTweenTransition)
	damageBarTween.set_ease(damageBarTweenEase)
	damageBarTween.tween_property(
		shaderMaterial,
		"shader_parameter/damage",
		healthPercent,
		damageBarTweenDuration
	)

## Update the visual representation of both bars
func updateBarsVisual(updateDamageBar : bool = true):
	var healthPercent = health / maxHealth
	
	# Update health bar
	if healthTween:
		healthTween.kill()
	
	healthTween = create_tween()
	healthTween.set_trans(healthTweenTransition)
	healthTween.set_ease(healthTweenEase)
	healthTween.tween_property(
		shaderMaterial,
		"shader_parameter/health",
		healthPercent,
		healthTweenDuration
	)
	
	# Update damage bar if requested
	if updateDamageBar:
		if damageBarTween:
			damageBarTween.kill()
		
		damageBarTween = create_tween()
		damageBarTween.set_trans(damageBarTweenTransition)
		damageBarTween.set_ease(damageBarTweenEase)
		damageBarTween.tween_property(
			shaderMaterial,
			"shader_parameter/damage",
			healthPercent,
			damageBarTweenDuration
		)
		
		# Stop damage bar timer since we're syncing them
		damageBarTimer.stop()

## Public function to take damage
func takeDamage(amount : float):
	setHealth(health - amount)

## Public function to heal
func heal(amount : float):
	setHealth(health + amount)

## Increase max health and optionally heal to the new amount
func increaseMaxHealth(amount : float, healToNewMax : bool = false):
	setMaxHealth(maxHealth + amount)
	if healToNewMax:
		setHealth(maxHealth)

## Get current health percentage (0.0 to 1.0)
func getHealthPercent() -> float:
	return health / maxHealth

## Check if dead
func isDead() -> bool:
	return health <= 0

## Check if at full health
func isFullHealth() -> bool:
	return is_equal_approx(health, maxHealth)
