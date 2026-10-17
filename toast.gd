extends RigidBody2D
class_name Toast

signal landed(butter_down: bool)

@export var toast_size := Vector2(140, 26)
@export var launch_speed := 700.0     # fırlatma hızı (px/sn)
@export var launch_spin := 6.0        # fırlatmadaki başlangıç dönüşü (rad/sn)
@export var spin_step := 4.0          # her tıklamanın dönüşe eklediği hız
@export var max_spin := 12.0          # azami dönüş hızı
@export var bounce := 0.1
@export var friction := 0.9
@export var settle_speed := 15.0      # "durdu" sayılma eşiği
@export var settle_spin := 0.3
@export var settle_time := 0.3
@export var max_settle_wait := 3.0
@export var ground_group := &"ground"

var airborne := false
var _landing := false
var _grace := 0.0
var _stable := 0.0
var _wait := 0.0


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = toast_size
	$CollisionShape2D.shape = rect
	if has_node("Sprite2D"):
		$Sprite2D.visible = false

	var mat := PhysicsMaterial.new()
	mat.bounce = bounce
	mat.friction = friction
	physics_material_override = mat

	mass = 1.0
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = 0.0
	contact_monitor = true
	max_contacts_reported = 4
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	body_entered.connect(_on_body_entered)
	reset_to(global_position)


func reset_to(pos: Vector2) -> void:
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	global_position = pos
	airborne = false
	_landing = false
	_grace = 0.0
	_stable = 0.0
	_wait = 0.0
	queue_redraw()


func launch() -> void:
	freeze = false
	airborne = true
	_grace = 0.2  # fırlatma anındaki zemin temasını yok say
	linear_velocity = Vector2(0, -launch_speed)
	angular_velocity = launch_spin * (1.0 if randf() > 0.5 else -1.0)


func spin(dir: int) -> void:
	# dir: -1 = saat yönünün tersi, +1 = saat yönü
	if not airborne:
		return
	angular_velocity = clampf(angular_velocity + dir * spin_step, -max_spin, max_spin)


func _on_body_entered(body: Node) -> void:
	if not airborne or _grace > 0.0 or _landing:
		return
	if body.is_in_group(ground_group):
		airborne = false   # kontrol hemen kilitlenir
		_landing = true    # sonuç, tost durunca hesaplanır


func _physics_process(delta: float) -> void:
	if _grace > 0.0:
		_grace -= delta
	if not _landing:
		return
	_wait += delta
	if linear_velocity.length() < settle_speed and absf(angular_velocity) < settle_spin:
		_stable += delta
	else:
		_stable = 0.0
	if _stable >= settle_time or _wait >= max_settle_wait:
		_landing = false
		# Tereyağlı yüz yerel "yukarı" (0,-1). Aşağı bakıyorsa cos(rotation) < 0.
		# Kenarda dengede kalma gibi belirsiz durumda yine işaret belirler.
		landed.emit(cos(rotation) < 0.0)


func _draw() -> void:
	var hw := toast_size.x * 0.5
	var hh := toast_size.y * 0.5
	draw_rect(Rect2(-hw, -hh, toast_size.x, toast_size.y), Color("c98a3b"))           # ekmek
	draw_rect(Rect2(-hw, -hh, toast_size.x, toast_size.y), Color("7a4a14"), false, 3) # kabuk
	draw_rect(Rect2(-hw + 3, -hh + 3, toast_size.x - 6, 7), Color("ffe566"))          # tereyağı
