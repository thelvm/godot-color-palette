@tool
class_name PaletteTileContainer
extends HFlowContainer

signal grid_item_reordered(index_from: int, index_to: int)

var dragging: ColorRect = null
var drag_start_index = -1

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
