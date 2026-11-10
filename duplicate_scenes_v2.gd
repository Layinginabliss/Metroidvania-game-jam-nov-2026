
@tool
extends EditorScript

# ============================================================
# SETTINGS
# ============================================================

var source_scene_path := ""

var destination_directory := "" # get this as well

var new_scene_path := ""


# ============================================================
# RUN - SELECT SCENE
# ============================================================

# the script has not duplicated

func _run():

	var dialog := EditorFileDialog.new()

	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.add_filter("*.tscn", "Godot Scenes")

	EditorInterface.get_base_control().add_child(dialog)

	dialog.file_selected.connect(func(path: String):

		source_scene_path = path
		dialog.queue_free()

		select_destination_directory()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_file_dialog()


func select_destination_directory():

	var dialog := EditorFileDialog.new()

	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dialog.access = EditorFileDialog.ACCESS_RESOURCES

	EditorInterface.get_base_control().add_child(dialog)

	dialog.dir_selected.connect(func(path: String):

		destination_directory = path

		new_scene_path = destination_directory.path_join(
			source_scene_path.get_file()
		)

		dialog.queue_free()

		duplicate_scene()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_file_dialog()

# ============================================================
# DUPLICATE SCENE
# ============================================================

func duplicate_scene():

	var source_scene := load(source_scene_path)

	if source_scene == null:
		push_error("Could not load scene: " + source_scene_path)
		return

	if not source_scene is PackedScene:
		push_error("Source is not a PackedScene.")
		return


	# --------------------------------------------------------
	# Make sure destination folder exists
	# --------------------------------------------------------

	var destination_dir := new_scene_path.get_base_dir()

	var error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(destination_dir)
	)

	if error != OK:
		push_error("Could not create destination directory: " + destination_dir)
		return


	# --------------------------------------------------------
	# Instantiate original scene
	# --------------------------------------------------------

	var root = source_scene.instantiate()


	# --------------------------------------------------------
	# Duplicate attached scripts
	# --------------------------------------------------------

	duplicate_scripts(root)


	# --------------------------------------------------------
	# Pack copied scene
	# --------------------------------------------------------

	var new_scene := PackedScene.new()

	var result := new_scene.pack(root)

	if result != OK:
		push_error("Could not pack new scene.")
		root.free()
		return


	# --------------------------------------------------------
	# Save copied scene
	# --------------------------------------------------------

	result = ResourceSaver.save(
		new_scene,
		new_scene_path
	)

	if result != OK:
		push_error("Could not save new scene: " + new_scene_path)
	else:
		print("")
		print("========================================")
		print("Scene successfully copied!")
		print("========================================")
		print("Original:")
		print(source_scene_path)
		print("")
		print("New scene:")
		print(new_scene_path)
		print("========================================")
		print("")
		print("WARNING : Please restart the editor to load the scripts")


	# --------------------------------------------------------
	# Clean up
	# --------------------------------------------------------

	root.free()


# ============================================================
# DUPLICATE SCRIPTS
# ============================================================

func duplicate_scripts(node: Node):

	var script: Script = node.get_script()

	# --------------------------------------------------------
	# Does this node have a script?
	# --------------------------------------------------------

	if script != null:

		var script_path := script.resource_path

		if script_path != "" and script_path.begins_with("res://"):

			var new_script_path := make_new_script_path(
				script_path
			)

			# ------------------------------------------------
			# Copy script if it doesn't already exist
			# ------------------------------------------------

			if not FileAccess.file_exists(new_script_path):

				var error := DirAccess.copy_absolute(
					ProjectSettings.globalize_path(script_path),
					ProjectSettings.globalize_path(new_script_path)
				)

				if error != OK:
					push_error(
						"Failed to copy script: " + script_path
					)
					return

				print(
					"Copied script: ",
					script_path,
					" -> ",
					new_script_path
				)

			# ------------------------------------------------
			# Load copied script
			# ------------------------------------------------

			var new_script = ResourceLoader.load(
				new_script_path,
				"",
				ResourceLoader.CACHE_MODE_IGNORE
			)

			# ------------------------------------------------
			# Attach copied script
			# ------------------------------------------------

			if new_script is Script:
				node.set_script(new_script)
			else:
				push_error(
					"Could not load copied script: " +
					new_script_path
				)

	# --------------------------------------------------------
	# Process children
	# --------------------------------------------------------

	for child in node.get_children():
		duplicate_scripts(child)


# ============================================================
# CREATE NEW SCRIPT PATH
# ============================================================

func make_new_script_path(old_path: String) -> String:

	var file_name := old_path.get_file()

	return new_scene_path.get_base_dir().path_join(file_name)
