extends Node2D
# This script manages the card slots on the board

func _ready():
	# Make sure all slots start empty
	for slot in get_children():
		if slot.has_method("get"):
			slot.card_in_slot = false

# Get all empty slots
func get_empty_slots():
	var empty_slots = []
	
	for slot in get_children():
		if slot.has_method("get") and not slot.card_in_slot:
			empty_slots.append(slot)
	
	return empty_slots

# Get a specific slot by grid position (0-2, 0-2)
func get_slot_at_grid(x, y):
	# Calculate the index in the grid
	var index = y * 3 + x
	
	# Return the slot if it exists
	if index >= 0 and index < 9:
		return get_child(index)
	
	return null

# Check if the board is full
func is_board_full():
	for slot in get_children():
		if slot.has_method("get") and not slot.card_in_slot:
			return false
	
	return true

# Reset all slots to empty
func reset_board():
	for slot in get_children():
		if slot.has_method("get"):
			slot.card_in_slot = false
