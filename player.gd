extends CharacterBody2D

#*
@onready var background = get_tree().get_first_node_in_group("tilemap")
@onready var terrain = get_tree().get_first_node_in_group("terrain")
@onready var collision = $CollisionShape2D

const SPEED = 15.0
const JUMP_VELOCITY = -300.0
const MAX_SPEED = 500
const GRAVITY = Vector2(0, 800.0)

var jump_count = 3
var is_jumping = false
var is_falling = false
var platformtype = 0
var tiletype = 0
var nextplatform = false


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * delta
	else: 
		jump_count = 3
		is_jumping = false
		
	# Check if falling (not from jump) *
	if velocity.y > 10 and !is_jumping:
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
		
	if is_jumping and Input.is_action_just_pressed("down"):
		velocity.y -= JUMP_VELOCITY
		
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
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
		accelerate(direction)
	else:
		decelerate()
	
	check_tiletype() #*
	wall_collision(delta)
	move_and_slide()
	
func jump(y_velocity, mult):
	velocity.y = y_velocity*mult

func accelerate(dir):
	if dir==1:
		velocity.x = min(velocity.x + SPEED*dir, MAX_SPEED)
	elif dir==-1:
		velocity.x = max(velocity.x + SPEED*dir, -MAX_SPEED)

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

# *
func check_tiletype():
	var player_pos = background.local_to_map(global_position)
	var floor_cell = terrain.get_neighbor_cell(player_pos, 4)
	var next_cell = terrain.get_neighbor_cell(floor_cell, 4)
	if terrain.get_cell_tile_data(player_pos):
		tiletype = terrain.get_cell_tile_data(player_pos).get_custom_data("Type")
		if tiletype == 3:
			var destination = terrain.get_cell_tile_data(player_pos).get_custom_data("Coords")
			teleport(destination)
			tiletype = 0
	if terrain.get_cell_tile_data(floor_cell):
		platformtype = terrain.get_cell_tile_data(floor_cell).get_custom_data("Type")
	if terrain.get_cell_tile_data(next_cell):
		nextplatform = true

#*
func teleport(destination):
	var target_tile = terrain.map_to_local(destination)
	global_position = target_tile
	velocity *= 0
