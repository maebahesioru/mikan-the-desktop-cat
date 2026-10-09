extends Node2D
## Mikan — a tiny orange cat that lives on your desktop.
## She walks along the bottom of your screen, stops to rest, falls asleep
## if you leave her alone, and you can pick her up and drop her.

const SPEED := 70.0        # walking speed px/s
const FALL_SPEED := 900.0  # gravity for dropping
const PET_W := 96.0        # on-screen width of the pet
const PET_H := 96.0

enum State { WALK, IDLE, SLEEP, FALL, DRAG, HOP }

var state: State = State.WALK
var dir := 1
var state_time := 0.0
var anim_time := 0.0
var fall_vy := 0.0
var drag_offset := Vector2.ZERO
var hop_vy := 0.0
var last_click_time := 0.0
var frames := {}
var sprite: Sprite2D
var win_size := Vector2(1920, 1080)
var floor_y := 0.0


func _ready() -> void:
	frames = {
		"walk": [load("res://assets/sprites/walk1.png"), load("res://assets/sprites/walk2.png")],
		"idle": [load("res://assets/sprites/idle1.png"), load("res://assets/sprites/idle2.png")],
		"sleep": [load("res://assets/sprites/sleep1.png"), load("res://assets/sprites/sleep2.png")],
		"drag": [load("res://assets/sprites/drag.png")],
	}
	sprite = Sprite2D.new()
	sprite.texture = frames["idle"][0]
	# scale the 128px art down a bit so she is not huge
	sprite.scale = Vector2(PET_W / 128.0, PET_H / 128.0)
	add_child(sprite)

	win_size = Vector2(DisplayServer.screen_get_size())
	get_window().size = Vector2i(win_size)
	floor_y = win_size.y - PET_H * 0.55
	position = Vector2(win_size.x * 0.5, floor_y)
	state_time = randf_range(2.0, 5.0)
	_update_passthrough()


func _update_passthrough() -> void:
	# clicks only land on the cat; everything else passes through to the desktop
	var r := Rect2(position - Vector2(PET_W, PET_H) * 0.5, Vector2(PET_W, PET_H))
	var poly := PackedVector2Array([
		r.position,
		Vector2(r.end.x, r.position.y),
		r.end,
		Vector2(r.position.x, r.end.y),
	])
	DisplayServer.window_set_mouse_passthrough(poly)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and state != State.DRAG:
			# only react if the click is on the cat
			var local := get_local_mouse_position()
			if abs(local.x) < PET_W * 0.5 and abs(local.y) < PET_H * 0.5:
				# double-click = she hops!
				var now_t := Time.get_ticks_msec() / 1000.0
				if now_t - last_click_time < 0.35 and state != State.HOP:
					state = State.HOP
					hop_vy = -620.0
					anim_time = 0.0
					last_click_time = 0.0
					return
				last_click_time = now_t
				state = State.DRAG
				drag_offset = position - get_global_mouse_position()
				anim_time = 0.0
		elif not event.pressed and state == State.DRAG:
			# dropped — she falls to the floor
			state = State.FALL
			fall_vy = 0.0


func _process(delta: float) -> void:
	anim_time += delta
	match state:
		State.WALK:
			position.x += SPEED * dir * delta
			if position.x < PET_W * 0.5:
				position.x = PET_W * 0.5
				dir = 1
			elif position.x > win_size.x - PET_W * 0.5:
				position.x = win_size.x - PET_W * 0.5
				dir = -1
			sprite.texture = frames["walk"][int(anim_time * 5.0) % 2]
			sprite.flip_h = dir < 0
			state_time -= delta
			if state_time <= 0.0:
				state = State.IDLE
				state_time = randf_range(2.0, 4.5)
		State.IDLE:
			sprite.texture = frames["idle"][int(anim_time * 1.6) % 2]
			state_time -= delta
			if state_time <= 0.0:
				if randf() < 0.25:
					state = State.SLEEP
					state_time = randf_range(4.0, 9.0)
				else:
					state = State.WALK
					state_time = randf_range(2.5, 7.0)
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
		State.DRAG:
			position = get_global_mouse_position() + drag_offset
			# keep her on screen while held
			position.x = clampf(position.x, PET_W * 0.5, win_size.x - PET_W * 0.5)
			position.y = clampf(position.y, PET_H * 0.5, win_size.y - PET_H * 0.5)
			sprite.texture = frames["drag"][0]
			sprite.flip_h = false
	_update_passthrough()
