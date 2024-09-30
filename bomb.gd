extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var bomb_sprite = $CharacterBody2D/AnimatedSprite2D
@onready var player_par = player.get_parent()

var EXPLOSION_FORCE = 200
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = player.global_position
	bomb_sprite.play("Exploding")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if bomb_sprite.frame == 10:
		player_par.is_exploding = true
		var force = ((player.global_position - global_position)).normalized()
		print(force)
		player_par.velocity += force*EXPLOSION_FORCE
		
		

func _on_animated_sprite_2d_animation_finished() -> void:
	player_par.is_exploding = false
	queue_free()
