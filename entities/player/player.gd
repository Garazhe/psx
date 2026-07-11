extends CharacterBody3D

#variables
@onready var raycast = $RayCast3D
var sen = 0.005
var SPEED = 5.0
const JUMP_VELOCITY = 0
@onready var dialoger: Node3D = get_tree().current_scene.get_node("dialog_trigger2")
@onready var ds = dialoger.started

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Прячем курсор при старте игры

#Rotation and interaction check
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sen) 
		$Camera3D.rotate_x(-event.relative.y * sen) 
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2, PI/2)




func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#run
	if  dialoger.started == false and Input.is_action_pressed("ui_run"):
		SPEED = 10.0
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	

	move_and_slide()
#hui test aboba
#Dialog

func check_interaction():
	if raycast and raycast.is_colliding():
		var target = raycast.get_collider()
		if target.has_method("interact"):
			target.interact()
