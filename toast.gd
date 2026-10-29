extends RigidBody2D
class_name Toast

signal landed(butter_down: bool)

@export var toast_size := Vector2(140, 26)   # çarpışma kutusu, Inspector'daki değerinle aynı bırak
@export var launch_speed := 700.0
@export var launch_spin := 6.0
@export var spin_step := 4.0
@export var max_spin := 12.0
@export var bounce := 0.1
@export var friction := 0.9
@export var ground_group := &"ground"

@export_group("Görsel")
@export var butter_texture: Texture2D
@export var plain_texture: Texture2D
@export var swap_face_in_flight := true              # havada yukarı bakan yüzü göster
@export var show_bottom_face_after_landing := false  # true: sonuçta alttaki yüzü göster

@export_group("İniş animasyonu")
@export var lay_duration := 0.4
@export var flat_squash := 0.82     # yatarken dikey basıklık (1.0 = basık değil)
@export var lean_time := 0.06       # sonuç hesabında dönüşü bu kadar ileri tahmin et
@export var rest_offset_y := 0.0    # tost zemine gömülü/havada kalırsa piksel ayarı

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D

var airborne := false
var _landing := false
var _grace := 0.0
var _base_scale := Vector2.ONE
var _tween: Tween


func _ready() -> void:
	if butter_texture == null:
		butter_texture = load("res://assets/toast_butter.png")
	if plain_texture == null:
		plain_texture = load("res://assets/toast_plain.png")

	var rect := RectangleShape2D.new()
	rect.size = toast_size
	_shape.shape = rect
	_base_scale = _sprite.scale   # 0.28 gibi mevcut ölçeği korur

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
	if _tween and _tween.is_valid():
		_tween.kill()
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	global_position = pos
	airborne = false
	_landing = false
	_grace = 0.0
	_sprite.position = Vector2.ZERO
	_sprite.rotation = 0.0
	_sprite.scale = _base_scale
	_sprite.texture = butter_texture


func launch() -> void:
	freeze = false
	airborne = true
	_grace = 0.2
	linear_velocity = Vector2(0, -launch_speed)
	angular_velocity = launch_spin * (1.0 if randf() > 0.5 else -1.0)


func spin(dir: int) -> void:
	if not airborne:
		return
	angular_velocity = clampf(angular_velocity + dir * spin_step, -max_spin, max_spin)


func _process(_delta: float) -> void:
	# Gerçek 3D flip yok: dünyada yukarı bakan yüzün sprite'ını göstererek taklit ediyoruz.
	if airborne and swap_face_in_flight:
		_sprite.texture = butter_texture if cos(rotation) >= 0.0 else plain_texture


func _physics_process(delta: float) -> void:
	if _grace > 0.0:
		_grace -= delta


func _on_body_entered(body: Node) -> void:
	if not airborne or _grace > 0.0 or _landing:
		return
	if not body.is_in_group(ground_group):
		return
	airborne = false   # kontrol hemen kilitlenir
	_landing = true    # bir daha girilemez: sonuç tek sefer hesaplanır
	# Tereyağlı yüz yerel "yukarı" (0,-1). cos(açı) < 0 ise aşağı bakıyor.
	# Kenarda ilk temas anındaki belirsizliği azaltmak için dönüşü biraz ileri tahmin et.
	var predicted := rotation + clampf(angular_velocity, -max_spin, max_spin) * lean_time
	var butter_down := cos(predicted) < 0.0
	call_deferred("_lay_down", butter_down)   # fizik callback'inde freeze etme


func _lay_down(butter_down: bool) -> void:
	# Fizik gövdesi bulunduğu yerde donar; yalnızca Sprite2D tween ile yatar.
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	var show_butter := not butter_down            # alttaki yüz tereyağlıysa üstte sade görünür
	if show_bottom_face_after_landing:
		show_butter = butter_down
	_sprite.texture = butter_texture if show_butter else plain_texture

	var tex_h := 0.0
	if _sprite.texture:
		tex_h = _sprite.texture.get_height()
	var flat_scale := Vector2(_base_scale.x * 1.05, _base_scale.y * flat_squash)
	var ground_y := _lowest_point_y()
	var target_pos := Vector2(_sprite.global_position.x, ground_y - tex_h * flat_scale.y * 0.5 + rest_offset_y)
	var target_rot := _sprite.global_rotation + angle_difference(_sprite.global_rotation, 0.0)

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite, "global_position", target_pos, lay_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sprite, "global_rotation", target_rot, lay_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sprite, "scale", flat_scale, lay_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)   # yumuşak "pat" hissi
	_tween.chain().tween_callback(func(): landed.emit(butter_down))


func _lowest_point_y() -> float:
	var half := toast_size * 0.5
	var lowest := -INF
	for c in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
		lowest = maxf(lowest, _shape.to_global(c).y)
	return lowest
