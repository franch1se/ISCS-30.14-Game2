extends CharacterBody2D

const SPEED = 10.0
const JUMP_VELOCITY = -275.0
const MAX_SPEED = 500
const GRAVITY = Vector2(0, 800.0)

var jump_count = 3
var is_jumping = false
var is_falling = false


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * delta
	else: 
		jump_count = 3
		is_jumping = false
	
	# Check if falling (not from jump)
	if velocity.y > 0 and !is_jumping:
		is_falling = true
	else:
		is_falling = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump(JUMP_VELOCITY, 1)
		is_jumping = true
	elif Input.is_action_just_pressed("jump") and !is_on_floor() and jump_count>1:
		jump(JUMP_VELOCITY, 1)
		jump_count -= 1
		is_jumping = true
		
	# End jump / "smash down"
	if is_jumping and Input.is_action_just_pressed("down"):
		velocity.y -= JUMP_VELOCITY

	# Handle input and left/right movement
	var direction = Input.get_axis("left", "right")
	if direction:
		accelerate(direction)
	else:
		decelerate()

	wall_collision(delta)
	move_and_slide()

func jump(y_velocity, mult):
	velocity.y = y_velocity*mult

func accelerate(dir):
	if dir==1:
		velocity.x = min(velocity.x + SPEED*dir, MAX_SPEED)
		print(velocity.x)
	elif dir==-1:
		velocity.x = max(velocity.x + SPEED*dir, -MAX_SPEED)
		print(velocity.x)

func decelerate():
	if velocity.x > 0:
		velocity.x = max(velocity.x - SPEED*0.5, 0)
	elif velocity.x < 0:
		velocity.x = min(velocity.x + SPEED*0.5, 0)
		
func wall_collision(delta) -> void:
	var collision = move_and_collide(velocity*delta)
	if collision and !is_jumping and !is_falling:
		if velocity.x > 0:
			velocity.x = -100
		else:
			velocity.x = 100
		decelerate()
