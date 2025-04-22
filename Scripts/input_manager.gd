extends Node2D

signal left_mouse_clicked
signal left_mouse_released

const COLLISON_MASK_CARD = 1
const COLLISON_MASK_DECK = 4

var card_manager_reference
var deck_reference
var game_manager_reference

func _ready() -> void:
	card_manager_reference = $"../CardManager"
	deck_reference = $"../Deck"
	game_manager_reference = $"../GameManager"
	
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("left_mouse_clicked")
			# Only process clicks during player turn or setup
			if game_manager_reference.current_state == game_manager_reference.GAME_STATE.PLAYER_TURN or \
			   game_manager_reference.current_state == game_manager_reference.GAME_STATE.SETUP:
				raycast_at_cursor()
		else:
			emit_signal("left_mouse_released")
			
func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLISON_MASK_CARD:
			var card_found = result[0].collider.get_parent()
			if card_found:
				card_manager_reference.start_drag(card_found)
		elif result_collision_mask == COLLISON_MASK_DECK:
			# Only allow drawing cards during setup phase
			if game_manager_reference.current_state == game_manager_reference.GAME_STATE.SETUP:
				deck_reference.draw_card()
				# If the player has drawn enough cards, set up the initial hand
				if $"../PlayerHand".player_hand.size() >= 5:
					game_manager_reference.start_game()
