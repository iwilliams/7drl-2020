extends Camera2D

func _input(event: InputEvent):
  if event.is_action_pressed("zoom_in"):
    zoom_camera()
  if event.is_action_pressed("zoom_out"):
    zoom_camera(false)

  if event is InputEventScreenDrag:
    offset -= event.relative

func zoom_camera(zoom_in : bool = true):
  var zoom_scale := .02
  var zoom_amount := Vector2(zoom_scale, zoom_scale)
  if zoom_in:
    zoom_amount *= -1
  print(zoom_amount)
  zoom += zoom_amount
