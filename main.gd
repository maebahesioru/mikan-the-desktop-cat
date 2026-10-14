extends Node2D
## Mikan — a tiny orange cat that lives on your desktop.
## She walks along the bottom of your screen, stops to rest, falls asleep
## if you leave her alone, watches your cursor, and you can pick her up
## and drop her. Right-click her for a little menu (come here, nap, size...).

const BASE_SPEED := 70.0        # walking speed px/s
const FALL_SPEED := 900.0       # gravity for dropping
const PET_BASE_W := 96.0        # on-screen width of the pet at normal size
const PET_BASE_H := 96.0
const CONFIG_PATH := "user://mikan.cfg"
const VERSION := "1.1.0"

enum State { WALK, IDLE, SLEEP, FALL, DRAG, HOP, PET, COME }

var state: State = State.WALK
var dir := 1
var state_time := 0.0
var anim_time := 0.0
var fall_vy := 0.0
var drag_offset := Vector2.ZERO
var hop_vy := 0.0
var last_click_time := 0.0
var press_pos := Vector2.ZERO
var dragged := false
var pet_time := 0.0
var meow_player: AudioStreamPlayer
var frames := {}
var sprite: Sprite2D
var win_size := Vector2(1920, 1080)
var floor_y := 0.0
var pet_w := PET_BASE_W
var pet_h := PET_BASE_H

# settings (persisted to user://mikan.cfg)
var size_name := "normal"
var roam := true
var pets_today := 0
var pets_date := ""

# menu / behaviours
var menu: PopupMenu
var menu_open := false
var come_time := 0.0

const SIZE_SCALE := {"small": 0.72, "normal": 1.0, "big": 1.32}


func _ready() -> void:
	_load_config()

	frames = {
		"walk": [load("res://assets/sprites/walk1.png"), load("res://assets/sprites/walk2.png")],
		"idle": [load("res://assets/sprites/idle1.png"), load("res://assets/sprites/idle2.png")],
		"sleep": [load("res://assets/sprites/sleep1.png"), load("res://assets/sprites/sleep2.png")],
		"drag": [load("res://assets/sprites/drag.png")],
	}
	# procedural meow: a short gliding tone with vibrato
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.6
	meow_player = AudioStreamPlayer.new()
	meow_player.stream = stream
	add_child(meow_player)

	sprite = Sprite2D.new()
	sprite.texture = frames["idle"][0]
	add_child(sprite)
	_apply_size()

	menu = PopupMenu.new()
	menu.id_pressed.connect(_on_menu_id)
	menu.popup_hide.connect(func(): menu_open = false)
	add_child(menu)

	win_size = Vector2(DisplayServer.screen_get_size())
	get_window().size = Vector2i(win_size)
	floor_y = win_size.y - pet_h * 0.55
	position = Vector2(win_size.x * 0.5, floor_y)
	state_time = randf_range(2.0, 5.0)
	_update_passthrough()


func _apply_size() -> void:
	var s: float = SIZE_SCALE.get(size_name, 1.0)
	pet_w = PET_BASE_W * s
	pet_h = PET_BASE_H * s
	sprite.scale = Vector2(pet_w / 128.0, pet_h / 128.0)
	floor_y = win_size.y - pet_h * 0.55
	if state != State.DRAG and state != State.FALL and state != State.HOP:
		position.y = floor_y


func _update_passthrough() -> void:
	# clicks only land on the cat (and her menu while it is open);
	# everything else passes through to the desktop
	var r := Rect2(position - Vector2(pet_w, pet_h) * 0.5, Vector2(pet_w, pet_h))
	if menu_open:
		var mr := Rect2(menu.get_position(), menu.get_size()).grow(10.0)
		r = r.merge(mr)
	var poly := PackedVector2Array([
		r.position,
		Vector2(r.end.x, r.position.y),
		r.end,
		Vector2(r.position.x, r.end.y),
	])
	DisplayServer.window_set_mouse_passthrough(poly)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		if state != State.DRAG and _click_on_cat():
			_show_menu(event.position)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and state != State.DRAG:
			# only react if the click is on the cat
			if _click_on_cat():
				# double-click = she hops!
				var now_t := Time.get_ticks_msec() / 1000.0
				if now_t - last_click_time < 0.35 and state != State.HOP:
					state = State.HOP
					hop_vy = -620.0
					anim_time = 0.0
					last_click_time = 0.0
					return
				last_click_time = now_t
				press_pos = get_global_mouse_position()
				dragged = false
				state = State.DRAG
				drag_offset = position - press_pos
				anim_time = 0.0
		elif not event.pressed and state == State.DRAG:
			if dragged:
				# dropped — she falls to the floor
				state = State.FALL
				fall_vy = 0.0
			else:
				# it was a tap = a pet! she melts and meows
				state = State.PET
				pet_time = 0.9
				_count_pet()
				_play_meow()
	if event is InputEventMouseMotion and state == State.DRAG:
		if get_global_mouse_position().distance_to(press_pos) > 6.0:
			dragged = true


func _click_on_cat() -> bool:
	var local := get_local_mouse_position()
	return abs(local.x) < pet_w * 0.5 and abs(local.y) < pet_h * 0.5


func _process(delta: float) -> void:
	anim_time += delta
	match state:
		State.WALK:
			position.x += BASE_SPEED * dir * delta
			if position.x < pet_w * 0.5:
				position.x = pet_w * 0.5
				dir = 1
			elif position.x > win_size.x - pet_w * 0.5:
				position.x = win_size.x - pet_w * 0.5
				dir = -1
			sprite.texture = frames["walk"][int(anim_time * 5.0) % 2]
			sprite.flip_h = dir < 0
			state_time -= delta
			if state_time <= 0.0:
				state = State.IDLE
				state_time = randf_range(2.0, 4.5)
				_notice_cursor()
		State.IDLE:
			sprite.texture = frames["idle"][int(anim_time * 1.6) % 2]
			state_time -= delta
			if state_time <= 0.0:
				if randf() < 0.25:
					state = State.SLEEP
					state_time = randf_range(4.0, 9.0)
				elif roam:
					state = State.WALK
					state_time = randf_range(2.5, 7.0)
				else:
					state_time = randf_range(2.0, 5.0)
		State.SLEEP:
			sprite.texture = frames["sleep"][int(anim_time * 0.9) % 2]
			state_time -= delta
			if state_time <= 0.0:
				state = State.IDLE
				state_time = randf_range(1.5, 3.0)
		State.FALL:
			fall_vy += FALL_SPEED * delta
			position.y += fall_vy * delta
			sprite.texture = frames["drag"][0]
			if position.y >= floor_y:
				position.y = floor_y
				state = State.WALK
				state_time = randf_range(2.0, 5.0)
		State.HOP:
			hop_vy += FALL_SPEED * 1.4 * delta
			position.y += hop_vy * delta
			sprite.texture = frames["drag"][0]
			sprite.flip_h = false
			if position.y >= floor_y:
				position.y = floor_y
				state = State.IDLE
				state_time = randf_range(0.8, 1.6)
		State.PET:
			sprite.texture = frames["idle"][int(anim_time * 3.0) % 2]
			sprite.flip_h = false
			pet_time -= delta
			if pet_time <= 0.0:
				state = State.IDLE
				state_time = randf_range(2.0, 4.0)
		State.DRAG:
			position = get_global_mouse_position() + drag_offset
			# keep her on screen while held
			position.x = clampf(position.x, pet_w * 0.5, win_size.x - pet_w * 0.5)
			position.y = clampf(position.y, pet_h * 0.5, win_size.y - pet_h * 0.5)
			sprite.texture = frames["drag"][0]
			sprite.flip_h = false
		State.COME:
			# she follows your cursor around for a few seconds
			come_time -= delta
			if come_time <= 0.0:
				state = State.IDLE
				state_time = randf_range(2.0, 4.0)
			else:
				var target_x := clampf(get_global_mouse_position().x, pet_w * 0.5, win_size.x - pet_w * 0.5)
				var dx := target_x - position.x
				if abs(dx) < 8.0:
					# she's caught up — wait for you to move
					sprite.texture = frames["idle"][int(anim_time * 1.6) % 2]
				else:
					dir = 1 if dx > 0.0 else -1
					position.x += BASE_SPEED * 1.35 * dir * delta
					position.x = clampf(position.x, pet_w * 0.5, win_size.x - pet_w * 0.5)
					sprite.texture = frames["walk"][int(anim_time * 6.0) % 2]
					sprite.flip_h = dir < 0
	_update_passthrough()


func _notice_cursor() -> void:
	# when she settles down, she might look at where your mouse is
	if randf() < 0.55:
		var mouse_x := get_global_mouse_position().x
		if abs(mouse_x - position.x) < 260.0:
			dir = 1 if mouse_x > position.x else -1
			sprite.flip_h = dir < 0
			state_time = maxf(state_time, 2.5)


func _show_menu(at: Vector2) -> void:
	menu.clear()
	menu.add_item("come here!", 1)
	if state == State.SLEEP:
		menu.add_item("wake up", 2)
	else:
		menu.add_item("nap time", 2)
	menu.add_check_item("roam around", 3)
	menu.set_item_checked(menu.get_item_index(3), roam)
	menu.add_separator()
	menu.add_radio_check_item("small", 11)
	menu.add_radio_check_item("normal", 12)
	menu.add_radio_check_item("big", 13)
	var cur: int = {"small": 11, "normal": 12, "big": 13}.get(size_name, 12)
	menu.set_item_checked(menu.get_item_index(cur), true)
	menu.add_separator()
	menu.add_item("pets today: %d" % pets_today, 99)
	menu.set_item_disabled(menu.get_item_index(99), true)
	menu.add_item("Mikan v%s — a Hack Club pet" % VERSION, 98)
	menu.set_item_disabled(menu.get_item_index(98), true)

	menu.position = Vector2i(at)
	menu.popup()
	menu_open = true


func _on_menu_id(id: int) -> void:
	match id:
		1:
			state = State.COME
			come_time = 5.0
		2:
			if state == State.SLEEP:
				state = State.IDLE
				state_time = randf_range(1.5, 3.0)
			else:
				state = State.SLEEP
				state_time = randf_range(8.0, 14.0)
		3:
			roam = !roam
			_save_config()
		11, 12, 13:
			size_name = {"11": "small", "12": "normal", "13": "big"}.get(str(id), "normal")
			_apply_size()
			_save_config()


func _count_pet() -> void:
	var today := Time.get_date_string_from_system()
	if pets_date != today:
		pets_date = today
		pets_today = 0
	pets_today += 1
	_save_config()


func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	size_name = cfg.get_value("mikan", "size", "normal")
	roam = cfg.get_value("mikan", "roam", true)
	pets_date = cfg.get_value("mikan", "pets_date", "")
	pets_today = cfg.get_value("mikan", "pets_today", 0)


func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("mikan", "size", size_name)
	cfg.set_value("mikan", "roam", roam)
	cfg.set_value("mikan", "pets_date", pets_date)
	cfg.set_value("mikan", "pets_today", pets_today)
	cfg.save(CONFIG_PATH)


func _play_meow() -> void:
	"""Synthesize a tiny 'mrrp!' — a rising-falling glide with vibrato."""
	meow_player.play()
	var pb := meow_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var rate := 44100.0
	var n := int(rate * 0.35)
	for i in range(n):
		var t := float(i) / rate
		# base pitch: 520 Hz rising to 780 then falling to 430
		var f: float = 520.0 + 260.0 * sin(PI * clampf(t / 0.35, 0.0, 1.0))
		f += 18.0 * sin(2.0 * PI * 28.0 * t)  # vibrato
		var env: float = clampf(1.0 - t / 0.35, 0.0, 1.0)
		env = pow(env, 0.7) as float
		var sample: float = sin(TAU * f * t) * 0.25 * env
		pb.push_frame(Vector2(sample, sample))
