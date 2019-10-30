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
#define LIGHT_RAY_OFFSET 0.001


struct PointLight { vec3 pos; vec3 intensity; };

const float SPACE_WIDTH = voxel_count * voxel_width;
const vec3 SPACE_CENTER = vec3(0.5 * voxel_count * voxel_width);
const float LIGHT_INTENCITY = SPACE_WIDTH * SPACE_WIDTH ;

#define LIGHT_COUNT 3
PointLight lights[LIGHT_COUNT] = {
	PointLight(SPACE_CENTER + SPACE_WIDTH * vec3(0.9, 0.8, 1.0),
	           1.5 * LIGHT_INTENCITY * vec3(1.0, 0.8, 0.7)),
	PointLight(SPACE_CENTER + SPACE_WIDTH * vec3(-0.7, 0.6, 1.0),
	           LIGHT_INTENCITY * vec3(0.7, 0.8, 1.0)),
	PointLight(SPACE_CENTER + vec3(0.5 * SPACE_WIDTH - 1.5 * voxel_width) * vec3(1.0, -0.4, 1.0),
	           0.5 * LIGHT_INTENCITY * vec3(0.75, 1.0, 0.75))
};

void main()
{
	vec3 ray_dir = normalize(ray_origin - view_pos);
	Ray r = Ray(ray_origin, ray_dir, vec3(1.0) / ray_dir);

	RaymarchVoxelHit hit;
	if (raymarchVoxels(r, hit)) {
		vec3 light = vec3(0.0);
		for (int i = 0; i < LIGHT_COUNT; ++i) {
			RaymarchVoxelHit occluderHit;
			vec3 light_offset = lights[i].pos - hit.world_pos;
			vec3 to_light = normalize(light_offset);
			Ray light_r = Ray(hit.world_pos + LIGHT_RAY_OFFSET * hit.normal, to_light, vec3(1.0) / to_light);
			if (!raymarchVoxels(light_r, occluderHit, length(light_offset))) {
				light += lights[i].intensity / lengthSqrd(light_offset);
			}
		}
		light = max(vec3(0.0), light);
		out_color = vec4(light /* * vec3(hit.voxel_value.x) */, 1.0);
	}
	else {
		out_color = BACKGROUND_COLOR;
	}
}
