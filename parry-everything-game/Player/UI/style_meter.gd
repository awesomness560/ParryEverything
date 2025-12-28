extends PanelContainer
class_name StyleMeter

##The name of our rank
@export var rankNameLabel : RichTextLabel
##Saying how long before we lose a rank
@export var timeoutProgressBar : ProgressBar

var currentScore : float

func _ready() -> void:
	SignalBus.sucessfullParry.connect(onSucessfullParry)

func onSucessfullParry(parryResource : ParryResource, isPerfect : bool):
	pass
