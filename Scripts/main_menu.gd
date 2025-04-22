extends Control


func _on_quit_btn_pressed() -> void:
	get_tree().quit()



func _on_new_game_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/god_select.tscn")
