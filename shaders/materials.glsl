#ifndef MATERIALS_GLSL
#define MATERIALS_GLSL

#define MATERIAL_COUNT 3
#define STD_VOID_INDEX 0

struct Material {
	vec3  color;
	float diffusivity;
	float specularity;
	float reflectivity;
	float refractivity;
	float refraction_index;
};

// TODO: Draw current material if entering air

Material materials[MATERIAL_COUNT] = {
	Material(vec3(0.0), 0.0, 0.0, 0.0, 0.0, 1.0), // Void
	Material(vec3(1.0), 0.1, 0.7, 0.3, 1.0, 1.5), // Glass
	Material(vec3(1.0), 0.6, 0.5, 0.2, 0.0, 1.0)  // Solid
};

#endif // MATERIALS_GLSL
