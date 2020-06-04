extends Node

# Port must be open in router settings
const PORT = 27015
const MAX_PLAYERS = 32

# To play over internet check your IP and change it here
export var ip : String = "localhost"
# To use a background server download the server export template without graphics and audio from:
# https://godotengine.org/download/server
# And choose it as a custom template upon export
export var background_server : bool = false

# Preload a character and controllers
# Character is a node which we control by the controller node
# This way we can extend the Controller class to create an AI controller
# Peer controller represents other players in the network
onready var character_scene = preload("res://scenes/character.tscn")
onready var player_scene = preload("res://scenes/player.tscn")
onready var peer_scene = preload("res://scenes/peer.tscn")

func _ready():
	# If we are exporting this game as a server for running in the background
	if background_server:
		# Just create server
		create_server()
		# To keep it simple we are creating an uncontrollable server's character to prevent errors
		# TO-DO: Create players upon reading configuration from the server
		create_player(1, false)
	else:
		# Elsewise connect menu button events
		var _host_pressed = $display/menu/host.connect("pressed", self, "_on_host_pressed")
		var _connect_pressed = $display/menu/connect.connect("pressed", self, "_on_connect_pressed")
		var _quit_pressed = $display/menu/quit.connect("pressed", self, "_on_quit_pressed")
		
# When a Host button is pressed
func _on_host_pressed():
	# Create the server
	create_server()
	# Create our player, 1 is a reference for a host/server
	create_player(1, false)
	# Hide a menu
	$display/menu.visible = false
	$display/output.text = ""

# When Connect button is pressed
func _on_connect_pressed():
	# Connect network events
	var _peer_connected = get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	var _peer_disconnected = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	var _connected_to_server = get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	var _connection_failed = get_tree().connect("connection_failed", self, "_on_connection_failed")
	var _server_disconnected = get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	# Set up an ENet instance
	var network = NetworkedMultiplayerENet.new()
	network.create_client(ip, PORT)
	get_tree().set_network_peer(network)

func _on_quit_pressed():
	# Quitting the game
	get_tree().quit()

func _on_peer_connected(id):
	# When other players connect a character and a child player controller are created
	create_player(id, true)

func _on_peer_disconnected(id):
	# Remove unused nodes when player disconnects
	remove_player(id)

func _on_connected_to_server():
	# Upon successful connection get the unique network ID
	# This ID is used to name the character node so the network can distinguish the characters
	var id = get_tree().get_network_unique_id()
	$display/output.text = "Connected! ID: " + str(id)
	# Hide a menu
	$display/menu.visible = false
	# Create a player
	create_player(id, false)

func _on_connection_failed():
	# Upon failed connection reset the RPC system
	get_tree().set_network_peer(null)
	$display/output.text = "Connection failed"

func _on_server_disconnected():
	# If server disconnects just reload the game
	var _reloaded = get_tree().reload_current_scene()

func create_server():
	# Connect network events
	var _peer_connected = get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	var _peer_disconnected = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	# Set up an ENet instance
	var network = NetworkedMultiplayerENet.new()
	network.create_server(PORT, MAX_PLAYERS)
	get_tree().set_network_peer(network)

func create_player(id, is_peer):
	# Create a character with a player or a peer controller attached
	var controller : Controller
	# Check whether we are creating a player or a peer controller
	if is_peer:
		# Peer controller represents other connected players on the network
		controller = peer_scene.instance()
	else:
		# Player controller is our input which controls the character node
		controller = player_scene.instance()
	# Instantiate the character
	var character = character_scene.instance()
	# Attach the controller to the character
	character.add_child(controller)
	# Set the controller's name for easier reference by the character
	controller.name = "controller"
	# Set the character's name to a given network id for synchronization
	character.name = str(id)
	# Add the character to this (main) scene 
	$characters.add_child(character)
	# Spawn the character at random location within 40 units from the center
	character.global_transform.origin = random_point(40, 20)
	# Enable the controller's camera if it's not an other player 
	controller.get_node("camera").current = !is_peer

func remove_player(id):
	# Remove unused characters
	$characters.get_node(str(id)).free()

func random_point(area, height):
	# Random point within some area units
	randomize()
	return Vector3(rand_range(-area, area), height, rand_range(-area, area))
