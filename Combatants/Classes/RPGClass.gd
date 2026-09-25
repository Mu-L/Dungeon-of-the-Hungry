class_name RPGClass extends Resource

#tag skills
@export_range(1,100,1) var strength : int = 10
@export_range(1,100,1) var agility : int = 10
@export_range(1,100,1) var endurance : int = 10 
@export_range(1,100,1) var intelligence : int = 10
@export_range(1,100,1) var devotion : int = 10
@export_range(1,100,1) var cooking : int = 10
@export_range(1,100,1) var luck : int = 10


enum class_names {Berserker, Cleric, Cook, Landsknecht, Mage, Pact_Bound, Samurai, Thief, None}

@export var rpg_class_name : class_names

@export var current_level : int = 1
const MAX_LEVEL : int = 99

var speed : int # 10 + (.1 - 10)

@export var health : int = -1 #-1 when hasn't been in combat yet

@export var hunger : int = -1

func get_rpg_class() -> String:
	match rpg_class_name:
		0:
			return "berserk"
		1:
			return "cleric"
		2:
			return "cook"
		3:
			return "landsknecht"
		4:
			return "mage"
		5:
			return "pact bound"
		6:
			return "samurai"
		7:
			return "thief"
		8:
			return "none"
		_:
			return "default"

func set_stats(stat_array : Array[int]):
	strength = stat_array[0]
	agility = stat_array[1]
	endurance = stat_array[2]
	intelligence = stat_array[3]
	devotion = stat_array[4]
	cooking = stat_array[5]
	luck = stat_array[6]

func level_up() -> bool:
	if current_level >= MAX_LEVEL:
		current_level = MAX_LEVEL
		return false
	else:
		increase_stats()
		current_level += 1
		return true

func level_to_threshold(new_level : int):
	var dif = new_level - current_level
	for i in range(dif):
		level_up()

func increase_stats():
	match rpg_class_name:
		class_names.Berserker:
			strength += randi_range(1,3)
			agility += randi_range(0,2)
			endurance += randi_range(1,2)
			intelligence += randi_range(0,1)
			devotion += randi_range(0,1)
			cooking += randi_range(0,1)
			luck += randi_range(0,2)
		class_names.Cleric:
			strength += randi_range(0,2)
			agility += randi_range(0,2)
			endurance += randi_range(1,2)
			intelligence += randi_range(0,2)
			devotion += randi_range(1,3)
			cooking += randi_range(0,1)
			luck += randi_range(0,2)
		class_names.Cook:
			strength += randi_range(0,2)
			agility += randi_range(0,1)
			endurance += randi_range(1,2)
			intelligence += randi_range(0,2)
			devotion += randi_range(0,2)
			cooking += randi_range(1,3)
			luck += randi_range(0,1)
		class_names.Landsknecht:
			strength += randi_range(1,2)
			agility += randi_range(1,2)
			endurance += randi_range(1,3)
			intelligence += randi_range(0,1)
			devotion += randi_range(0,2)
			cooking += randi_range(0,2)
			luck += randi_range(0,1)
		class_names.Mage:
			strength += randi_range(0,1)
			agility += randi_range(0,2)
			endurance += randi_range(0,1)
			intelligence += randi_range(1,3)
			devotion += randi_range(1,2)
			cooking += randi_range(0,2)
			luck += randi_range(1,2)
		class_names.Pact_Bound:
			strength += randi_range(0,2)
			agility += randi_range(1,2)
			endurance += randi_range(0,1)
			intelligence += randi_range(0,2)
			devotion += randi_range(1,3)
			cooking += randi_range(0,1)
			luck += randi_range(1,2)
		class_names.Samurai:
			strength += randi_range(0,2)
			agility += randi_range(1,3)
			endurance += randi_range(1,2)
			intelligence += randi_range(0,2)
			devotion += randi_range(1,2)
			cooking += randi_range(0,1)
			luck += randi_range(0,1)
		class_names.Thief:
			strength += randi_range(0,1)
			agility += randi_range(1,3)
			endurance += randi_range(0,1)
			intelligence += randi_range(0,2)
			devotion += randi_range(0,2)
			cooking += randi_range(0,2)
			luck += randi_range(1,3)
		_: #umbrella
			strength += randi_range(0,2)
			agility += randi_range(0,2)
			endurance += randi_range(0,2)
			intelligence += randi_range(0,2)
			devotion += randi_range(0,2)
			cooking += randi_range(0,2)
			luck += randi_range(0,2)

	strength = min(100, strength)
	agility = min(100, agility)
	endurance = min(100, endurance)
	devotion = min(100, devotion)
	intelligence = min(100, intelligence)
	cooking = min(100, cooking)
	luck = min(100, luck)

func reset_class_stats():
	match rpg_class_name:
		class_names.Berserker:
			set_stats([15,13,14,9,11,10,9])
		class_names.Cleric:
			set_stats([12,11,12,10,15,14,10])
		class_names.Cook:
			set_stats([12,13,14,11,10,9,15])
		class_names.Landsknecht:
			set_stats([14,13,15,11,10,12,9])
		class_names.Mage:
			set_stats([9,12,10,15,13,14,11])
		class_names.Pact_Bound:
			set_stats([9,13,11,12,14,14,10])
		class_names.Samurai:
			set_stats([12,15,14,11,13,10,9])
		class_names.Thief:
			set_stats([9,15,10,13,11,14,12])
		_:
			set_stats([10,10,10,10,10,10,10])

func get_stats() -> Array:
	return [strength,agility,endurance,intelligence,devotion,cooking,luck]

func get_health() -> int:
	return health

func get_max_health() -> int:
	return endurance * 50

func set_health(new_current_health : int):
	if new_current_health >= get_max_health():
		health = get_max_health()
	else:
		health = new_current_health

func get_hunger() -> int:
	return hunger

func get_max_hunger() -> int:
	return max(devotion, intelligence) * 20

func set_hunger(new_hunger : int):
	if new_hunger > get_max_hunger():
		hunger = get_max_hunger()
	elif new_hunger <= 0:
		hunger = 0
	else:
		hunger = new_hunger

func get_current_level() -> int:
	return current_level

func get_speed() -> int:
	return 10 + int(agility / 10)
