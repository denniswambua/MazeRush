extends Node3D

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {
	Vector3(1, 0, 0): E,
	Vector3(-1, 0, 0): W,
	Vector3(0, 0, 1): S,
	Vector3(0, 0, -1): N
}


@onready var map: GridMap = $GridMap
@onready var gui = $Gui
@onready var ui = $UI
@onready var ui_score = $Gui/NinePatchRect/HBoxContainer/Collection
@onready var seed_label = $Gui/NinePatchRect2/HBoxContainer/Seed
@onready var size_label = $Gui/NinePatchRect2/HBoxContainer/Size

@onready var seed_field = $UI/MarginContainer/VBoxContainer/HBoxContainer2/Seed
@onready var width_field = $UI/MarginContainer/VBoxContainer/HBoxContainer/width
@onready var height_field = $UI/MarginContainer/VBoxContainer/HBoxContainer3/height

@onready var continue_button = $Gui/VBoxContainer/Continue
@onready var quit_button = $Gui/VBoxContainer/Quit
@onready var intro_text = $Gui/VBoxContainer/intro

var intro = "Can you find all the coins?"
var outro =  "Hurray! You found all of them."


var Player = preload("res://Scenes/player.tscn")
var Coin = preload("res://Scenes/coin.tscn")
var player

var started =  false

func _ready():
	gui.visible = false
	ui.visible = true

func _input(event: InputEvent) -> void:
	# check if pause action is pressed and pause the game.
	if started and event.is_action_pressed("pause"):
		pause_game()
	
func pause_game():
	# pause the game
	if !get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		if started:
			continue_button.show()
			intro_text.show()
		quit_button.show()
		print("Game paused ...")

func resume_game():
	print("Resuming the game ...")
	continue_button.hide()
	quit_button.hide()

	# resume the game
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false


func start():
	started = true
	intro_text.text = intro
	continue_button.hide()
	quit_button.hide()

	gui.show()
	ui.hide()

	randomize()
	if !Global.maze_seed:
		Global.maze_seed = randi()
	seed(Global.maze_seed)
	seed_label.text = "Seed: " + str(Global.maze_seed)
	
	print("Seed: ", Global.maze_seed)
	Global.total_coins = 0
	var width = Global.maze_width
	var height = Global.maze_height
	size_label.text = "Size "+ str(width) + " by "+ str(height)
	
	print("Generating maze: " + str(width) + " by " + str(height))
	
	make_maze(width, height)
	update_collection()
	
	print("Rewards to be collected: ", Global.total_coins)
	add_player()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var tween = get_tree().create_tween()
	tween.tween_property(intro_text, "visible", false, 5).set_trans(Tween.TRANS_SINE)

func check_neighbors(cell, unvisited):
	# returns an array of cell's unvisited neighbors
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list
	
func make_maze(width, height):
	var unvisited = []  # array of unvisited tiles
	var stack = []
	var previous
	var max_stack = 0
	# fill the map with solid tiles
	map.clear()
	for x in range(width):
		for z in range(height):
			unvisited.append(Vector3(x, 0, z))
			map.set_cell_item(Vector3(x, 0, z), N|E|S|W)
	var current = Vector3(0, 0, 0)
	unvisited.erase(current)
	
	while unvisited:
		var neighbors = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)
			# remove walls from *both* cells
			var dir = next - current
			var current_walls = map.get_cell_item(current) - cell_walls[dir]
			var next_walls = map.get_cell_item(next) - cell_walls[-dir]
			
			map.set_cell_item(current, current_walls)
			map.set_cell_item(next, next_walls)
			
			current = next
			
			unvisited.erase(current)
			
		elif stack:
			current = stack.pop_back()
			if stack.size() > max_stack:
				max_stack = stack.size()
				previous = current
				add_tressure_position(previous)			
			
		#await get_tree().create_timer(0.1).timeout

				
func add_player():
	player = Player.instantiate()
	player.set_active_camera()
	add_child(player)
	
	
func add_tressure_position(finish: Vector3):
	var reward = Coin.instantiate()
	reward.position = to_global(map.map_to_local(finish))
	reward.collected.connect(_on_coin_collected)
	add_child(reward)
	Global.total_coins += 1


func update_collection():
	# update the collection UI label by concatenating the collected coins with the total coins
	ui_score.text = str(Global.collected_coins) + "/" + str(Global.total_coins)

	if Global.collected_coins == Global.total_coins:
		# if all coins are collected, show the finish message
		intro_text.text = outro
		var tween = get_tree().create_tween()
		tween.tween_property(intro_text, "visible", true, 3)
		started = false
		tween.tween_callback(pause_game)
	# 
func _on_coin_collected():
	Global.collected_coins += 1
	update_collection()

func _on_start_pressed() -> void:
	# check if text is numeric
	if seed_field.text.is_valid_int():
		Global.maze_seed = int(seed_field.text)
	else:
		Global.maze_seed = 0
	if width_field.text.is_valid_int():
		Global.maze_width = int(width_field.text)
	else:
		Global.maze_width = 10
	if height_field.text.is_valid_int():
		Global.maze_height = int(height_field.text)
	else:
		Global.maze_height = 10
	start()


func _on_continue_pressed() -> void:
	resume_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
