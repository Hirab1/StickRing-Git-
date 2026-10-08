extends Area2D

# @export makes this variable show up in the Godot Inspector!
@export var next_level: PackedScene

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		if next_level != null:
			print("Teleporting to next stage...")
			# Update this specific line:
			get_tree().call_deferred("change_scene_to_packed", next_level)
		else:
			print("DOOR ERROR: You forgot to set the next level in the Inspector!")
