@tool
extends Control
class_name LocalHistoryPanel

@onready var tree: Tree = $HSplitContainer/Tree
@onready var code_edit: CodeEdit = $HSplitContainer/CodeEdit
const RELOAD = preload("res://addons/gd_local_history/ui/reload.svg")
const REMOVE = preload("res://addons/gd_local_history/ui/remove.svg")
var _tree_root: TreeItem
var _previous_scroll_value: int = 0

func _ready() -> void:
	var _tree_root: TreeItem = tree.create_item()
	var directories: PackedStringArray = DirAccess.get_directories_at(GDLocalHistory.save_file_path)
	for directory: String in directories:
		create_file_tree_item(directory)

func create_file_tree_item(file_name: String) -> void:
	# Prevents adding files that do not end with .gd, for saftey
	if (file_name.right(2) != &"gd"): return

	var child: TreeItem = tree.create_item(_tree_root)
	child.set_text(0, file_name)
	child.set_custom_color(0, Color.WHITE_SMOKE)
	child.add_button(0, REMOVE, 1)
	child.set_button_color(0, 0, Color.INDIAN_RED)
	child.add_button(0, RELOAD, 2)
	child.set_button_tooltip_text(0, 0, "Delete %s" % file_name)
	child.set_button_tooltip_text(0, 1, "Refresh %s" % file_name)

func _on_tree_item_selected() -> void:
	var selected_tree_item: TreeItem = tree.get_selected()
	var metadata: Variant = selected_tree_item.get_metadata(0)
	_previous_scroll_value = code_edit.scroll_vertical

	if (metadata != null):
		code_edit.text = metadata
		code_edit.scroll_vertical = _previous_scroll_value
		return

	var folder_path: String = "%s/%s" % [GDLocalHistory.save_file_path, selected_tree_item.get_text(0)]
	_refresh_tree_item(selected_tree_item, folder_path)

func _on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var folder_path: String = "%s/%s" % [GDLocalHistory.save_file_path, item.get_text(0)]
	match (id):
		1:
			_clear_tree_item(item, folder_path, true)
		2:
			_refresh_tree_item(item, folder_path)
		_:
			pass

func _clear_tree_item(tree_item: TreeItem, folder_path: String = "", delete_files: bool = false) -> void:
	if (delete_files):
		OS.move_to_trash(ProjectSettings.globalize_path(folder_path))
		tree_item.free()
	else:
		for child: TreeItem in tree_item.get_children():
			tree_item.remove_child(child)

func _refresh_tree_item(tree_item: TreeItem, folder_path: String) -> void:
	_clear_tree_item(tree_item)

	for source_code_file_name: String in DirAccess.get_files_at(folder_path):
		var txt_child: TreeItem = tree_item.create_child()
		txt_child.set_text(0, source_code_file_name)
		txt_child.set_metadata(0, FileAccess.open("%s/%s" % [folder_path, source_code_file_name], FileAccess.READ).get_as_text())
