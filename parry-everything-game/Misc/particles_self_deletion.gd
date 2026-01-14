extends GPUParticles3D
class_name ParticlesSelfDeletion

func _ready() -> void:
	finished.connect(onFinished)

func onFinished():
	queue_free()
