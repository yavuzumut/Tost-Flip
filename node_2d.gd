extends Node2D

enum GameState { READY, FLYING, LANDED, GAME_OVER }

@onready var toast: Toast = $Toast
@onready var ground: StaticBody2D = $Ground

var state := GameState.READY
var score := 0
var _start_pos := Vector2.ZERO

var _score_label: Label
var _result_label: Label
var _retry_button: Button


func _ready() -> void:
	ground.add_to_group("ground")
	_start_pos = Vector2(get_viewport_rect().size.x * 0.5, _ground_top() - toast.toast_size.y * 0.5)
	toast.landed.connect(_on_toast_landed)
	_build_ui()
	_restart()


func _ground_top() -> float:
	var cs := ground.get_node("CollisionShape2D") as CollisionShape2D
	var y := ground.global_position.y + cs.position.y
	if cs.shape is RectangleShape2D:
		y -= (cs.shape as RectangleShape2D).size.y * 0.5
	return y


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var btn := (event as InputEventMouseButton).button_index
	match state:
		GameState.READY:
			if btn == MOUSE_BUTTON_LEFT:
				toast.launch()
				state = GameState.FLYING
		GameState.FLYING:
			if not toast.airborne:
				return  # yere değdi, kontrol kilitli
			if btn == MOUSE_BUTTON_LEFT:
				toast.spin(-1)
			elif btn == MOUSE_BUTTON_RIGHT:
				toast.spin(1)


func _on_toast_landed(butter_down: bool) -> void:
	if state != GameState.FLYING:
		return  # aynı sonuç iki kez işlenmesin
	state = GameState.LANDED
	if butter_down:
		score = 0
		_result_label.text = "KAYBETTİN! Tereyağı yere yapıştı."
		_result_label.modulate = Color("ff5555")
	else:
		score += 1
		_result_label.text = "KAZANDIN! +1 puan"
		_result_label.modulate = Color("66ff88")
	_score_label.text = "Puan: %d" % score
	_result_label.visible = true
	_retry_button.visible = true
	state = GameState.GAME_OVER


func _restart() -> void:
	toast.reset_to(_start_pos)
	state = GameState.READY
	_result_label.visible = false
	_retry_button.visible = false
	_score_label.text = "Puan: %d" % score


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_top = 16
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)

	box.add_child(_make_label("TOST FLIP", 48, Color("ffd24a")))
	_score_label = _make_label("Puan: 0", 28, Color.WHITE)
	box.add_child(_score_label)
	box.add_child(_make_label("Sol tık: fırlat / sola döndür   |   Sağ tık: sağa döndür\nTereyağlı yüz yere gelmesin!", 18, Color("dddddd")))

	_result_label = _make_label("", 36, Color.WHITE)
	box.add_child(_result_label)

	_retry_button = Button.new()
	_retry_button.text = "Tekrar Oyna"
	_retry_button.add_theme_font_size_override("font_size", 26)
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry_button.pressed.connect(_restart)
	box.add_child(_retry_button)


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
