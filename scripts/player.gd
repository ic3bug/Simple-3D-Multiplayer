extends Controller
class_name Player

func _ready():
	# Capture the mouse cursor within the window frame
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(_delta):
	# Send our input to the character
	character.cmd[0] = Input.is_action_pressed("forward")
	character.cmd[1] = Input.is_action_pressed("backward")
	character.cmd[2] = Input.is_action_pressed("left")
	character.cmd[3] = Input.is_action_pressed("right")
	character.cmd[4] = Input.is_action_just_pressed("jump")
	character.cmd[5] = Input.is_action_pressed("sprint")
	character.cmd[6] = Input.is_action_just_pressed("primary")
	character.cmd[7] = Input.is_action_just_pressed("secondary")
	
	# Escape toggles the mouse mode
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# For type checking
func is_player():
	return true
