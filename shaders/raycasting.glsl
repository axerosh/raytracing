#ifndef RAYCASTING_GLSL
#define RAYCASTING_GLSL

#include aabb.glsl
#include materials.glsl
#include utils.glsl

#define VOXEL_WORLD_SKIN vec3(0.0001)

// Ray with origin o, direction dir and inverse (1/dir) dir_inv
struct Ray { vec3 o; vec3 dir; vec3 dir_inv; };

struct RaycastAABBHit {
	vec3  world_pos;
	float depth;
	vec3  normal;
};

struct RaymarchVoxelHit {
	int   hit_value;
	int   draw_value;
	ivec3 voxel_coords;
	vec3  world_pos;
	float depth;
	vec3  normal;
	float refr_index_ratio;
	float transparency;
};

int getVoxelValue(vec3 voxel_coords) {
	return int(round(255 * texture(voxel_tex, voxel_coords / voxel_count).x));
}

/**
 * Sets information about the first side of the specified AABB, hit by the
 * specified ray, to the hit parameter.
 *
 * Returns true if there was a hit or false otherwise.
 */
bool raycastAABB(const Ray r, const AABB aabb, out RaycastAABBHit hit)
{
// References:
//	https://www.reddit.com/r/opengl/comments/8ntzz5/fast_glsl_ray_box_intersection/dzyqwgr
//	https://github.com/stackgl/ray-aabb-intersection

	vec3 dist_lo = (aabb.lo - r.o) * r.dir_inv;
	vec3 dist_hi = (aabb.hi - r.o) * r.dir_inv;
	vec3 dist_min = min(dist_hi, dist_lo);
	vec3 dist_max = max(dist_hi, dist_lo);
	float dist_max_min = min(min(dist_max.x, dist_max.y), dist_max.z);

	float dist_min_max;
	vec3 normal = vec3(0.0);
	if (dist_min.x >= dist_min.y) {
		if (dist_min.x >= dist_min.z) {
			normal.x = -r.dir.x;
			dist_min_max = dist_min.x;
		}
		else {
			normal.z = -r.dir.z;
			dist_min_max = dist_min.z;
		}
	}
	else if (dist_min.y >= dist_min.z) {
		normal.y = -r.dir.y;
		dist_min_max = dist_min.y;
	}
	else {
		normal.z = -r.dir.z;
		dist_min_max = dist_min.z;
	}

	if (dist_min_max > dist_max_min) {
		// No intersection
		return false;
	}

	float depth = max(dist_min_max, 0.0);
	hit = RaycastAABBHit(r.o + depth * r.dir, depth, normalize(normal));
	return true;
}

/* Voxel raymarching hit condition. */
#define HIT_CONDITION_NONREF 0x0001u
#define HIT_CONDITION_OPAQUE 0x0002u
struct HitCondition {
	uint type; // One of the above constants
	int ref_value;
};

/**
 * Returns true if the specified hit condition is met by the specified
 * hit value.
 */
bool isHitConditionMet(const HitCondition c, int hit_value) {
	if (c.type == HIT_CONDITION_NONREF) {
		return hit_value != c.ref_value;
	}
	else if (c.type == HIT_CONDITION_OPAQUE) {
		return materials[hit_value].refractivity <= 0.0;
	}
	// else unsupported condition type
}

/**
 * Sets information about the first set voxel, hit by the specified ray
 * and meeting the specified hit_condition, to the hit parameter.
 * Stops before the specified maximum depth.
 *
 * Returns true if there was a hit or false otherwise.
 */
bool raymarchVoxels(const Ray r, out RaymarchVoxelHit hit, int start_value, float max_depth, const HitCondition hit_condition)
{
// References:
//	https://theshoemaker.de/2016/02/ray-casting-in-2d-grids/
//	http://www.cse.yorku.ca/~amana/research/grid.pdf

	ivec3 voxel_coords; // Voxel coordinates
	ivec3 voxel_step;   // Change in voxel coordinates, per axis, if traversing along said axis
	vec3  normal;       // Surface normal

	float depth;        // Traversed distance along the ray
	vec3  next_depth;   // New depth, per axis, if traversing along said axis
	vec3  depth_step;   // Change in depth, per axis, if traversing along said axis
	float min_transparency; // Minimum transparency (refractivity) of traversed materials


	// Start at intersection with voxel space AABB
	AABB aabb = AABB(to_world(VOXEL_WORLD_SKIN), to_world(vec3(voxel_count)) - VOXEL_WORLD_SKIN);
	RaycastAABBHit aabb_hit;
	if (!raycastAABB(r, aabb, aabb_hit)) {
		// No intersection
		return false;
	}
	depth = aabb_hit.depth;
	normal = aabb_hit.normal;
	min_transparency = 1.0;

	// Initialize variables
	voxel_coords = ivec3(floor(to_voxel(r.o + depth * r.dir)));
	voxel_step = ivec3(r.dir.x >= 0.0 ? 1 : -1,
	                   r.dir.y >= 0.0 ? 1 : -1,
	                   r.dir.z >= 0.0 ? 1 : -1);
	vec3 init_offset = vec3(r.dir.x >= 0.0 ? 1.0 : 0.0,
	                        r.dir.y >= 0.0 ? 1.0 : 0.0,
	                        r.dir.z >= 0.0 ? 1.0 : 0.0);
	next_depth = (to_world(voxel_coords + init_offset) - r.o) * r.dir_inv;
	depth_step = to_world(voxel_step) * r.dir_inv;

	// Traverse voxel space
	AABBi voxel_bounds = AABBi(ivec3(0), voxel_count - ivec3(1));
	if (lengthSqrd(r.dir) > 0.0) {
		while (depth < max_depth && isInAABBi(voxel_coords, voxel_bounds)) {

			// Check voxel hit
			int hit_value = getVoxelValue(vec3(voxel_coords) + vec3(0.5));
			if (isHitConditionMet(hit_condition, hit_value)) {
				int draw_value = hit_value;
				if (hit_value == STD_VOID_INDEX) {
					// If exiting into actual void, draw previous material
					draw_value = getVoxelValue(vec3(voxel_coords) + normal + vec3(0.5));
				}
				float transparency = 0.0;
				vec3 world_pos = r.o + depth * r.dir;
				float refr_index_ratio = materials[start_value].refraction_index / materials[hit_value].refraction_index;
				hit = RaymarchVoxelHit(hit_value, draw_value, voxel_coords, world_pos, depth, normal, refr_index_ratio, transparency);
				return true;
			}

			// Traverse to next voxel
			if (next_depth.x <= next_depth.y) {
				if (next_depth.x <= next_depth.z) {
					min_transparency = min(min_transparency, materials[hit_value].refractivity);
					depth = next_depth.x;
					normal = vec3(-voxel_step.x, 0.0, 0.0);
					voxel_coords.x += voxel_step.x;
					next_depth.x += depth_step.x;
				}
				else {
					min_transparency = min(min_transparency, materials[hit_value].refractivity);
					depth = next_depth.z;
					normal = vec3(0.0, 0.0, -voxel_step.z);
					voxel_coords.z += voxel_step.z;
					next_depth.z += depth_step.z;
				}
			}
			else if (next_depth.y <= next_depth.z) {
				min_transparency = min(min_transparency, materials[hit_value].refractivity);
				depth = next_depth.y;
				normal = vec3(0.0, -voxel_step.y, 0.0);;
				voxel_coords.y += voxel_step.y;
				next_depth.y += depth_step.y;
			}
			else {
				min_transparency = min(min_transparency, materials[hit_value].refractivity);
				depth = next_depth.z;
				normal = vec3(0.0, 0.0, -voxel_step.z);
				voxel_coords.z += voxel_step.z;
				next_depth.z += depth_step.z;
			}
		}
	}

	if (hit_condition.type == HIT_CONDITION_OPAQUE) {
		// Didn't hit any opaque materials -- Return min transparency
		hit = RaymarchVoxelHit(-1, -1, ivec3(0.0), vec3(0.0), 0.0, vec3(0.0), 0.0, min_transparency);
	}

	// No hit
	return false;
}

/**
 * Sets information about the first voxel different form the specified
 * start value, hit by the specified ray, to the hit parameter.
 *
 * Returns true if there was a hit or false otherwise.
 */
bool raymarchVoxelsDifferent(const Ray r, out RaymarchVoxelHit hit, const int start_value) {
	return raymarchVoxels(r, hit, start_value, 1e20, HitCondition(HIT_CONDITION_NONREF, start_value));
}

/**
 * Sets information about the first opaque voxel, hit by the specified
 * ray, to the hit parameter.
 * Stops before the specified maximum depth.
 *
 * Returns true if there was a hit or false otherwise.
 * hit.transparency is set either way.
 */
bool raymarchVoxelsOpaque(const Ray r, out RaymarchVoxelHit hit, const int start_value, float max_depth) {
	return raymarchVoxels(r, hit, start_value, max_depth, HitCondition(HIT_CONDITION_OPAQUE, 0));
}

#endif // RAYCASTING_GLSL
