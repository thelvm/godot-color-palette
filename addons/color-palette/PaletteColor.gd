@tool
class_name PaletteColor
extends RefCounted

var color: Color = Color.BLACK
var name: String

func _init(p_color: Color, p_name: String):
	self.color = p_color
	self.name = p_name
