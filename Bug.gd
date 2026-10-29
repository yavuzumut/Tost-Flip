extends Area2D

signal hit_toast
signal bug_killed

@export var speed := 250.0

func _ready():
	$AnimatedSprite2D.play("default")

func _process(delta):
	position.x += speed * delta

	if position.x > 1500:
		queue_free()

func _on_body_entered(body):
	if body is Toast:
		hit_toast.emit()
		queue_free()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed:
			bug_killed.emit()
			queue_free()
