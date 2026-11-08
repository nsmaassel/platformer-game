extends Node

## A* Pathfinding Manager
## Provides efficient grid-based pathfinding using Godot's AStar2D class.

var astar := AStar2D.new()

func setup_grid(grid: Array) -> void:
	astar.clear()
	var height = grid.size()
	var width = grid[0].size()
	
	# Add all walkable points
	for y in range(height):
		for x in range(width):
			if grid[y][x] == 0:
				astar.add_point(get_id(x, y), Vector2(x, y))
	
	# Connect adjacent points
	for y in range(height):
		for x in range(width):
			if grid[y][x] == 0:
				var neighbors = [
					Vector2i(x + 1, y),
					Vector2i(x - 1, y),
					Vector2i(x, y + 1),
					Vector2i(x, y - 1)
				]
				
				for n in neighbors:
					if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height:
						if grid[n.y][n.x] == 0:
							astar.connect_points(get_id(x, y), get_id(n.x, n.y), false)

func find_path(grid: Array, start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Rebuild grid if necessary (or keep as a cached setup)
	setup_grid(grid)
	
	if not astar.has_point(get_id(start.x, start.y)) or not astar.has_point(get_id(end.x, end.y)):
		return []
		
	var path := astar.get_point_path(get_id(start.x, start.y), get_id(end.x, end.y))
	
	var result: Array[Vector2i] = []
	for p in path:
		result.append(Vector2i(p))
	return result

func get_id(x: int, y: int) -> int:
	# Unique ID based on grid position
	return y * 1000 + x

