extends Node2D

signal game_over(winner, player_score, opponent_score)
signal turn_changed(current_player)

enum PLAYER {PLAYER, OPPONENT}
enum GAME_STATE {SETUP, PLAYER_TURN, OPPONENT_TURN, GAME_OVER}

var current_state = GAME_STATE.SETUP
var current_player = PLAYER.PLAYER
var player_score = 5  # Start with 5 cards
var opponent_score = 5  # Start with 5 cards
var total_turns = 0
var max_turns = 9  # 9 slots on the board

var opponent_reference
var card_manager_reference
var ui_reference
var card_slots_reference
var card_battle_reference

func _ready():
	opponent_reference = $"../Opponent"
	card_manager_reference = $"../CardManager"
	card_slots_reference = $"../CardSlots"
	ui_reference = $"../UI"
	card_battle_reference = $"../CardBattle"
	
	# Connect to signals
	opponent_reference.connect("turn_ended", _on_opponent_turn_ended)
	card_manager_reference.connect("card_played", _on_card_played)
	
	# Start with coin flip
	start_game()

func start_game():
	# Reset scores
	player_score = 5
	opponent_score = 5
	total_turns = 0
	current_state = GAME_STATE.SETUP
	
	print("DEBUG: GameManager starting game, calling UI.show_coin_flip()")
	# Show coin flip UI
	ui_reference.show_coin_flip()

func perform_coin_flip():
	# Randomly determine who goes first
	randomize()
	var coin_result = randi() % 2
	
	if coin_result == 0:
		# Player goes first
		current_player = PLAYER.PLAYER
		current_state = GAME_STATE.PLAYER_TURN
		ui_reference.show_turn_message("Player's Turn")
	else:
		# Opponent goes first
		current_player = PLAYER.OPPONENT
		current_state = GAME_STATE.OPPONENT_TURN
		opponent_reference.set_turn(true)
		ui_reference.show_turn_message("Opponent's Turn")
	
	emit_signal("turn_changed", current_player)

func _on_card_played(card):
	# A card was played by the player
	if current_state == GAME_STATE.PLAYER_TURN:
		print("DEBUG: Player played a card, checking for battles")
		# Add debug print to show the card values
		print("DEBUG: Card values - N:", card.values[0], "E:", card.values[1], "S:", card.values[2], "W:", card.values[3])
		
		# Check for card battles
		var captured_cards = check_card_battles(card, "player")
		print("DEBUG: Captured", captured_cards.size(), "cards")
		
		# End player's turn
		end_turn()

func _on_opponent_turn_ended():
	# End opponent's turn
	end_turn()

func end_turn():
	# Increment turn counter
	total_turns += 1
	
	# Update scores display
	update_scores()
	
	# Check if game is over
	if total_turns >= max_turns or player_score == 0 or opponent_score == 0:
		end_game()
		return
	
	# Switch turns
	if current_player == PLAYER.PLAYER:
		current_player = PLAYER.OPPONENT
		current_state = GAME_STATE.OPPONENT_TURN
		opponent_reference.set_turn(true)
		ui_reference.show_turn_message("Opponent's Turn")
	else:
		current_player = PLAYER.PLAYER
		current_state = GAME_STATE.PLAYER_TURN
		ui_reference.show_turn_message("Player's Turn")
	
	emit_signal("turn_changed", current_player)

func check_card_battles(card, owner):
	# Get adjacent cards to the played card
	var adjacent_cards = get_adjacent_cards(card)
	var captured_cards = []
	
	print("DEBUG: Found", adjacent_cards.size(), "adjacent cards for", owner, "at position", card.position)
	
	for adjacent_card in adjacent_cards:
		# Determine which values to compare based on relative direction
		var played_card_value = 0
		var adjacent_card_value = 0
		var direction = adjacent_card["direction"]
		
		# Print the cards being compared
		print("DEBUG: Comparing", owner, "card with", 
			  "player" if adjacent_card["card"].is_in_group("player_cards") else "opponent", 
			  "card in direction", direction)
		
		match direction:
			"north":
				played_card_value = card.values[0]  # North value of played card
				adjacent_card_value = adjacent_card["card"].values[2]  # South value of adjacent card
			"east":
				played_card_value = card.values[1]  # East value of played card
				adjacent_card_value = adjacent_card["card"].values[3]  # West value of adjacent card
			"south":
				played_card_value = card.values[2]  # South value of played card
				adjacent_card_value = adjacent_card["card"].values[0]  # North value of adjacent card
			"west":
				played_card_value = card.values[3]  # West value of played card
				adjacent_card_value = adjacent_card["card"].values[1]  # East value of adjacent card
		
		print("DEBUG: Battle direction:", direction)
		print("DEBUG: Played card value:", played_card_value, "vs Adjacent card value:", adjacent_card_value)
		
		# Only check for capture if the adjacent card is owned by the other player
		var can_capture = false
		if owner == "player" and adjacent_card["card"].is_in_group("opponent_cards"):
			can_capture = played_card_value > adjacent_card_value
		elif owner == "opponent" and adjacent_card["card"].is_in_group("player_cards"):
			can_capture = played_card_value > adjacent_card_value
			print("DEBUG: Opponent trying to capture player card. Can capture:", can_capture)
		
		# Check if card can be captured
		if can_capture:
			print("DEBUG: Capture successful!")
			# Capture the card
			capture_card(adjacent_card["card"], owner)
			captured_cards.append(adjacent_card["card"])
		else:
			print("DEBUG: No capture - either values don't allow it or card already owned")
	
	return captured_cards

func get_adjacent_cards(card):
	var adjacent_cards = []
	var card_pos = card.position
	
	# Find all cards on the board
	var placed_cards = get_tree().get_nodes_in_group("placed_cards")
	
	print("DEBUG: Total placed cards on board:", placed_cards.size())
	print("DEBUG: Played card position:", card_pos)
	
	# Updated slot spacing values to match the new card and slot sizes
	var slot_spacing_x = 154  # Horizontal spacing between slots
	var slot_spacing_y = 208  # Vertical spacing between slots
	var tolerance = 10  # Tolerance for position checking
	
	for other_card in placed_cards:
		if other_card != card:
			var other_pos = other_card.position
			print("DEBUG: Checking card at position:", other_pos)
			
			# Check each direction with exact position checks using updated spacing
			# North - same X position, Y position is one slot higher
			if abs(other_pos.x - card_pos.x) < tolerance and abs(other_pos.y - (card_pos.y - slot_spacing_y)) < tolerance:
				adjacent_cards.append({"card": other_card, "direction": "north"})
				print("DEBUG: Found north adjacent card")
			# East - X position is one slot to the right, same Y position
			elif abs(other_pos.x - (card_pos.x + slot_spacing_x)) < tolerance and abs(other_pos.y - card_pos.y) < tolerance:
				adjacent_cards.append({"card": other_card, "direction": "east"})
				print("DEBUG: Found east adjacent card")
			# South - same X position, Y position is one slot lower
			elif abs(other_pos.x - card_pos.x) < tolerance and abs(other_pos.y - (card_pos.y + slot_spacing_y)) < tolerance:
				adjacent_cards.append({"card": other_card, "direction": "south"})
				print("DEBUG: Found south adjacent card")
			# West - X position is one slot to the left, same Y position
			elif abs(other_pos.x - (card_pos.x - slot_spacing_x)) < tolerance and abs(other_pos.y - card_pos.y) < tolerance:
				adjacent_cards.append({"card": other_card, "direction": "west"})
				print("DEBUG: Found west adjacent card")
	
	return adjacent_cards

func capture_card(card, new_owner):
	print("DEBUG: Capturing card for", new_owner)
	
	# Change card ownership
	if new_owner == "player":
		if card.is_in_group("opponent_cards"):
			card.remove_from_group("opponent_cards")
			card.add_to_group("player_cards")
			card.set_card_owner("player")
			player_score += 1
			opponent_score -= 1
			
			# Visual indicator of capture
			flash_card(card, Color(0, 1, 0, 0.5))  # Green flash for player capture
			
	elif new_owner == "opponent":
		if card.is_in_group("player_cards"):
			card.remove_from_group("player_cards")
			card.add_to_group("opponent_cards")
			card.set_card_owner("opponent")
			opponent_score += 1
			player_score -= 1
			
			# Visual indicator of capture
			flash_card(card, Color(1, 0, 0, 0.5))  # Red flash for opponent capture

func flash_card(card, color):
	# Create a flash effect to show card capturing
	var flash = ColorRect.new()
	flash.color = color
	flash.size = Vector2(180, 180)
	flash.position = Vector2(-90, -90)
	card.add_child(flash)
	
	# Animate the flash
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	await tween.finished
	flash.queue_free()

func update_scores():
	# Update the score display
	ui_reference.update_score(player_score, opponent_score)

func end_game():
	current_state = GAME_STATE.GAME_OVER
	
	# Determine winner
	var winner = ""
	if player_score > opponent_score:
		winner = "Player"
	elif opponent_score > player_score:
		winner = "Opponent"
	else:
		winner = "Draw"
	
	# Emit game over signal
	emit_signal("game_over", winner, player_score, opponent_score)
	
	# Show game over UI
	ui_reference.show_game_over(winner, player_score, opponent_score)

func reset_game():
	# First, clear all cards in play
	for card in get_tree().get_nodes_in_group("placed_cards"):
		card.queue_free()
		
	# Clear ALL cards in the scene - this is more thorough
	for card in get_tree().get_nodes_in_group("player_cards"):
		card.queue_free()
	
	# Make sure we get all opponent cards too
	for card in get_tree().get_nodes_in_group("opponent_cards"):
		card.queue_free()
	
	# Extra check - find any Card nodes that might not be in a group
	for card in get_tree().get_nodes_in_group("Card"):
		card.queue_free()
	
	# Even more thorough - get all nodes that are children of the CardManager
	for card in $"../CardManager".get_children():
		card.queue_free()
	
	# Reset card slots
	for slot in card_slots_reference.get_children():
		if slot.has_method("get"):
			slot.card_in_slot = false
	
	# Reset player hand - both the reference and any actual cards
	var player_hand_node = $"../PlayerHand"
	player_hand_node.player_hand.clear()
	
	# Reset opponent - both the reference and any actual cards
	opponent_reference.opponent_hand.clear()
	
	# Reset deck references and nodes
	var deck_node = $"../Deck"
	# Restore full decks with randomized order
	deck_node.player_deck = ["Knight", "Archer", "Mage", "Knight", "Archer", "Mage", "Knight", "Archer"]
	deck_node.player_deck.shuffle()
	# Reset UI elements on deck
	deck_node.get_node("RichTextLabel").text = str(deck_node.player_deck.size())
	deck_node.get_node("Area2D/CollisionShape2D").disabled = false
	deck_node.get_node("Sprite2D").visible = true
	deck_node.get_node("RichTextLabel").visible = true
	
	# Reset opponent deck
	opponent_reference.opponent_deck = ["Knight", "Archer", "Mage", "Knight", "Archer", "Mage", "Knight", "Archer"]
	opponent_reference.opponent_deck.shuffle()
	
	# Wait a moment to ensure all cards are properly removed
	await get_tree().create_timer(0.1).timeout
	
	# Draw initial hands
	for i in range(5):
		deck_node.draw_card()
	
	for i in range(5):
		opponent_reference.draw_card_to_hand()
	
	# Reset game state and score
	player_score = 5
	opponent_score = 5
	total_turns = 0
	current_state = GAME_STATE.SETUP
	
	# Start a new game
	start_game()
