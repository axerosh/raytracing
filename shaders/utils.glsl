#ifndef UTILS_GLSL
#define UTILS_GLSL

float lengthSqrd(vec3 vec) {
	return dot(vec, vec);
}

vec3 to_voxel(vec3 world_pos) {
	return world_pos * voxel_density;
}

vec3 to_world(vec3 voxel_pos) {
	return voxel_pos * voxel_width;
}

#endif // UTILS_GLSL
