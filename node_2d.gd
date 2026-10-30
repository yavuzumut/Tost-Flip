extends Node2D

var bug_scene = preload("res://Bug.tscn")

const RECORD_PATH := "user://tost_flip_record.save"

enum GameState { MAIN_MENU, COLLECTION, READY, FLYING, LANDED, GAME_OVER }

@onready var toast: Toast = $Toast
@onready var ground: StaticBody2D = $Ground
@onready var menu_bg: Sprite2D = $MenuBG

var state := GameState.MAIN_MENU
var score := 0
var combo := 0
var best_score := 0
var _start_pos := Vector2.ZERO

var _score_label: Label
var _combo_label: Label
var _result_label: Label
var _retry_button: Button
var _game_ui: CanvasLayer
var _best_score_label: Label


func _ready() -> void:
	_load_best_score()
	_best_score_label = $CanvasLayer/MainMenu/BestScoreDisplay/BestScoreValue
	_best_score_label.text = str(best_score)
	ground.add_to_group("ground")
	_start_pos = Vector2(get_viewport_rect().size.x * 0.5, _ground_top() - toast.toast_size.y * 0.5)
	toast.landed.connect(_on_toast_landed)
	_build_ui()
	_show_main_menu()
	_setup_menu_animations()
	_play_menu_intro()


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
		return

	state = GameState.LANDED

	if butter_down:
		# Oyuncu kaybetti
		score = 0
		combo=0
		_result_label.text = "KAYBETTİN! Combo sıfırlandı."
		_result_label.modulate = Color("ff6b6b")

	else:
		# Oyuncu kazandı
		combo += 1

		var earned = mini(combo, 5)

		score += earned

		if combo > 1:
			_result_label.text = "COMBO x%d! +%d puan" % [combo, earned]
		else:
			_result_label.text = "KAZANDIN! +1 puan"
		_result_label.modulate = Color("7dff8a")
	if randi() % 3 == 0:
		spawn_bug()

		# Yeni rekor kontrolü
		if score > best_score:
			best_score = score
			_save_best_score()

			if _best_score_label != null:
				_best_score_label.text = str(best_score)

	_score_label.text = "Puan: %d" % score
	_combo_label.text = "Combo: x%d" % combo
	_result_label.visible = true

	state = GameState.GAME_OVER

	await get_tree().create_timer(1.2).timeout
	_restart()



func _load_best_score() -> void:
	if not FileAccess.file_exists(RECORD_PATH):
		return

	var file := FileAccess.open(RECORD_PATH, FileAccess.READ)
	if file == null:
		push_warning("Rekor dosyasi okunamadi.")
		return

	var saved := file.get_as_text().strip_edges()
	if saved.is_valid_int():
		best_score = maxi(0, saved.to_int())

	print("Kayitli rekor: ", best_score)


func _save_best_score() -> void:
	var file := FileAccess.open(RECORD_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Rekor kaydedilemedi.")
		return

	file.store_string(str(best_score))
	print("Yeni rekor: ", best_score)


func _restart() -> void:
	toast.reset_to(_start_pos)
	state = GameState.READY
	_result_label.visible = false
	_score_label.text = "Puan: %d" % score
	_combo_label.text = "Combo: x%d" % combo
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

	box.add_child(_make_label("TOST FLIP", 54, Color("ffd24a")))

	_score_label = _make_label("Puan: 0", 30, Color("fff4d6"))
	box.add_child(_score_label)
	
	_combo_label = _make_label("Combo: x0", 24, Color("ffd24a"))
	box.add_child(_combo_label)

	box.add_child(_make_label(
		"Sol tık: fırlat / sola döndür   |   Sağ tık: sağa döndür\nTereyağlı yüz yere gelmesin!",
		20,
		Color("fff8ee")
	))

	_result_label = _make_label("", 38, Color.WHITE)
	box.add_child(_result_label)

	_retry_button = Button.new()
	_retry_button.text = "Tekrar Oyna"
	_retry_button.add_theme_font_size_override("font_size", 26)
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry_button.pressed.connect(_restart)
	_retry_button.visible = false
	box.add_child(_retry_button)


func _build_best_score_note() -> void:
	var note := Control.new()
	note.name = "BestScoreNote"
	note.anchor_left = 0.0
	note.anchor_right = 0.0
	note.anchor_top = 1.0
	note.anchor_bottom = 1.0
	note.offset_left = 18.0
	note.offset_right = 230.0
	note.offset_top = -212.0
	note.offset_bottom = -12.0
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var picture := TextureRect.new()
	picture.name = "NoteImage"
	picture.texture = preload("res://assets/high_score_note.png")
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(picture)

	_best_score_label = Label.new()
	_best_score_label.name = "BestScoreValue"
	_best_score_label.text = str(best_score)
	_best_score_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_best_score_label.offset_left = 18.0
	_best_score_label.offset_right = -18.0
	_best_score_label.offset_top = 70.0
	_best_score_label.offset_bottom = -26.0
	_best_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_best_score_label.add_theme_font_size_override("font_size", 48)
	_best_score_label.add_theme_color_override("font_color", Color("#603419"))
	_best_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(_best_score_label)

	$CanvasLayer/MainMenu.add_child(note)


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


func get_level(points: int) -> int:
	if points >= 6:
		return 3
	elif points >= 3:
		return 2
	else:
		return 1


# OYNA BUTONU
func _on_play_button_pressed() -> void:
	menu_bg.hide()
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/CollectionMenu.hide()

	toast.show()
	_game_ui.show()

	score = 0
	_restart()


# KOLEKSIYON BUTONU
func _on_collection_button_pressed() -> void:
	menu_bg.show()
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
	menu_bg.show()

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

			button.mouse_entered.connect(_animate_menu_button.bind(button, 1.08))
			button.mouse_exited.connect(_animate_menu_button.bind(button, 1.0))
			button.button_down.connect(_animate_menu_button.bind(button, 1.12))


func _animate_menu_button(button: Button, target_scale: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.15)


# ANA MENU GIRIS ANIMASYONU
func _play_menu_intro() -> void:
	var title := $CanvasLayer/MainMenu/TitleLogo
	var buttons := $CanvasLayer/MainMenu/MenuButtons
	var record := $CanvasLayer/MainMenu/BestScoreDisplay

	# Başlangıçta saydam yap
	title.modulate.a = 0.0
	buttons.modulate.a = 0.0
	record.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# Logo
	tween.tween_property(
		title, "modulate:a", 1.0, 0.5
	)

	# Ahşap butonlar
	tween.tween_property(
		buttons, "modulate:a", 1.0, 0.5
	).set_delay(0.15)

	# Rekor notu
	tween.tween_property(
		record, "modulate:a", 1.0, 0.5
	).set_delay(0.30)
func spawn_bug():
	var bug = bug_scene.instantiate()

	add_child(bug)

	bug.global_position = Vector2(
	-50,
	toast.global_position.y
)

	bug.hit_toast.connect(_on_bug_hit)
	bug.bug_killed.connect(_on_bug_killed)

	print("BUG OLUSTU")



func _on_bug_hit():

	score -= 1

	if score < 0:
		score = 0

	_score_label.text = "Puan: %d" % score

	print("Bocek tosta degdi! -1 puan")

func _on_bug_killed():

	score += 2

	_score_label.text = "Puan: %d" % score

	print("Bocek olduruldu! +2 puan")
