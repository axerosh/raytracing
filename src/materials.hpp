#ifndef MATERIALS_HPP
#define MATERIALS_HPP

#include "gl-import.hpp"

enum class Material : GLubyte {
	VOID = 0,
	GLASS = 1,
	SOLID = 2,
	SEMI_SOLID = 3
};

#endif // MATERIALS_HPP
