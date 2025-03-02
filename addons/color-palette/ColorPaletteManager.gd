@tool
class_name ColorPaletteManager
extends MarginContainer

# Palette list
@onready var refresh_list_button: Button = %RefreshListButton
@onready var palette_list: TabContainer = %PaletteList
# Options
@onready var palette_dir_le: LineEdit = %PaletteDirectoryLineEdit
@onready var new_palette_name_le: LineEdit = %NewPaletteNameLineEdit
@onready var new_palette_button: Button = %NewPaletteButton
@onready var open_palette_dir_button: Button = %OpenPaletteDirectoryButton
# Color Editor
@onready var color_picker: ColorPicker = %ColorPicker
@onready var color_preview_rect: ColorRect = %SelectedColorRect
@onready var color_preview_label: Label = %SelectedColorLabel
@onready var color_name_line_edit: LineEdit = %ColorNameLineEdit
@onready var apply_color_changed_button: Button = %ApplyChangesButton
@onready var new_color_rect: ColorRect = %NewColorRect
@onready var new_color_button: Button = %AddNewColorButton

var palette_container: PackedScene = preload("res://addons/color-palette/ColorPaletteContainer.tscn")

var palettes: Array[Palette]
var undoredo: EditorUndoRedoManager # passed from EditorPlugin

var selected_palette: Palette
var selected_color_index: int

func _ready():
	refresh_palettes()
	refresh_list_button.pressed.connect(refresh_palettes)
	apply_color_changed_button.pressed.connect(_apply_new_color_to_selected_palette)
	new_palette_button.pressed.connect(_create_new_palette)
	color_picker.color_changed.connect(func(new_color): new_color_rect.color = new_color)
	new_color_button.pressed.connect(_add_color_to_selected_palette)
	open_palette_dir_button.pressed.connect(_open_dir_in_file_manager)

# Clear the palette list, load the gpl files and populate the list again
func refresh_palettes():
	palettes.clear()
	for plc in palette_list.get_children():
		palette_list.remove_child(plc)

#	Ensure trailing slash
	if not palette_dir_le.text.ends_with("/"):
		palette_dir_le.text += "/"

	var gpl_files = PaletteImporter.get_gpl_files(palette_dir_le.text)
	
	for i in gpl_files:
		palettes.append(PaletteImporter.import_gpl(i))
	
	for p: Palette in palettes:
		var pc: ColorPaletteContainer = palette_container.instantiate()
		pc.name = p.name
		pc.palette = p
		pc.undoredo = undoredo
		if selected_palette:
			pc.selected = true if pc.palette.name == selected_palette.name else false
		pc.palette_updated.connect(refresh_palettes)
		pc.palette_color_selected.connect(_on_palette_color_selected)
		pc.container_selected.connect(_on_palette_container_selected)
		palette_list.add_child(pc)
	
	# Selects the correct tab
	if selected_palette:
		for n in palette_list.get_children():
			if n.name == selected_palette.name:
				palette_list.current_tab = n.get_index()


func _on_palette_color_selected(palette: Palette, index: int):
	color_preview_label.text = palette.name
	color_name_line_edit.text = palette.colors[index].name
	color_preview_rect.color = palette.colors[index].color
	color_picker.color = palette.colors[index].color
	new_color_rect.color = palette.colors[index].color
	
	selected_palette = palette
	selected_color_index = index


func _apply_new_color_to_selected_palette() -> void:
#	Check that we can actually apply before doing so
	var size: int = selected_palette.colors.size()
	if size == 0 or selected_color_index >= size:
		return
		
	var new_color: Color = color_picker.color
	var new_name: String = color_name_line_edit.text
	
	var original_color = selected_palette.colors[selected_color_index].color
	var original_name = selected_palette.colors[selected_color_index].name
	
	undoredo.create_action("Change Palette Color")
	undoredo.add_do_method(selected_palette, "change_color", selected_color_index, new_color, new_name)
	undoredo.add_do_method(selected_palette, "save")
	undoredo.add_do_method(self, "refresh_palettes")
	
	undoredo.add_undo_method(selected_palette, "change_color", selected_color_index, original_color, original_name)
	undoredo.add_undo_method(selected_palette, "save")
	undoredo.add_undo_method(self, "refresh_palettes")
	undoredo.commit_action()


func _create_new_palette() -> void:
	var new_palette_name: String = new_palette_name_le.text.strip_edges()
	
	if new_palette_name.length() > 0:
		var palette = Palette.new()
		palette.path = palette_dir_le.text + new_palette_name.to_lower().replace(" ", "_") + ".gpl"
		palette.name = new_palette_name
		palette.save()
		refresh_palettes()
	else:
		push_error("Name cannot be blank")


func _on_palette_container_selected(container: Control) -> void:
	for pc: ColorPaletteContainer in palette_list.get_children():
		if pc != container:
			pc.selected = false
	
	selected_palette = container.palette
	selected_color_index = 0
	color_preview_label.text = selected_palette.name
	color_name_line_edit.clear()


func _add_color_to_selected_palette() -> void:
	if selected_palette != null:
		selected_palette.add_color(color_picker.color, color_name_line_edit.text)
		selected_palette.save()
		refresh_palettes()


func _open_dir_in_file_manager():
	var file_dialog: FileDialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.current_dir = ProjectSettings.globalize_path(palette_dir_le.text)
	file_dialog.use_native_dialog = true
	file_dialog.dir_selected.connect(func(folder: String):
		palette_dir_le.text = folder
		refresh_palettes())
	
	add_child(file_dialog)
	file_dialog.popup_centered()


func _on_color_name_line_edit_text_submitted(new_name: String) -> void:
	var previous_name: String = selected_palette.colors[selected_color_index].name
	
	undoredo.create_action("Changed color name to " + new_name)
	
	undoredo.add_do_property(selected_palette.colors[selected_color_index], "name", new_name)
	undoredo.add_undo_property(selected_palette.colors[selected_color_index], "name", previous_name)
	
	undoredo.add_do_method(selected_palette, "save")
	undoredo.add_undo_method(selected_palette, "save")
	
	undoredo.add_do_method(self, "refresh_palettes")
	undoredo.add_undo_method(self, "refresh_palettes")
	
	undoredo.commit_action()
	
	color_name_line_edit.release_focus()
