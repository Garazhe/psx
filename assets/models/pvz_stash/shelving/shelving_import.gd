@tool
extends EditorScenePostImport

# Shelving's GLB has four disconnected rectangular posts (Cube) and three
# disconnected shelf boards (Plane). Its original one-sided trimeshes have
# inward-facing board tops. Build one solid box per piece at import time so
# every GLB instance gets reliable two-sided collision without filling gaps.
func _post_import(scene: Node) -> Object:
	for node in scene.get_children():
		if node is MeshInstance3D and node.name in ["Cube", "Plane"]:
			for child in node.get_children():
				if child is StaticBody3D:
					child.free()
			var body := StaticBody3D.new()
			body.name = "StaticBody3D"
			node.add_child(body)
			body.owner = scene
			for bounds in _piece_bounds(node.mesh.get_faces()):
				var shape := BoxShape3D.new()
				shape.size = bounds.size
				var collision := CollisionShape3D.new()
				collision.shape = shape
				body.add_child(collision)
				collision.position = bounds.get_center()
				collision.owner = scene
	return scene

func _root(parents: Array[int], index: int) -> int:
	while parents[index] != index:
		parents[index] = parents[parents[index]]
		index = parents[index]
	return index

func _piece_bounds(faces: PackedVector3Array) -> Array[AABB]:
	# Weld UV/normal seams for topology only; bounds use the original vertices.
	var vertices: Dictionary = {}
	var parents: Array[int] = []
	var indices: Array[int] = []
	for vertex in faces:
		var key := Vector3i((vertex * 1000.0).round())
		if not vertices.has(key):
			vertices[key] = parents.size()
			parents.append(parents.size())
		indices.append(vertices[key])
	for i in range(0, indices.size(), 3):
		var root_index := _root(parents, indices[i])
		parents[_root(parents, indices[i + 1])] = root_index
		parents[_root(parents, indices[i + 2])] = root_index
	var pieces: Dictionary = {}
	for i in faces.size():
		var root_index := _root(parents, indices[i])
		if not pieces.has(root_index):
			pieces[root_index] = AABB(faces[i], Vector3.ZERO)
		else:
			pieces[root_index] = pieces[root_index].expand(faces[i])
	var result: Array[AABB] = []
	for bounds: AABB in pieces.values():
		result.append(bounds)
	return result
