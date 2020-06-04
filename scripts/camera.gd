extends Camera

var MOUSE_SENSITIVITY = 1

# Get a reference to the character this controller is controlling
onready var character : Character = owner.get_parent()
# Head shape is used to attach the camera
onready var head : Spatial = character.get_node("shape_head")

func _ready():
	# Make the character invisible to the camera
	set_character_visible(false)

func _physics_process(_delta):
	# Camera copies the position and rotation of the head shape
	global_transform = head.global_transform

func _input(event):
	# If we are moving the mouse and mouse is captured within the window
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the head shape. Camera copies it's rotation.
		head.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -0.05))
		# Clamp rotation of the head on X axis
		var head_rotation = head.rotation_degrees
		head_rotation.x = clamp(head_rotation.x, -80, 80)
		head.rotation_degrees = head_rotation
		# Rotate the body of the character
		character.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -0.05))

func set_character_visible(value):
	# Render layers are used, for each mesh, so the shadows can still be seen
	# Check the cull mask of the camera node. 10th bit is set to false.
	character.get_node("shape_head/head").set_layer_mask_bit(0, value)
	character.get_node("shape_head/head").set_layer_mask_bit(10, !value)
	character.get_node("shape_head/eye_L").set_layer_mask_bit(0, value)
	character.get_node("shape_head/eye_L").set_layer_mask_bit(10, !value)
	character.get_node("shape_head/eye_R").set_layer_mask_bit(0, value)
	character.get_node("shape_head/eye_R").set_layer_mask_bit(10, !value)
	character.get_node("shape_body/body").set_layer_mask_bit(0, value)
	character.get_node("shape_body/body").set_layer_mask_bit(10, !value)
