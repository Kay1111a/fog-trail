class_name TrailStages
extends RefCounted
## Campaign order. All stages use the same hiker, pickups, hazards, and checkpoint rules.

const NAMES: Array[String] = [
	"Trailhead", "Creek Steps", "Moss Steps", "Pine Ledges", "Fern Ravine",
	"Cloud Crossing", "Switchback Ridge", "Stone Teeth", "High Traverse", "Summit Run",
]
const SCENES: Array[PackedScene] = [
	preload("res://scenes/trail.tscn"),
	preload("res://scenes/stages/02-creek-steps.tscn"),
	preload("res://scenes/stages/03-moss-steps.tscn"),
	preload("res://scenes/stages/04-pine-ledges.tscn"),
	preload("res://scenes/stages/05-fern-ravine.tscn"),
	preload("res://scenes/stages/06-cloud-crossing.tscn"),
	preload("res://scenes/stages/07-switchback-ridge.tscn"),
	preload("res://scenes/stages/08-stone-teeth.tscn"),
	preload("res://scenes/stages/09-high-traverse.tscn"),
	preload("res://scenes/stages/10-summit-run.tscn"),
]
const COUNT := 10
