extends Node2D

# This script handles the card battle mechanics

# Direction constants
enum DIRECTION {NORTH, EAST, SOUTH, WEST}

func _ready():
	pass

# Check which cards a newly placed card can capture
func check_battles(played_card, owner, board_slots):
	var cards_to_capture = []
	var played_position = played_card.position
	
	# Find all placed cards adjacent to the played card
	for slot in board_slots:
		if slot.card_in_slot:
			var adjacent_card = get_card_at_position(slot.position)
			if adjacent_card and adjacent_card != played_card:
				var direction = get_relative_direction(played_position, adjacent_card.position)
				if direction != -1:
					# Compare card values in the appropriate direction
					if can_capture(played_card, adjacent_card, direction):
						cards_to_capture.append(adjacent_card)
	
	return cards_to_capture

# Determine the relative direction between two card positions
func get_relative_direction(from_pos, to_pos):
	# Cards are spaced 200 units apart
	if to_pos.y == from_pos.y - 200 and to_pos.x == from_pos.x:
		return DIRECTION.NORTH
	elif to_pos.x == from_pos.x + 200 and to_pos.y == from_pos.y:
		return DIRECTION.EAST
	elif to_pos.y == from_pos.y + 200 and to_pos.x == from_pos.x:
		return DIRECTION.SOUTH
	elif to_pos.x == from_pos.x - 200 and to_pos.y == from_pos.y:
		return DIRECTION.WEST
	return -1  # Not adjacent

# Check if one card can capture another in the given direction
func can_capture(attacking_card, defending_card, direction):
	var attack_value = 0
	var defense_value = 0
	
	match direction:
		DIRECTION.NORTH:
			attack_value = attacking_card.values[0]  # North value of attacker
			defense_value = defending_card.values[2]  # South value of defender
		DIRECTION.EAST:
			attack_value = attacking_card.values[1]  # East value of attacker
			defense_value = defending_card.values[3]  # West value of defender
		DIRECTION.SOUTH:
			attack_value = attacking_card.values[2]  # South value of attacker
			defense_value = defending_card.values[0]  # North value of defender
		DIRECTION.WEST:
			attack_value = attacking_card.values[3]  # West value of attacker
			defense_value = defending_card.values[1]  # East value of defender
	
	return attack_value > defense_value

# Get the card at a specific position
func get_card_at_position(position):
	# Find all cards on the board
	var placed_cards = get_tree().get_nodes_in_group("placed_cards")
	
	for card in placed_cards:
		if card.position == position:
			return card
	
	return null

# Capture a card (change ownership)
func capture_card(card, new_owner):
	# Visual effect for capture
	flash_card(card, new_owner)
	
	# Change card ownership
	if new_owner == "player":
		if card.is_in_group("opponent_cards"):
			card.set_card_owner("player")  # Use set_card_owner instead of set_owner
	else:
		if card.is_in_group("player_cards"):
			card.set_card_owner("opponent")  # Use set_card_owner instead of set_owner

# Create a visual effect for card capture
func flash_card(card, new_owner):
	var flash_color = Color(0, 1, 0, 0.5) if new_owner == "player" else Color(1, 0, 0, 0.5)
	
	var flash = ColorRect.new()
	flash.color = flash_color
	flash.size = Vector2(180, 180)
	flash.position = Vector2(-90, -90)
	card.add_child(flash)
	
	# Animate the flash
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	await tween.finished
	flash.queue_free()
