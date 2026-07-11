extends Node3D

@onready var dialog_ui = get_tree().current_scene.get_node("dialog_ui/canvas")
@onready var character_name: RichTextLabel = get_tree().current_scene.get_node("dialog_ui/canvas/character_name")
@onready var dialog_text: RichTextLabel = get_tree().current_scene.get_node("dialog_ui/canvas/dialog_text")
@onready var player: CharacterBody3D = get_tree().current_scene.get_node("Player")
@onready var dialog_animation: AnimationPlayer = get_tree().current_scene.get_node('dialog_ui/canvas/AnimationPlayer')

var is_typing: bool = false
var skip_requested: bool = false

@export var names: Array[String]
@export var dialogs: Array[String]
@export var speaker: Node3D

var current_dialog = -1
var started = false

func _ready() -> void:
	dialog_ui.get_node("continue").connect("pressed", Callable(self, 'continue_dialog'))

func show_text(text:String)->void:
	dialog_text.text = text
	dialog_text.visible_characters = 0
	is_typing = true
	skip_requested = false

func dialog_start(body):
	if body == player and !started:
		started = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.SPEED = 0.0
		player.sen = 0.0
		dialog_ui.visible = true
		continue_dialog() 
		
func continue_dialog():
	if current_dialog < dialogs.size()-1:
		current_dialog+=1
		dialog_text.text = dialogs[current_dialog]
		character_name.text = names[current_dialog]
		dialog_animation.play("RESET")
		dialog_animation.play("scroll")
	else:
		dialog_finish()
		
		
func dialog_finish():
	player.SPEED = 5.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.sen = 0.01
	dialog_ui.visible = false
	started = false
	print(started)
	print("Zov")
		
