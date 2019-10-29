## Problems during development

### Ray casting
- Ray-AABB distance check returning distance to back rather than front, resulting in a concave view of the back of the voxel space.
- The AABB used for the Ray-AABB distance calculations had at first the exact dimensions as the voxel space but this resulted random misses resulting in a spotty circular noise instead of solid surfaces on the outer layers of the voxel space. Solution: skin offset inwards making the AABB slightly smaller than the voxel space.
- Incorrectly increased the depth with the next depth instead of setting it to next depth, resulting in exponential increase of calculated depth inside voxel space, rather than linear.

### 3D textures
- Apparently need to be square and with side lengths being powers of 2 greater than or equal to 4. Otherwise, very weird artifacts emerge.

## References

### Ray-AABB distance/intersection
- https://www.reddit.com/r/opengl/comments/8ntzz5/fast_glsl_ray_box_intersection/dzyqwgr
- https://github.com/stackgl/ray-aabb-intersection

### Ray casting in grid
- https://theshoemaker.de/2016/02/ray-casting-in-2d-grids/
- http://www.cse.yorku.ca/~amana/research/grid.pdf
