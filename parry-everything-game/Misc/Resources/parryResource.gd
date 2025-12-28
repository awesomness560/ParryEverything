extends Resource
class_name ParryResource

enum ParryType {
	PARRY_WINDOW, ##For if the Parry opens a window for the time
	PARRY_ONE_SHOT ##For if the Parry is just a one time check
}

##Damage to deal (0 if not applicable)
@export var damage : float
@export var parryType : ParryType = ParryType.PARRY_ONE_SHOT
##The amount of time for it to still count as a perfect pary
@export_range(0, 1, 0.01) var perfectParryWindow : float
##This should be higher than the perfect parry window
@export_range(0, 1, 0.01) var normalParryWindow : float
##IMPORTANT: The function this connects to should define an argument bool for perfect parry or not
@export var successfulParryCallback : Callable
@export var failingParryCallback : Callable

@export_group("Style Settings")
##The name that should show up when you successfully parry
@export var name : String
@export var normalParryPoints : float
@export var perfectParryPoints : float
