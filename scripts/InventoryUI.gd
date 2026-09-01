extends CanvasLayer
# Beth's inventory screen: shows TWO SwiftGrids side by side so items can be
# dragged between them:
#   - "Bag"   (left)  -> Inventory.beth_inventory  (Beth's carried 10x10 grid)
#   - "Drawer" (right) -> Inventory.drawer_inventory (the drawer's own small grid)
# The "Keys" item is seeded into the Drawer on first open (see PlayerController),
# and you drag it left into the Bag. SwiftSlot handles the cross-inventory transfer.
# Autoloaded as "InventoryUI".

const SLOT := 48
const BAG_COLS := 10
const BAG_ROWS := 10
const DRAWER_COLS := 4
const DRAWER_ROWS := 2

var _bag_grid: SwiftGrid
var _drawer_grid: SwiftGrid

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20

	# Backdrop: catches the mouse and centers the panel.
	var backdrop := Control.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var total_w := (SLOT * BAG_COLS) + (SLOT * DRAWER_COLS) + 60
	var total_h := SLOT * maxi(BAG_ROWS, DRAWER_ROWS) + 70
	panel.custom_minimum_size = Vector2(total_w, total_h)
	backdrop.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	hbox.add_child(_build_side("Bag", Inventory.beth_inventory, BAG_COLS * BAG_ROWS, BAG_COLS))
	hbox.add_child(_build_side("Drawer", Inventory.drawer_inventory, DRAWER_COLS * DRAWER_ROWS, DRAWER_COLS))

	Inventory.inventory_toggled.connect(_on_toggled)

	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_side(title: String, inv: SwiftInventory, size: int, cols: int) -> VBoxContainer:
	var side := VBoxContainer.new()
	side.name = title + "Side"
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.name = "Label"
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side.add_child(label)

	var grid := SwiftGrid.new()
	grid.name = title + "Grid"
	grid.swift_inventory = inv
	grid.inventory_size = size
	grid.slot_size = Vector2i(SLOT, SLOT)
	grid.separation = Vector2i(4, 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.custom_minimum_size = Vector2(SLOT * cols, SLOT * ceil(float(size) / float(cols)))
	side.add_child(grid)

	if title == "Bag":
		_bag_grid = grid
	else:
		_drawer_grid = grid
	return side

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		Inventory.toggle()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and Inventory.is_open:
		Inventory.toggle()

func _on_toggled(open: bool) -> void:
	if open:
		show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
