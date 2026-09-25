class_name Battle extends Node

signal ally_ready(combatant : Combatant)


var party : Party = preload("uid://b87ogx8bknmnh")
var allies : Array[Combatant] = party.get_party()
var enemies : Array[Combatant] = [preload("uid://1jqo1lmoi5in")]
var all_combatants : Array[Combatant] = allies + enemies

var action_queue : Queue = Queue.new()

var increase_atb : bool = true
var current_combatant : Combatant
var target_index : int = 0 #index

var battle_speed : float = .5

var selected_ability : Ability
var valid_targets : Array[Combatant] = []
var can_select_targets : bool = false
#set up

func _ready() -> void:
	ally_ready.connect(%Options.print_ally_name)
	%Options.ability_selected.connect(ally_ability_selected)
	
	if allies[0]:
		allies[0].stat_updated.connect(%player_stat_display.update_display)
		%player_stat_display.visible = true
	else:
		%player_stat_display.visible = false
	
	if allies.size() >= 2 and allies[1]:
		allies[1].stat_updated.connect(%player_stat_display2.update_display)
		%player_stat_display2.visible = true
	else:
		%player_stat_display2.visible = false
	
	if  allies.size() >= 3 and allies[2]:
		allies[2].stat_updated.connect(%player_stat_display3.update_display)
		%player_stat_display3.visible = true
	else:
		%player_stat_display3.visible = false
	
	if  allies.size() >= 4 and allies[3]:
		allies[3].stat_updated.connect(%player_stat_display4.update_display)
		%player_stat_display4.visible = true
	else:
		%player_stat_display4.visible = false
	
	initialize_combat()
	print("battle start")
	battle_loop()

func battle_loop():
	while not (win_conditions() and loss_conditions()):
		for combatant in all_combatants:
			if combatant:
				#combatant.apply_status_effects()
				combatant.increase_atb()
				
				if combatant.can_act() and combatant.is_ally and not combatant.is_in_queue: #can act and is ally
					ally_ready.emit(combatant)
					combatant.is_in_queue = true
					#print("combatant in queue")
				elif combatant.can_act() and not combatant.is_ally and not combatant.is_in_queue:#can act and is enemy
					run_enemy_turn(combatant)
		if not action_queue.is_empty():
			var next_action : QueuedAction = action_queue.dequeue()
			if is_valid_targets(next_action.targets):
				apply_abilities(next_action.ability, next_action.user, next_action.targets)
				next_action.user.is_in_queue = false
				next_action.user.reset_atb()
		await get_tree().create_timer(battle_speed).timeout

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("settings"): #for debugging
		get_tree().quit()
		for combatant in all_combatants:
			print(combatant.combatant_name)
			print(combatant.get_stats())
			print(combatant.get_health())
	if Input.is_action_just_pressed("ui_battle_left") and can_select_targets:
		target_index = ((target_index - 1) % all_combatants.size() + all_combatants.size()) % all_combatants.size()
		#TODO update visuals for targeting
		print(target_index)
	if Input.is_action_just_pressed("ui_battle_right") and can_select_targets: 
		target_index = (target_index + 1) % all_combatants.size()
		#TODO update visuals for targeting
		print(target_index)
	if Input.is_action_just_pressed("ui_battle_accept") and can_select_targets: #TODO add cond for valid targets
		#TODO figure out better way to do this
		valid_targets = get_valid_targets(selected_ability,current_combatant)
		var action : QueuedAction
		if selected_ability.target_type == Ability.TargetType.single_enemy or selected_ability.target_type == Ability.TargetType.single_ally:
			action  = QueuedAction.new(current_combatant,selected_ability,[all_combatants[target_index]])
		else:
			action = QueuedAction.new(current_combatant,selected_ability,all_combatants)
		#print(action.ability.ability_name + " added to queue")
		action_queue.enqueue(action) #current combatant's action gets added to queue upon hitting enter

func initialize_combat() -> void:
	for combatant in all_combatants:
		if combatant:
			#print(combatant.combatant_name)
			#print(combatant.rpg_class.endurance)
			#print(combatant.get_health())
			#print(combatant.get_max_health())
			if combatant.get_health() >= -1: #only applied if combatant hasn't been in combat yet
				combatant.set_health(combatant.get_max_health())
				#print(combatant.get_health())
			if combatant.get_hunger() >= -1:
				combatant.set_hunger(combatant.get_max_hunger())
			combatant.get_equipment_effects() #applies all resistances
			combatant.get_random_atb() #randomly sets atb for each combatant
			combatant.stat_updated.emit(combatant)

func hide_action_menu():
	%Options.visible = false

func show_action_menu():
	%Options.visible = true

func get_random_combatant() -> Combatant:
	return all_combatants.filter(is_alive).pick_random()

func get_random_ally() -> Combatant:
	return allies.filter(is_alive).pick_random()

func get_random_enemy() -> Combatant:
	return enemies.filter(is_alive).pick_random()

func get_valid_targets(ability : Ability, user : Combatant) -> Array[Combatant]:
	match ability.target_type:
		Ability.TargetType.single_enemy:
			return enemies.filter(is_alive)
		Ability.TargetType.all_enemies:
			return enemies.filter(is_alive)
		Ability.TargetType.random_enemy:
			return [get_random_enemy()]
		Ability.TargetType.single_ally:
			return allies.filter(is_alive)
		Ability.TargetType.all_allies:
			return allies.filter(is_alive)
		Ability.TargetType.random_ally:
			return [get_random_ally()]
		Ability.TargetType.Self:
			return [user]
		Ability.TargetType.all_combatants:
			return all_combatants.filter(is_alive)
		Ability.TargetType.random_combatant:
			return [get_random_combatant()]
	return []

func is_valid_targets(targets : Array[Combatant]) -> bool:
	for target in targets:
		if not target.is_alive():
			return false
	return true

func is_alive(combatant : Combatant) -> bool:
	return combatant.is_alive()

func apply_abilities(ability : Ability, user : Combatant, targets : Array[Combatant]):
	user.change_hunger(-1 * ability.hunger_cost)
	
	for target in targets:
		resolve_abilities(ability,user,target)

func resolve_abilities(ability : Ability, user : Combatant, target : Combatant):
	match ability.ability_type:
		Ability.AbilityType.damage:
			resolve_dmg(ability,user,target)
		Ability.AbilityType.heal:
			resolve_heal(ability,user,target)
		Ability.AbilityType.steal:
			resolve_steal(ability,user,target)
		Ability.AbilityType.add_status:
			resolve_add_status(ability,user,target)
		Ability.AbilityType.remove_status:
			resolve_remove_status(ability,user,target)
		Ability.AbilityType.revive:
			resolve_revive(ability,user,target)

func resolve_dmg(ability : Ability, user : Combatant, target : Combatant):
	var raw : int = int(ability.effect.get_total_dmg(target.equipment_effect) * user.get_total_dmg_multi())
	@warning_ignore("integer_division")
	var dmg : int = int(max(1, raw * randf_range(.9, float(user.rpg_class.luck + 50 / 100))))
	target.take_damage(dmg)

func resolve_heal(ability : Ability, user : Combatant, target : Combatant):
	var amount : int = ability.effect.health_change + int(max(user.rpg_class.devotion, user.rpg_class.intelligence))
	target.change_health(amount)

func resolve_steal(_ability : Ability, _user : Combatant, target : Combatant):
	if target.stealable_item:
		print("target has following item: %s" % [target.stealable_item.slot_datas[0].item_data.name]) #temp
	else:
		pass

func resolve_add_status(ability : Ability, _user : Combatant, target : Combatant):
	target.add_status(ability.status_effect)

func resolve_remove_status(ability : Ability, _user : Combatant, target : Combatant):
	target.remove_status(ability.status_effect)

func resolve_revive(_ability : Ability, _user : Combatant, target : Combatant):
	if target.is_alive():
		return
	target.set_health(1)

#func can_afford(user : Combatant, ability : Ability) -> bool:
	#return user.get_hunger() >= ability.hunger_cost

func run_enemy_turn(combatant : Combatant):
	var usable : Array[Ability] = combatant.prepped_abilities.filter(func(c) : return combatant.can_afford(c))
	usable.append(combatant.make_basic_attack())
	
	var chosen_ability : Ability = usable.pick_random() #TODO add some sorta enemy combatant state machine that chooses abilities and whatnot
	var targets : Array[Combatant] = get_valid_targets(chosen_ability, combatant)
	
	if targets.is_empty():
		return
	
	var is_all : bool = chosen_ability.target_type in [Ability.TargetType.all_enemies, Ability.TargetType.all_allies, Ability.TargetType.all_combatants]
	var final_targets : Array[Combatant] 
	if is_all:
		final_targets = targets
	else:
		final_targets.append(targets.pick_random())
	
	var action : QueuedAction = QueuedAction.new(combatant,chosen_ability,final_targets)
	combatant.reset_atb()
	action_queue.enqueue(action)
	

func win_conditions() -> bool: #if player wins returns true
	return false

func loss_conditions() -> bool: #if player losses returns true
	return false

func ally_ability_selected(ability : Ability, user : Combatant):
	#print(user.combatant_name + " ability selected: " + ability.ability_name)
	current_combatant = user
	selected_ability = ability
	can_select_targets = true
