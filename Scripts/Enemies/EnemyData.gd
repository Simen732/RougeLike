extends Resource
class_name EnemyData

@export var enemy_name: String
@export var enemy_scene: PackedScene
@export var spawn_weight: int = 1  # Higher = more likely to spawn
@export var min_encounter_level: int = 1  # Minimum level for this enemy to appear
@export var max_count_per_encounter: int = 3  # Maximum of this enemy type per encounter

func _init(p_name: String = "", p_scene: PackedScene = null, p_weight: int = 1, p_min_level: int = 1, p_max_count: int = 3):
	enemy_name = p_name
	enemy_scene = p_scene
	spawn_weight = p_weight
	min_encounter_level = p_min_level
	max_count_per_encounter = p_max_count