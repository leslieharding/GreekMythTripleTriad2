extends Node2D

signal hovered
signal hovered_off

var hand_position
var card_name = ""  # Store the card name for reference
var values = [0, 0, 0, 0]  # [North, East, South, West]
var owner_type = "player"  # "player" or "opponent"
var border_color = Color(0, 0, 0, 0)  # Default transparent border

# Card dimensions - centralized for easy adjustment
const CARD_WIDTH = 146  # Match the CollisionShape2D width in the scene
const CARD_HEIGHT = 197 # Match the CollisionShape2D height in the scene

func _ready() -> void:
	get_parent().connect_card_signals(self)
	create_border()
	
func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)
	
func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
	
# New function to set card values
func set_card_data(name, card_values):
	card_name = name
	values = card_values
	$North.text = str(values[0])
	$East.text = str(values[1])
	$South.text = str(values[2])
	$West.text = str(values[3])
	
	print("DEBUG: Card data set - Name:", name, "Values:", values)
	
# Change card visually to show ownership - renamed from set_owner to avoid conflicts
func set_card_owner(new_owner):
	print("DEBUG: Setting card owner to", new_owner)
	owner_type = new_owner
	
	if owner_type == "player":
		# Set player card styling (blue border)
		update_border(Color(0, 0, 1, 0.7))
		
		# Update groups
		if is_in_group("opponent_cards"):
			remove_from_group("opponent_cards")
			print("DEBUG: Removed from opponent_cards group")
		
		if not is_in_group("player_cards"):
			add_to_group("player_cards")
			print("DEBUG: Added to player_cards group")
	else:
		# Set opponent card styling (red border)
		update_border(Color(1, 0, 0, 0.7))
		
		# Update groups
		if is_in_group("player_cards"):
			remove_from_group("player_cards")
			print("DEBUG: Removed from player_cards group")
			
		if not is_in_group("opponent_cards"):
			add_to_group("opponent_cards")
			print("DEBUG: Added to opponent_cards group")

# Create the border around the card
func create_border():
	if not has_node("CardBorder"):
		var border = ColorRect.new()
		border.name = "CardBorder"
		
		# Size it to match the card dimensions
		border.size = Vector2(CARD_WIDTH + 10, CARD_HEIGHT + 10)  # Slightly larger than the card
		border.position = Vector2(-CARD_WIDTH/2 - 5, -CARD_HEIGHT/2 - 5)  # Center the border around the card
		
		# Set initial color based on owner
		if owner_type == "player":
			border.color = Color(0, 0, 1, 0.7)  # Blue for player
		else:
			border.color = Color(1, 0, 0, 0.7)  # Red for opponent
			
		# Make border appear behind the card image but in front of everything else
		border.z_index = -1
		
		# Store the border color
		border_color = border.color
		
		add_child(border)
		print("DEBUG: Created card border for", owner_type)

# Update the border color
func update_border(color):
	border_color = color
	if has_node("CardBorder"):
		$CardBorder.color = color
		print("DEBUG: Updated border color to", color)
	else:
		create_border()
