# games/tactics/tests/test_tactical_board.gd
## Unit test suite for TacticalBoard geometry: square GRID_SIZE cells and the board's screen bounds
extends RefCounted

const BOARD_PATH := "res://games/tactics/scripts/tactics/tactical_board.gd"

var errors: Array[String] = []


func _record_failure(msg: String) -> void:
	errors.append(msg)
	print("    ❌ FAILED: %s" % msg)


func assert_eq(actual, expected, message: String = "") -> bool:
	if actual != expected:
		var err := "Expected '%s', got '%s'. %s" % [str(expected), str(actual), message]
		_record_failure(err)
		return false
	return true


func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		var err := "Condition is false. %s" % message
		_record_failure(err)
		return false
	return true


func _get_board() -> Object:
	if ResourceLoader.exists(BOARD_PATH):
		var script = load(BOARD_PATH)
		if script != null:
			return script.new()
	_record_failure("TacticalBoard script does not exist at %s" % BOARD_PATH)
	return null


## Specification 1: cells are GRID_SIZE (24 px) squares in both directions.
func test_cells_are_square_grid_size() -> void:
	var board = _get_board()
	if board == null:
		return
	assert_eq(board.GRID_SIZE, 24, "GRID_SIZE should be 24 px to match the art contract")
	var step = board.grid_to_world(Vector2i(1, 1)) - board.grid_to_world(Vector2i(0, 0))
	assert_eq(step, Vector2(24, 24), "one cell right and down should move 24 px in each direction")


## Specification 2: world_to_grid inverts grid_to_world, including points near a cell's edge.
func test_world_to_grid_round_trip() -> void:
	var board = _get_board()
	if board == null:
		return
	for cell in [Vector2i(0, 0), Vector2i(5, 3), Vector2i(11, 9)]:
		var center = board.grid_to_world(cell)
		assert_eq(board.world_to_grid(center), cell, "centre of %s" % str(cell))
		assert_eq(board.world_to_grid(center + Vector2(11, 11)), cell, "near the bottom-right edge of %s" % str(cell))
		assert_eq(board.world_to_grid(center - Vector2(11, 11)), cell, "near the top-left edge of %s" % str(cell))


## Specification 3: is_on_board accepts every cell and rejects the HUD panel to the right, so clicks on the HUD
## buttons are not also handled as board clicks.
func test_hud_panel_is_off_board() -> void:
	var board = _get_board()
	if board == null:
		return
	if not board.has_method("is_on_board"):
		_record_failure("TacticalBoard.is_on_board is not implemented")
		return
	assert_true(board.is_on_board(board.grid_to_world(Vector2i(0, 0)) - Vector2(12, 12)), "top-left corner of the board")
	assert_true(board.is_on_board(board.grid_to_world(Vector2i(11, 9))), "centre of the last cell")
	assert_true(not board.is_on_board(Vector2(294, 100)), "x 294 is just past the right edge")
	assert_true(not board.is_on_board(Vector2(330, 215)), "ability button in the HUD panel")
	assert_true(not board.is_on_board(Vector2(390, 243)), "end-turn button in the HUD panel")
	assert_true(not board.is_on_board(Vector2(420, 40)), "main-menu button in the HUD panel")
	assert_true(not board.is_on_board(Vector2(100, 260)), "below the board")
