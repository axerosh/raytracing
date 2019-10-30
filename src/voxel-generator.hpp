#ifndef VOXEL_GENERATOR_HPP
#define VOXEL_GENERATOR_HPP

#include "gl-import.hpp"

// Must be power of 2
#define VOXEL_COUNT 16

#define VOXEL_WIDTH 1.0

void printVoxels(GLubyte grid[VOXEL_COUNT][VOXEL_COUNT][VOXEL_COUNT]);
void initVoxels(GLuint shader);

#endif // VOXEL_GENERATOR_HPP
