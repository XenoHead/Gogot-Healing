extends "res://addons/kenyoni/app_settings/app_settings.gd"

enum GameDifficulty {
    EASY,
    NORMAL,
    HARD
}

enum GraphicDetails {
    LOW,
    MEDIUM,
    HIGH,
    ULTRA
}

const SETTINGS_FILE: String = "res://examples/app_settings/settings.cfg"

const GAME_DIFFICULTY: StringName = &"game/difficulty"
const GAME_PLUGINS: StringName = &"game/plugins"
const GAME_BOT_LEVEL: StringName = &"game/bot_level"
const GAME_LANGUAGE: StringName = &"game/language"
const GAME_FOV: StringName = &"game/fov"
const GAME_ADVANCED_KI: StringName = &"game/advanced_ki"
const GRAPHICS_DETAILS: StringName = &"graphics/common/details"
const GRAPHICS_DISPLAY_WINDOW_MODE: StringName = &"graphics/display/window_mode"
const GRAPHICS_DISPLAY_VSYNC: StringName = &"graphics/display/vsync"
const AUDIO_MASTER_VOLUME: StringName = &"audio/master_volume"
const AUDIO_MUSIC_VOLUME: StringName = &"audio/music_volume"
const AUDIO_SFX_VOLUME: StringName = &"audio/sfx_volume"
const AUDIO_VOICE_VOLUME: StringName = &"audio/voice_volume"

## For localization use TranslationServer.get_loaded_locales() to get available languages.
## use "display_values" to set the display names for a list of values or enums.
## Almost always use .add_meta("type", TYPE_XXX). You could also just check for set.value() is bool, etc. But if the value allows null or it is an enum, it is better to define the type this way.
func _init() -> void:
    print("Initializing game settings...")
    self.add_setting(Setting.new(GAME_DIFFICULTY, GameDifficulty.NORMAL)
    .set_description("The difficulty of the game.")
    .set_staged()
    .set_validate_fn(func(_stg: Setting, val: Variant): return val in GameDifficulty.values())
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_ENUM)
    .add_meta("values", GameDifficulty.values())
    .add_meta("display_values", ["easy", "normal", "hard"]))
    self.add_setting(Setting.new(GAME_ADVANCED_KI, false)
    .set_description("Enable advanced AI features (experimental).")
    .set_staged()
    .add_meta("type", TYPE_BOOL))
    self.add_setting(Setting.new(GAME_FOV, 70)
    .set_description("Field of view.")
    .set_staged()
    .set_validate_fn(func(stg: Setting, val: Variant): return val >= stg.get_meta("min", 50) && val <= stg.get_meta("max", 120))
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_RANGE)
    .add_meta("min", 50)
    .add_meta("max", 120))
    self.add_setting(Setting.new(GAME_LANGUAGE, "en")
    .set_description("The language of the game.")
    .set_staged()
    .set_validate_fn(func(_stg: Setting, val: Variant): return val in ["en", "de", "fr", "es"])
    .set_apply_fn(func(stg: Setting) -> void: TranslationServer.set_locale(stg.value() as String))
    .add_meta("type", TYPE_STRING)
    .add_meta("hint", PROPERTY_HINT_ENUM)
    # use TranslationServer.get_loaded_locales(), this is just an example
    .add_meta("values", ["en", "de", "fr", "es"])
    .add_meta("display_values", ["english", "deutsch", "français", "español"])
    # this is an example of using a custom meta key, in this case to hide resetting in the UI
    .add_meta("no_default", true))
    self.add_setting(Setting.new(GRAPHICS_DETAILS, GraphicDetails.MEDIUM)
    .set_description("Graphic detail level.")
    .set_staged()
    .set_validate_fn(func(_stg: Setting, val: Variant): return val in GraphicDetails.values())
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_ENUM)
    .add_meta("values", GraphicDetails.values())
    .add_meta("display_values", ["low", "medium", "high", "ultra"]))
    self.add_setting(Setting.new(GRAPHICS_DISPLAY_WINDOW_MODE, DisplayServer.WINDOW_MODE_WINDOWED)
    .set_description("Enable fullscreen mode.")
    .set_staged()
    .set_apply_fn(func(stg: Setting) -> void:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if stg.value() else DisplayServer.WINDOW_MODE_WINDOWED))
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_ENUM)
    .add_meta("values", [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_FULLSCREEN])
    .add_meta("display_values", ["windowed", "exclusive fullscreen", "fullscreen"]))
    self.add_setting(Setting.new(GRAPHICS_DISPLAY_VSYNC, false)
    .set_description("VSync.")
    .set_staged()
    .add_meta("type", TYPE_BOOL))
    self.add_setting(Setting.new(GAME_PLUGINS, [])
    .set_description("Enabled plugins.")
    .set_internal())
    self.add_setting(Setting.new(GAME_BOT_LEVEL, 10)
    .set_description("Bot level.")
    .set_internal()
    .set_exported(false))
    self.add_setting(Setting.new(AUDIO_MASTER_VOLUME, 100)
    .set_description("Master volume.")
    .set_staged()
    .set_validate_fn(func(stg: Setting, val: Variant): return val >= stg.get_meta("min", 0) && val <= stg.get_meta("max", 100))
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_RANGE)
    .add_meta("min", 0)
    .add_meta("max", 100))
    self.add_setting(Setting.new(AUDIO_MUSIC_VOLUME, 60)
    .set_description("Master volume.")
    .set_staged()
    .set_validate_fn(func(stg: Setting, val: Variant): return val >= stg.get_meta("min", 0) && val <= stg.get_meta("max", 100))
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_RANGE)
    .add_meta("min", 0)
    .add_meta("max", 100))
    self.add_setting(Setting.new(AUDIO_SFX_VOLUME, 80)
    .set_description("Master volume.")
    .set_staged()
    .set_validate_fn(func(stg: Setting, val: Variant): return val >= stg.get_meta("min", 0) && val <= stg.get_meta("max", 100))
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_RANGE)
    .add_meta("min", 0)
    .add_meta("max", 100))
    self.add_setting(Setting.new(AUDIO_VOICE_VOLUME, 90)
    .set_description("Master volume.")
    .set_staged()
    .set_validate_fn(func(stg: Setting, val: Variant): return val >= stg.get_meta("min", 0) && val <= stg.get_meta("max", 100))
    .add_meta("type", TYPE_INT)
    .add_meta("hint", PROPERTY_HINT_RANGE)
    .add_meta("min", 0)
    .add_meta("max", 100))

    self.load()
    self.apply_staged_values()

func save() -> Error:
    return self.to_config().save(SETTINGS_FILE)

func load() -> Error:
    var cfg: ConfigFile = ConfigFile.new()
    var err: Error = cfg.load(SETTINGS_FILE)
    if err == Error.ERR_FILE_NOT_FOUND:
        return Error.OK
    if err != Error.OK:
        return err
    self.from_config(cfg)

    return Error.OK