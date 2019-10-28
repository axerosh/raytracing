#ifndef CAMERA_HPP
#define CAMERA_HPP

#include "gl-import.hpp"


class Camera {

public:
	Camera(GLuint shader);
	Camera() : Camera(0) {};

	void updateCameraMatrix();
	void update();
	void mouseClicked(int button, int state, int mx, int my);
	void mouseDragged(int mx, int my);

private:
	GLuint shader;
	float x, y;
	float zoom;
	int mx_prev, my_prev;
};

#endif // CAMERA_HPP
