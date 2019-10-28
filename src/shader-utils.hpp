#ifndef SHADER_UTILS_HPP
#define SHADER_UTILS_HPP

#include "gl-import.hpp"

#include <iostream>


inline
GLint uniformLoc(GLuint program, const GLchar *name) {
	GLint loc = glGetUniformLocation(program, name);
	if (loc < 0) {
		std::cout << "WARNING: Uniform " << name << " not found in program " << program << std::endl;
	}
	return loc;
}

inline
GLint attribLoc(GLuint program, const GLchar *name) {
	GLint loc = glGetAttribLocation(program, name);
	if (loc < 0) {
		std::cout << "WARNING: Attribute " << name << " not found in program " << program << std::endl;
	}
	return loc;
}

#endif // SHADER_UTILS_HPP
