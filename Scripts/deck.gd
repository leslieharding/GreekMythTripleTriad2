extends Node2D

const CARD_SCENE_PATH = "res://Scenes/card.tscn"
const CARD_DRAW_SPEED = 0.5

var player_deck = ["Knight", "Archer", "Mage", "Knight", "Archer", "Mage", "Knight"]
var card_database_reference
var game_manager_reference

func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())	
	card_database_reference = preload("res://Scripts/card_database.gd")
	game_manager_reference = $"../GameManager"
	
	# Draw initial hand if this is a new game
	if $"../PlayerHand".player_hand.size() == 0:
		for i in range(5):  # Draw 5 cards initially
			draw_card()

func draw_card():
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
		return
		
	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	
	$RichTextLabel.text = str(player_deck.size())	
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	
	new_card.owner_type = "player"
	new_card.set_card_owner("player")  # This will create and update the border
	
	# Load card image
	var card_image_path = str("res://Images/" + card_drawn + "Card.jpeg")
	new_card.get_node("CardImage").texture = load(card_image_path)
	
	# Set card values using the new function
	new_card.set_card_data(card_drawn, card_database_reference.CARDS[card_drawn])
	
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
