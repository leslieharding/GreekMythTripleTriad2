extends Node2D

# Main scene script to initialize and coordinate all game components

func _ready():
	print("Main scene loading...")
	
	# Initialize references and ensure they exist
	var game_manager = $GameManager
	var ui = $UI
	var deck = $Deck
	var opponent = $Opponent
	var card_manager = $CardManager
	var player_hand = $PlayerHand
	var card_slots = $CardSlots
	var card_battle = $CardBattle
	
	# Check that all essential nodes exist
	if !game_manager:
		push_error("GameManager node not found!")
		return
	if !ui:
		push_error("UI node not found!")
		return
	if !opponent:
		push_error("Opponent node not found!")
		return
	if !card_manager:
		push_error("CardManager node not found!")
		return
	
	# Setup signal connections (ensure these are connected even if they're already connected in the individual scripts)
	if !game_manager.is_connected("game_over", _on_game_over):
		game_manager.connect("game_over", _on_game_over)
	
	if !game_manager.is_connected("turn_changed", _on_turn_changed):
		game_manager.connect("turn_changed", _on_turn_changed)
	
	if !opponent.is_connected("turn_ended", game_manager._on_opponent_turn_ended):
		opponent.connect("turn_ended", game_manager._on_opponent_turn_ended)
	
	if !card_manager.is_connected("card_played", game_manager._on_card_played):
		card_manager.connect("card_played", game_manager._on_card_played)
		
	
	
	# Initialize the game
	print("Starting game...")
	game_manager.start_game()

func _on_game_over(winner, player_score, opponent_score):
	print("Game Over! " + winner + " wins with score " + str(player_score) + " to " + str(opponent_score))
	
func _on_turn_changed(current_player):
	if current_player == $GameManager.PLAYER.PLAYER:
		print("Player's turn")
	else:
		print("Opponent's turn")
