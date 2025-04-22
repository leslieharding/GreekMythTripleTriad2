extends CanvasLayer

# This is a simplified UI for testing the Triple Triad game

var game_manager_reference

func _ready():
	game_manager_reference = $"../GameManager"
	
	# Setup basic UI elements if they don't exist
	if !has_node("ScoreDisplay"):
		var score_display = Label.new()
		score_display.name = "ScoreDisplay"
		score_display.text = "Player: 5 - Opponent: 5"
		score_display.size = Vector2(400, 40)
		score_display.position = Vector2(get_viewport().size.x / 2 - 200, 20)
		score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(score_display)
	
	if !has_node("TurnDisplay"):
		var turn_display = Label.new()
		turn_display.name = "TurnDisplay"
		turn_display.text = "Game Starting"
		turn_display.size = Vector2(400, 80)
		turn_display.position = Vector2(get_viewport().size.x / 2 - 200, get_viewport().size.y / 2 - 40)
		turn_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		turn_display.visible = false
		add_child(turn_display)
	
	if !has_node("CoinFlipPanel"):
		# Create coin flip panel
		var panel = Panel.new()
		panel.name = "CoinFlipPanel"
		panel.size = Vector2(400, 300)
		panel.position = Vector2(get_viewport().size.x / 2 - 200, get_viewport().size.y / 2 - 150)
		panel.visible = false
		add_child(panel)
		
		# Add a title label
		var title = Label.new()
		title.name = "TitleLabel"
		title.text = "Triple Triad"
		title.size = Vector2(300, 50)
		title.position = Vector2(50, 20)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(title)
		
		# Add an instruction label
		var instruction = Label.new()
		instruction.name = "InstructionLabel"
		instruction.text = "Flip a coin to decide who goes first"
		instruction.size = Vector2(350, 50)
		instruction.position = Vector2(25, 100)
		instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(instruction)
		
		# Add flip button
		var button = Button.new()
		button.name = "FlipButton"
		button.text = "Flip Coin"
		button.size = Vector2(200, 50)
		button.position = Vector2(100, 200)
		button.connect("pressed", _on_flip_button_pressed)
		panel.add_child(button)
	
	if !has_node("GameOverPanel"):
		# Create game over panel
		var panel = Panel.new()
		panel.name = "GameOverPanel"
		panel.size = Vector2(400, 300)
		panel.position = Vector2(get_viewport().size.x / 2 - 200, get_viewport().size.y / 2 - 150)
		panel.visible = false
		add_child(panel)
		
		# Add result label
		var result = Label.new()
		result.name = "ResultLabel"
		result.text = "Game Over"
		result.size = Vector2(350, 50)
		result.position = Vector2(25, 20)
		result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(result)
		
		# Add score label
		var score = Label.new()
		score.name = "ScoreLabel"
		score.text = "Final Score: 0 - 0"
		score.size = Vector2(350, 50)
		score.position = Vector2(25, 100)
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(score)
		
		# Add play again button
		var button = Button.new()
		button.name = "PlayAgainButton"
		button.text = "Play Again"
		button.size = Vector2(200, 50)
		button.position = Vector2(100, 200)
		button.connect("pressed", _on_play_again_button_pressed)
		panel.add_child(button)
	
	# Initialize score display
	update_score(5, 5)  # Start with 5 cards each

func show_coin_flip():
	print("Showing coin flip UI")
	$CoinFlipPanel.visible = true
	$TurnDisplay.visible = false
	$GameOverPanel.visible = false

func _on_flip_button_pressed():
	print("Coin flip button pressed")
	$CoinFlipPanel.visible = false
	$TurnDisplay.visible = true
	game_manager_reference.perform_coin_flip()

func show_turn_message(message):
	print("Turn message: " + message)
	$TurnDisplay.text = message
	$TurnDisplay.visible = true
	
	# Flash the message
	var tween = get_tree().create_tween()
	tween.tween_property($TurnDisplay, "modulate:a", 0.5, 0.3)
	tween.tween_property($TurnDisplay, "modulate:a", 1.0, 0.3)

func update_score(player_score, opponent_score):
	print("Score update: Player " + str(player_score) + " - " + str(opponent_score) + " Opponent")
	$ScoreDisplay.text = "Player: " + str(player_score) + " - Opponent: " + str(opponent_score)

func show_game_over(winner, player_score, opponent_score):
	print("Game over: " + winner + " wins!")
	$GameOverPanel.visible = true
	$TurnDisplay.visible = false
	
	if winner == "Draw":
		$GameOverPanel/ResultLabel.text = "Game Over - It's a Draw!"
	else:
		$GameOverPanel/ResultLabel.text = "Game Over - " + winner + " Wins!"
	
	$GameOverPanel/ScoreLabel.text = "Final Score: Player " + str(player_score) + " - " + str(opponent_score) + " Opponent"

func _on_play_again_button_pressed():
	print("Play again button pressed")
	$GameOverPanel.visible = false
	game_manager_reference.reset_game()
