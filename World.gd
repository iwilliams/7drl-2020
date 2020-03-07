extends Node2D

var tile_scene : PackedScene = preload("res://Tiles/Tile.tscn")
var thread

var tile_width = 32
var tile_height = 32

var world_width : int = 9
var world_height : int = 15
const max_world_width : int = 100
const max_world_height : int = 100
const min_world_width : int = 3
const min_world_height : int = 3
var is_generating = false

onready var astar := AStar.new()
onready var tiles := get_node("Tiles")
onready var player := get_node("Entities/Player")
onready var camera := get_node("Camera2D")
var player_path : Array
onready var turn_clock := get_node("TurnClock")

func _ready():
  create_dungeon(Vector2(100, 100))
  calculate_fov()
#  turn_clock.connect("timeout", self, "turn")

var walk_time = 0

func _physics_process(delta):
  if !walk_time:
    walk_time = 0
  walk_time += delta
  if walk_time < .1:
    return
  walk_time = 0
  if player_path.size() > 0:
    var target_tile_position = player_path.pop_front()
    var player_tile_position = get_tile_position(player.position)
    if Vector2(target_tile_position.x, target_tile_position.y) == player_tile_position:
      target_tile_position = player_path.pop_front()
    if !target_tile_position:
      return
    var direction = player_tile_position - Vector2(target_tile_position.x, target_tile_position.y)
    var did_move = move_player(direction*-1)
    if !did_move:
      player_path.push_front(target_tile_position)

# https://github.com/godotengine/godot/issues/32222#issuecomment-541929475
func get_global_mouse_position() -> Vector2:
  var zoom = camera.zoom
  var offset_position = get_tree().current_scene.get_global_mouse_position() - get_viewport_transform().origin
  offset_position *= zoom
  return offset_position

func _input(event : InputEvent) -> void:
  if event.is_action_pressed("ui_up"):
    move_player(Vector2(0, -1))
  elif event.is_action_pressed("ui_right"):
    move_player(Vector2(1, 0))
  elif event.is_action_pressed("ui_down"):
    move_player(Vector2(0, 1))
  elif event.is_action_pressed("ui_left"):
    move_player(Vector2(-1, 0))
  elif event is InputEventMouseButton:
    if event.pressed:
      var mouseEvent : InputEventMouseButton = (event as InputEventMouseButton)
      var world_position : Vector2 = get_global_mouse_position()
      var tile_position := get_tile_position(world_position)
      var world_bounds = Rect2(0, 0, world_width, world_height)
      if world_bounds.has_point(tile_position):
        var tile : Tile = get_tile(tile_position)
        move_player_to(tile)
  
func move_player_to(tile : Tile) -> bool:
  if player_path.size() > 0:
    return false
  if !(tile.type == Globals.TileTypes.FLOOR || Globals.TileTypes.DOOR):
    return false
  var from_tile_index : int = get_tile(get_tile_position(player.position)).get_index()
  var to_tile_index : int = tile.get_index()
  if astar.has_point(to_tile_index) && astar.has_point(from_tile_index):
    var path = astar.get_point_path(from_tile_index, to_tile_index)
    player_path = path
    return true
  else:
    return false
    
func move_player(direction : Vector2) -> bool:
  if !player: return false
  if direction.x == -0:
    direction.x = 0
  var player_current_tile_position : Vector2 = get_tile_position(player.position as Vector2)
  var next_tile_position = player_current_tile_position + direction
  var next_tile : Tile = get_tile(next_tile_position)

  match next_tile.type:
    Globals.TileTypes.WALL:
      return false
    Globals.TileTypes.DOOR:
      next_tile.type = Globals.TileTypes.FLOOR
      calculate_fov()
      return false
  player.position += direction * Vector2(tile_width, tile_height)
  camera.position = player.position
  calculate_fov()
  return true
  
func generate_tiles() -> void:
  for y in world_height:
    for x in world_width:
      var n : Tile = tile_scene.instance()
      n.type = Globals.TileTypes.NOTHING
      n.rect_position = Vector2(x*tile_width, y*tile_height)
      n.visible = false
      tiles.add_child(n)
  camera.position = Vector2(world_width*tile_width/2, world_height*tile_height/2)

func get_tile_position(world_position : Vector2) -> Vector2:
  return Vector2(floor(world_position.x/tile_width), floor(world_position.y/tile_width))

func child_index_to_tile_position(index: int) -> Vector2:
  var position := Vector2(0, 0)
  var loop := 0
  for y in world_height:
    position.y = y
    for x in world_height:
      position.x = x
      loop += 1
      if loop == index:
        break
    if loop == index:
      break
  return position

func get_tile(position: Vector2) -> Tile:
  var tile_index = floor(position.x) + (floor(position.y)*world_width)
  var tile : Tile = (tiles.get_child(tile_index) as Tile)
  return tile
  
# http://www.roguebasin.com/index.php?title=Dungeon-Building_Algorithm
func create_dungeon(dungeon_size: Vector2):
  randomize()
  var width = dungeon_size.x
  var height = dungeon_size.y
  # Clamp width and height
  world_width = int(clamp(width, min_world_width, max_world_width))
  world_height = int(clamp(height, min_world_height, max_world_height))
  
  # Clear out any current tiles
  for child in tiles.get_children():
    tiles.remove_child(child)
    child.queue_free()
  
  # Fill tiles node with tiles
  generate_tiles()

  # Make first room
  var first_room_bounds := make_room(Rect2(world_width/2 - 2, world_height/2 - 2, 4, 4))
  
  var top_left : Vector2 = first_room_bounds.position
  var bottom_right : Vector2 = first_room_bounds.end
  
  # Make features
  for i in range(0, 20):
    var new_feature_bounds := make_new_feature(Rect2(1, 1, world_width - 2, world_height - 2))
    if new_feature_bounds.position.x < top_left.x:
      top_left.x = new_feature_bounds.position.x
    if new_feature_bounds.position.y < top_left.y:
      top_left.y = new_feature_bounds.position.y
    if new_feature_bounds.end.x > bottom_right.x:
      bottom_right.x = new_feature_bounds.end.x
    if new_feature_bounds.end.y > bottom_right.y:
      bottom_right.y = new_feature_bounds.end.y

  var used_tile_bounds = Rect2(top_left, bottom_right - top_left)
  
#  var used_tiles = []
#  for y in world_height:
#    for x in world_width:
#      var i = x + y*world_width
#      if used_tile_bounds.has_point(Vector2(x, y)):
#        used_tiles.push_back(tiles.get_child(i))
        
#  var new_tiles = Node2D.new()
#  for tile in used_tiles:
#    tiles.remove_child(tile)
#    new_tiles.add_child(tile)
#
#  tiles.queue_free()
#  tiles = new_tiles
#  add_child(new_tiles)
#  world_width = used_tile_bounds.size.x
#  world_height = used_tile_bounds.size.y

  # Add all FLOOR and DOOR tiles to A*
  astar.reserve_space(tiles.get_child_count())
  for tile_index in range(0, tiles.get_child_count()):
    var tile = tiles.get_child(tile_index) as Tile
    if !(tile.type == Globals.TileTypes.FLOOR || tile.type == Globals.TileTypes.DOOR):
      continue
    var tile_position = get_tile_position(tile.position)
    astar.add_point(tile_index, Vector3(tile_position.x, tile_position.y, 0))

  var stairs_down := get_random_tile_of_type(Globals.TileTypes.FLOOR)
  stairs_down.type = Globals.TileTypes.STAIRS_DOWN
  
  var stairs_up := get_random_tile_of_type(Globals.TileTypes.FLOOR)
  stairs_up.type = Globals.TileTypes.STAIRS_UP

  # Connect all A* points
  for point in astar.get_points():
    var tile_index : int = point
    if !tile_index:
      continue
    var tile_n_index = tile_index - world_width
    var tile_e_index = tile_index + 1
    var tile_s_index = tile_index + world_width
    var tile_w_index = tile_index - 1
    for other_tile_index in [tile_n_index, tile_e_index, tile_s_index, tile_w_index]:
      if tile_index != other_tile_index && astar.has_point(other_tile_index):
        astar.connect_points(tile_index, other_tile_index)

  player.position = stairs_up.rect_position
  camera.position = player.position

func make_new_feature(world_bounds : Rect2) -> Rect2:
  # Find a wall
  var can_make_room = false
  while(!can_make_room):
    var results : Dictionary = find_wall()
    var direction : Vector2 = results["direction"]
    var wall : Tile = results["tile"]
    var wall_position : Vector2 = results["tile_position"]
    
    # Set the potential new room's rect
    var new_room_rect := Rect2(wall_position.x, wall_position.y, floor(rand_range(3, 10)), floor(rand_range(3, 10)))
    if direction.x != 0:
      new_room_rect.position.y = floor(rand_range(wall_position.y - new_room_rect.size.y + 1, wall_position.y))
    else:
      new_room_rect.position.x = floor(rand_range(wall_position.x - new_room_rect.size.x + 1, wall_position.x))
    
    if results["direction"].y < 0:
      new_room_rect.position.y -= new_room_rect.size.y
    if results["direction"].y > 0:
      new_room_rect.position.y += 1
    if results["direction"].x < 0:
      new_room_rect.position.x -= new_room_rect.size.x
    if results["direction"].x > 0:
      new_room_rect.position.x += 1
  
    if !world_bounds.encloses(new_room_rect):
      continue
    
    # Check if there is room for the room
    can_make_room = true
    for possible_room_tile in get_tiles_in_rect(new_room_rect):
      if (possible_room_tile as Tile).type != Globals.TileTypes.NOTHING:
        can_make_room = false
        break
    
    if can_make_room:
      var new_room_bounds = make_room(new_room_rect)
      results["tile"].type = Globals.TileTypes.DOOR
      return new_room_bounds
  return Rect2()

func get_tiles_in_rect(rect: Rect2) -> Array:
  # 0 1 2 3 
  # 4 5 6 7 
  # 8 9 A B
  # C D E F
  var tiles_in_rect = []
  for y in range(max(0, rect.position.y), min(rect.position.y + rect.size.y, world_height - 1)):
    for x in range(max(0, rect.position.x), min(rect.position.x + rect.size.x, world_width - 1)):
      tiles_in_rect.push_back(get_tile(Vector2(x, y)))
  return tiles_in_rect

func fill_tiles_in_rect(rect: Rect2, type: int) -> void:
  for y in range(rect.position.y, rect.position.y + rect.size.y):
    for x in range(rect.position.x, rect.position.x + rect.size.x):
      var t : Tile = get_tile(Vector2(x, y))
      t.type = type
      t.visible = true

func make_room(rect: Rect2) -> Rect2:
  var total_bounds = rect.grow(1)
  fill_tiles_in_rect(total_bounds, Globals.TileTypes.WALL)
  fill_tiles_in_rect(rect, Globals.TileTypes.FLOOR)
  return total_bounds
  
func get_random_tile_of_type(type: int, possible_tiles: Array = tiles.get_children()) -> Tile:
  var tile : Tile
  if possible_tiles.size() == 0:
    return null
  possible_tiles.shuffle()
  tile = (possible_tiles.pop_front() as Tile)
  while tile.type != type && possible_tiles.size() > 0:
    tile = (possible_tiles.pop_front() as Tile)
  return tile

func find_wall() -> Dictionary:
  var floor_tile : Tile = get_random_tile_of_type(Globals.TileTypes.FLOOR)
  var floor_tile_position := get_tile_position(floor_tile.rect_position)

  var adjacent_tiles := get_tiles_in_rect(\
    Rect2(\
      Vector2(floor_tile_position.x - 1, floor_tile_position.y -1), \
      Vector2(3, 3) \
    ) \
  )
  
  # 0 1 2
  # 3 4 5
  # 6 7 8 
  var possible_wall_tiles = []
  if adjacent_tiles.size() >= 2:
    possible_wall_tiles.push_back(adjacent_tiles[1]) 
  if adjacent_tiles.size() >= 4:
    possible_wall_tiles.push_back(adjacent_tiles[3])
  if adjacent_tiles.size() >= 6:
    possible_wall_tiles.push_back(adjacent_tiles[5]) 
  if adjacent_tiles.size() >= 8:
    possible_wall_tiles.push_back(adjacent_tiles[7])
  
  var wall_tile : Tile = get_random_tile_of_type(\
    Globals.TileTypes.WALL, \
    possible_wall_tiles
  )
  
  if wall_tile == null:
    return find_wall()
  else:
    var wall_position := get_tile_position(wall_tile.rect_position)
    var direction := wall_position - floor_tile_position
    return {
      "tile": wall_tile,
      "tile_position": wall_position,
      "direction": direction
    }

# https://github.com/domasx2/mrpas-js/blob/master/mrpas.js
func calculate_fov() -> void:
  for tile in tiles.get_children():
    tile.can_see = false
    if tile.discovered:
      tile.material.set_shader_param("brightness", .1)
    else:
      tile.visible = false
  var player_tile_position = get_tile_position(player.position)
  tile_set_visible(player_tile_position)
  var vision_range = 10
  calculate_fov_quadrant(player_tile_position, vision_range, 1, 1);
  calculate_fov_quadrant(player_tile_position, vision_range, 1, -1);
  calculate_fov_quadrant(player_tile_position, vision_range, -1, 1);
  calculate_fov_quadrant(player_tile_position, vision_range, -1, -1);
  pass
  
func calculate_fov_quadrant(player_position : Vector2, max_radius : int, dx : int, dy : int):
  var start_angle := []
  start_angle.resize(100)
  var end_angle := []
  end_angle.resize(100)
  # octant: vertical edge:
  var iteration := 1;
  var done := false;
  var total_obstacles := 0;
  var obstacles_in_last_line := 0;
  var min_angle := 0.0;
  var x := 0.0;
  var y := player_position.y + dy;
  var c;
  var wsize := Vector2(world_width, world_height);
  
  var slopes_per_cell : float
  var half_slopes : float
  var processed_cell : int
  var minx
  var maxx
  var pos : Vector2
  var is_visible
  var start_slope
  var center_slope
  var end_slope
  var idx;
  # do while there are unblocked slopes left and the algo is within
  # the map's boundaries
  # scan progressive lines/columns from the PC outwards
  if (y < 0) || (y >= wsize.y):
    done = true;
    
  while !done:
    # process cells in the line
    slopes_per_cell = 1.0 / (iteration + 1);
    half_slopes = slopes_per_cell * 0.5;
    processed_cell = int(min_angle / slopes_per_cell);
    minx = max(0, player_position.x - iteration);
    maxx = min(wsize.x - 1, player_position.x + iteration);
    done = true
    x = player_position.x + (processed_cell * dx)
    while (x >= minx) && (x <= maxx):
      pos = Vector2(x, y)
      is_visible = true;
      start_slope = processed_cell * slopes_per_cell
      center_slope = start_slope + half_slopes
      end_slope = start_slope + slopes_per_cell
      if (obstacles_in_last_line > 0) && (!tile_is_visible(pos)):
        idx = 0;
        while(is_visible && (idx < obstacles_in_last_line)):
          if tile_is_transparent(pos):
            if((center_slope > start_angle[idx]) && (center_slope < end_angle[idx])):
              is_visible = false;  
          elif ((start_slope >= start_angle[idx]) && (end_slope <= end_angle[idx])):
            is_visible = false;

          if (is_visible && ( (!tile_is_visible(Vector2(x, y - dy))) || \
            (!tile_is_transparent(Vector2(x, y - dy)))) \
            && ((x - dx >= 0) && (x - dx < wsize.x) && \
            ((!tile_is_visible(Vector2(x - dx, y - dy))) \
            || (!tile_is_transparent(Vector2(x - dx, y - dy)))))):
            is_visible = false;
          idx += 1;
              
      if is_visible:
        tile_set_visible(pos)
        done = false
        # if the cell is opaque, block the adjacent slopes
        if !tile_is_transparent(pos):
          if min_angle >= start_slope:
            min_angle = end_slope
          else:
            start_angle[total_obstacles] = start_slope
            end_angle[total_obstacles] = end_slope
            total_obstacles += 1

      processed_cell += 1
      x += dx

    if iteration == max_radius:
      done = true
    iteration += 1
    obstacles_in_last_line = total_obstacles
    y += dy
    if (y < 0) || (y >= wsize.y):
      done = true
    if min_angle == 1.0:
      done = true
  
  # octant: horizontal edge
  iteration = 1 # iteration of the algo for this octant
  done = false
  total_obstacles = 0
  obstacles_in_last_line = 0
  min_angle = 0.0
  x = player_position.x + dx # the outer slope's coordinates (first processed line)
  y = 0
  # do while there are unblocked slopes left and the algo is within the map's boundaries
  # scan progressive lines/columns from the PC outwards
  if (x < 0) || (x >= wsize.x):
    done = true;

  while !done:
    # process cells in the line
    slopes_per_cell = 1.0 / (iteration + 1)
    half_slopes = slopes_per_cell * 0.5
    processed_cell = int(min_angle / slopes_per_cell)
    var miny = max(0, player_position.y - iteration)
    var maxy = min(wsize.y - 1, player_position.y + iteration)
    done = true
    y = player_position.y + (processed_cell * dy)
    while (y >= miny) && (y <= maxy):
      # calculate slopes per cell
      pos = Vector2(x, y)
      is_visible = true
      start_slope = processed_cell * slopes_per_cell
      center_slope = start_slope + half_slopes
      end_slope = start_slope + slopes_per_cell
      if (obstacles_in_last_line > 0) && (!tile_is_visible(pos)):
        idx = 0
        while is_visible && (idx < obstacles_in_last_line):
          if(tile_is_transparent(pos)):
            if((center_slope > start_angle[idx]) && (center_slope < end_angle[idx])):
              is_visible = false;
          elif (start_slope >= start_angle[idx]) && (end_slope <= end_angle[idx]):
              is_visible = false;
                    
          if is_visible && (!tile_is_visible(Vector2(x - dx, y)) || \
            (!tile_is_transparent(Vector2(x - dx, y)))) && \
            ((y - dy >= 0) && (y - dy < wsize.y) && \
            ((!tile_is_visible(Vector2(x - dx, y - dy))) || \
            (!tile_is_transparent(Vector2(x - dx, y - dy))))):
            is_visible = false;
          idx += 1;
          
      if is_visible:
        tile_set_visible(pos)
        done = false
        # if the cell is opaque, block the adjacent slopes
        if !tile_is_transparent(pos):
          if(min_angle >= start_slope):
            min_angle = end_slope
          else:
            start_angle[total_obstacles] = start_slope
            end_angle[total_obstacles] = end_slope
            total_obstacles += 1

      processed_cell += 1;
      y += dy;

    if iteration == max_radius:
      done = true
    iteration += 1
    obstacles_in_last_line = total_obstacles
    x += dx
    if (x < 0) || (x >= wsize.x):
      done = true
    if min_angle == 1.0:
      done = true
  
  return

func tile_is_visible(tile_position : Vector2) -> bool:
  var tile = get_tile(tile_position)
  if tile:
    return tile.can_see
  else:
    return false
  
func tile_is_transparent(tile_position : Vector2) -> bool:
  var tile = get_tile(tile_position)
  if tile:
    return tile.type != Globals.TileTypes.WALL && tile.type != Globals.TileTypes.DOOR
  else:
    return false
  
func tile_set_visible(tile_position : Vector2) -> void:
  var tile = get_tile(tile_position)
  if tile:
    tile.can_see = true
    tile.discovered = true
    tile.visible = true
    tile.material.set_shader_param("brightness", 1)
