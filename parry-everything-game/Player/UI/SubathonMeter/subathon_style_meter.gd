extends PanelContainer
class_name SubathonStyleMeter

@export var ranks : Array[Rank]

@export var hypeTrainText : RichTextLabel
@export var hypeTrainProgressBar : ProgressBar
@export var eyeIcon : TextureRect
@export var viewersLabel : Label
@export var chatManager : ChatManager

var currentScore : float = 0.0
var currentRankIndex : int = 0

func _ready() -> void:
	SignalBus.successfullParry.connect(onSuccessfullParry)
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
	if currentRankIndex >= ranks.size():
		return
	
	# If we're at max rank, fill the bar completely
	if currentRankIndex == ranks.size() - 1:
		hypeTrainProgressBar.value = hypeTrainProgressBar.max_value
		return
	
	# Calculate progress from current rank to next rank
	var currentRankPoints : float = ranks[currentRankIndex].pointsRequired
	var nextRankPoints : float = ranks[currentRankIndex + 1].pointsRequired
	var pointsInCurrentTier : float = nextRankPoints - currentRankPoints
	var progressInCurrentTier : float = currentScore - currentRankPoints
	
	# Set progress bar (0 to 100)
	var progressPercentage : float = (progressInCurrentTier / pointsInCurrentTier) * 100.0
	hypeTrainProgressBar.value = clamp(progressPercentage, 0.0, 100.0)

## Called when the rank changes - override or connect to this to add behavior
func onRankChanged() -> void:
	pass
