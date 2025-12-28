extends Node
class_name ParryManager

@export var maxParryWindow : float = 0.6
@export var parryCooldownPenaltyTime : float = 0.3
##The timer to keep track of how long we have been parrying
@export var parryTimer : Timer
##The timer to keep track of the cooldown (only triggered if nothing is parried before timeout)
@export var parryCooldownTimer : Timer
@export var perfectParryPauseTimer : Timer
##The reference to the first person animation manager
@export var fpAnimationManager : ArmsAnimationController
@export var normalParrySound : AudioStreamPlayer
@export var perfectParrySound : AudioStreamPlayer
@export var parryFlash : ColorRect

var isParrying : bool = false
var canParry : bool = true

func _ready() -> void:
	SignalBus.dealDamage.connect(receiveDamage)
	parryTimer.wait_time = maxParryWindow
	parryCooldownTimer.wait_time = parryCooldownPenaltyTime

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("parry_activate") and canParry:
		activateParry()

func receiveDamage(parryResource : ParryResource):
	match parryResource.parryType:
		ParryResource.ParryType.PARRY_ONE_SHOT:
			dealOneShotParry(parryResource)
		ParryResource.ParryType.PARRY_WINDOW:
			pass

func activateParry():
	isParrying = true
	canParry = false
	fpAnimationManager.playAnimation("FP_Parry_Stance")
	parryTimer.start()

func dealOneShotParry(parryResource : ParryResource):
	if not isParrying:
		# Player is not parrying, take damage normally
		_onParryFail(parryResource)
		return
	
	# Calculate how much time has elapsed since parry activation
	var elapsedTime = maxParryWindow - parryTimer.time_left
	
	# Check if it's a perfect parry
	if elapsedTime <= parryResource.perfectParryWindow:
		_onPerfectParry(parryResource)
	# Check if it's a normal parry
	elif elapsedTime <= parryResource.normalParryWindow:
		_onNormalParry(parryResource)
	# Parry window missed
	else:
		_onParryFail(parryResource)

func _onNormalParry(parryResource : ParryResource):
	print("Normal")
	# Stop the parry timer since we successfully parried
	parryTimer.stop()
	
	# Play success animation
	fpAnimationManager.playAnimation("FP_Parry_Success")
	normalParrySound.play()
	
	# Reset parry state and allow immediate re-parry
	isParrying = false
	canParry = true
	
	# Call the success callback if it exists (passing false for not perfect)
	if parryResource.successfulParryCallback.is_valid():
		parryResource.successfulParryCallback.call(false)
	SignalBus.successfullParry.emit(parryResource, false)
	
	await get_tree().create_timer(1).timeout
	fpAnimationManager.playAnimation("FP_Idle_Pose")

func _onPerfectParry(parryResource : ParryResource):
	# Stop the parry timer since we successfully parried
	parryTimer.stop()
	
	# Play success animation
	fpAnimationManager.playAnimation("FP_Parry_Success")
	perfectParrySound.play()
	
	# Reset parry state and allow immediate re-parry
	isParrying = false
	canParry = true
	
	# Call the success callback if it exists (passing true for perfect parry)
	if parryResource.successfulParryCallback.is_valid():
		parryResource.successfulParryCallback.call(true)
	SignalBus.successfullParry.emit(parryResource, true)
	
	get_tree().paused = true
	parryFlash.show()
	
	perfectParryPauseTimer.start()
	await perfectParryPauseTimer.timeout
	
	get_tree().paused = false
	parryFlash.hide()
	
	await get_tree().create_timer(0.3).timeout
	fpAnimationManager.playAnimation("FP_Idle_Pose")

func _onParryFail(parryResource : ParryResource):
	# Call the failing callback if it exists
	if parryResource.failingParryCallback.is_valid():
		parryResource.failingParryCallback.call(false)

func _on_parry_timer_timeout() -> void:
	# Player missed the parry window, apply cooldown penalty
	isParrying = false
	fpAnimationManager.playAnimation("FP_Idle_Pose")
	parryCooldownTimer.start()

func _on_parry_cooldown_timer_timeout() -> void:
	# Cooldown is over, player can parry again
	canParry = true
