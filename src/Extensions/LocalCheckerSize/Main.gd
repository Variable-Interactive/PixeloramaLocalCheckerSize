extends Node

var api: Node
var default_checker_size: int

var new_proj_option_label: Label
var checker_size_label: Label
var new_proj_value_slider: TextureProgressBar
var local_value_slider: TextureProgressBar


# This script acts as a setup for the extension
func _enter_tree() -> void:
	api = get_node_or_null("/root/ExtensionsApi")
	var global =  api.general.get_global()
	if global:
		# basic initialization
		default_checker_size = global.checker_size
		global.checker_follow_movement = true
		global.checker_follow_scale = true
		api.signals.signal_project_switched(proj_switched)

		# Add size option to new image panel
		var new_proj_dialog = global.top_menu_container.new_image_dialog
		new_proj_dialog.instantiate_scene()
		var new_proj_window: Window = new_proj_dialog.node
		if is_instance_valid(new_proj_window):
			var option_parent = new_proj_window.find_child("FillColorContainer")
			if option_parent:
				new_proj_option_label = Label.new()
				new_proj_option_label.text = "Checker Size"
				new_proj_option_label.custom_minimum_size.x = 100
				new_proj_option_label.size_flags_horizontal = Control.SIZE_EXPAND
				new_proj_value_slider = initialize_slider(default_checker_size)
				option_parent.add_child(new_proj_option_label)
				option_parent.add_child(new_proj_value_slider)

		# Add size option to project properties
		var proj_prop_dialog = global.top_menu_container.project_properties_dialog
		proj_prop_dialog.instantiate_scene()
		var proj_prop_window: Window = proj_prop_dialog.node
		if is_instance_valid(proj_prop_dialog):
			var prop_parent: GridContainer = proj_prop_window.size_value_label.get_parent()
			if prop_parent:
				checker_size_label = Label.new()
				checker_size_label.text = "Local Checker Size"
				checker_size_label.custom_minimum_size.x = 100
				checker_size_label.size_flags_horizontal = Control.SIZE_EXPAND
				var initial_value = default_checker_size
				var proj: RefCounted = api.project.current_project
				if proj:
					proj.set_meta(
						"checker_size",
						proj.get_meta(
							"checker_size", initial_value
						)
					)
					initial_value = proj.get_meta("checker_size", initial_value)
				local_value_slider = initialize_slider(initial_value)
				local_value_slider.value_changed.connect(
					func(new_value):
						var c_proj = api.project.current_project
						if is_instance_valid(c_proj):
							c_proj.set_meta("checker_size", new_value)
							api.general.get_global().checker_size = new_value
				)
				api.general.get_global().checker_size = initial_value

				prop_parent.add_child(checker_size_label)
				prop_parent.add_child(local_value_slider)


## This also gets called when new project gets created
func proj_switched():
	var proj: RefCounted = api.project.current_project
	# set project checker size if it isn't defined yet
	proj.set_meta("checker_size", proj.get_meta("checker_size", new_proj_value_slider.value))
	# change the checker size based on project's metadata
	if proj.has_meta("checker_size"):  # Failsafe
		api.general.get_global().checker_size = proj.get_meta("checker_size")
		if api.general.get_global().top_menu_container.project_properties_dialog.node:
			local_value_slider.value = api.general.get_global().checker_size


func _exit_tree() -> void:  # Extension is being uninstalled or disabled
	api.signals.signal_project_switched(proj_switched, true)
	if new_proj_option_label and checker_size_label and new_proj_option_label and new_proj_value_slider:
		new_proj_option_label.queue_free()
		checker_size_label.queue_free()
		new_proj_value_slider.queue_free()
		local_value_slider.queue_free()
	api.general.get_global().checker_size = default_checker_size


func initialize_slider(initial_value: int) -> TextureProgressBar:
	var new_value_slider = api.general.create_value_slider()
	new_value_slider.allow_greater = true
	new_value_slider.allow_lesser = false
	new_value_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_value_slider.min_value = 1.0
	new_value_slider.max_value = 64
	new_value_slider.step = 1.0
	new_value_slider.value = initial_value
	new_value_slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return new_value_slider
