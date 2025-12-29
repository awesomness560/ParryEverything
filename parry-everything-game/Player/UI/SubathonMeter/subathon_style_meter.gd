extends PanelContainer
class_name SubathonStyleMeter

@export var ranks : Array[Rank]

@export_group("Gradient Textures")
@export var rank0Gradient : GradientTexture1D
@export var rank1Gradient : GradientTexture1D
@export var rank2Gradient : GradientTexture1D
@export var rank3Gradient : GradientTexture1D
@export var rank4Gradient : GradientTexture1D

@export_group("UI Elements")
@export var hypeTrainText : RichTextLabel
@export var hypeTrainProgressBar : ColorRect
@export var hypeTrainControl : Control
@export var eyeIcon : TextureRect
@export var viewersLabel : Label
@export var viewerContainer : HBoxContainer
@export var timeLeftProgressBar : ProgressBar
@export var chatManager : ChatManager

@export_group("Chat Settings")
@export var chatTimer : Timer
@export var rank0ChatInterval : float = 5.0  # Slowest chat rate
@export var rank1ChatInterval : float = 4.0
@export var rank2ChatInterval : float = 3.0
@export var rank3ChatInterval : float = 2.0
@export var rank4ChatInterval : float = 1.0  # Fastest chat rate

@export_group("Viewer Settings")
@export var viewerScoreMultiplier : float = 3.0  # Score multiplied by this to get viewer count
@export var viewerFlashColor : Color = Color(1.0, 1.0, 0.0, 1.0)  # Color to flash when viewers increment
@export var viewerFlashDuration : float = 0.15  # Duration of the flash effect
@export var viewerScaleMultiplier : float = 1.1  # Scale multiplier for container flash (e.g., 1.1 = 10% larger)

@export_group("Time Left Settings")
@export var rank0DecayRate : float = 5.0  # Points lost per second at rank 0
@export var rank1DecayRate : float = 7.0  # Points lost per second at rank 1
@export var rank2DecayRate : float = 10.0  # Points lost per second at rank 2
@export var rank3DecayRate : float = 15.0  # Points lost per second at rank 3
@export var rank4DecayRate : float = 20.0  # Points lost per second at rank 4
@export var stage1Color : Color = Color.WHITE  # Color when 2/3 to full
@export var stage2Color : Color = Color.ORANGE  # Color when 1/3 to 2/3
@export var stage3Color : Color = Color.RED  # Color when 0 to 1/3
@export var stage2ShakeIntensity : float = 2.0  # Shake amount for stage 2 (orange)
@export var stage3ShakeIntensity : float = 8.0  # Shake amount for stage 3 (red)

var currentScore : float = 0.0
var currentRankIndex : int = 0
var progressBarMaterial : ShaderMaterial
var progressTween : Tween
var rankUpTween : Tween
var viewerTween : Tween
var viewerFlashTween : Tween
var eyeFlashTween : Tween
var viewerContainerTween : Tween
var timeLeftBarTween : Tween
var messageBank : MessageBank
var timeLeft : float = 0.0  # Current time left value
var currentTimeLeftStage : int = 3  # Track which stage we're in (1, 2, or 3)
var isShaking : bool = false  # Track if currently shaking
var originalPosition : Vector2  # Store original position for shake effect

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
	
	# Store original position for shake effect
	originalPosition = position
	
	# Store reference to the shader material
	if hypeTrainProgressBar and hypeTrainProgressBar.material:
		progressBarMaterial = hypeTrainProgressBar.material as ShaderMaterial
	
	# Configure chat timer
	if chatTimer:
		chatTimer.wait_time = rank0ChatInterval
		chatTimer.timeout.connect(sendRandomChatMessage)
		chatTimer.start()
	
	# Initialize time left progress bar
	if timeLeftProgressBar:
		timeLeftProgressBar.max_value = 100.0
		timeLeft = 0.0  # Start with no time
		timeLeftProgressBar.value = timeLeft
		updateTimeLeftStage()  # Set initial color
	
	# Initialize viewer count to 10
	if viewersLabel:
		viewersLabel.text = "10"
	
	# Apply initial rank effects
	applyRank0Effects()
	
	updateDisplay()

func _process(delta: float) -> void:
	# Decay time left based on current rank
	if timeLeft > 0:
		var decayRate : float = getDecayRateForRank()
		timeLeft = max(0.0, timeLeft - (decayRate * delta))
		
		# Update progress bar
		if timeLeftProgressBar:
			timeLeftProgressBar.value = timeLeft
		
		# Check for stage changes
		updateTimeLeftStage()
		
		# Check if we hit zero
		if timeLeft == 0.0:
			onTimeLeftReachedZero()
	
	# Decay score (which causes viewers to drip down)
	if currentScore > 0:
		var scoreDecayRate : float = getDecayRateForRank() * 0.5  # Score decays at half the rate of time left
		currentScore = max(0.0, currentScore - (scoreDecayRate * delta))
		
		# Manually update viewer count as score decays (no tween, just direct update)
		if viewersLabel:
			var targetViewers : int = int(currentScore * viewerScoreMultiplier)
			# Never drop below 10 viewers
			targetViewers = max(10, targetViewers)
			viewersLabel.text = str(targetViewers)
	
	# Apply shake effect based on current stage
	applyShakeEffect()

func onSuccessfullParry(parryResource : ParryResource, isPerfect : bool):
	# Calculate points based on parry type and current rank multiplier
	var basePoints : float = parryResource.perfectParryPoints if isPerfect else parryResource.normalParryPoints
	var pointsToAdd : float = basePoints * ranks[currentRankIndex].multiplier
	
	# Add points to current score
	addScore(pointsToAdd)
	
	# Add time to the time left bar based on points earned
	addTimeLeft(pointsToAdd)

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
	
	# Update viewer count
	updateViewerCount()

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
		3:
			return rank3Gradient
		4:
			return rank4Gradient
		_:
			return null

## Resets all effects to default state
func resetEffectsToDefault() -> void:
	# Reset pulse mode to off
	if progressBarMaterial:
		progressBarMaterial.set_shader_parameter("pulse_mode", false)

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
	# Change gradient to rank 3 gradient and enable pulse mode
	if progressBarMaterial:
		if rank3Gradient:
			progressBarMaterial.set_shader_parameter("gradient_texture", rank3Gradient)
		progressBarMaterial.set_shader_parameter("pulse_mode", true)

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

## Updates the viewer count label with a smooth lerp animation (only for increases)
func updateViewerCount() -> void:
	if not viewersLabel:
		return
	
	# Calculate target viewer count
	var targetViewers : int = int(currentScore * viewerScoreMultiplier)
	
	# Get current viewer count from label (parse the text)
	var currentViewers : int = 0
	if viewersLabel.text.is_valid_int():
		currentViewers = viewersLabel.text.to_int()
	
	# Only proceed if viewers are increasing
	if targetViewers <= currentViewers:
		return
	
	# Flash when viewers increase
	playViewerFlash()
	
	# Kill existing viewer tween if it exists
	if viewerTween:
		viewerTween.kill()
	
	# Create tween to lerp viewer count up
	viewerTween = create_tween()
	viewerTween.tween_method(
		func(value: float): viewersLabel.text = str(int(value)),
		float(currentViewers),
		float(targetViewers),
		0.5  # Duration in seconds
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

## Flashes the viewer label and eye icon when viewers increment
func playViewerFlash() -> void:
	# Flash viewer label
	if viewersLabel:
		# Kill existing flash tween if it exists
		if viewerFlashTween:
			viewerFlashTween.kill()
		
		var originalColor : Color = viewersLabel.modulate
		
		viewerFlashTween = create_tween()
		viewerFlashTween.tween_property(viewersLabel, "modulate", viewerFlashColor, viewerFlashDuration)
		viewerFlashTween.tween_property(viewersLabel, "modulate", originalColor, viewerFlashDuration)
	
	# Flash eye icon
	if eyeIcon:
		# Kill existing flash tween if it exists
		if eyeFlashTween:
			eyeFlashTween.kill()
		
		var originalColor : Color = eyeIcon.modulate
		
		eyeFlashTween = create_tween()
		eyeFlashTween.tween_property(eyeIcon, "modulate", viewerFlashColor, viewerFlashDuration)
		eyeFlashTween.tween_property(eyeIcon, "modulate", originalColor, viewerFlashDuration)
	
	# Scale up and down the viewer container
	if viewerContainer:
		# Kill existing container tween if it exists
		if viewerContainerTween:
			viewerContainerTween.kill()
		
		var originalScale : Vector2 = viewerContainer.scale
		var flashScale : Vector2 = originalScale * viewerScaleMultiplier
		
		viewerContainerTween = create_tween()
		viewerContainerTween.tween_property(viewerContainer, "scale", flashScale, viewerFlashDuration)
		viewerContainerTween.tween_property(viewerContainer, "scale", originalScale, viewerFlashDuration)

## Adds time to the time left progress bar
func addTimeLeft(points: float) -> void:
	if not timeLeftProgressBar:
		return
	
	timeLeft = min(timeLeftProgressBar.max_value, timeLeft + points)
	timeLeftProgressBar.value = timeLeft
	
	# Check for stage changes when adding time
	updateTimeLeftStage()

## Returns the decay rate for the current rank
func getDecayRateForRank() -> float:
	match currentRankIndex:
		0:
			return rank0DecayRate
		1:
			return rank1DecayRate
		2:
			return rank2DecayRate
		3:
			return rank3DecayRate
		4:
			return rank4DecayRate
		_:
			return rank0DecayRate

## Checks and updates the time left bar stage/color
func updateTimeLeftStage() -> void:
	if not timeLeftProgressBar:
		return
	
	var percentage : float = timeLeft / timeLeftProgressBar.max_value
	var newStage : int = currentTimeLeftStage
	
	# Determine which stage we're in
	if percentage >= 0.666:  # 2/3 to full
		newStage = 1
	elif percentage >= 0.333:  # 1/3 to 2/3
		newStage = 2
	else:  # 0 to 1/3
		newStage = 3
	
	# Only update if stage changed
	if newStage != currentTimeLeftStage:
		currentTimeLeftStage = newStage
		applyTimeLeftStageEffects()

## Applies visual effects for the current time left stage
func applyTimeLeftStageEffects() -> void:
	if not timeLeftProgressBar:
		return
	
	# Kill existing tween if it exists
	if timeLeftBarTween:
		timeLeftBarTween.kill()
	
	var targetColor : Color
	
	match currentTimeLeftStage:
		1:
			targetColor = stage1Color
		2:
			targetColor = stage2Color
		3:
			targetColor = stage3Color
		_:
			targetColor = stage3Color
	
	# Get the progress bar's StyleBox and tween its color
	var stylebox : StyleBox = timeLeftProgressBar.get_theme_stylebox("fill")
	if stylebox is StyleBoxFlat:
		var styleboxFlat : StyleBoxFlat = stylebox as StyleBoxFlat
		
		timeLeftBarTween = create_tween()
		timeLeftBarTween.tween_property(styleboxFlat, "bg_color", targetColor, 0.2)

## Called when time left reaches zero
func onTimeLeftReachedZero() -> void:
	# Stop shaking
	position = originalPosition
	isShaking = false
	
	# Rank down to rank 0 (index 0)
	currentRankIndex = 0
	
	# Reset score to the first rank's requirement (0)
	currentScore = ranks[0].pointsRequired
	
	#Clear chat
	chatManager.clearAllMessages()
	
	# Apply rank 0 effects (resets all effects)
	applyRank0Effects()
	
	# Update displays
	updateDisplay()
	
	# Lerp viewers to 10 (minimum)
	if viewersLabel:
		# Kill existing viewer tween if it exists
		if viewerTween:
			viewerTween.kill()
		
		var currentViewers : int = 0
		if viewersLabel.text.is_valid_int():
			currentViewers = viewersLabel.text.to_int()
		
		viewerTween = create_tween()
		viewerTween.tween_method(
			func(value: float): viewersLabel.text = str(int(value)),
			float(currentViewers),
			10.0,  # Minimum viewer count
			1.0  # Duration in seconds
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

## Applies shake effect based on current time left stage
func applyShakeEffect() -> void:
	# Don't shake if time is zero
	if timeLeft == 0.0:
		position = originalPosition
		isShaking = false
		return
	
	var shakeIntensity : float = 0.0
	
	match currentTimeLeftStage:
		1:
			# No shake in stage 1 (white/safe)
			shakeIntensity = 0.0
			isShaking = false
		2:
			# Light shake in stage 2 (orange/warning)
			shakeIntensity = stage2ShakeIntensity
			isShaking = true
		3:
			# Heavy shake in stage 3 (red/danger)
			shakeIntensity = stage3ShakeIntensity
			isShaking = true
	
	# Apply shake or reset to original position
	if isShaking:
		var offsetX : float = randf_range(-shakeIntensity, shakeIntensity)
		var offsetY : float = randf_range(-shakeIntensity, shakeIntensity)
		position = originalPosition + Vector2(offsetX, offsetY)
	else:
		position = originalPosition
