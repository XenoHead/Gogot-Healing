extends ScrollContainer

const ResetButton := preload("res://examples/app_settings/settings/reset_button.gd")

@export var _container: GridContainer

func _ready() -> void:
    GameSettings.settings_changed.connect(self._update)
    GameSettings.settings_staged_changed.connect(self._update)

func add_section(section: String) -> void:
    if self._container.get_child_count() > 0:
        var spacer: Control = Control.new()
        spacer.custom_minimum_size = Vector2(0, 32)
        self._container.add_child(spacer)
        self._container.add_child(Control.new())
        self._container.add_child(Control.new())

    var label: Label = Label.new()
    self._container.add_child(label)
    label.text = section
    label.theme_type_variation = &"HeaderLarge"
    self._container.add_child(Control.new())
    self._container.add_child(Control.new())

func add_setting(setting: GameSettings.Setting) -> void:
    self._add_label(setting)
    self._add_edit(setting)
    self._add_reset_button(setting)

func _add_label(setting: GameSettings.Setting) -> void:
    var label: Label = Label.new()
    self._container.add_child(label)
    label.text = setting.key().rsplit("/", 1)[-1].capitalize()
    label.tooltip_text = setting.description()
    label.mouse_filter = Control.MOUSE_FILTER_PASS
    label.set_meta(&"setting_key", setting.key())

func _add_edit(setting: GameSettings.Setting) -> void:
    var typ: int = setting.get_meta("type", -1)
    var type_hint: int = setting.get_meta("hint", PROPERTY_HINT_NONE)
    # bool
    if typ == TYPE_BOOL:
        var option_button: OptionButton = self._create_option_button(setting)
        option_button.add_item("On")
        option_button.add_item("Off")
        if setting.staged_or_value():
            option_button.select(0)
        else:
            option_button.select(1)
        option_button.item_selected.connect(func(idx: int) -> void:
            setting.set_value(idx == 0))
        return
    # enum
    if (typ == TYPE_INT || typ == TYPE_STRING) && type_hint == PROPERTY_HINT_ENUM:
        var values: Array[Variant] = setting.get_meta("values", [])
        var display_values: Array[String] = []
        display_values.assign(setting.get_meta("display_values", []))
        if values.size() != display_values.size():
            push_error("Setting %s has mismatched values and display_values size.".format(setting.key()))
            self._add_placeholder_label(setting)
            return
        var option_button: OptionButton = self._create_option_button(setting)
        var sel_idx: int = 0
        for idx: int in range(len(values)):
            option_button.add_item(display_values[idx].capitalize())
            if setting.staged_or_value() == values[idx]:
                sel_idx = idx
        option_button.select(sel_idx)
        option_button.item_selected.connect(func(idx: int) -> void:
            setting.set_value(setting.get_meta(&"values")[idx])
        )
        return
    # int, float slider
    if (typ == TYPE_INT || typ == TYPE_FLOAT) && type_hint == PROPERTY_HINT_RANGE:
        var hbox: HBoxContainer = HBoxContainer.new()
        self._container.add_child(hbox)
        hbox.set_meta(&"setting_key", setting.key())
        hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var slider: HSlider = HSlider.new()
        hbox.add_child(slider)
        slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slider.size_flags_vertical = Control.SIZE_EXPAND_FILL
        slider.editable = !setting.is_readonly()
        slider.min_value = setting.get_meta("min", 0)
        slider.max_value = setting.get_meta("max", 100)
        slider.value = setting.staged_or_value()
        slider.value_changed.connect(func(val: float) -> void:
            setting.set_value(val)
        )
        var label: Label = Label.new()
        hbox.add_child(label)
        if typ == TYPE_INT:
            label.text = str(int(setting.staged_or_value()))
        else:
            label.text = str(setting.staged_or_value())
        return
    self._add_placeholder_label(setting)

func _add_reset_button(setting: GameSettings.Setting) -> void:
    # hide reset button if setting is marked having no default value
    if setting.get_meta("no_default", false):
        self._container.add_child(Control.new())
        return
    var reset_button: ResetButton = ResetButton.new()
    self._container.add_child(reset_button)
    reset_button.set_meta(&"setting_key", setting.key())
    reset_button.tooltip_text = "Reset to default"
    reset_button.disabled = setting.staged_or_value() == setting.default_value()
    reset_button.pressed.connect(func() -> void: setting.reset())

func _add_placeholder_label(setting: GameSettings.Setting) -> void:
    var label: Label = Label.new()
    self._container.add_child(label)
    label.set_meta(&"setting_key", setting.key())
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.text = str(setting.staged_or_value())

func _create_option_button(setting: GameSettings.Setting) -> OptionButton:
    var option_button: OptionButton = OptionButton.new()
    self._container.add_child(option_button)
    option_button.set_meta(&"setting_key", setting.key())
    option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    option_button.disabled = setting.is_readonly()
    return option_button

func _update() -> void:
    for idx: int in range(self._container.get_child_count()):
        if idx % 3 == 0:
            continue
        var child: Node = self._container.get_child(idx)
        var key: StringName = child.get_meta(&"setting_key", "")
        # skip spacer rows or section rows
        if key == "":
            continue
        var setting: GameSettings.Setting = GameSettings.get_setting(key)
        if setting == null:
            continue
        if idx % 3 == 1:
            var typ: int = setting.get_meta("type", -1)
            var type_hint: int = setting.get_meta("hint", PROPERTY_HINT_NONE)
            if typ == TYPE_BOOL:
                (child as OptionButton).disabled = setting.is_readonly()
                if setting.staged_or_value():
                    (child as OptionButton).select(0)
                else:
                    (child as OptionButton).select(1)
            if (typ == TYPE_INT || typ == TYPE_STRING) && type_hint == PROPERTY_HINT_ENUM:
                var values: Array[Variant] = setting.get_meta("values", [])
                (child as OptionButton).disabled = setting.is_readonly()
                (child as OptionButton).select(values.find(setting.staged_or_value()))
            if (typ == TYPE_INT || typ == TYPE_FLOAT) && type_hint == PROPERTY_HINT_RANGE:
                (child.get_child(0) as HSlider).value = setting.staged_or_value()
                if typ == TYPE_INT:
                    (child.get_child(1) as Label).text = str(int(setting.staged_or_value()))
                else:
                    (child.get_child(1) as Label).text = str(setting.staged_or_value())
        if idx % 3 == 2:
            (child as Button).disabled = setting.staged_or_value() == setting.default_value()
