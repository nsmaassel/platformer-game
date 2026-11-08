@tool
extends EditorScript

func _run() -> void:
	print("Forcing filesystem scan...")
	EditorInterface.get_resource_filesystem().scan()
	print("Done")
