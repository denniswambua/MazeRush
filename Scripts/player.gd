extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed = 5
var jump_speed = 4
var mouse_sensitivity = 0.002

@onready var map_camera = $SubViewportContainer/SubViewport/MapCamera
@onready var step_sound = $FootSteps
@onready var animation_player = $AnimationPlayer


func _process(delta: float) -> void:
	map_camera.position = position + Vector3(0,15,0)

func _physics_process(delta):
	velocity.y += -gravity * delta
	var input = Input.get_vector("left", "right", "forward", "back")
	var movement_dir = transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = movement_dir.x * speed
	velocity.z = movement_dir.z * speed
	
	if is_on_floor() and movement_dir != Vector3():
		animation_player.play("walk")

	move_and_slide()
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
		
func _input(event):
	if event is InputEventMouseMotion  and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

		
func set_active_camera(start=Vector3(0.5,0.5,0.5)):
	position = start
	$Camera3D.make_current()
	
func play_footstep():
	step_sound.pitch_scale =  randf_range(0.8, 1.2)
	step_sound.play()
