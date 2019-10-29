#ifndef AABB_GLSL
#define AABB_GLSL

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

#endif // AABB_GLSL
