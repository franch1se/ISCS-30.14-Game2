extends CharacterBody2D


@onready var background = get_tree().get_first_node_in_group("tilemap")
@onready var terrain = get_tree().get_first_node_in_group("terrain")
@onready var objects = get_tree().get_first_node_in_group("objects")
@onready var collision = $CollisionShape2D

@onready var anim_sprite: AnimatedSprite2D = $Sprite2D
@onready var run_particles: AnimatedSprite2D = $"../RunParticles"
@onready var jump_particles: AnimatedSprite2D = $"../JumpParticles"
@onready var jump_particles2: AnimatedSprite2D = $"../JumpParticles2"
@onready var fall_particles: AnimatedSprite2D = $"../FallParticles"
@onready var door_a = get_tree().get_first_node_in_group("door_a")
@onready var door_b = get_tree().get_first_node_in_group("door_b")

const SPEED = 20.0
const JUMP_VELOCITY = -320.0
const MAX_SPEED = 125
const GRAVITY = Vector2(0, 800.0)
const MX_JUMP_COUNT = 2
const WALL_BUMP_SPEED = 80
const DOOR_A_COOR = Vector2i(4, 3)
const DOOR_B_COOR = Vector2i(68, -22)

var jump_count = MX_JUMP_COUNT
var is_jumping = false
var is_running = false
var is_teleporting = false
var direction = 0
var platformtype = 0
var tiletype = 0
var nextplatform = false
var is_exploding = false

var run_particles_stopping = false

func _ready():
	anim_sprite.play("Idle")
	door_a.play("Closing")

func animate_change_direction():
	anim_sprite.set_flip_h(direction == -1)
	run_particles.set_flip_h(direction == -1)
	if not is_jumping:
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
	if not is_jumping:
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

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * delta
	else: 
		jump_count = MX_JUMP_COUNT
		is_jumping = false
	
	if is_teleporting:
		check_tiletype()
		return
		
	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_count>=1:
		jump(JUMP_VELOCITY, 1)
		jump_count -= 1
		is_jumping = true
		animate_jump_particles()
		anim_sprite.play("Jump")
		
	if Input.is_action_just_pressed("down") and is_jumping:
		velocity.y = -JUMP_VELOCITY
		animate_fall_particles()
	
	if is_jumping:
		anim_sprite.play("Jump")
	
	# Trampoline *
	if platformtype == 2:
		jump(JUMP_VELOCITY, 1.5)
		is_jumping = true
		platformtype = 0
		
	# Jumping down from one way platform *
	if platformtype == 1 and Input.is_action_just_pressed("down") and !is_jumping:
		collision.set_deferred('disabled', true)
		nextplatform = false
	elif nextplatform:
		collision.set_deferred('disabled', false)


	# Get the input direction and handle the movement/deceleration.
	var prev_direction = direction
	direction = Input.get_axis("left", "right")
		
	if direction and not is_exploding:
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
	
	check_tiletype()
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

func check_tiletype():
	var player_pos = terrain.local_to_map(global_position)
	var floor_cell = terrain.get_neighbor_cell(player_pos, 4)
	var next_cell = terrain.get_neighbor_cell(floor_cell, 4)
	if terrain.get_cell_tile_data(player_pos):
		tiletype = terrain.get_cell_tile_data(player_pos).get_custom_data("Type")
		if tiletype == 3:
			if is_teleporting:
				if not door_a.is_playing():
					door_a.play("Closing")
					teleport(DOOR_B_COOR)
					await get_tree().create_timer(0.7).timeout
					anim_sprite.play("Going_out")
					door_b.play("Opening")
					door_b.play("Closing")
					is_teleporting = false
					
				
			elif not is_teleporting and player_pos == DOOR_A_COOR:
				is_teleporting = true
				door_a.play("Opening")
				anim_sprite.play("Going_in")
				
			#var destination = terrain.get_cell_tile_data(player_pos).get_custom_data("Coords")
			#teleport(destination)
			tiletype = 0
	if terrain.get_cell_tile_data(floor_cell):
		platformtype = terrain.get_cell_tile_data(floor_cell).get_custom_data("Type")
	if terrain.get_cell_tile_data(next_cell):
		nextplatform = true

func teleport(destination):
	var target_tile = terrain.map_to_local(destination)
	global_position = target_tile
	velocity *= 0
