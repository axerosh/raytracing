#include "voxel-generator.hpp"

#include "shader-utils.hpp"

#include <iomanip>
#include <iostream>


void printVoxels(GLubyte grid[VOXEL_COUNT][VOXEL_COUNT][VOXEL_COUNT]) {
	std::cout << "{";
	for (int x = 0; x < VOXEL_COUNT; ++x) {
		if (x > 0)
			std::cout << " ";
		std::cout << "{";
		for (int y = 0; y < VOXEL_COUNT; ++y) {
			std::cout << "{";
			for (int z = 0; z < VOXEL_COUNT; ++z) {
				std::cout << std::setw(3) << (unsigned short) grid[x][y][z];
				if (z < VOXEL_COUNT - 1)
					std::cout << ", ";
			}
			std::cout << "}";
			if (y < VOXEL_COUNT - 1)
				std::cout << ", ";
		}
		std::cout << "}";
		if (x < VOXEL_COUNT - 1)
			std::cout << "," << std::endl;
	}
	std::cout << "}" << std::endl;
}

bool isCenter(int x) {
	return x >= int(0.5 * VOXEL_COUNT - 0.5) && x <= VOXEL_COUNT / 2;
}

bool isCenter(int x, int y) {
	return isCenter(x) && isCenter(y);
}

bool isCenter(int x, int y, int z) {
	return isCenter(x) && isCenter(y) && isCenter(z);
}

bool isWall(int x, int y, int z) {
	return x == 0 || y == 0 || z == 0 ||
		/*x == VOXEL_COUNT - 1 ||*/ y == VOXEL_COUNT - 1 || z == VOXEL_COUNT - 1;
}

void initVoxels(GLuint shader) {
	// Generate voxels
	GLubyte grid[VOXEL_COUNT][VOXEL_COUNT][VOXEL_COUNT] = {};

	static const float MAX_SUM_INV = 1.0 / (3 * (VOXEL_COUNT - 1));

	for (int x = 0; x < VOXEL_COUNT; ++x) {
		for (int y = 0; y < VOXEL_COUNT; ++y) {
			for (int z = 0; z < VOXEL_COUNT; ++z) {
				if (isCenter(x, y, z) ||
				   (isWall(x, y, z) && !(isCenter(x, y) || isCenter(x, z) || isCenter(y, z)))) {
					grid[x][y][z] = 1 + 254 * (x + y + z) * MAX_SUM_INV;
				} else {
					grid[x][y][z] = 0;
				}
			}
		}
	}

	// printVoxels(grid);

	// Init 3D texture
	GLuint voxel_tex;
	glUseProgram(shader);
	glGenTextures(1, &voxel_tex);
	glBindTexture(GL_TEXTURE_3D, voxel_tex);
	glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_BORDER);
	glTexImage3D(GL_TEXTURE_3D, 0, GL_RED, VOXEL_COUNT, VOXEL_COUNT, VOXEL_COUNT,
				0, GL_RED, GL_UNSIGNED_BYTE, grid);

	// Upload voxel-world data
	glUniform1f(uniformLoc(shader, "voxel_density"), 1.0 / VOXEL_WIDTH);
	glUniform1f(uniformLoc(shader, "voxel_width"), VOXEL_WIDTH);
	glUniform1i(uniformLoc(shader, "voxel_count"), VOXEL_COUNT);
}
