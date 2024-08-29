extends CharacterBody3D

@export var BASE_MOVEMENT_SPEED : float = 3
@export var WALK_MODIFIER : float = .25
@export var MOUSE_SENSITIVITY := 1.0
@export var CAMERA_CONTROLLER : Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Limits on head movement up and down.
var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
var TILT_UPPER_LIMIT := deg_to_rad(90.0)

# Mouse vars.
var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation: Vector3
var _camera_rotation: Vector3


# Movement vars.
var _is_walking : bool = false
var _current_speed : float = BASE_MOVEMENT_SPEED

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	_update_camera(delta)
	
	var input_dir = Input.get_vector("move_left","move_right","move_forward","move_backward")
	# Normalize to prevent faster movement when multiple buttons are pressed.
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() 
	
	if direction:
		velocity.x = direction.x * _current_speed
		velocity.z = direction.z * _current_speed
	else:
		velocity.x = move_toward(velocity.x, 0 ,_current_speed)
		velocity.z = move_toward(velocity.z, 0 ,_current_speed)
	move_and_slide()

func _update_camera(delta: float) -> void:
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)
	
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	_rotation_input = 0.0
	_tilt_input = 0.0

# Makes sure our mouse movements can be seen by the engine.
func _ready() -> void:
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED

# Main function that will handle inputs.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("walk"):
		toggle_walk()	
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
	
		
# Toggles walking with shift key.
func toggle_walk():
	if _is_walking:
		_current_speed = BASE_MOVEMENT_SPEED
		_is_walking = false
		
	else:
		_current_speed = BASE_MOVEMENT_SPEED * WALK_MODIFIER
		_is_walking = true
	
