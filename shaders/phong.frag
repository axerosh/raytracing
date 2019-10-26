#version 150

// Simplified Phong: No materials, only one, hard coded light source
// and no ambient

out vec4 out_color;
in vec3 var_normal; // Phong
in vec3 var_surface; // Phong (specular)

void main(void)
{
	const vec3 light = vec3(0.58, 0.58, 0.58); // Given in VIEW coordinates!
	float diffuse, specular, shade;

	// Diffuse
	diffuse = dot(normalize(var_normal), light);
	diffuse = max(0.0, diffuse); // No negative light

	// Specular
	vec3 r = reflect(-light, normalize(var_normal));
	vec3 v = normalize(-var_surface); // View direction
	specular = dot(r, v);
	if (specular > 0.0)
		specular = 1.0 * pow(specular, 150.0);
	specular = max(specular, 0.0);
	shade = 0.7*diffuse + 1.0*specular;
	out_color = vec4(shade, shade, shade, 1.0);
}
