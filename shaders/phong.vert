#version 150

in  vec3 in_pos;
in  vec3 in_normal;
out vec3 var_normal; // Phong
out vec3 var_surface; // Phong (specular)

uniform mat4 mv_matrix;
uniform mat4 proj_matrix;

void main(void)
{
	var_normal = mat3(mv_matrix) * in_normal; // Phong, "fake" normal transformation

	var_surface = vec3(mv_matrix * vec4(in_pos, 1.0)); // Don't include projection here - we only want to go to view coordinates

	gl_Position = proj_matrix * mv_matrix * vec4(in_pos, 1.0); // This should include projection
}
