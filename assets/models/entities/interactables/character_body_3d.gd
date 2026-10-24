#Dialogs
extends CharacterBody3D

@onready var raycast = $Camera3D/RayCast3D
@onready var dialogue_ui = $CanvasLayer # Путь к твоему UI
@onready var label = $CanvasLayer/Panel/DialogueText

var is_talking = false

func _input(event):
	if event.is_action_pressed("interact"):
		if is_talking:
			# Закрываем диалог, так как игрок нажал "взаимодействовать" во время разговора
			close_dialogue()
		else:
			check_interaction()


func check_interaction():
	if raycast.is_colliding():
		var target = raycast.get_collider()
		
		# Проверяем, состоит ли объект в группе interactable
		if target.is_in_group("interactable"):
			start_dialogue("Привет... Здесь слишком темно, тебе не кажется?")

func start_dialogue(text):
	label.text = text
	dialogue_ui.show()
	is_talking = true
	# Для PS1 стиля можно остановить движение игрока:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 

func close_dialogue():
	dialogue_ui.hide()
	is_talking = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
