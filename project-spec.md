<div align=right>Axel Nordanskog, axeno840</div>

# Projekt-spec — Ray tracing och dylikt

Jag har tänkt implementera ray tracing i OpenGL:s ordinarie pipeline, snarare än med compute shaders, CUDA eller OpenCL.

## Skall-krav
1. Ray tracing mot voxel-geometeri.
1. Punktljus — Hårda skuggor.
1. Phong shading.
1. Spegling.
1. Spekulär reflektion.
1. Diffus reflektion.
1. Refraktion.
1. Voxelisering av godtycklig polygon-geometri.

## Bör-krav
1. Ljus genom semitransparenta material.
1. Octree-geometri snarare än rent 3D-grid.
1. Ljuskällor med area — Mjuka skuggor.
1. Voxel cone tracing.
1. En av följande:
	1. Marching-cubes-visualisering av voxlar.
	2. Ray tracing mot polygon-geometri vars motsvarande voxlar har träffats.

## Milstolpe
Skall-krav 1–7 klara till vecka 46-47.

## Gruppmedlemmar
1st: Axel Nordanskog, axeno840

## Svårighetsgrad
Medel till avancerat.