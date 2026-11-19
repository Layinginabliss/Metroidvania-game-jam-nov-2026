
@tool
extends EditorContextMenuPlugin

func _popup_menu(paths: PackedStringArray) -> void:
	if paths.size() == 1:
		add_context_menu_item(
			"Extract as New Scene",
			_on_extract
		)

func _on_extract(nodes: Array) -> void:
	if nodes.is_empty():
		return

	var selected: Node = nodes[0]
	var scene_root := EditorInterface.get_edited_scene_root()

	if scene_root == null:
		return

	if selected == scene_root:
		push_warning("Cannot extract the scene root.")
		return

	if selected.get_parent() == null:
		return

	if scene_root.scene_file_path.is_empty():
		push_error("Save the current scene before extracting.")
		return

	# Create a unique folder beside the current scene.
	var base_dir := scene_root.scene_file_path.get_base_dir()
	var folder_name := selected.name.validate_filename()
	var folder_path := base_dir.path_join(folder_name)

	var suffix := 2
	while DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path(folder_path)
	):
		folder_path = base_dir.path_join(
			folder_name + "_" + str(suffix)
		)
		suffix += 1

	var absolute_folder := ProjectSettings.globalize_path(folder_path)

	var error := DirAccess.make_dir_recursive_absolute(absolute_folder)
	if error != OK:
		push_error("Could not create scene folder.")
		return

	var scene_path := folder_path.path_join(
		folder_path.get_file() + ".tscn"
	)

	# Duplicate the complete selected branch.
	var clone := selected.duplicate(
		Node.DUPLICATE_SIGNALS |
		Node.DUPLICATE_GROUPS |
		Node.DUPLICATE_SCRIPTS |
		Node.DUPLICATE_USE_INSTANTIATION
	)

	if clone == null:
		push_error("Could not duplicate selected node.")
		return

	# Give all descendants ownership of the new scene.
	_set_owners(clone, clone)

	# Copy and reassign scripts.
	var copied_scripts := {}

	if not _copy_scripts(clone, folder_path, copied_scripts):
		clone.free()
		return

	# Pack the extracted scene.
	var packed := PackedScene.new()

	error = packed.pack(clone)

	if error != OK:
		push_error("Could not pack extracted scene: " + str(error))
		clone.free()
		return

	# Save the new scene.
	error = ResourceSaver.save(packed, scene_path)

	if error != OK:
		push_error("Could not save extracted scene: " + str(error))
		clone.free()
		return

	clone.free()

	# Load the new scene as an instance.
	var saved_scene := load(scene_path) as PackedScene

	if saved_scene == null:
		push_error("Could not reload extracted scene.")
		return

	var _instance := saved_scene.instantiate()

	
	print("Duplicated scene successfully: ", scene_path)

	EditorInterface.get_resource_filesystem().scan()



func _set_owners(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_set_owners(child, root)


func _copy_scripts(
	root: Node,
	destination: String,
	copied_scripts: Dictionary
) -> bool:

	var nodes: Array[Node] = [root]

	while not nodes.is_empty():
		var node: Node = nodes.pop_back()

		for child in node.get_children():
			nodes.append(child)

		var script := node.get_script() as GDScript

		if script == null:
			continue

		# Identify scripts so shared scripts are copied only once.
		var original_path := script.resource_path
		var script_id := str(script.get_instance_id())

		var key := original_path if not original_path.is_empty() else script_id

		if copied_scripts.has(key):
			node.set_script(copied_scripts[key])
			continue

		var new_script_path: String

		if original_path.begins_with("res://") \
		and FileAccess.file_exists(original_path) \
		and original_path.ends_with(".gd"):

			var filename := original_path.get_file()
			new_script_path = _unique_script_path(
				destination,
				filename
			)

			var copy_error := DirAccess.copy_absolute(
				ProjectSettings.globalize_path(original_path),
				ProjectSettings.globalize_path(new_script_path)
			)
			
			if copy_error != OK:
				push_error("Could not copy script: " + original_path)
				return false

		else:
			# Built-in script: save its source as an independent .gd file.
			var filename := node.name.validate_filename() + ".gd"

			new_script_path = _unique_script_path(
				destination,
				filename
			)

			var file := FileAccess.open(
				new_script_path,
				FileAccess.WRITE
			)

			if file == null:
				push_error("Could not create script: " + new_script_path)
				return false

			file.store_string(script.source_code)
			file.close()

		# Load the copied script and assign it to the new node.
		var new_script := ResourceLoader.load(
			new_script_path,
			"GDScript",
			ResourceLoader.CACHE_MODE_IGNORE
		) as GDScript

		if new_script == null:
			push_error("Could not load copied script: " + new_script_path)
			return false

		copied_scripts[key] = new_script
		node.set_script(new_script)

	return true


func _unique_script_path(folder: String, filename: String) -> String:
	var base_name := filename.get_basename()
	var extension := filename.get_extension()

	var path := folder.path_join(filename)
	var counter := 2

	while FileAccess.file_exists(path):
		path = folder.path_join(
			base_name + "_" + str(counter) + "." + extension
		)
		counter += 1

	return path
