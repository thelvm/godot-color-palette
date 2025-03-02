@tool
class_name ColorPaletteContainer
extends PanelContainer

signal palette_updated
signal palette_color_selected(palette, color_index)
signal palette_color_deleted(palette, color_index)
signal container_selected(container_object)

@onready var btn_load_to_picker: Button = %BtnLoadToPicker
@onready var btn_update_from_picker: Button = %BtnUpdateFromPicker
@onready var palette_name_line_edit: LineEdit = %PaletteNameLineEdit
@onready var column_count_spin_box: SpinBox = %ColumnCountSpinBox
@onready var grid: PaletteTileContainer = %TileContainer as PaletteTileContainer

var palette: Palette
var undoredo: EditorUndoRedoManager
var selected: bool = false: set = set_selected 


func _ready():
	btn_load_to_picker.pressed.connect(load_to_picker)
	btn_update_from_picker.pressed.connect(update_from_picker)
	grid.grid_item_reordered.connect(_grid_item_reordered)
	
#	Base settings for all color rects are set in the color tile class
	if palette:
		palette_name_line_edit.text = palette.name
		palette_name_line_edit.tooltip_text = palette.path
		column_count_spin_box.set_value_no_signal(palette.columns)
		for palette_color: PaletteColor in palette.colors:
#			Color rect instance properties
			var cri: ColorTile = ColorTile.new()
			cri.palette_color = palette_color
			cri.tile_selected.connect(_on_tile_selected)
			cri.tile_deleted.connect(_on_tile_deleted)
			grid.add_child(cri)
		grid.call_deferred("set_smart_columns", palette.columns)

func load_to_picker():
	var new_picker_presets: PackedColorArray
	
	for palette_color: PaletteColor in palette.colors:
		new_picker_presets.append(palette_color.color)
	
#	Hack?
	var ep = EditorPlugin.new()
	ep.get_editor_interface() \
		.get_editor_settings() \
		.set_project_metadata("color_picker", "presets", new_picker_presets)
	ep.free()


func update_from_picker():
	var ep = EditorPlugin.new()
	var colors: PackedColorArray = ep.get_editor_interface() \
		.get_editor_settings() \
		.get_project_metadata("color_picker", "presets")
	
	palette.colors.clear()
	for c: Color in colors:
		palette.add_color(c)
	
	palette.save()
	
	ep.free()
	
	palette_updated.emit()


func _grid_item_reordered(p_index_from: int, p_index_to: int) -> void:
	undoredo.create_action("Reorder Palette %s" % palette.name)
	
#	To do, move from "from" to "to"
	undoredo.add_do_method(palette, "reorder_color", p_index_from, p_index_to)
	undoredo.add_do_method(palette, "save")
	undoredo.add_do_method(self, "emit_signal", "palette_updated")
	undoredo.add_do_method(self, "emit_signal", "palette_color_selected", palette, p_index_to)
	
#	To undo, just reverse the positions!
	undoredo.add_undo_method(palette, "reorder_color", p_index_to, p_index_from)
	undoredo.add_undo_method(palette, "save")
	undoredo.add_undo_method(self, "emit_signal", "palette_updated")
	undoredo.add_undo_method(self, "emit_signal", "palette_color_selected", palette, p_index_from)
	
	undoredo.commit_action()


# Bubble the event up the tree
func _on_tile_selected(index):
	palette_color_selected.emit(palette, index)


func _on_tile_deleted(index):	
	var original_color = palette.colors[index]
	
	undoredo.create_action("Delete Color %s from Palette %s" % [original_color.color.to_html(), palette.name])
	
#	To do, move from "from" to "to"
	undoredo.add_do_method(palette, "remove_color", index)
	undoredo.add_do_method(palette, "save")
	undoredo.add_do_method(self, "emit_signal", "palette_updated")
	
#	To undo, just reverse the positions!
	undoredo.add_undo_method(palette, "add_color", original_color, index)
	undoredo.add_undo_method(palette, "save")
	undoredo.add_undo_method(self, "emit_signal", "palette_updated")
	
	undoredo.commit_action()


func set_selected(value: bool) -> void:
	selected = value
	if selected:
		container_selected.emit(self)


func _on_focus_entered() -> void:
	selected = true


func _on_palette_name_text_submitted(new_name: String) -> void:
	var stripped_name: String = new_name.strip_edges()
	if not stripped_name.is_empty():
		palette.name = stripped_name
		palette.save()
		palette_updated.emit()
		


func _on_column_count_spin_box_value_changed(value: float) -> void:
	palette.columns = value
	palette.save()
	grid.set_smart_columns(value)
