extends Node
# Autoload: "Inventory"
# Holds Beth's SwiftInventory (a 10x10 grid) and a separate Drawer SwiftInventory.
# The visual UI lives in res://scenes/InventoryUI.tscn (also autoloaded) and
# listens to inventory_toggled to show/hide both grids.
#
# Dragging between the two grids transfers stacks (SwiftSlot handles this natively).
# The "Keys" item is seeded into the DRAWER on first open; the "Folded Note"
# is seeded into Beth's bag on first open.

signal inventory_toggled(open: bool)

const GRID_COLS := 10
const GRID_ROWS := 10
const DRAWER_SIZE := 8

var beth_inventory: SwiftInventory
var drawer_inventory: SwiftInventory
var drawer_note_data: SwiftItemData
var keys_data: SwiftItemData
var is_open: bool = false

func _ready() -> void:
	# Beth's bag: 10 x 10.
	beth_inventory = SwiftInventory.new()
	beth_inventory.size = GRID_COLS * GRID_ROWS

	# The drawer's own inventory (separate from Beth's bag).
	drawer_inventory = SwiftInventory.new()
	drawer_inventory.size = DRAWER_SIZE

	# Starter "Folded Note" item definition (placeholder icon = project icon, until real art).
	drawer_note_data = SwiftItemData.new()
	drawer_note_data.id = &"drawer_note"
	drawer_note_data.display_name = "Folded Note"
	drawer_note_data.description = "A slip of paper tucked in the drawer. The handwriting is yours."
	drawer_note_data.max_stack_size = 1
	var ic := load("res://icon.svg")
	if ic is Texture2D:
		drawer_note_data.icon = ic

	# Keys (from assets/models/key/). Use the model's diffuse texture as the icon
	# until dedicated 2D inventory art is made.
	keys_data = SwiftItemData.new()
	keys_data.id = &"keys"
	keys_data.display_name = "Keys"
	keys_data.description = "A set of old brass keys. They feel heavy in your palm."
	keys_data.max_stack_size = 1
	var key_tex := load("res://assets/models/key/13491_Set_Of_Keys_Diffuse.jpg")
	if key_tex is Texture2D:
		keys_data.icon = key_tex

func toggle() -> void:
	is_open = not is_open
	inventory_toggled.emit(is_open)

func has_item(id: StringName) -> bool:
	for inv in [beth_inventory, drawer_inventory]:
		if inv == null:
			continue
		for stack in inv.inventory.values():
			if stack != null and stack.item_data != null and stack.item_data.id == id:
				return true
	return false

# Seed the drawer note into Beth's bag on first drawer open.
func ensure_drawer_note() -> void:
	if beth_inventory == null or drawer_note_data == null:
		return
	if beth_inventory_has(&"drawer_note"):
		return
	beth_inventory.try_add(drawer_note_data, 1)

func ensure_keys() -> void:
	if drawer_inventory == null or keys_data == null:
		return
	if drawer_inventory_has(&"keys"):
		return
	drawer_inventory.try_add(keys_data, 1)

func beth_inventory_has(id: StringName) -> bool:
	if beth_inventory == null:
		return false
	for stack in beth_inventory.inventory.values():
		if stack != null and stack.item_data != null and stack.item_data.id == id:
			return true
	return false

func drawer_inventory_has(id: StringName) -> bool:
	if drawer_inventory == null:
		return false
	for stack in drawer_inventory.inventory.values():
		if stack != null and stack.item_data != null and stack.item_data.id == id:
			return true
	return false
