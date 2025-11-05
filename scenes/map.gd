extends Node3D
@onready var plane : Aircraft = $Plane

func _on_plane_destroyed() -> void:
	plane.global_position = $Marker3D.global_position
	plane.velocity = Vector3.ZERO
