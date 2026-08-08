extends Node2D

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/Floor_1/PVZ_ROOM/PVZ.tscn")


func _on_test_room_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/Floor_1/test_room/floor.tscn")
