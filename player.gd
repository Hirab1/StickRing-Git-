extends CharacterBody2D

# --- Node References ---
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer

# Movement Tuning (Soulslike snappy feel)
const WALK_SPEED = 150.0
const RUN_SPEED = 280.0
const ACCELERATION = 2400.0
const FRICTION = 1800.0
const JUMP_VELOCITY = -450.0

# Dodge Roll Tuning
const ROLL_SPEED = 480.0
const ROLL_DURATION = 0.28
const ROLL_COOLDOWN = 0.45

# Death Tuning
const RESPAWN_DELAY = 1.2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State { NORMAL, ROLLING, DEAD }
var current_state = State.NORMAL

var roll_timer = 0.0
var roll_cd_timer = 0.0
var facing_direction = 1.0
var is_invulnerable = false
var spawn_position = Vector2.ZERO

func _ready():
	spawn_position = global_position
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
			State.DEAD:
				pass # frozen until respawn

		move_and_slide()

func handle_timers(delta):
	if roll_cd_timer > 0.0:
		roll_cd_timer -= delta

func handle_normal_movement(delta):
	var input_dir = Input.get_axis("move_left", "move_right")

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Roll: A+Alt / D+Alt (needs a direction held)
	if Input.is_action_just_pressed("dodge") and is_on_floor() and input_dir != 0 and roll_cd_timer <= 0.0:
		facing_direction = sign(input_dir)
		sprite.flip_h = facing_direction < 0
		start_roll()
		return

	# Jump: Space (works while holding A or D too)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal Acceleration & Deceleration
	if input_dir != 0:
		var is_running = Input.is_action_pressed("run")
		var target_speed = RUN_SPEED if is_running else WALK_SPEED

		velocity.x = move_toward(velocity.x, input_dir * target_speed, ACCELERATION * delta)
		facing_direction = sign(input_dir)
		sprite.flip_h = facing_direction < 0

		if is_on_floor():
			anim.play("run" if is_running else "walk")
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

		if is_on_floor():
			anim.play("idle")

	# --- JUMP / AIR ANIMATION ---
	if not is_on_floor() or velocity.y < 0:
		if anim.assigned_animation != "jump":
			anim.play("jump")

func start_roll():
	current_state = State.ROLLING
	anim.play("roll")
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

# --- Death / Respawn ---
func die():
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	is_invulnerable = true
	velocity = Vector2.ZERO
	anim.play("death")
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	respawn()

func respawn():
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_invulnerable = false
	current_state = State.NORMAL
	anim.play("idle")
