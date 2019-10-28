#version 460

uniform mat4  camera_to_world_matrix;
uniform float screen_ratio;

in vec3 in_pos;

out vec3 ray_origin;

void main(void) {
	ray_origin = vec3(camera_to_world_matrix * (vec4(screen_ratio, 1.0, 1.0, 1.0) * vec4(in_pos, 1.0)));
	gl_Position = vec4(in_pos, 1.0);
}
