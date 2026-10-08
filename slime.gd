extends CharacterBody2D

@onready var detection_zone = $DetectionZone
@onready var kill_zone = $KillZone

var speed = 75.0
var player = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Connect the Area2D signals via code
	detection_zone.body_entered.connect(_on_detection_entered)
	detection_zone.body_exited.connect(_on_detection_exited)
	kill_zone.body_entered.connect(_on_kill_entered)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if player:
		var direction = global_position.direction_to(player.global_position)
		# This single line perfectly calculates left/right movement based on the player's exact coordinates
		velocity.x = direction.x * speed 
	else:
		velocity.x = 0
		
	move_and_slide()

func _on_detection_entered(body):
	if body.name == "Player":
		player = body

func _on_detection_exited(body):
	if body.name == "Player":
		player = null

func _on_kill_entered(body):
	if body.name == "Player":
		print("Player caught! Restarting stage...")
		# This instantly reloads the current level, acting as a death/respawn
		get_tree().reload_current_scene()
