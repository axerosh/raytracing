// Phong shaded cube
// (No perspective)
// gcc phongcube.c ../../common/*.c ../../common/Linux/*.c -lGL -o phongcube -I../../common -I../../common/Linux -DGL_GLEXT_PROTOTYPES  -lXt -lX11 -lm

#ifdef __APPLE__
	#include <OpenGL/gl3.h>
	// linking hint for Lightweight IDE
	//uses framework Cocoa
#endif
#include "MicroGlut.h"
#include "GL_utilities.h"
#include "VectorUtils3.h"

#define W 1200
#define H 1200

// Globals
// Data would normally be read from files
GLfloat vertices[8][3] = {{-0.5,-0.5,-0.5},
                          { 0.5,-0.5,-0.5},
                          { 0.5, 0.5,-0.5},
                          {-0.5, 0.5,-0.5},
                          {-0.5,-0.5, 0.5},
                          { 0.5,-0.5, 0.5},
                          { 0.5, 0.5, 0.5},
                          {-0.5, 0.5, 0.5}};
GLfloat normals[8][3] = {{-0.58,-0.58,-0.58},
                         { 0.58,-0.58,-0.58},
                         { 0.58, 0.58,-0.58},
                         {-0.58, 0.58,-0.58},
                         {-0.58,-0.58, 0.58},
                         { 0.58,-0.58, 0.58},
                         { 0.58, 0.58, 0.58},
                         {-0.58, 0.58, 0.58}};
GLubyte cube_indices[36] = { 0,3,2, 0,2,1, 
                             2,3,7, 2,7,6,
                             0,4,7, 0,7,3,
                             1,2,6, 1,6,5,
                             4,5,6, 4,6,7,
                             0,1,5, 0,5,4};

// NEW
GLfloat rot_matrix[] = { 0.7f, -0.7f, 0.0f, 0.0f,
                         0.7f,  0.7f, 0.0f, 0.0f,
                         0.0f,  0.0f, 1.0f, 0.0f,
                         0.0f,  0.0f, 0.0f, 1.0f };

#define FOV 90
#define NEAR 1
#define FAR 30

mat4 proj_matrix = perspective(FOV, (GLfloat) W / (GLfloat) H, NEAR, FAR);

unsigned int vao;
GLuint shader;

float last_time;

float getElapsedTime()
{
	return glutGet(GLUT_ELAPSED_TIME) * 0.001;
}

void init()
{
	last_time = getElapsedTime();

	// three vertex buffer objects, used for uploading the data
	unsigned int vbo, ibo, nbo;

	// GL inits
	glClearColor(0.2,0.2,0.5,0);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);
	printError("GL inits");

	// Load and compile shader
	shader = loadShaders("shaders/phong.vert", "shaders/phong.frag");
	glUseProgram(shader);
	printError("init shader");

	// Upload geometry to the GPU:

	// Allocate and activate Vertex Array Object
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);
	// Allocate Vertex Buffer Objects
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ibo);
	glGenBuffers(1, &nbo);

	// VBO for vertex data
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, 8*3*sizeof(GLfloat), vertices, GL_STATIC_DRAW);
	glVertexAttribPointer(glGetAttribLocation(shader, "in_pos"), 3, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(glGetAttribLocation(shader, "in_pos"));
	printError("init vertices");

	// VBO for normal/color data
	glBindBuffer(GL_ARRAY_BUFFER, nbo);
	glBufferData(GL_ARRAY_BUFFER, 8*3*sizeof(GLfloat), normals, GL_STATIC_DRAW);
	glVertexAttribPointer(glGetAttribLocation(shader, "in_normal"), 3, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(glGetAttribLocation(shader, "in_normal"));
	printError("init normals");

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 36*sizeof(GLubyte), cube_indices, GL_STATIC_DRAW);
	printError("init index");

	// End of upload of geometry

	glUniformMatrix4fv(glGetUniformLocation(shader, "proj_matrix"), 1, GL_TRUE, proj_matrix.m);

	printError("init arrays");
}

GLfloat a = 0.0;

void display()
{
	float current_time = getElapsedTime();
	float delta_t = current_time - last_time;
	last_time = current_time;

	// clear the screen
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	mat4 m1, m2, m, tr;

	a += delta_t;
	m1 = Rz(M_PI/5);
	m2 = Ry(a);
	m = Mult(m2,m1);
	tr = T(0, 0, -2.0);
	m = Mult(tr, m); // tr * ry * rz
	glUniformMatrix4fv(glGetUniformLocation(shader, "mv_matrix"), 1, GL_TRUE, m.m);

	glBindVertexArray(vao); // Select VAO
	glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_BYTE, NULL); // draw object

	printError("display");

	glutSwapBuffers();
}

void reshape(GLsizei w, GLsizei h)
{
	glViewport(0, 0, w, h);
	proj_matrix = perspective(FOV, (GLfloat) w / (GLfloat) h, NEAR, FAR);
	glUniformMatrix4fv(glGetUniformLocation(shader, "proj_matrix"), 1, GL_TRUE, proj_matrix.m);
}

int main(int argc, char *argv[])
{
	glutInit(&argc, argv);
	glutInitContextVersion(4, 6);
	glutInitWindowSize(W, H);
	glutCreateWindow ("Ray Tracing");
	glutRepeatingTimerFunc(20);
	glutDisplayFunc(display);
	glutReshapeFunc(reshape);
	init();
	glutMainLoop();
}
