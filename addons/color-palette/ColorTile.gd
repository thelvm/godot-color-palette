@tool
class_name ColorTile
extends ColorRect

signal tile_deleted(index: int)
signal tile_selected(index: int)

const TILE_SIZE: float = 30

@onready var parent: PaletteTileContainer = get_parent() as PaletteTileContainer

var dragging: bool = false
var palette_color: PaletteColor:
	set(new_palette_color):
		palette_color = new_palette_color
		color = new_palette_color.color

func _ready():
	custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	mouse_filter = MOUSE_FILTER_PASS

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			parent.dragging = self
			parent.drag_start_index = get_index()
			tile_selected.emit(get_index())
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			tile_deleted.emit(get_index())
			accept_event()
			return
		


func set_color(new_color: Color) -> void:
	color = new_color
	palette_color.color = color
