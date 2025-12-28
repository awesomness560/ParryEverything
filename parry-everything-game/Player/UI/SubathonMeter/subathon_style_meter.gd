extends PanelContainer
class_name SubathonStyleMeter

@export var ranks : Array[Rank]
@export var rankUpSoundEffect : AudioStreamPlayer

@export_group("Gradient Textures")
@export var rank0Gradient : GradientTexture1D
@export var rank1Gradient : GradientTexture1D
@export var rank2Gradient : GradientTexture1D
@export var rank4Gradient : GradientTexture1D

@export_group("UI Elements")
@export var hypeTrainText : RichTextLabel
@export var hypeTrainProgressBar : ColorRect
@export var hypeTrainControl : Control
@export var eyeIcon : TextureRect
@export var viewersLabel : Label
@export var chatManager : ChatManager

@export_group("Chat Settings")
@export var chatTimer : Timer
@export var rank0ChatInterval : float = 5.0  # Slowest chat rate
@export var rank1ChatInterval : float = 4.0
@export var rank2ChatInterval : float = 3.0
@export var rank3ChatInterval : float = 2.0
@export var rank4ChatInterval : float = 1.0  # Fastest chat rate

var currentScore : float = 0.0
var currentRankIndex : int = 0
var progressBarMaterial : ShaderMaterial
var progressTween : Tween
var rankUpTween : Tween
var messageBank : MessageBank

# Chat system variables
var chatUsers : Array[String] = [
	"xXDarkSlayer99Xx",
	"PogChampion",
	"NoobMaster69",
	"TwitchTV_Bot",
	"SneakyNinja",
	"EpicGamer420",
	"MemeLord",
	"ProPlayer_TTV",
	"CoffeeAddict",
	"NightOwl88"
]

func _ready() -> void:
	SignalBus.successfullParry.connect(onSuccessfullParry)
	
	# Instantiate message bank
	messageBank = MessageBank.new()
	
	# Store reference to the shader material
	if hypeTrainProgressBar and hypeTrainProgressBar.material:
		progressBarMaterial = hypeTrainProgressBar.material as ShaderMaterial
	
	# Configure chat timer
	if chatTimer:
		chatTimer.wait_time = rank0ChatInterval
		chatTimer.timeout.connect(sendRandomChatMessage)
		chatTimer.start()
	
	# Apply initial rank effects
	applyRank0Effects()
	
	updateDisplay()

func onSuccessfullParry(parryResource : ParryResource, isPerfect : bool):
	# Calculate points based on parry type and current rank multiplier
	var basePoints : float = parryResource.perfectParryPoints if isPerfect else parryResource.normalParryPoints
	var pointsToAdd : float = basePoints * ranks[currentRankIndex].multiplier
	
	# Add points to current score
	addScore(pointsToAdd)

func addScore(points : float) -> void:
	currentScore += points
	
	# Check if we should rank up
	checkRankUp()
	
	# Update the UI
	updateDisplay()

func checkRankUp() -> void:
	# Keep checking if we can rank up (handles multiple rank ups at once)
	while currentRankIndex < ranks.size() - 1:
		var nextRank : Rank = ranks[currentRankIndex + 1]
		if currentScore >= nextRank.pointsRequired:
			currentRankIndex += 1
			onRankChanged()
		else:
			break

func updateDisplay() -> void:
	# Update rank name text
	if currentRankIndex < ranks.size():
		hypeTrainText.text = ranks[currentRankIndex].rankName
	
	# Update progress bar
	updateProgressBar()

func updateProgressBar() -> void:
	if currentRankIndex >= ranks.size() or not progressBarMaterial:
		return
	
	# Kill existing tween if it exists
	if progressTween:
		progressTween.kill()
	
	var targetProgress : float
	
	# If we're at max rank, fill the bar completely
	if currentRankIndex == ranks.size() - 1:
		targetProgress = 1.0
	else:
		# Calculate progress from current rank to next rank
		var currentRankPoints : float = ranks[currentRankIndex].pointsRequired
		var nextRankPoints : float = ranks[currentRankIndex + 1].pointsRequired
		var pointsInCurrentTier : float = nextRankPoints - currentRankPoints
		var progressInCurrentTier : float = currentScore - currentRankPoints
		
		# Calculate target progress (0.0 to 1.0)
		targetProgress = progressInCurrentTier / pointsInCurrentTier
		targetProgress = clamp(targetProgress, 0.0, 1.0)
	
	# Create new tween with overshoot effect
	progressTween = create_tween()
	progressTween.set_ease(Tween.EASE_OUT)
	progressTween.set_trans(Tween.TRANS_BACK)  # This creates the overshoot effect
	progressTween.tween_method(
		func(value: float): progressBarMaterial.set_shader_parameter("progress", value),
		progressBarMaterial.get_shader_parameter("progress"),
		targetProgress,
		0.5  # Duration in seconds
	)

## Called when the rank changes - override or connect to this to add behavior
func onRankChanged() -> void:
	playRankUpAnimation()
	
	match currentRankIndex:
		0:
			applyRank0Effects()
		1:
			applyRank1Effects()
		2:
			applyRank2Effects()
		3:
			applyRank3Effects()
		4:
			applyRank4Effects()

## Plays the rank up animation with white flash and scale effect
func playRankUpAnimation() -> void:
	if not progressBarMaterial or not hypeTrainControl:
		return
	
	# Kill existing rank up tween if it exists
	if rankUpTween:
		rankUpTween.kill()
	
	# Store original values
	var originalScale : Vector2 = hypeTrainControl.scale
	var originalModulate : Color = hypeTrainControl.modulate
	var flashScale : Vector2 = Vector2(originalScale.x, originalScale.y * 1.5)  # Increase height by 50%
	var flashColor : Color = Color(3.0, 3.0, 3.0, 1.0)  # Bright white flash (values > 1.0 for bloom effect)
	
	# Create the rank up tween
	rankUpTween = create_tween()
	rankUpTween.set_parallel(true)
	
	# Tween to bright white modulate and scale up
	rankUpTween.tween_property(hypeTrainControl, "modulate", flashColor, 0.2)
	rankUpTween.tween_property(hypeTrainControl, "scale", flashScale, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Chain: scale back down and fade modulate back
	rankUpTween.chain()
	rankUpTween.tween_property(hypeTrainControl, "modulate", originalModulate, 0.3)
	rankUpTween.tween_property(hypeTrainControl, "scale", originalScale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Set the new gradient immediately (not tweened, as gradient resources can't be interpolated)
	var newGradient : GradientTexture1D = getGradientForRank(currentRankIndex)
	if newGradient:
		progressBarMaterial.set_shader_parameter("gradient_texture", newGradient)

## Returns the gradient texture for a given rank index
func getGradientForRank(rankIndex: int) -> GradientTexture1D:
	match rankIndex:
		0:
			return rank0Gradient
		1:
			return rank1Gradient
		2:
			return rank2Gradient
		4:
			return rank4Gradient
		_:
			return null

## Resets all effects to default state
func resetEffectsToDefault() -> void:
	# Reset any visual effects, sounds, etc. to default state
	pass

## Updates the chat timer interval based on current rank
func updateChatInterval() -> void:
	if not chatTimer:
		return
	
	var newInterval : float
	
	match currentRankIndex:
		0:
			newInterval = rank0ChatInterval
		1:
			newInterval = rank1ChatInterval
		2:
			newInterval = rank2ChatInterval
		3:
			newInterval = rank3ChatInterval
		4:
			newInterval = rank4ChatInterval
		_:
			newInterval = rank0ChatInterval
	
	chatTimer.wait_time = newInterval
	# Restart timer with new interval
	chatTimer.start()

## Rank 0 effects (first/lowest rank)
func applyRank0Effects() -> void:
	resetEffectsToDefault()
	updateChatInterval()
	# Change gradient to rank 0 gradient
	if progressBarMaterial and rank0Gradient:
		progressBarMaterial.set_shader_parameter("gradient_texture", rank0Gradient)

## Rank 1 effects (second rank)
func applyRank1Effects() -> void:
	resetEffectsToDefault()
	updateChatInterval()
	# Change gradient to rank 1 gradient
	if progressBarMaterial and rank1Gradient:
		progressBarMaterial.set_shader_parameter("gradient_texture", rank1Gradient)

## Rank 2 effects (third rank)
func applyRank2Effects() -> void:
	resetEffectsToDefault()
	updateChatInterval()
	# Change gradient to rank 2 gradient
	if progressBarMaterial and rank2Gradient:
		progressBarMaterial.set_shader_parameter("gradient_texture", rank2Gradient)

## Rank 3 effects (fourth rank)
func applyRank3Effects() -> void:
	resetEffectsToDefault()
	updateChatInterval()
	# Add any additional effects for rank 3 here
	pass

## Rank 4 effects (fifth/max rank)
func applyRank4Effects() -> void:
	resetEffectsToDefault()
	updateChatInterval()
	# Change gradient to rank 4 gradient (max rank)
	if progressBarMaterial and rank4Gradient:
		progressBarMaterial.set_shader_parameter("gradient_texture", rank4Gradient)

## Sends a random chat message based on current rank tier
func sendRandomChatMessage() -> void:
	if not chatManager:
		return
	
	# Get available messages based on current rank (unlocks cumulative messages)
	var availableMessages : Array[String] = getMessagesForCurrentRank()
	
	if availableMessages.is_empty():
		return
	
	# Pick random user and message
	var randomUser : String = chatUsers[randi() % chatUsers.size()]
	var randomMessage : String = availableMessages[randi() % availableMessages.size()]
	
	# Send the message
	chatManager.addMessage(randomUser, randomMessage)

## Returns messages for the current rank tier only (not cumulative)
func getMessagesForCurrentRank() -> Array[String]:
	if not messageBank:
		return []
	
	match currentRankIndex:
		0:
			return messageBank.rank0Messages
		1:
			return messageBank.rank1Messages
		2:
			return messageBank.rank2Messages
		3:
			return messageBank.rank3Messages
		4:
			return messageBank.rank4Messages
		_:
			return []
