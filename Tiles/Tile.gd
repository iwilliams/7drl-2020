tool
extends ColorRect

class_name Tile

var default_bg = Color("#323353")

export (Globals.TileTypes) var type := 0 setget type_set
func type_set(value: int) -> void:
  type = value
  set_tile_attributes()

var position : Vector2 setget , position_get
func position_get():
  return self.rect_position
  
var discovered := false
var can_see := false

var tile_styles := {
  Globals.TileTypes.NOTHING : {
    "sprite_position": Vector2(16, 3), # Box character
    "fg_color": Color("#3e3546"),
    "bg_color": default_bg
  },
  Globals.TileTypes.FLOOR: {
    "sprite_position": Vector2(11, 3), # .
    "fg_color": Color("#625565"),
    "bg_color": default_bg
  },
  Globals.TileTypes.WALL: {
    "sprite_position": Vector2(12, 2), # #
    "fg_color": Color("#313638"),
    "bg_color": Color("#b2ba90")
  },
  Globals.TileTypes.DOOR: {
    "sprite_position": Vector2(22, 2), # +
    "fg_color": Color("#cd683d"),
    "bg_color": Color("#9e4539")
  },
  Globals.TileTypes.STAIRS_DOWN: {
    "sprite_position": Vector2(10, 3), # >
    "fg_color": Color("#ffffff"),
    "bg_color": default_bg
  },
  Globals.TileTypes.STAIRS_UP: {
    "sprite_position": Vector2(8, 3), # <
    "fg_color": Color("#ffffff"),
    "bg_color": default_bg
   },
   Globals.TileTypes.PLAYER: {
    "sprite_position": Vector2(11, 2), # @
    "fg_color": Color("#ffffff"),
    "bg_color": Color(0, 0, 0, 0)
   }
}

func _init():
  if material:
    material = material.duplicate()

func set_tile_attributes():
  if !material:
    return
  var tile_type = tile_styles[type]
  material.set_shader_param("tile", tile_type["sprite_position"])
  material.set_shader_param("fg_color", tile_type["fg_color"])
  material.set_shader_param("bg_color", tile_type["bg_color"])
