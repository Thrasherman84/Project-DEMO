shader_type spatial;
render_mode unshaded;

uniform sampler2D hair_atlas;
uniform sampler2D hair_atlas_alpha;
uniform int atlas_rows = 3;
uniform int atlas_columns = 3;

/*
void vertex() {
    // Transform vertex from object space into instance world space
    vec3 world_pos = VERTEX;//(INSTANCE_TRANSFORM * vec4(VERTEX, 1.0)).xyz;

    // Get camera forward/right/up vectors from VIEW_MATRIX
    vec3 right = normalize(VIEW_MATRIX[0].xyz);
    vec3 up = normalize(VIEW_MATRIX[1].xyz);

    // Full billboard: make it face the camera regardless of camera angle
    vec3 billboard_pos = world_pos
                       + VERTEX.x * right
                       + VERTEX.y * up;

    //VERTEX = billboard_pos;
}
*/

void fragment() {
    vec2 atlas_offset = vec2(0.0,0.0);

	//INSTANCE_ID
    vec2 atlas_uv = UV / vec2(float(atlas_columns), float(atlas_rows)) + atlas_offset;
    vec4 tex_color = vec4(
		texture(hair_atlas, atlas_uv).rgb,
		texture(hair_atlas_alpha, atlas_uv).r
	);

	tex_color.rgb = vec3(1.0,0.0,1.0);
    ALBEDO = tex_color.rgb;
    ALPHA = 1.0;//tex_color.a;
}
