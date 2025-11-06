extends Area3D
var velocity = Vector3.ZERO

func _on_body_entered(body: Target) -> void:
	body.queue_free()
	queue_free()

func _physics_process(delta: float) -> void:
	global_position+=velocity
	

func _on_timer_timeout() -> void:
	queue_free()
