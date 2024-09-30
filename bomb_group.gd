extends Node2D

@export var bombPath : PackedScene = load("res://bomb.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		#print("BOMB")
		var newBomb = bombPath.instantiate()
		add_child(newBomb)
