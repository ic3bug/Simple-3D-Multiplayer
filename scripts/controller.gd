extends Node
class_name Controller

# Get the reference to a character
# All controllers, like AI or a player inherit parameters of this class
onready var character : Character = get_parent()

func _ready():
	pass
