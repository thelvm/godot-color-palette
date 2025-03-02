@tool
class_name Palette
extends RefCounted

var name: String = "Palette"
var path: String
var comments: String
var colors: Array[PaletteColor]
var columns: int = 0


func add_color(p_color : Color, name: String = "", p_index: int = -1) -> void:
	# TODO add undoredo
	var palette_color: PaletteColor = PaletteColor.new(p_color, name)
	if p_index != -1:
		colors.insert(p_index, palette_color)
	else:
		colors.append(palette_color)


func change_color(p_index: int, p_color: Color, p_name: String) -> void:
	colors[p_index].color = p_color
	colors[p_index].name = p_name


func reorder_color(p_index_from: int, p_index_to: int):
	if p_index_from == p_index_to:
		return
	
	var moving_color: PaletteColor = colors[p_index_from]
	colors.remove_at(p_index_from)
	colors.insert(p_index_to, moving_color)


func remove_color(p_index: int):
	colors.remove_at(p_index)


func save():
	if path.ends_with(".gpl") == false:
		push_error("To export gpl, file name must end in .gpl")
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_line("GIMP Palette")
	file.store_line("Name: " + name)
	file.store_line("Columns: " + str(columns))

	var comment_lines: PackedStringArray = comments.split("\n", false)
	for cl: String in comment_lines:
		file.store_line("#" + cl)
	
	for palette_color: PaletteColor in colors:
		var color_data: PackedStringArray = [
			str(palette_color.color.r8), 
			str(palette_color.color.g8), 
			str(palette_color.color.b8), 
			palette_color.name
		]

		var line = " ".join(color_data)
		file.store_line(line)

	file.close()
