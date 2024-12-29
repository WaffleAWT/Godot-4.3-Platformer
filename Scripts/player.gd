extends CharacterBody2D

const MAX_SPEED : float = 75.0
const ACCELERATION : float = 50.0
const DECELERATION : float = 50.0
const JUMP_FORCE : float = 275.0
const WALL_JUMP_FORCE : float = 1500.0

const NORMAL_SCALE : Vector2 = Vector2(1.0, 1.0)
const SQUASH_SCALE : Vector2 = Vector2(0.8, 1.2)
const SCALE_SPEED : float = 15.0

var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var on_wall : bool = false
var has_double_jump : bool = true
var was_in_air : bool = false

@export var do_effects : bool = true

@export_group("Refrences")
@export var graphics : AnimatedSprite2D
@export var wall_ray : RayCast2D
@export var wall_timer : Timer
@export var ghost_effect_scene : PackedScene
@export var ripple_animation_player : AnimationPlayer
@export var camera : Camera2D
@export var puff_effect_scene : PackedScene
@export var jump_sound_effect : AudioStreamPlayer
@export var double_jump_sound_effect : AudioStreamPlayer
@export var land_sound_effect : AudioStreamPlayer

func _physics_process(delta : float) -> void:
	apply_gravity(delta)
	update_wall_ray()
	
	if get_input_direction() != 0.0 and not on_wall:
		accelerate(get_input_direction(), delta)
	else:
		decelerate(delta)
	
	if is_on_floor() and was_in_air:
		if do_effects:
			spawn_puff_effect()
			land_sound_effect.playing = true
	was_in_air = not is_on_floor()
	
	if is_on_floor():
		has_double_jump = true
	
	squash_and_stretch(delta)
	animate()
	
	move_and_slide()

func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or on_wall or has_double_jump):
			if not is_on_floor() and not on_wall:
				has_double_jump = false
				spawn_ghost_effect()
				play_ripple_effect()
				shake_camera()
				if do_effects:
					double_jump_sound_effect.playing = true
			else:
				if do_effects:
					jump_sound_effect.playing = true
			jump()

func apply_gravity(delta_time : float) -> void:
	if not on_wall:
		velocity.y += gravity * delta_time
	else:
		velocity.y += (gravity * delta_time) / 4

func update_wall_ray() -> void:
	if wall_timer.is_stopped():
		on_wall = true if wall_ray.is_colliding() and not is_on_floor() and velocity.y > 0.0 else false
	else:
		on_wall = false

func get_input_direction() -> float:
	var input_direction : float = Input.get_axis("move_left", "move_right")
	return input_direction

func accelerate(player_input : float, delta_time : float) -> void:
	velocity.x = lerpf(velocity.x, player_input * MAX_SPEED, ACCELERATION * delta_time)

func decelerate(delta_time : float) -> void:
	velocity.x = lerpf(velocity.x, 0.0, DECELERATION * delta_time)

func jump() -> void:
	if on_wall:
		if not graphics.flip_h:
			velocity.x = -WALL_JUMP_FORCE
		else:
			velocity.x = WALL_JUMP_FORCE
		wall_timer.start()
		has_double_jump = true
	velocity.y = -JUMP_FORCE

func spawn_ghost_effect() -> void:
	if do_effects:
		var ghost_effect : AnimatedSprite2D = ghost_effect_scene.instantiate()
		ghost_effect.flip_h = graphics.flip_h
		ghost_effect.animation = graphics.animation
		ghost_effect.frame = graphics.frame
		ghost_effect.global_position = global_position
		ghost_effect.scale = graphics.scale
		get_tree().current_scene.add_child(ghost_effect)

func play_ripple_effect() -> void:
	if do_effects:
		ripple_animation_player.play("animate")

func shake_camera() -> void:
	if do_effects:
		camera.start_camera_shake()

func spawn_puff_effect() -> void:
	if do_effects:
		var puff_effect : GPUParticles2D = puff_effect_scene.instantiate()
		puff_effect.global_position = global_position
		puff_effect.position.y += 7.0
		get_tree().current_scene.add_child(puff_effect)

func squash_and_stretch(delta_time : float) -> void:
	if do_effects:
		if not is_on_floor() and not on_wall:
				graphics.scale = lerp(graphics.scale, SQUASH_SCALE, SCALE_SPEED * delta_time)
		else:
			graphics.scale = lerp(graphics.scale, NORMAL_SCALE, SCALE_SPEED * delta_time)

func animate() -> void:
	if not on_wall:
		if is_on_floor():
			if velocity.x != 0.0:
				graphics.play("run")
			else:
				graphics.play("idle")
		else:
			if velocity.y > 0.0:
				graphics.play("fall")
			else:
				graphics.play("jump")
	else:
		graphics.play("wall")
	
	if velocity.x != 0.0:
		graphics.flip_h = true if velocity.x < 0.0 else false
		wall_ray.target_position.x = -5.0 if velocity.x < 0.0 else 5.0
