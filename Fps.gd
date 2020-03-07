extends Label

func _process(delta):
  text = "Fps: %d" % Engine.get_frames_per_second()
