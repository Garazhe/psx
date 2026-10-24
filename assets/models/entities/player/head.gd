extends Node3D

var sen = 0.01

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Прячем курсор при старте игры

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sen) 
		$Camera3D.rotate_x(-event.relative.y * sen) 
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2, PI/2)
