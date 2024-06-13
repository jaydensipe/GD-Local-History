@tool
extends EditorPlugin

var _previous_saved_files: Dictionary = {}
var local_history_panel: LocalHistoryPanel = preload("res://addons/gd_local_history/ui/local_history_panel/local_history_panel.tscn").instantiate()

# TODO:
# Add project setting for setting destination

func _enter_tree() -> void:
	# Add custom button to bottom panel
	add_control_to_bottom_panel(local_history_panel, "Local History")

	# Add signal connection
	resource_saved.connect(_local_history_save.bind())

func _exit_tree() -> void:
	# Remove custom button from bottom panel
	remove_control_from_bottom_panel(local_history_panel)

	# Remove signal connection
	resource_saved.disconnect(_local_history_save.bind())

func _local_history_save(_resource: Resource) -> void:
	if (_resource is not Script): return

	var file_name: String = _resource.resource_path.get_file()
	var source_code: String = _resource.source_code

	if (_previous_saved_files.get_or_add(file_name, "") == source_code): return
	_previous_saved_files[file_name] = source_code

	var path: String = "res://.gd_local_history/%s/" % file_name
	if (!DirAccess.dir_exists_absolute(path)):
		DirAccess.make_dir_recursive_absolute(path)
		local_history_panel.create_file_tree_item(file_name)

	var file: FileAccess = FileAccess.open(path + "%s-%s.txt" % [file_name, Time.get_unix_time_from_system()], FileAccess.WRITE)
	file.store_string(_resource.source_code)
	file.close()
