extends Node

var score = 0
var maps = [
	"res://level_1.tscn",
	"res://level_2.tscn",
	"res://level_3.tscn",
	#"res://levels/level_4.tscn",
	#"res://levels/level_5.tscn"
]

# This will hold our remaining levels for the current 'round'
var remaining_maps = []

func _ready():
	# Fill the pool when the game first starts
	refill_map_pool()

func refill_map_pool():
	# Duplicate the original list so we don't break the 'maps' variable
	remaining_maps = maps.duplicate()
	# Shuffle so the order is random every time
	remaining_maps.shuffle()

func get_random_map():
	if remaining_maps.size() == 0:
		refill_map_pool()
	
	# Pop the last map off the list (removes it so it can't be picked again)
	var next_map = remaining_maps.pop_back()
	
	print("Next Level: ", next_map)
	print("Levels left in rotation: ", remaining_maps.size())
	
	return next_map

func add_point():
	score += 1
	print("Current Score: ", score)
