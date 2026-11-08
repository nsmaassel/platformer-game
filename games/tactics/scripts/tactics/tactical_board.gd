class_name TacticalBoard
extends RefCounted

## Cells are GRID_SIZE px squares; OFFSET_X/OFFSET_Y is the centre of cell (0, 0). The 12x10 board spans
## x 6-294 and y 15-255 of the 480x270 viewport, leaving the right-hand panel for the HUD.
const GRID_SIZE: int = 24
const BOARD_WIDTH: int = 12
const BOARD_HEIGHT: int = 10
const OFFSET_X: float = 18.0
const OFFSET_Y: float = 27.0

var terrain_map: Dictionary = {}
var astar_grid: AStarGrid2D

func _init() -> void:
	_setup_terrain()
	_setup_astar()

func _setup_terrain() -> void:
	terrain_map[Vector2i(5, 3)] = "COVER"
	terrain_map[Vector2i(5, 6)] = "COVER"
	terrain_map[Vector2i(7, 2)] = "LAVA"
	terrain_map[Vector2i(7, 7)] = "LAVA"

func _setup_astar() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, BOARD_WIDTH, BOARD_HEIGHT)
	astar_grid.cell_size = Vector2i(1, 1)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if terrain_map.get(Vector2i(x,y)) == "COVER":
				astar_grid.set_point_solid(Vector2i(x,y), true)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(OFFSET_X + grid_pos.x * GRID_SIZE, OFFSET_Y + grid_pos.y * GRID_SIZE)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var gx = int(round((world_pos.x - OFFSET_X) / float(GRID_SIZE)))
	var gy = int(round((world_pos.y - OFFSET_Y) / float(GRID_SIZE)))
	return Vector2i(clamp(gx, 0, BOARD_WIDTH - 1), clamp(gy, 0, BOARD_HEIGHT - 1))

## True when a world position lies on the board (each cell spans its centre ± GRID_SIZE / 2).
func is_on_board(world_pos: Vector2) -> bool:
	var half := GRID_SIZE / 2.0
	return (world_pos.x >= OFFSET_X - half and world_pos.x < OFFSET_X + (BOARD_WIDTH - 0.5) * GRID_SIZE
		and world_pos.y >= OFFSET_Y - half and world_pos.y < OFFSET_Y + (BOARD_HEIGHT - 0.5) * GRID_SIZE)

func is_valid_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_WIDTH and pos.y >= 0 and pos.y < BOARD_HEIGHT

func update_astar_units(active_units: Array, ignore_team: String = "") -> void:
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if terrain_map.get(Vector2i(x,y)) != "COVER":
				astar_grid.set_point_solid(Vector2i(x,y), false)
	for u in active_units:
		if u["team"] != ignore_team and u["hp"] > 0:
			astar_grid.set_point_solid(u["pos"], true)

func has_line_of_sight(start: Vector2i, end: Vector2i) -> bool:
	var x0 = start.x; var y0 = start.y
	var x1 = end.x; var y1 = end.y
	var dx = abs(x1 - x0); var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	while true:
		var pos = Vector2i(x0, y0)
		if pos != start and pos != end:
			if terrain_map.get(pos) == "COVER": return false
		if x0 == x1 and y0 == y1: break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return true
