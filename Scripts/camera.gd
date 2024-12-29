extends Camera2D

const SHAKE_INTENSITY : float = 1.0
const SHAKE_DURATION : float = 0.2
const SHAKE_FREQUENCY : float = 30.0

var shake_timer : float = 0.0
var original_position : Vector2

func _ready() -> void:
	original_position = position

func _process(delta : float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		apply_camera_shake()
	else:
		reset_camera_position()

func start_camera_shake() -> void:
	shake_timer = SHAKE_DURATION

func apply_camera_shake() -> void:
	var shake_offset = Vector2(randf_range(-1, 1) * SHAKE_INTENSITY, randf_range(-1, 1) * SHAKE_INTENSITY)
	position = original_position + shake_offset * sin(PI * shake_timer * SHAKE_FREQUENCY)

func reset_camera_position() -> void:
	position = original_position
