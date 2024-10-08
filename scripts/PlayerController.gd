extends CharacterBody3D

@export var BASE_MOVEMENT_SPEED : float = 3
@export var WALK_MODIFIER : float = .25
@export_range(1, 10, .1) var CROUCH_ANIMATION_SPEED : float = 1.0
@export var CROUCH_MODIFIER : float = .5
@export var UNCROUCH_SHAPECAST : ShapeCast3D
@export var MOUSE_SENSITIVITY := 1.0
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
@export var JUMP_IMPLUSE : float = 4.0

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
var _is_crouching : bool = false
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
	
	# Add self as exception to shapecast collisions
	UNCROUCH_SHAPECAST.add_exception(self)

# Main function that will handle inputs.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("walk"):
		toggle_walk()
	if event.is_action_pressed("crouch"):
		toggle_crouch()		
	if event.is_action_pressed("jump") and !_is_crouching:
		jump()		
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
		_current_speed = _current_speed / WALK_MODIFIER
		_is_walking = false
		
	else:
		_current_speed = _current_speed * WALK_MODIFIER
		_is_walking = true
		
# Toggles crouch with ctrl key.
func toggle_crouch():
	if _is_crouching and UNCROUCH_SHAPECAST.is_colliding() == false:
		_current_speed = _current_speed / CROUCH_MODIFIER
		ANIMATIONPLAYER.play("Crouch", -1, -CROUCH_ANIMATION_SPEED, true)
		_is_crouching = false
		
	elif !_is_crouching:
		_current_speed = _current_speed * CROUCH_MODIFIER
		ANIMATIONPLAYER.play("Crouch", -1, CROUCH_ANIMATION_SPEED)
		_is_crouching = true

func jump():
	if is_on_floor():
		velocity.y += JUMP_IMPLUSE
	
