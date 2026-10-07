extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("Entered kill zone: ", body.name)
	if body.has_method("die"):
		body.die()
