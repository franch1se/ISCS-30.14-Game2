extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $Sprite2D
@onready var run_particles: AnimatedSprite2D = $"../RunParticles"
@onready var jump_particles: AnimatedSprite2D = $"../JumpParticles"
@onready var jump_particles2: AnimatedSprite2D = $"../JumpParticles2"
@onready var fall_particles: AnimatedSprite2D = $"../FallParticles"


const SPEED = 15.0
const JUMP_VELOCITY = -320.0
const MAX_SPEED = 100
const GRAVITY = Vector2(0, 800.0)
const MX_JUMP_COUNT = 2
const WALL_BUMP_SPEED = 80;

var jump_count = MX_JUMP_COUNT
var is_jumping = false
var is_running = false
var direction = 0

var run_particles_stopping = false

func _ready():
	anim_sprite.play("Idle")

func animate_change_direction():
	anim_sprite.set_flip_h(direction == -1)
	run_particles.set_flip_h(direction == -1)
	anim_sprite.play("Run")

func animate_run_particles():
	if run_particles_stopping:
		if run_particles.frame == 7:
			run_particles.pause()
			run_particles_stopping = false
	elif not run_particles.is_playing() and not is_jumping:
		run_particles.global_position = anim_sprite.global_position + Vector2((-1 if direction==1 else 1)*20, 17)
		run_particles.play("Run")

func stop_run_particles():
	run_particles_stopping = true
	anim_sprite.play("Idle")

func animate_jump_particles():
	if not jump_particles.is_playing():
		jump_particles.global_position = anim_sprite.global_position + Vector2((-1 if direction==1 else 1)*5, 10)
		jump_particles.play("Run")
	elif not jump_particles2.is_playing():
		jump_particles2.global_position = anim_sprite.global_position + Vector2((-1 if direction==1 else 1)*5, 10)
		jump_particles2.play("Run")

func animate_fall_particles():
	if not fall_particles.is_playing():
		fall_particles.global_position = anim_sprite.global_position + Vector2(0, 20)
		fall_particles.play("Run")
		print("??")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * delta
	else: 
		jump_count = MX_JUMP_COUNT
		is_jumping = false
		
	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_count>=1:
		jump(JUMP_VELOCITY, 1)
		jump_count -= 1
		is_jumping = true
		animate_jump_particles()
		
	if Input.is_action_just_pressed("down") and is_jumping:
		velocity.y = -JUMP_VELOCITY
		animate_fall_particles()

	# Get the input direction and handle the movement/deceleration.
	var prev_direction = direction
	direction = Input.get_axis("left", "right")
	if direction:
		accelerate(direction)
		is_running = true
	else:
		decelerate()
		is_running = false
		
	if is_running:
		if prev_direction == direction:
			animate_change_direction()
		
		animate_run_particles()
	else:
		stop_run_particles()
		
		
	
	wall_collision(delta)
	move_and_slide()
	
func jump(y_velocity, mult):
	velocity.y = y_velocity*mult

func accelerate(dir):
	if dir==1:
		velocity.x = min(velocity.x + SPEED*dir, MAX_SPEED)
	elif dir==-1:
		velocity.x = max(velocity.x + SPEED*dir, -MAX_SPEED)
	#print(velocity.x)

func decelerate():
	if velocity.x > 0:
		velocity.x = max(velocity.x - SPEED*0.5, 0)
	elif velocity.x < 0:
		velocity.x = min(velocity.x + SPEED*0.5, 0)

func wall_collision(delta) -> void:
	var collision = move_and_collide(velocity*delta)
	if collision and not is_jumping:
		if velocity.x > 0:
			velocity.x = -WALL_BUMP_SPEED
		elif velocity.x < 0:
			velocity.x = WALL_BUMP_SPEED
			
