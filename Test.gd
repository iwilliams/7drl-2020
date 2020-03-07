extends Node2D
var font : Font = preload("res://Font.tres")

var opto_tile_scene = preload("res://Tiles/OptoTile.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
  visible = false
#  tile_map() # ~38 FPS
#  sprites() # ~39 FPS
#  tiles() # ~29 FPS
#  draw_calls()
#  texture_rect() # 60 FPS
  visible = true
  
# 12 FPS
#func _draw():
#  draw_calls()

func texture_rect():
  var width = 86
  var height = 48
  for x in width:
    for y in height:
      var n : OptoTile = opto_tile_scene.instance()
      n.material = n.material.duplicate()
      if x % 2 == 0:
        n.material.set_shader_param("tile", Vector2(1, 0))
        n.material.set_shader_param("fg_color", Color(1, 0, 0, 1))
        n.material.set_shader_param("bg_color", Color(0, 1, 0, 1))
      $Container.add_child(n)
      n.rect_position = Vector2(x*32, y*32)
      n.rect_position.x -= width*32/2
      n.rect_position.y -= height*32/2
#      n.position = Vector2(x*32, y*32)
    
#func _process(delta):
#  for x in $Container.get_child_count()/2:
#    $Container.get_child(x).material.set_shader_param("fg_color", Color(randf(), randf(), randf(), 1))
#    $Container.get_child(x).material.set_shader_param("bg_color", Color(randf(), randf(), randf(), 1))

func tiles():
  var tile_scene = load("res://Tiles/Tile.tscn")
  var width = 100
  var height = 100
  for x in width:
    for y in height:
      var tile : Tile = tile_scene.instance()
      tile.tile_type = x % 2
      tile.position = Vector2(x*32, y*32)
      tile.position.x -= width*32/2
      tile.position.y -= height*32/2
      add_child(tile)
  
func sprites():
  var width = 100
  var height = 100
  var sheet = load("res://font_sprite.png")
  
  for x in width:
    for y in height:
      var sprite = Sprite.new()
      var pos = Vector2(32*x, 32*y)
      pos.x -= width*32/2
      pos.y -= height*32/2
      sprite.region_enabled = true
      sprite.texture = sheet
      sprite.region_rect = Rect2(0, 0, 32, 32)
      sprite.position = pos
      add_child(sprite)
      
      var sprite2 = Sprite.new()
      sprite2.region_enabled = true
      sprite2.texture = sheet
      sprite2.region_rect = Rect2(0, 0, 32, 32)
      sprite2.position = pos
      add_child(sprite2)
  
func tile_map():
  var tile_map := TileMap.new()
  tile_map.tile_set = load("res://World.tres")
  tile_map.cell_size = Vector2(32, 32)
  var width = 100
  var height = 100
  
  for x in width:
    for y in height: 
      tile_map.set_cell(x, y, 0)
  add_child(tile_map)
  tile_map.position.x -= width*32/2
  tile_map.position.y -= height*32/2
  add_child(tile_map.duplicate())

func draw_calls():
  var width = 100
  var height = 100
  
  for x in width:
    for y in height:
      draw_rect(Rect2(x*32, y*32, 32, 32), Color(0, 0, 0))
      draw_char(font, Vector2(x*32, (y+1)*32), ".", "", Color(1, 1, 1))
  
func _on_Shader_button_down():
  texture_rect()
  pass # Replace with function body.
