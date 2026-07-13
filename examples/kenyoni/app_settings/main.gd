extends PanelContainer

const SettingsContainer := preload("res://examples/app_settings/settings/container.gd")

@export var _settings_container: PackedScene
@export var _tab_container: TabContainer
@export var _apply_button: Button
@export var _cancel_button: Button

func _ready() -> void:
    GameSettings.settings_applied.connect(self._on_settings_applied)
    GameSettings.settings_changed.connect(self._on_settings_changed)
    GameSettings.settings_staged_changed.connect(self._on_settings_staged_changed)
    # connecting to applied, changed and staged_changed signals can lead to performance issues
    # they will be emitted immediately after the setting is applied, changed or staged changed
    GameSettings.applied.connect(self._on_setting_applied)
    GameSettings.changed.connect(self._on_setting_changed)
    GameSettings.staged_changed.connect(self._on_setting_staged_changed)

    self._apply_button.pressed.connect(self._on_apply_button_pressed)
    self._cancel_button.pressed.connect(self._on_cancel_button_pressed)

    self._setup_settings()

# this will create settings with the following structure:
# section/sub_section/key
# each section is a tab container
# each sub_section will be a new titled label
func _setup_settings() -> void:
    var sections: PackedStringArray = GameSettings.get_sub_sections()
    for idx: int in range(len(sections)):
        var section: String = sections[idx]

        var container: SettingsContainer = self._settings_container.instantiate()
        self._tab_container.add_child(container)
        self._tab_container.set_tab_title(idx, section.capitalize())
        # OR
        # self._tab_container.set_tab_title(idx, self.tr("section_" + section))

        # all settings in section without a sub section
        for setting: GameSettings.Setting in GameSettings.get_section(section, 1):
            container.add_setting(setting)
        # add all sub sections and their settings
        for sub_section: String in GameSettings.get_sub_sections(section):
            container.add_section(sub_section.capitalize())
            for setting: GameSettings.Setting in GameSettings.get_section(section.path_join(sub_section)):
                container.add_setting(setting)

func _on_apply_button_pressed() -> void:
    GameSettings.apply_staged_values()
    print(GameSettings.to_config().encode_to_text())

func _on_cancel_button_pressed() -> void:
    GameSettings.discard_staged_values()

func _on_settings_applied() -> void:
    print("Setting applied")
    GameSettings.save()

func _on_settings_changed() -> void:
    print("Setting changed")

func _on_settings_staged_changed() -> void:
    print("Setting staged changed")
    self._apply_button.disabled = !GameSettings.has_staged_values()
    self._cancel_button.disabled = !GameSettings.has_staged_values()

func _on_setting_applied(key: String) -> void:
    print("'%s' applied" % key)

func _on_setting_changed(key: String) -> void:
    print("'%s' changed" % key)

func _on_setting_staged_changed(key: String) -> void:
    print("'%s' staged changed" % key)
