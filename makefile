src_dir = src
lib_dir = lib
glut_dir = $(lib_dir)/Linux
out_dir = out

src_files = $(wildcard $(src_dir)/*.cpp) $(wildcard $(src_dir)/*.c)
lib_files = $(wildcard $(lib_dir)/*.cpp) $(wildcard $(lib_dir)/*.c)
glut_files = $(wildcard $(glut_dir)/*.c)
out_file = $(out_dir)/raytracing

cflags = -Wall
includes = -I$(src_dir) -I$(lib_dir) -I$(glut_dir)
defines = -DGL_GLEXT_PROTOTYPES
sources = $(src_files) $(lib_files) $(glut_files)
libraries = -lXt -lX11 -lGL -lm

.PHONY: build_and_run build force-build run clean high-res low-res

build_and_run: build run

build: $(sources)
	make force-build

force-build: $(out_dir)
	g++ $(cflags) -o $(out_file) $(includes) $(defines) $(sources) $(libraries)

run:
	./$(out_file)

clean:
	rm -r $(out_dir)

high-res:
	xrandr --output eDP-1-1 --mode 2560x1440

low-res:
	xrandr --output eDP-1-1 --mode 640x360

$(out_dir):
	mkdir $(out_dir)
