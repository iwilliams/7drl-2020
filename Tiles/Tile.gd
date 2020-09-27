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
var brightness := 1.0 setget brightness_set
func brightness_set(value : float) -> void:
  brightness = value
  if material:
    material.set_shader_param("brightness", value)
  

var tile_styles := {
  Globals.TileTypes.NOTHING : {
    "sprite_position": Vector2(16, 3), # Box character
    "fg_color": Color("#3e3546"),
    "bg_color": default_bg
  },
  Globals.TileTypes.FLOOR: {
    "sprite_position": Vector2(2, 18), # .
    "fg_color": Color("#625565"),
    "bg_color": default_bg
  },
  Globals.TileTypes.WALL: {
    "sprite_position": Vector2(3, 0), # #
    "fg_color": Color("#313638"),
    "bg_color": Color("#b2ba90")
  },
  Globals.TileTypes.DOOR: {
    "sprite_position": Vector2(11, 0), # +
    "fg_color": Color("#cd683d"),
    "bg_color": Color("#9e4539")
  },
  Globals.TileTypes.STAIRS_DOWN: {
    "sprite_position": Vector2(30, 0), # >
    "fg_color": Color("#ffffff"),
    "bg_color": default_bg
  },
  Globals.TileTypes.STAIRS_UP: {
    "sprite_position": Vector2(28, 0), # <
    "fg_color": Color("#ffffff"),
    "bg_color": default_bg
   },
   Globals.TileTypes.PLAYER: {
    "sprite_position": Vector2(0, 1), # @
    "fg_color": Color("#ffffff"),
    "bg_color": Color(0, 0, 0, 0)
   },
  Globals.TileTypes.RAT: {
    "sprite_position":  Vector2(18, 2), # @
    "fg_color": Color("#ffffff"),
    "bg_color": Color(0, 0, 0, 0)
   }
}

func _init():
  if material:
    material = material.duplicate()
    
func reset():
  type_set(Globals.TileTypes.NOTHING)
  brightness_set(1.0)
  can_see = false
  discovered = false

func set_tile_attributes():
  if !material:
    return
  var tile_type = tile_styles[type]
  material.set_shader_param("tile", tile_type["sprite_position"])
  material.set_shader_param("fg_color", tile_type["fg_color"])
  material.set_shader_param("bg_color", tile_type["bg_color"])
