#ifndef RAYCASTING_GLSL
#define RAYCASTING_GLSL

#include aabb.glsl
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
	vec4  voxel_value;
	ivec3 voxel_coords;
	vec3  world_pos;
	float depth;
	vec3  normal;
};

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

/**
 * Sets information about the first set voxel, hit by the specified ray,
 * to the hit parameter.
 * Stops before the specified maximum depth.
 *
 * Returns true if there was a hit or false otherwise.
 */
bool raymarchVoxels(const Ray r, out RaymarchVoxelHit hit, float max_depth = 1e20)
{
// References:
//	https://theshoemaker.de/2016/02/ray-casting-in-2d-grids/
//	http://www.cse.yorku.ca/~amana/research/grid.pdf

	ivec3 voxel_coords; // Voxel coordinates
	ivec3 voxel_step;   // Change in voxel coordinates, per axis, if traversing along said axis
	vec3 normal;        // Surface normal

	float depth = 0;    // Traversed distance along the ray, in voxel space
	vec3  next_depth;   // New depth, per axis, if traversing along said axis
	vec3  depth_step;   // Change in depth, per axis, if traversing along said axis


	// Start at intersection with voxel space AABB
	AABB aabb = AABB(to_world(VOXEL_WORLD_SKIN), to_world(vec3(voxel_count)) - VOXEL_WORLD_SKIN);
	RaycastAABBHit aabb_hit;
	if (!raycastAABB(r, aabb, aabb_hit)) {
		// No intersection
		return false;
	}
	depth = aabb_hit.depth;
	normal = aabb_hit.normal;

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
			vec4 voxel_value = texture(voxel_tex, (vec3(voxel_coords) + vec3(0.5)) / voxel_count);
			if (voxel_value.x > 0.0) {
				vec3 world_pos = r.o + depth * r.dir;
				hit = RaymarchVoxelHit(voxel_value, voxel_coords, world_pos, depth, normal);
				return true;
			}

			// Traverse to next voxel
			if (next_depth.x <= next_depth.y) {
				if (next_depth.x <= next_depth.z) {
					depth = next_depth.x;
					normal = vec3(-voxel_step.x, 0.0, 0.0);
					voxel_coords.x += voxel_step.x;
					next_depth.x += depth_step.x;
				}
				else {
					depth = next_depth.z;
					normal = vec3(0.0, 0.0, -voxel_step.z);
					voxel_coords.z += voxel_step.z;
					next_depth.z += depth_step.z;
				}
			}
			else if (next_depth.y <= next_depth.z) {
				depth = next_depth.y;
				normal = vec3(0.0, -voxel_step.y, 0.0);;
				voxel_coords.y += voxel_step.y;
				next_depth.y += depth_step.y;
			}
			else {
				depth = next_depth.z;
				normal = vec3(0.0, 0.0, -voxel_step.z);
				voxel_coords.z += voxel_step.z;
				next_depth.z += depth_step.z;
			}
		}
	}

	// No hit
	return false;
}

#endif // RAYCASTING_GLSL
