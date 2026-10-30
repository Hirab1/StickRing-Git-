extends CharacterBody2D

# --- Node References ---
@onready var visuals = $Visuals
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

	# Check Input States
	var is_running = Input.is_action_pressed("run")
	var is_crouching = Input.is_action_pressed("crouch") # Added crouch check

	# Roll: A+Alt / D+Alt (disabled while crouching)
	if Input.is_action_just_pressed("dodge") and is_on_floor() and input_dir != 0 and roll_cd_timer <= 0.0 and not is_crouching:
		facing_direction = sign(input_dir)
		visuals.scale.x = absf(visuals.scale.y) * facing_direction
		start_roll()
		return

	# Jump: Space (disabled while crouching)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# Horizontal Acceleration & Deceleration
	if input_dir != 0 and not is_crouching:
		var target_speed = RUN_SPEED if is_running else WALK_SPEED
		velocity.x = move_toward(velocity.x, input_dir * target_speed, ACCELERATION * delta)
		facing_direction = sign(input_dir)
		visuals.scale.x = absf(visuals.scale.y) * facing_direction
	else:
		# Stop moving if no input OR if crouching
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# --- ANIMATION PRIORITY ---
	if not is_on_floor():
		# Plays jump if in the air
		if anim.has_animation("jump") and anim.assigned_animation != "jump":
			anim.play("jump")
	elif is_crouching:
		# Plays crouch if grounded and holding crouch button
		if anim.has_animation("crouch") and anim.assigned_animation != "crouch":
			anim.play("crouch")
	elif input_dir != 0:
		# Plays run or walk if grounded and moving
		if is_running and anim.assigned_animation != "run":
			anim.play("run")
		elif not is_running and anim.assigned_animation != "walk":
			anim.play("walk")
	else:
		# Plays idle if grounded and standing still
		if anim.assigned_animation != "idle":
			anim.play("idle")
func start_roll():
	current_state = State.ROLLING
	if anim.has_animation("roll"):
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
	if anim.has_animation("death"):
		anim.play("death")
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	respawn()

func respawn():
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_invulnerable = false
	current_state = State.NORMAL
	if anim.has_animation("idle"):
		anim.play("idle")
