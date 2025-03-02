@tool
class_name PaletteImporter
extends RefCounted

# Adapted from Github -> Orama-Interactive/Pixelorama/src/Autoload/Import.gd
static func import_gpl(path : String) -> Palette:
	var color_line_regex = RegEx.new()
	color_line_regex.compile("(?<red>[0-9]{1,3})\\s+(?<green>[0-9]{1,3})\\s+(?<blue>[0-9]{1,3})(?:\\s+(?<name>.+))?")

	var result: Palette = null

	var file: FileAccess
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ)
		var text: String = file.get_as_text()
		var lines: PackedStringArray = text.split('\n')
		var line_number := 0
		var comments := ""
		for line: String in lines:
			line = line.lstrip(" ")
			# Check if valid Gimp Palette Library file
			if line_number == 0:
				if line.strip_edges() != "GIMP Palette":
					printerr("File " + path + " is not a valid GIMP Palette")
					break
				else:
					result = Palette.new()
					result.path = path
					var name_start: int = path.rfind('/') + 1
					var name_end: int = path.rfind('.')
					if name_end > name_start:
						result.name = path.substr(name_start, name_end - name_start)
			# Comments
			elif line_number == 1 and line.begins_with("Name:"):
				# Palette has a custom name
				result.name = line.trim_prefix("Name:").strip_edges()
			elif line_number == 2 and line.begins_with("Columns:"):
				# Palette has a custom number of columns
				result.columns = int(line.trim_prefix("Columns:").strip_edges())
			elif line.begins_with('#'):
				# Line is a comment
				comments += line.trim_prefix('#') + '\n'
			elif not line.is_empty():
				var matches: RegExMatch = color_line_regex.search(line)
				if matches:
					var red: float = matches.get_string("red").to_float() / 255.0
					var green: float = matches.get_string("green").to_float() / 255.0
					var blue: float = matches.get_string("blue").to_float() / 255.0
					var color: Color = Color(red, green, blue)
					var color_name: String = matches.get_string("name")
					result.add_color(color, color_name)
				else:
					push_error("Unable to parse line %s with content: %s" % [line_number + 1, line])

			line_number += 1

		if result:
			result.comments = comments
		file.close()
	else:
		push_error("File \"%s\" does not exist." % path)

	return result


# Get all gpl files in a path
static func get_gpl_files(path: String) -> Array[String]:
	var files: Array[String] = []

	var dir: DirAccess
	if DirAccess.dir_exists_absolute(path):
		dir = DirAccess.open(path)
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".gpl"):
				files.append(path + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the color palette path")

	return files
