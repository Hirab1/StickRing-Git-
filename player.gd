extends CharacterBody2D

# --- Node References ---
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer

# Movement Tuning (Soulslike snappy feel)
const SPEED = 280.0
const ACCELERATION = 2400.0
const FRICTION = 1800.0
const JUMP_VELOCITY = -450.0

# Dodge Roll Tuning
const ROLL_SPEED = 480.0
const ROLL_DURATION = 0.28
const ROLL_COOLDOWN = 0.45

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State { NORMAL, ROLLING }
var current_state = State.NORMAL

var roll_timer = 0.0
var roll_cd_timer = 0.0
var facing_direction = 1.0
var is_invulnerable = false

func _ready():
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())
	else:
		set_multiplayer_authority(1)

func _physics_process(delta):
	if is_multiplayer_authority():
		handle_timers(delta)
		
		match current_state:
			State.NORMAL:
				handle_normal_movement(delta)
			State.ROLLING:
				handle_rolling_movement(delta)

		move_and_slide()

func handle_timers(delta):
	if roll_cd_timer > 0.0:
		roll_cd_timer -= delta

func handle_normal_movement(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal Acceleration & Deceleration
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * SPEED, ACCELERATION * delta)
		facing_direction = sign(input_dir)
		
		# --- VISUAL FLIP (Faces left when moving left) ---
		if facing_direction == -1:
			sprite.flip_h = true
		else:
			sprite.flip_h = false

		# --- PLAY WALK ANIMATION ---
		if is_on_floor():
			anim.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
		# --- PLAY IDLE ANIMATION WHEN STOPPED ---
		if is_on_floor():
			anim.play("idle")

	# Roll / Dodge Check
	if Input.is_action_just_pressed("dodge") and is_on_floor() and roll_cd_timer <= 0.0:
		start_roll()

func start_roll():
	current_state = State.ROLLING
	roll_timer = ROLL_DURATION
	roll_cd_timer = ROLL_COOLDOWN
	is_invulnerable = true
	velocity.x = facing_direction * ROLL_SPEED
	velocity.y = 0

func handle_rolling_movement(delta):
	roll_timer -= delta
	velocity.x = facing_direction * ROLL_SPEED
	
	if roll_timer <= 0:
		is_invulnerable = false
		current_state = State.NORMAL
