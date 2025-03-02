@tool
class_name PaletteTileContainer
extends GridContainer

signal grid_item_reordered(index_from: int, index_to: int)

var dragging: ColorRect = null
var drag_start_index = -1
var dynamic_columns: bool

@onready var tile_container_scroll_container: ScrollContainer = %TileContainerScrollContainer
@onready var tile_container_margin: MarginContainer = %TileContainerMargin


func _gui_input(event):
	if event is InputEventMouseMotion and dragging != null:
#		Move the color rect as the user drags it for a live preview
		var mouse_position: Vector2 = (event as InputEventMouseMotion).position
		for c: Node in get_children():
			if c is ColorRect:
				if (c as ColorRect).get_rect().has_point(mouse_position):
					move_child(dragging, c.get_index())
		
	
#	When dragging finished
	if (event is InputEventMouseButton and 
			dragging != null and
			event.get_button_index() == 1 and
			event.is_pressed() == false):
				grid_item_reordered.emit(drag_start_index, dragging.get_index())
				dragging = null


func set_smart_columns(value: int) -> void:
	if value < 1:
		dynamic_columns = true
		_resize_columns()
	else:
		dynamic_columns = false
		columns = value


func _resize_columns() -> void:
	if dynamic_columns:
		var max_size: float = tile_container_scroll_container.size.x - tile_container_margin.get_theme_constant("margin_left") - tile_container_margin.get_theme_constant("margin_right")
		var column_width: float = ColorTile.TILE_SIZE + get_theme_constant("v_separation")
		columns = max(1, floori(max_size / column_width))
