extends NinePatchRect

signal ability_selected(ability : Ability, user : Combatant)

@onready var fight: Button = %Fight
@onready var ability: MenuButton = %Ability
@onready var item: Button = %Item
@onready var run: Button = %Run

var ally_action_queue : Queue = Queue.new()
var current_combatant : Combatant

func _ready() -> void:
	ability.get_popup().index_pressed.connect(emit_ability)
	pass

func print_ally_name(combatant : Combatant):
	#print(combatant.combatant_name)
	ally_action_queue.enqueue(combatant)
	self.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_fight_pressed() -> void:
	print("fight")
	self.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_combatant = ally_action_queue.dequeue()
	ability_selected.emit(current_combatant.make_basic_attack(),current_combatant)



func _on_ability_pressed() -> void:
	print("ability")
	current_combatant = ally_action_queue.dequeue()
	for abilities in current_combatant.prepped_abilities:
		ability.get_popup().add_item(abilities.ability_name)



func _on_item_pressed() -> void:
	print("item")
	self.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_run_pressed() -> void:
	print("run")
	self.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func emit_ability(index : int):
	print(current_combatant.prepped_abilities[index].ability_name + " ability added to action queue")
	ability_selected.emit(current_combatant.prepped_abilities[index],current_combatant)
	
	for i in range(current_combatant.prepped_abilities.size()):
		ability.get_popup().remove_item(i)
	
	self.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
