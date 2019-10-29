#version 460

uniform mat4      camera_matrix;
uniform vec3      view_pos;
uniform sampler3D voxel_tex;
uniform float     voxel_density;
uniform float     voxel_width;
uniform int       voxel_count;

#include raycasting.glsl

in vec3 ray_origin;

out vec4 out_color;


#define BACKGROUND_COLOR vec4(1.0, 0.0, 1.0, 1.0)

void main()
{
	vec3 ray_dir = normalize(ray_origin - view_pos);
	Ray r = Ray(ray_origin, ray_dir, vec3(1.0) / ray_dir);

	VoxelRaycastHit hit;
	if (voxelRaycast(r, hit)) {
		out_color = vec4(vec3(hit.voxel_value.x) * vec3(0.5, 1.0, 1.0), 1.0);
	}
	else {
		out_color = BACKGROUND_COLOR;
	}
}