extends Node2D

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_play_pressed() -> void:
	pass


func _on_test_room_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/test_room/floor.tscn")
