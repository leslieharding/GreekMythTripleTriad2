extends Node2D
# This script manages the card slots on the board

func _ready():
	# Make sure all slots start empty
	for slot in get_children():
		if slot.has_method("get"):
			slot.card_in_slot = false
	
	# Print the positions of all slots for debugging
	print("DEBUG: Card slot positions:")
	for i in range(get_child_count()):
		var slot = get_child(i)
		if slot.has_method("get"):
			print("DEBUG: Slot", i, "position:", slot.position)

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
			print("DEBUG: Reset slot at position", slot.position)

# Get the exact distance between slots
func get_slot_spacing():
	# This can be useful for debugging
	if get_child_count() >= 2:
		var first_slot = get_child(0)
		var second_slot = get_child(1)
		
		if first_slot.has_method("get") and second_slot.has_method("get"):
			var x_diff = abs(second_slot.position.x - first_slot.position.x)
			var y_diff = abs(second_slot.position.y - first_slot.position.y)
			print("DEBUG: Slot spacing - X:", x_diff, "Y:", y_diff)
			return Vector2(x_diff, y_diff)
	
	return Vector2.ZERO
