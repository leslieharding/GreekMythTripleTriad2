extends Node2D

signal turn_ended

const CARD_SCENE_PATH = "res://Scenes/card.tscn"
var opponent_hand = []
# Expanded the deck to ensure we have enough cards
var opponent_deck = ["Knight", "Archer", "Mage", "Knight", "Archer", "Mage", "Knight", "Archer"]
var card_database_reference
var game_manager_reference
var card_slots_reference
var is_opponent_turn = false


func _ready() -> void:
	opponent_deck.shuffle()
	card_database_reference = preload("res://Scripts/card_database.gd")
	game_manager_reference = $"../GameManager"
	card_slots_reference = $"../CardSlots"
	
	# Initialize opponent's hand with cards
	opponent_hand.clear() # Clear any existing cards first
	for i in range(5):  # Draw exactly 5 cards initially
		draw_card_to_hand()
	
	print("Opponent has " + str(opponent_hand.size()) + " cards in hand after initialization")

# Add this function to handle card signals for opponent's cards
func connect_card_signals(card):
	# We don't need hover effects for opponent cards, but we still need this function
	# to avoid the error when cards are instantiated
	pass

# Draw a card from the opponent's deck to their hand
func draw_card_to_hand():
	if opponent_deck.size() == 0:
		print("WARNING: Opponent deck is empty, can't draw more cards")
		return
		
	var card_drawn = opponent_deck[0]
	opponent_deck.erase(card_drawn)
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	
	# Load card image
	var card_image_path = str("res://Images/" + card_drawn + "Card.jpeg")
	new_card.get_node("CardImage").texture = load(card_image_path)
	
	# Set card values using the function
	new_card.set_card_data(card_drawn, card_database_reference.CARDS[card_drawn])
	
	# Set the owner type
	new_card.owner_type = "opponent"
	new_card.set_card_owner("opponent")  # Make sure to explicitly set card owner
	
	# Add card to opponent's hand
	add_child(new_card)
	new_card.name = "OpponentCard_" + card_drawn
	new_card.position = Vector2(-200, -200)  # Hide the card off-screen
	opponent_hand.append(new_card)
	print("Added card to opponent hand. Size now: " + str(opponent_hand.size()))

# Make the opponent's move when it's their turn
func make_move():
	print("DEBUG: Opponent turn: " + str(is_opponent_turn) + " Hand size: " + str(opponent_hand.size()))
	
	if not is_opponent_turn:
		print("DEBUG: Not opponent turn, skipping move")
		return
		
	if opponent_hand.size() == 0:
		print("DEBUG: Opponent has no cards, skipping move")
		is_opponent_turn = false
		emit_signal("turn_ended")
		return
	
	# Wait a moment before making the move (to simulate thinking)
	await get_tree().create_timer(1.0).timeout
	
	# Find the best move using a simple strategy
	var best_move = find_best_move()
	
	if best_move:
		print("DEBUG: Opponent found a move to make")
		var card_to_play = best_move["card"]
		var slot_to_play = best_move["slot"]
		
		# Play the card
		play_card(card_to_play, slot_to_play)
		
		# Wait a bit before ending turn
		await get_tree().create_timer(0.5).timeout
		
		# End the opponent's turn
		is_opponent_turn = false
		emit_signal("turn_ended")
	else:
		print("DEBUG: No valid moves found for opponent")
		# No valid moves, end turn
		is_opponent_turn = false
		emit_signal("turn_ended")

# Find the best move for the opponent
func find_best_move():
	var empty_slots = []
	var best_score = -1
	var best_move = null
	
	# Find all empty slots
	for slot in card_slots_reference.get_children():
		if slot.has_method("get") and not slot.card_in_slot:
			empty_slots.append(slot)
	
	print("DEBUG: Found " + str(empty_slots.size()) + " empty slots")
	
	# If no empty slots, return null
	if empty_slots.size() == 0:
		return null
	
	# For each card in hand and each empty slot, calculate the score
	for card in opponent_hand:
		for slot in empty_slots:
			var score = calculate_move_score(card, slot)
			if score > best_score:
				best_score = score
				best_move = {"card": card, "slot": slot}
	
	return best_move

# Calculate a score for playing a card in a slot
func calculate_move_score(card, slot):
	var score = 0
	var slot_position = slot.position
	
	# Get adjacent slots and check if they have cards
	var adjacent_slots = get_adjacent_slots(slot)
	
	for adjacent_slot in adjacent_slots:
		if adjacent_slot["slot"].card_in_slot:
			# Get the card in the adjacent slot
			var adjacent_card = get_card_in_slot(adjacent_slot["slot"])
			if adjacent_card:
				# Check if our card can capture the adjacent card
				var direction = adjacent_slot["direction"]
				var our_value = 0
				var their_value = 0
				
				match direction:
					"north":
						our_value = card.values[2]  # South value of our card
						their_value = adjacent_card.values[0]  # North value of their card
					"east":
						our_value = card.values[3]  # West value of our card
						their_value = adjacent_card.values[1]  # East value of their card
					"south":
						our_value = card.values[0]  # North value of our card
						their_value = adjacent_card.values[2]  # South value of their card
					"west":
						our_value = card.values[1]  # East value of our card
						their_value = adjacent_card.values[3]  # West value of their card
				
				# If our value is higher, we can capture
				if our_value > their_value and adjacent_card.is_in_group("player_cards"):
					print("DEBUG: Found potential capture - Our", our_value, "vs Their", their_value)
					score += 3  # Prioritize captures
	
	# Add some randomness to avoid predictable AI
	score += randi() % 3
	
	return score

# Get adjacent slots to a given slot
func get_adjacent_slots(slot):
	var adjacent_slots = []
	var slot_pos = slot.position
	
	# Check all card slots for adjacency
	for other_slot in card_slots_reference.get_children():
		if other_slot.has_method("get") and other_slot != slot:
			var other_pos = other_slot.position
			
			# Use the same position checking as in game_manager.gd
			# North - check with tolerance
			if abs(other_pos.x - slot_pos.x) < 10 and abs(other_pos.y - slot_pos.y + 279) < 10:
				adjacent_slots.append({"slot": other_slot, "direction": "north"})
			# East - check with tolerance
			elif abs(other_pos.x - slot_pos.x - 194) < 10 and abs(other_pos.y - slot_pos.y) < 10:
				adjacent_slots.append({"slot": other_slot, "direction": "east"})
			# South - check with tolerance
			elif abs(other_pos.x - slot_pos.x) < 10 and abs(other_pos.y - slot_pos.y - 279) < 10:
				adjacent_slots.append({"slot": other_slot, "direction": "south"})
			# West - check with tolerance
			elif abs(other_pos.x - slot_pos.x + 194) < 10 and abs(other_pos.y - slot_pos.y) < 10:
				adjacent_slots.append({"slot": other_slot, "direction": "west"})
	
	return adjacent_slots

# Get the card currently in a slot
func get_card_in_slot(slot):
	# Find the card in this slot
	for card in get_tree().get_nodes_in_group("placed_cards"):
		if card.position == slot.position:
			return card
	return null

# Play a card to a slot
func play_card(card, slot):
	# Remove card from opponent's hand
	opponent_hand.erase(card)
	print("DEBUG: Opponent played a card. Cards remaining: " + str(opponent_hand.size()))
	print("DEBUG: Card values - N:", card.values[0], "E:", card.values[1], "S:", card.values[2], "W:", card.values[3])
	
	# Make sure the card's owner_type is set correctly BEFORE moving it
	card.owner_type = "opponent"
	card.set_card_owner("opponent")
	
	# Ensure the card is in the right groups
	if not card.is_in_group("opponent_cards"):
		card.add_to_group("opponent_cards")
	
	# Move the card to the slot
	var original_position = card.position
	card.position = slot.position
	
	# Mark the slot as occupied
	slot.card_in_slot = true
	
	# Add card to placed cards group for battle checking
	if not card.is_in_group("placed_cards"):
		card.add_to_group("placed_cards")
	
	print("DEBUG: Opponent card moved from", original_position, "to", slot.position)
	
	# IMPORTANT: Wait a moment to ensure the card is fully placed before checking battles
	# This ensures the position is fully updated
	await get_tree().create_timer(0.1).timeout
	
	print("DEBUG: Checking battles for opponent card at", card.position)
	# After the card is in position, check if this card captures adjacent cards
	var captured_cards = game_manager_reference.check_card_battles(card, "opponent")
	print("DEBUG: Opponent captured", captured_cards.size() if captured_cards else 0, "cards")

# Set if it's the opponent's turn
func set_turn(is_turn):
	print("DEBUG: Setting opponent turn to: " + str(is_turn))
	is_opponent_turn = is_turn
	if is_opponent_turn:
		make_move()
