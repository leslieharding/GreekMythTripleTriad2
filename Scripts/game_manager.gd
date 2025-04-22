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
		# Check for card battles
		check_card_battles(card, "player")
		
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
	
	for adjacent_card in adjacent_cards:
		# Determine which values to compare based on relative position
		var played_card_value = 0
		var adjacent_card_value = 0
		var direction = adjacent_card["direction"]
		
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
		
		# Check if card can be captured
		if played_card_value > adjacent_card_value:
			# Capture the card
			capture_card(adjacent_card["card"], owner)

func get_adjacent_cards(card):
	var adjacent_cards = []
	var card_pos = card.position
	
	# Find all cards on the board
	var placed_cards = get_tree().get_nodes_in_group("placed_cards")
	
	for other_card in placed_cards:
		if other_card != card:
			var other_pos = other_card.position
			
			# North
			if other_pos.x == card_pos.x and other_pos.y == card_pos.y - 200:
				adjacent_cards.append({"card": other_card, "direction": "north"})
			# East
			elif other_pos.x == card_pos.x + 200 and other_pos.y == card_pos.y:
				adjacent_cards.append({"card": other_card, "direction": "east"})
			# South
			elif other_pos.x == card_pos.x and other_pos.y == card_pos.y + 200:
				adjacent_cards.append({"card": other_card, "direction": "south"})
			# West
			elif other_pos.x == card_pos.x - 200 and other_pos.y == card_pos.y:
				adjacent_cards.append({"card": other_card, "direction": "west"})
	
	return adjacent_cards

func capture_card(card, new_owner):
	# Change card ownership
	if new_owner == "player":
		if card.is_in_group("opponent_cards"):
			card.set_card_owner("player") # Use set_card_owner instead of set_owner
			player_score += 1
			opponent_score -= 1
			
			# Visual indicator of capture
			flash_card(card, Color(0, 1, 0, 0.5))  # Green flash for player capture
			
	elif new_owner == "opponent":
		if card.is_in_group("player_cards"):
			card.set_card_owner("opponent") # Use set_card_owner instead of set_owner
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
	# Reset the board
	for card in get_tree().get_nodes_in_group("placed_cards"):
		card.queue_free()
	
	# Reset card slots
	for slot in card_slots_reference.get_children():
		if slot.has_method("get"):
			slot.card_in_slot = false
	
	# Reset player hand
	$"../PlayerHand".player_hand.clear()
	
	# Reset opponent
	for card in opponent_reference.opponent_hand:
		card.queue_free()
	opponent_reference.opponent_hand.clear()
	
	# Refill decks and start a new game
	$"../Deck".player_deck = ["Knight", "Archer", "Mage", "Knight"]
	$"../Deck".player_deck.shuffle()
	$"../Deck"._ready()
	
	opponent_reference.opponent_deck = ["Knight", "Archer", "Mage", "Knight"]
	opponent_reference.opponent_deck.shuffle()
	opponent_reference._ready()
	
	# Start a new game
	start_game()
