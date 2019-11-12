#version 460

uniform mat4      camera_matrix;
uniform vec3      view_pos;
uniform sampler3D voxel_tex;
uniform float     voxel_density;
uniform float     voxel_width;
uniform int       voxel_count;

#include materials.glsl
#include raycasting.glsl

in vec3 ray_origin;

out vec4 out_color;

#define AMBIENT_LIGHT vec3(0.05, 0.075, 0.1)
#define RECURSIVE_RAY_OFFSET 0.001

#define MAX_REFLECTION_DEPTH 4
#define MAX_REFRACTION_DEPTH 4

#define MAX_ITERATIONS ((1 << (min(MAX_REFLECTION_DEPTH, MAX_REFRACTION_DEPTH)) + 1) - 1 \
	+ abs(MAX_REFLECTION_DEPTH - MAX_REFRACTION_DEPTH) * (1 << min(MAX_REFLECTION_DEPTH, MAX_REFRACTION_DEPTH)))
// = 2^(min_d+1) - 1 + (max_d - min_d) * 2^(min_d)
// = 2^0 + 2^1 + ... + 2^min_d + (max_d - min_d) * 2^min_d

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

struct RaytraceIteration {
	Ray ray;
	int recursion_depth;
	int void_value;
	int refl_i; // Index of reflection ray
	int refr_i; // Index of refraction ray
	bool has_hit;
	RaymarchVoxelHit hit;
	vec3 color;
};

RaytraceIteration newIteration(Ray ray, int recursion_depth, int void_value) {
	RaymarchVoxelHit dummy_hit;
	return RaytraceIteration(ray, recursion_depth, void_value, -1, -1, false, dummy_hit, vec3(0.0));
}

void main()
{
	vec3 ray_dir = normalize(ray_origin - view_pos);
	Ray primary_ray = Ray(ray_origin, ray_dir, vec3(1.0) / ray_dir);

	// Binary tree of raytracing iterations
	RaytraceIteration r[MAX_ITERATIONS];
	Ray dummy_ray = Ray(vec3(0.0), vec3(0.0), vec3(0.0));
	for (int i = 0; i < MAX_ITERATIONS; ++i) r[i].ray = dummy_ray; // To avoid warning C7050
	r[0] = newIteration(primary_ray, 0, 0);
	int i = 0;
	int last_i = 0;

	// Cast recursive rays
	for ( ; i <= last_i; ++i) {
		if (raymarchVoxels(r[i].ray, r[i].hit, r[i].void_value)) {
			r[i].has_hit = true;
			Material material = materials[r[i].hit.draw_value];
			// Reflection
			if (material.reflectivity > 0.0 && r[i].recursion_depth < MAX_REFLECTION_DEPTH) {
				vec3 refl_dir = normalize(reflect(r[i].ray.dir, r[i].hit.normal));
				vec3 offset_pos = r[i].hit.world_pos + RECURSIVE_RAY_OFFSET * r[i].hit.normal;
				Ray reflection_ray = Ray(offset_pos, refl_dir, vec3(1.0) / refl_dir);
				++last_i;
				r[last_i] = newIteration(reflection_ray, r[i].recursion_depth + 1, r[i].void_value);
				r[i].refl_i = last_i;
			}
			// Refraction
			if (material.refractivity > 0.0 && r[i].recursion_depth < MAX_REFRACTION_DEPTH) {
				vec3 refr_dir = normalize(refract(r[i].ray.dir, r[i].hit.normal, r[i].hit.refr_index_ratio));
				vec3 offset_pos = r[i].hit.world_pos - RECURSIVE_RAY_OFFSET * r[i].hit.normal;
				Ray refraction_ray = Ray(offset_pos, refr_dir, vec3(1.0) / refr_dir);
				++last_i;
				r[last_i] = newIteration(refraction_ray, r[i].recursion_depth + 1, r[i].hit.hit_value);
				r[i].refr_i = last_i;
			}
		}
	}

	// Trace back colors from rays
	for ( ; i >= 0; --i) {
		if (r[i].has_hit) {
			vec3 offset_pos = r[i].hit.world_pos + RECURSIVE_RAY_OFFSET * r[i].hit.normal;
			Material material = materials[r[i].hit.draw_value];

			// Lighting
			vec3 diffuse_light = vec3(0.0);
			vec3 specular_light = vec3(0.0);

			if (material.diffusivity > 0.0 || material.specularity > 0.0) {
				for (int light_i = 0; light_i < LIGHT_COUNT; ++light_i) {

					vec3 light_offset = lights[light_i].pos - r[i].hit.world_pos;
					vec3 to_light = normalize(light_offset);
					Ray shadow_ray = Ray(offset_pos, to_light, vec3(1.0) / to_light);

					RaymarchVoxelHit shadow_hit;
					if (!raymarchVoxels(shadow_ray, shadow_hit, r[i].void_value, length(light_offset))) {

						// Brightness
						vec3 brightness = lights[light_i].intensity / lengthSqrd(light_offset);

						// Diffuse
						diffuse_light += max(vec3(0.0), brightness * dot(r[i].hit.normal, to_light));

						// Specular
						float specular = dot(reflect(to_light, r[i].hit.normal), primary_ray.dir);
						if (specular > 0.0)
							specular = 1.0 * pow(specular, 150.0);
						specular_light += max(vec3(0.0), brightness * specular);
					}
				}
			}

			// From recursion
			vec3 reflection_color = r[i].refl_i != -1 ? r[r[i].refl_i].color : vec3(0.0);
			vec3 refraction_color = r[i].refr_i != -1 ? r[r[i].refr_i].color : vec3(0.0);

			r[i].color =
				material.color
				* (material.diffusivity * diffuse_light
				 + material.specularity * specular_light)
				+ material.reflectivity * reflection_color
				+ material.refractivity * refraction_color;
		}
	}

	// Final color
	out_color = vec4(AMBIENT_LIGHT + r[0].color, 1.0);
}
