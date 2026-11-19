@tool
extends EditorPlugin

var context_plugin: EditorContextMenuPlugin


func _enter_tree() -> void:
	context_plugin = preload("extract_context.gd").new()
	add_context_menu_plugin(
		EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE,
		context_plugin
	)


func _exit_tree() -> void:
	remove_context_menu_plugin(context_plugin)
	context_plugin = null

# TODO : set icon upload to web
# 3D object pivt point center
