
#include "camera.hpp"
#include "gl-import.hpp"
#include "shader-utils.hpp"
#include "voxel-generator.hpp"

#include "GL_utilities.h"
#include "loadobj.h"
#include "VectorUtils3.h"


//----------------------Constants----------------------------------------------

// initial width and heights
#define W 512
#define H 512

#define CLEAR_COLOR vec3(0.1, 0.1, 0.3)


//----------------------Square Model-------------------------------------------

GLfloat square_vertices[] = {-1.0,-1.0, 0.0,
                             -1.0, 1.0, 0.0,
                              1.0, 1.0, 0.0,
                              1.0,-1.0, 0.0};
GLfloat square_tex_coords[] = {0.0, 0.0,
                               0.0, 1.0,
                               1.0, 1.0,
                               1.0, 0.0};
GLuint square_indices[] = {0, 1, 2, 0, 2, 3};
Model* square_model;


//----------------------Globals------------------------------------------------

GLuint shader = 0;
Camera camera;


//----------------------Implementation-----------------------------------------

void onTimer(int value)
{
	glutPostRedisplay();
	glutTimerFunc(5, &onTimer, value);
}

void init(void)
{
	dumpInfo();  // shader info

	// GL inits
	glClearColor(CLEAR_COLOR.x, CLEAR_COLOR.y, CLEAR_COLOR.z, 0);
	glClearDepth(1.0);
	glEnable(GL_DEPTH_TEST);
	glDisable(GL_CULL_FACE);
	printError("GL inits");

	// Load and compile shaders
	shader = loadShaders("shaders/raytracing.vert", "shaders/raytracing.frag");
	glUseProgram(shader);
	printError("init shader");

	initVoxels(shader);
	printError("init voxels");

	// Load model
	square_model = LoadDataToModel(
		square_vertices, NULL, square_tex_coords, NULL,
		square_indices, 4, 6);
	printError("init model");

	camera = Camera(shader);
	printError("init camera");

	glutTimerFunc(5, &onTimer, 0);
}

void display()
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	camera.update();
	DrawModel(square_model, shader, "in_pos", NULL, NULL);
	glutSwapBuffers();
}

void reshape(GLsizei w, GLsizei h)
{
	glViewport(0, 0, w, h);
	GLfloat screen_ratio = (GLfloat) w / (GLfloat) h;
	glUniform1f(uniformLoc(shader, "screen_ratio"), screen_ratio);
}

void idle()
{
	glutPostRedisplay();
}

void mouse(int button, int state, int x, int y) {
	camera.mouseClicked(button, state, x, y);
}

void motion(int x, int y) {
	camera.mouseDragged(x, y);
}


//-----------------------------main--------------------------------------------

int main(int argc, char *argv[])
{
	glutInit(&argc, argv);

	glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);
	glutInitWindowSize(W, H);

	glutInitContextVersion(4, 6);
	glutCreateWindow ("Ray Tracing");
	glutDisplayFunc(display);
	glutReshapeFunc(reshape);
	glutIdleFunc(idle);
	glutMouseFunc(mouse);
	glutMotionFunc(motion);

	init();
	glutMainLoop();
	exit(0);
}
