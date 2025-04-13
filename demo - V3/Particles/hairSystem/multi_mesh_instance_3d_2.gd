extends MultiMeshInstance3D

@export var hair_shell_mesh: MeshInstance3D
@export var atlas_rows := 3
@export var atlas_columns := 3

func _ready():
	var mesh := hair_shell_mesh.mesh
	print(mesh)
	if mesh == null:
		return

	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(mesh, 0)
	var arrays = surface_tool.commit_to_arrays()

	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var total = vertices.size()
	multimesh.instance_count = total

	print( total )
	for i in total:
		var xform = Transform3D.IDENTITY
		xform.origin = vertices[i] + hair_shell_mesh.global_transform.origin

		# Random atlas index
		var index = randi() % (atlas_rows * atlas_columns)
		var uv_x = float(index % atlas_columns) / float(atlas_columns)
		var uv_y = float(index / atlas_columns) / float(atlas_rows)
		var custom_data := Color(uv_x, uv_y, 0.0, 0.0)

		multimesh.set_instance_transform(i, xform)
		multimesh.set_instance_custom_data(i, custom_data)
