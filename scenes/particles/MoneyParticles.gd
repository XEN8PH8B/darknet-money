extends CPUParticles2D

func _ready() -> void:
	emitting = true
	var t = create_tween()
	t.tween_interval(lifetime + 0.1)
	t.tween_callback(queue_free)
