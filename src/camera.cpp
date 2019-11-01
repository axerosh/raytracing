#include "camera.hpp"

#include "shader-utils.hpp"
#include "voxel-generator.hpp"

#include "VectorUtils3.h"


//----------------------Constants----------------------------------------------

#define ROTATE_RATE 0.01
#define ZOOM_RATE   0.25 * VOXEL_WIDTH * VOXEL_COUNT
#define MAX_Y       0.499 * M_PI
#define MAX_ZOOM    0.01
#define VIEW_OFFSET 3.0
#define VIEW_TARGET vec3(0.5 * VOXEL_COUNT * VOXEL_WIDTH)


//----------------------Implementation-----------------------------------------

Camera::Camera(GLuint shader)
	: shader{shader}, x{0.0}, y{0.0}, zoom{2.5 * VOXEL_COUNT}, mx_prev{0}, my_prev{0}
{
	updateCameraMatrix();
}

void Camera::updateCameraMatrix() {
	mat4 rot_y = Ry(x);
	vec3 sideways = CrossProduct(rot_y * FORWARD, UP);
	vec3 camera_position = ArbRotate(sideways, y) * rot_y * (zoom * BACK) + VIEW_TARGET;
	mat4 camera_to_world_matrix = InvertMat4(lookAtv(camera_position, VIEW_TARGET, UP));
	vec3 view_pos = camera_to_world_matrix * (VIEW_OFFSET * BACK);

	glUseProgram(shader);
	glUniformMatrix4fv(uniformLoc(shader, "camera_to_world_matrix"), 1, GL_TRUE, camera_to_world_matrix.m);
	glUniform3fv(uniformLoc(shader, "view_pos"), 1, (GLfloat *)&view_pos);
}

void Camera::update(float delta_t) {
	if (glutKeyIsDown('z')) {
		zoom -= ZOOM_RATE * delta_t;
		if (zoom < MAX_ZOOM) zoom = MAX_ZOOM;
		updateCameraMatrix();
	} else if (glutKeyIsDown('x')) {
		zoom += ZOOM_RATE * delta_t;
		updateCameraMatrix();
	}
}

void Camera::mouseClicked(int button, int state, int mx, int my)
{
	if (state == GLUT_DOWN)
	{
		mx_prev = mx;
		my_prev = my;
	}
}

void Camera::mouseDragged(int mx, int my)
{
	x -= ROTATE_RATE * (mx - mx_prev);
	y += ROTATE_RATE * (my_prev - my);

	if (y > MAX_Y) {
		y = MAX_Y;
	} else
	if (y < -MAX_Y) {
		y = -MAX_Y;
	}

	updateCameraMatrix();

	mx_prev = mx;
	my_prev = my;

	glutPostRedisplay();
}
