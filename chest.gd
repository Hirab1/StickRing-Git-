extends Area2D

@onready var anim = $AnimationPlayer
@onready var interact_label = $Label # Grabs the new text node

var player_in_range = false
var is_opened = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Make sure the label starts hidden when the level loads
	interact_label.hide()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		
		# Only show the prompt if the chest hasn't been looted yet
		if not is_opened:
			interact_label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		
		# Hide the prompt when the player walks away
		interact_label.hide()

func _process(_delta):
	if player_in_range and not is_opened:
		if Input.is_action_just_pressed("interact"):
			open_chest()

func open_chest():
	is_opened = true
	
	# Hide the interact prompt forever since it's empty now
	interact_label.hide()
	
	anim.play("open") 
	
	var roll = randf()
	var drop = ""
	
	if roll <= 0.60:
		drop = "Rusty Sword (Common)"
	elif roll <= 0.90:
		drop = "Steel Axe (Rare)"
	else:
		drop = "Magic Staff (Epic)"
		
	print("Chest opened! You looted: ", drop)
