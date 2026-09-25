class_name Combatant extends Resource

signal died(combatant : Combatant)
signal status_effect_applied(status_name : String)
signal stat_updated(combatant : Combatant)

@export var combatant_name : String = "default"
@export var rpg_class : RPGClass = null

@export var stealable_item : InventoryData = null

@export var helmet_inv_data : InventoryDataHelmet = InventoryDataHelmet.new()
@export var chest_inv_data : InventoryDataChestplate = InventoryDataChestplate.new()
@export var greeves_inv_data : InventoryDataGreeves = InventoryDataGreeves.new()
@export var boots_inv_data : InventoryDataBoots = InventoryDataBoots.new()
@export var ring1_inv_data : InventoryDataRing = InventoryDataRing.new()
@export var ring2_inv_data : InventoryDataRing = InventoryDataRing.new()
@export var offhand_inv_data : InventoryDataOffhand = InventoryDataOffhand.new()
@export var weapon_inv_data : InventoryDataWeapon = InventoryDataWeapon.new()

@export var texture : Texture2D
@export var frame_width : int = 16
@export var frame_height : int = 32

enum CombatantState {
	idle, 		#atb gauge filling -> 0
	ready,		#atb gauge full, awaiting input -> 1
	acting,		#preforming action -> 2
	casting,	#using ability -> 3
	stunned,	#can't act temp -> 4
	dead		#can't act -> 5
}

var equipment_effect : Effect
var status_effects : Array[StatusEffect]

var atb_gauge : int = 0 #0.0 - 100.0
const MAX_ATB : int = 100
@export var is_ally : bool = false
@export var dodge_chance : int = 0

var current_state : CombatantState = CombatantState.idle

@export var prepped_abilities : Array[Ability] = []
@export var all_abilities  : Array[Ability] = []
@export var max_abilities : int = rpg_class.current_level if rpg_class else 1

var is_in_queue : bool = false

const FIST = preload("uid://cb7htn8hlmxdj")

var queued_action

func get_hunger() -> int:
	return rpg_class.get_hunger()

func set_hunger(new_hunger : int):
	rpg_class.set_hunger(new_hunger)
	stat_updated.emit(self)

func get_max_hunger() -> int:
	return rpg_class.get_max_hunger()

func get_health() -> int:
	return rpg_class.get_health()

func set_health(new_health : int):
	rpg_class.set_health(new_health)
	stat_updated.emit(self)

func get_max_health() -> int:
	return rpg_class.get_max_health()

func get_speed() -> int:
	return rpg_class.get_speed()

func set_speed(value : int):
	if value < 0:
		rpg_class.speed = 0
	rpg_class.speed = value

func reset_speed():
	rpg_class.reset_speed()

func increase_speed(new_speed : int):
	set_speed(new_speed + get_speed())

func get_equipment_effects(): #executed at the beginning of combat for each combatant
	var equipment_array : Array = []
	var output : Effect = Effect.new()
	
	if helmet_inv_data.slot_datas[0]:
		equipment_array.append(helmet_inv_data.slot_datas[0].item_data.get_effect())
	if chest_inv_data.slot_datas[0]:
		equipment_array.append(chest_inv_data.slot_datas[0].item_data.get_effect())
	if greeves_inv_data.slot_datas[0]:
		equipment_array.append(greeves_inv_data.slot_datas[0].item_data.get_effect())
	if boots_inv_data.slot_datas[0]:
		equipment_array.append(boots_inv_data.slot_datas[0].item_data.get_effect())
	if ring1_inv_data.slot_datas[0]:
		equipment_array.append(ring1_inv_data.slot_datas[0].item_data.get_effect())
	if ring2_inv_data.slot_datas[0]:
		equipment_array.append(ring2_inv_data.slot_datas[0].item_data.get_effect())
	
	if equipment_array.is_empty():
		return
	
	output.combine(equipment_array)
	
	equipment_effect = output

func get_stats() -> Array:
	return rpg_class.get_stats()

func weapon_equipped() -> bool:
	if weapon_inv_data.slot_datas[0] and weapon_inv_data.slot_datas[0].item_data is ItemDataWeapon:
		return true
	else:
		return false

func get_weapon() -> ItemDataWeapon:
	if weapon_equipped():
		return weapon_inv_data.slot_datas[0].item_data
	else:
		return FIST

func change_health(change : int):
	set_health( get_health() + change )
	#hp_changed.emit(get_health(), get_max_health())
	if get_health() <= 0:
		current_state = CombatantState.dead
		died.emit(self)

func change_hunger(change : int):
	set_hunger( get_hunger() + change )
	#hunger_changed.emit(get_hunger(), get_max_health())
	if get_hunger() <= 0:
		#status_effects.append(HUNGRY_DEBUFF)
		status_effects.append(preload("uid://su7dn4tjp65w"))
 
func get_combatant_name() -> String:
	return self.combatant_name

func can_act() -> bool: #atb gauge is full, alive and isn't sleeping
	#var sleep_status : Array = has_status(preload("uid://yj0upoagb63x"))
	return has_full_atb() and is_alive()# and sleep_status[0] == false

func is_alive() -> bool:
	return get_health() > 0

func increase_atb():
	atb_gauge += get_speed()
	stat_updated.emit(self)
	if atb_gauge > MAX_ATB:
		atb_gauge = MAX_ATB

func has_full_atb() -> bool:
	return atb_gauge >= MAX_ATB

func get_random_atb(): #called at start of combat for each combatant
	atb_gauge = randi_range(0, get_speed() + 10) #0 - 30

func reset_atb():
	atb_gauge = 0
	stat_updated.emit(self)
	#current_state = CombatantState.idle

func take_damage(total_dmg : int):
	change_health(-1 * total_dmg)

func has_status(status_effect : StatusEffect) -> Array:
	var output : Array = [false,null]
	var index : int = 0
	for effect in status_effects:
		if effect.name == status_effect.name:
			output[0] = true
			output[1] = index
		index += 1
	return output

func add_status(status_effect : StatusEffect):
	var location_array = has_status(status_effect)
	if location_array[0] == true:
		if status_effects[location_array[1]].turn_duration == -1:
			return
		status_effects[location_array[1]].turn_duration += status_effect.turn_duration
	else: #status_effect not in array
		status_effects.append(status_effect)
		status_effect_applied.emit(status_effect)

func remove_status(status_effect : StatusEffect) -> bool:
	var removed : bool = false
	var location_array = has_status(status_effect)
	
	if location_array[0] == true:
		status_effects.pop_at(location_array[1])
		removed = true
	
	return removed

func apply_status_effects():
	for s in status_effects:
		if s.effect.has_damage():
			take_damage(s.effect)
		
		status_effects = status_effects.filter(func(d):
			if d.turn_duration == -1: 
				return true
			d.turn_duration -= 1
			if d.turn_duration <= 0:
				return false
			return true
			)

func tick_status_effects():
	for s in status_effects:
		if s.dmg_over_turn > 0:
			change_health(-1 * s.dmg_over_turn)
	
	status_effects = status_effects.filter(func(s):
		if s.duration == -1: return true
		s.duration -= 1
		if s.duration <= 0:
			return false
		return true
	)

func get_total_dmg_multi() -> float:
	var output : float = 0
	var i : int = 0
	for s in status_effects:
		if s.dmg_multiplier != 0:
			output += s.dmg_multiplier
			i += 1
	return output/i

func make_basic_attack() -> Ability:
	var output : Ability = Ability.new()
	var weapon : ItemDataWeapon = get_weapon() #returns weapon equiped otherwise is a fist
	
	output.ability_name = "basic attack"
	output.effect = weapon.effect
	if is_ally:
		output.target_type = Ability.TargetType.single_enemy
	else:
		output.target_type = Ability.TargetType.single_ally
	output.ability_type = Ability.AbilityType.damage
	output.accuracy = weapon.accuracy
	return output

func override_rpg_stats(stat_array : Array[int]):
	rpg_class.set_stats(stat_array)

func get_size() -> Vector2:
	return Vector2(frame_width,frame_height)

func can_afford(ability : Ability) -> bool:
	return get_hunger() >= ability.hunger_cost

func update_stats() -> void:
	rpg_class.update_stats()
