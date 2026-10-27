extends Node2D

enum GameState { MAIN_MENU, COLLECTION, READY, FLYING, LANDED, GAME_OVER }

@onready var toast: Toast = $Toast
@onready var ground: StaticBody2D = $Ground

var state := GameState.MAIN_MENU
var score := 0
var _start_pos := Vector2.ZERO

var _score_label: Label
var _result_label: Label
var _retry_button: Button
var _game_ui: CanvasLayer


func _ready() -> void:
	ground.add_to_group("ground")
	_start_pos = Vector2(get_viewport_rect().size.x * 0.5, _ground_top() - toast.toast_size.y * 0.5)
	toast.landed.connect(_on_toast_landed)
	_build_ui()
	_show_main_menu()
	_setup_menu_animations()


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
		_result_label.modulate = Color("ff6b6b")
	else:
		score += 1
		_result_label.text = "KAZANDIN! +1 puan"
		_result_label.modulate = Color("7dff8a")

	_score_label.text = "Puan: %d" % score
	_result_label.visible = true
	state = GameState.GAME_OVER

	await get_tree().create_timer(1.2).timeout
	_restart()


func _restart() -> void:
	toast.reset_to(_start_pos)
	state = GameState.READY
	_result_label.visible = false
	_score_label.text = "Puan: %d" % score

	print("Seviye: ", get_level(score), " | Puan: ", score)
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	_game_ui = layer
	add_child(layer)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_top = 16
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)

	# Buradan itibaren sola kaymış olan hizalamaları (Tab ile) içeri aldım
	box.add_child(_make_label("TOST FLIP", 54, Color("ffd24a")))

	_score_label = _make_label("Puan: 0", 30, Color("fff4d6"))
	box.add_child(_score_label)

	box.add_child(_make_label(
		"Sol tık: fırlat / sola döndür   |   Sağ tık: sağa döndür\nTereyağlı yüz yere gelmesin!",
		20,
		Color("fff8ee")
	))

	_result_label = _make_label("", 38, Color.WHITE)
	box.add_child(_result_label)
	# Mükerrer olan ikinci box.add_child(_result_label) satırını sildim.

	_retry_button = Button.new()
	_retry_button.text = "Tekrar Oyna"
	_retry_button.add_theme_font_size_override("font_size", 26)
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry_button.pressed.connect(_restart)
	_retry_button.visible = false # Otomatik başladığı için butonu gizledim
	box.add_child(_retry_button)


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("5a3418"))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# get_level fonksiyonu dışarı alındı ve girintisi (indentation) düzeltildi
func get_level(points: int) -> int:
	if points >= 6:
		return 3
	elif points >= 3:
		return 2
	else:
		return 1


# OYNA BUTONU
func _on_play_button_pressed() -> void:
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/CollectionMenu.hide()

	toast.show()
	_game_ui.show()

	score = 0
	_restart()


# KOLEKSIYON BUTONU
func _on_collection_button_pressed() -> void:
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/CollectionMenu.show()
	state = GameState.COLLECTION


# CIKIS BUTONU
func _on_exit_button_pressed() -> void:
	get_tree().quit()


# GERI BUTONU
func _on_back_button_pressed() -> void:
	_show_main_menu()


# ANA MENU
func _show_main_menu() -> void:
	toast.reset_to(_start_pos)
	toast.hide()

	_game_ui.hide()
	$CanvasLayer/CollectionMenu.hide()
	$CanvasLayer/MainMenu.show()

	state = GameState.MAIN_MENU

func _setup_menu_animations() -> void:
	for child in $CanvasLayer/MainMenu/MenuButtons.get_children():
		if child is Button:
			var button := child as Button

			# Buton merkezinden büyüsün
			button.pivot_offset = button.size / 2.0

			button.mouse_entered.connect(
				_animate_menu_button.bind(button, 1.08)
			)

			button.mouse_exited.connect(
				_animate_menu_button.bind(button, 1.0)
			)

			button.button_down.connect(
				_animate_menu_button.bind(button, 1.12)
			)


func _animate_menu_button(button: Button, target_scale: float) -> void:
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"scale",
		Vector2(target_scale, target_scale),
		0.15
	)
