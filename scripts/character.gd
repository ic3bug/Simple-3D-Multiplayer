extends KinematicBody
class_name Character

# Movement variables
var GRAVITY = -24.8
var MAX_SPEED = 6
var AIR_SPEED = 5
var SPRINT_SPEED = 12
var WATER_SPEED = 3
var JUMP_FORCE = 9
var ACCEL = 6
var DECEL = 6
var AIR_ACCEL = 3
var AIR_DECEL = 3
var WATER_ACCEL = 1
var WATER_DECEL = 1

# Movement direction and velocity
var dir : Vector3
var vel : Vector3

# Camera reference
var camera : Camera

# Commands
# An enum is used for readability
# Also a dictionary can be used
enum Command { FORWARD, BACKWARD, LEFT, RIGHT, JUMP, SPRINT, PRIMARY, SECONDARY }
var cmd = [false, false, false, false, false, false, false, false]

# States
# Useful for animations and animation transitions
var state : int = 0 setget set_state
signal state_entered
signal state_exited
enum State { AIR, WATER, GROUND, DEAD }

# Health
# We are using a setter function
var health : int = 100 setget set_health

func _ready():
	# Get the camera reference 
	camera = $controller/camera
	# Connect state changing events
	var _state_entered = connect("state_entered", self, "_on_state_entered")
	var _state_exited = connect("state_exited", self, "_on_state_exited")

func _physics_process(delta):
	if camera != null:
		# Direction is controlled by the commands to the character
		# Camera's Z basis is a local forward backward Z axis.
		# X is for right and left movement.
		dir = (int(cmd[Command.FORWARD]) - int(cmd[Command.BACKWARD])) * camera.transform.basis.z * -1
		dir += (int(cmd[Command.RIGHT]) - int(cmd[Command.LEFT])) * camera.transform.basis.x
	# Normalize direction so the diagonal movement doesn't exceed 1
	dir = dir.normalized()

	# Handling states
	match state:
		State.AIR:
			# Air movement
			# Reset the Y direction
			dir.y = 0
			# Apply gravity
			vel.y += delta * GRAVITY
			# Calculate horizontal velocity separately
			# We can't fly up and down
			var hvel = vel
			hvel.y = 0
			var target = dir
			target *= AIR_SPEED
			var accel
			# If we are moving accelerate or decelerate elsewise
			if dir.dot(hvel) > 0:
				accel = AIR_ACCEL
			else:
				accel = AIR_DECEL
			# Interpolation is used for smooth movement based on acceleration
			hvel = hvel.linear_interpolate(target, accel * delta)
			vel.x = hvel.x
			vel.z = hvel.z
			# We are using Kinematic body's move and slide function
			# Set only Y coordinate to prevent sliding on slopes
			vel.y = move_and_slide(vel, Vector3.UP, true, 4, 0.8, false).y
			
			# Transitions
			# Transition from this state to water state if we are below the ground level
			if translation.y < 0:
				set_state(State.WATER)
			# Transition to ground state if we are touching the floor
			if is_on_floor():
				set_state(State.GROUND)
		
		State.WATER:
			# Water movement
			# We can basically fly up and down
			var target = dir
			target *= WATER_SPEED
			var accel
			if dir.dot(vel) > 0:
				accel = WATER_ACCEL
			else:
				accel = WATER_DECEL
			vel = vel.linear_interpolate(target, accel * delta)
			vel = move_and_slide(vel, Vector3.UP, false, 4, 0.8, false)

			# Transitions
			if translation.y >= 0:
				set_state(State.AIR)
		
		State.GROUND:
			# Ground movement
			dir.y = 0
			vel.y += delta * GRAVITY
			var hvel = vel
			hvel.y = 0
			var target = dir
			if cmd[5]:
				target *= SPRINT_SPEED
			else:
				target *= MAX_SPEED
			var accel
			if dir.dot(hvel) > 0:
				accel = ACCEL
			else:
				accel = DECEL
			hvel = hvel.linear_interpolate(target, accel * delta)
			vel.x = hvel.x
			vel.z = hvel.z
			vel.y = move_and_slide(vel, Vector3.UP, true, 4, 0.8, false).y
			
			# Jumping
			# Apply jump force on Y (up-down) coordinate
			if cmd[4]:
				vel.y = JUMP_FORCE
			
			# Transitions
			if translation.y < 0:
				set_state(State.WATER)
			if !is_on_floor():
				set_state(State.AIR)
		
		State.DEAD:
			pass
	
	# Update the position and rotation over network
	# If this character is controlled by the actual player - send it's position and rotation
	if $controller.has_method("is_player"):
		# RPC unreliable is faster but doesn't verify whether data has arrived or is intact
		rpc_unreliable("network_update", translation, rotation, $shape_head.rotation)

# To update data both on a server and clients "sync" is used
sync func network_update(new_translation, new_rotation, head_rotation):
	translation = new_translation
	rotation = new_rotation
	$shape_head.rotation = head_rotation

# If character has been hit apply damage and knockback
func hit(damage, knockback, dealer):
	vel = (global_transform.origin - dealer.global_transform.origin).normalized() * knockback
	set_health(health - damage)

# State setter function
func set_state(value):
	emit_signal("state_exited", state)
	state = value
	emit_signal("state_entered", state)

# State events
func _on_state_entered(_new_state):
	pass
func _on_state_exited(_exited_state):
	pass

# Health setter function
func set_health(value):
	health = value
	if health <= 0:
		set_state(State.DEAD)
