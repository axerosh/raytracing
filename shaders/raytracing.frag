#version 460

uniform mat4 camera_matrix;

uniform vec3      view_pos;
uniform sampler3D voxel_tex;
uniform float     voxel_density;
uniform float     voxel_width;
uniform int       voxel_count;

in vec3 ray_origin;

out vec4 out_color;


#define VOXEL_WORLD_SKIN vec3(0.0001)
#define BACKGROUND_COLOR vec4(1.0, 0.0, 1.0, 1.0)


float lengthSqrd(vec3 vec) {
	return dot(vec, vec);
}

vec3 to_voxel(vec3 world_pos) {
	return world_pos * voxel_density;
}

vec3 to_world(vec3 voxel_pos) {
	return voxel_pos * voxel_width;
}

struct VoxelRaycastHit {
	vec4  voxel_value;
	ivec3 voxel_coords;
	vec3  world_pos;
	float depth;
	int   voxel_steps;
};

// Ray with origin o, direction dir and inverse (1/dir) dir_inv
struct Ray { vec3 o; vec3 dir; vec3 dir_inv; };

// Axis-aligned bounding box between lo and hi
struct AABB { vec3 lo; vec3 hi; };

// Integer-based axis-aligned bounding box between lo and hi
struct AABBi { ivec3 lo; ivec3 hi; };

/**
 * Returns true if a is encapsulated by b.
 */
bool isInAABBi(ivec3 a, AABBi b) {
	return a.x >= b.lo.x && a.y >= b.lo.y && a.z >= b.lo.z
	    && a.x <= b.hi.x && a.y <= b.hi.y && a.z <= b.hi.z;
}

/**
 * Returns the distance to the specified AABB from the specified ray.
 * Returns -1 if the ray does not intersect the AABB.
 */
float rayDistanceToAABB(const Ray r, const AABB aabb)
{
// References:
//	https://www.reddit.com/r/opengl/comments/8ntzz5/fast_glsl_ray_box_intersection/dzyqwgr
//	https://github.com/stackgl/ray-aabb-intersection

	vec3 dist_lo = (aabb.lo - r.o) * r.dir_inv;
	vec3 dist_hi = (aabb.hi - r.o) * r.dir_inv;
	vec3 dist_min = min(dist_hi, dist_lo);
	vec3 dist_max = max(dist_hi, dist_lo);
	float dist_min_max = max(max(dist_min.x, dist_min.y), dist_min.z);
	float dist_max_min = min(min(dist_max.x, dist_max.y), dist_max.z);
	return dist_min_max > dist_max_min ? -1 : max(dist_min_max, 0.0);
}

/**
 * Sets information about the first set voxel, hit by the specified ray,
 * to the hit parameter.
 *
 * Returns true if there was a hit or false otherwise.
 */
bool voxelRaycast(const Ray r, out VoxelRaycastHit hit)
{
// References:
//	https://theshoemaker.de/2016/02/ray-casting-in-2d-grids/
//	http://www.cse.yorku.ca/~amana/research/grid.pdf

	ivec3 voxel_coords;    // Voxel coordinates
	ivec3 voxel_step;      // Voxel coordinate step, per axis
	float depth;           // Traversed distance along the ray
	vec3  d_depth;         // Change in depth, per axis, if traversing along said axis
	vec3  dd_depth;        // Change in d_depth, per axis, if traversing along said axis
	int   voxel_steps = 0; // Number of steps taken through the voxel space

	// Start at intersection with voxel space AABB
	AABB aabb = AABB(to_world(VOXEL_WORLD_SKIN), to_world(vec3(voxel_count)) - VOXEL_WORLD_SKIN);
	depth = rayDistanceToAABB(r, aabb);
	if (depth < 0.0) {
		// No intersection
		return false;
	}

	// Initialize variables
	voxel_coords = ivec3(floor(to_voxel(r.o + depth * r.dir)));
	voxel_step = ivec3(r.dir.x >= 0.0 ? 1 : -1,
	                   r.dir.y >= 0.0 ? 1 : -1,
	                   r.dir.z >= 0.0 ? 1 : -1);
	vec3 init_offset = vec3(r.dir.x >= 0.0 ? 1.0 : 0.0,
	                        r.dir.y >= 0.0 ? 1.0 : 0.0,
	                        r.dir.z >= 0.0 ? 1.0 : 0.0);
	d_depth = ((voxel_coords + init_offset) * voxel_width - r.o) * r.dir_inv;
	dd_depth = voxel_step * voxel_width * r.dir_inv;

	// Traverse voxel space
	AABBi voxel_bounds = AABBi(ivec3(0), voxel_count - ivec3(1));
	if (lengthSqrd(r.dir) > 0.0) {
		while (isInAABBi(voxel_coords, voxel_bounds)) {

			// Check voxel hit
			vec4 voxel_value = texture(voxel_tex, vec3(voxel_coords) / voxel_count);
			if (voxel_value.x > 0.0) {
				vec3 world_pos = r.o + depth * r.dir;
				hit = VoxelRaycastHit(voxel_value, voxel_coords, world_pos, depth, voxel_steps);
				return true;
			}

			// Traverse to next voxel
			if (d_depth.x <= d_depth.y) {
				if (d_depth.x <= d_depth.z) {
					voxel_coords.x += voxel_step.x;
					depth += d_depth.x;
					d_depth.x += dd_depth.x;
				}
				else {
					voxel_coords.z += voxel_step.z;
					depth += d_depth.z;
					d_depth.z += dd_depth.z;
				}
			}
			else if (d_depth.y <= d_depth.z) {
				voxel_coords.y += voxel_step.y;
				depth += d_depth.y;
				d_depth.y += dd_depth.y;
			}
			else {
				voxel_coords.z += voxel_step.z;
				depth += d_depth.z;
				d_depth.z += dd_depth.z;
			}

			++voxel_steps;
		}
	}

	// No hit
	return false;
}

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