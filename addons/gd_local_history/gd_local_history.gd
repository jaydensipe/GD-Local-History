@tool
extends EditorPlugin
class_name GDLocalHistory

var local_history_panel: LocalHistoryPanel = preload("res://addons/gd_local_history/ui/local_history_panel/local_history_panel.tscn").instantiate()
var _previous_saved_files: Dictionary = {}
static var save_file_path: String = ""
static var _allow_global_directory: StringName = "local_history/config/allow_global_directory"
static var _file_setting_name: StringName = "local_history/config/save_file_path"

func _disable_plugin() -> void:
	# Gets rid of custom project settings
	ProjectSettings.set_setting(_allow_global_directory, null)
	ProjectSettings.set_setting(_file_setting_name, null)

func _enter_tree() -> void:
	# Init global directory project setting
	if (!ProjectSettings.has_setting(_allow_global_directory)):
		ProjectSettings.set_setting(_allow_global_directory, false)
	ProjectSettings.set_initial_value(_allow_global_directory, false)
	ProjectSettings.set_restart_if_changed(_allow_global_directory, true)
	var _global_directory_property_info = {
		"name": _allow_global_directory,
		"type": TYPE_BOOL
	}
	ProjectSettings.add_property_info(_global_directory_property_info)

	# Init file setting name project setting
	if (!ProjectSettings.has_setting(_file_setting_name)):
		ProjectSettings.set_setting(_file_setting_name, "res://.gd_local_history")
	ProjectSettings.set_initial_value(_file_setting_name, "res://.gd_local_history")
	ProjectSettings.set_as_basic(_file_setting_name, true)
	ProjectSettings.set_restart_if_changed(_file_setting_name, true)

	var _file_property_info: Dictionary = {}
	if (ProjectSettings.get_setting(_allow_global_directory)):
		_file_property_info = {
			"name": _file_setting_name,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_GLOBAL_DIR
		}
	else:
		_file_property_info = {
			"name": _file_setting_name,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
	ProjectSettings.add_property_info(_file_property_info)
	ProjectSettings.save()

	# Init save file path
	save_file_path = ProjectSettings.get_setting(_file_setting_name)
	if (!DirAccess.dir_exists_absolute(save_file_path)):
		DirAccess.make_dir_recursive_absolute(save_file_path)

	# Add custom button to bottom panel
	add_control_to_bottom_panel(local_history_panel, "Local History")

	# Add signal connection
	resource_saved.connect(_local_history_save.bind())

func _exit_tree() -> void:
	# Remove custom button from bottom panel
	remove_control_from_bottom_panel(local_history_panel)
	local_history_panel.queue_free()

	# Remove signal connection
	resource_saved.disconnect(_local_history_save.bind())

func _local_history_save(_resource: Resource) -> void:
	if (_resource is not Script): return

	var file_name: String = _resource.resource_path.get_file()
	var source_code: String = _resource.source_code

	# Prevents having identical files when spamming save
	if (_previous_saved_files.get_or_add(file_name, "") == source_code): return
	_previous_saved_files[file_name] = source_code

	var path: String = "%s/%s/" % [save_file_path, file_name]
	if (!DirAccess.dir_exists_absolute(path)):
		DirAccess.make_dir_recursive_absolute(path)
		local_history_panel.create_file_tree_item(file_name)

	var file: FileAccess = FileAccess.open("%s%s-%s.txt" % [path, file_name, Time.get_unix_time_from_system()], FileAccess.WRITE)
	file.store_string(_resource.source_code)
	file.close()
