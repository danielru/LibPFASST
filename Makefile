#
# Makefile for libpfasst.
#

#
# config
#

FC     = mpif90 
FFLAGS = -fPIC -Wall -g -pg -Ibuild -Jbuild
FFLAGS += -f90=/home/memmett/gcc-4.8/bin/gfortran -Wno-unused-dummy-argument

STATIC = ar rcs
SHARED = gfortran -shared -Wl,-soname,pfasst

FSRC = $(shell ls src/*.f90)
OBJ  = $(subst src,build,$(FSRC:.f90=.o))

MKVERBOSE =

# generate src/pf_version.f90
$(shell python tools/version.py src/pf_version.f90)


#
# rules
#

all: build/libpfasst.a # build/libpfasst.so 

build/libpfasst.so: $(OBJ)
	$(SHARED) -o build/libpfasst.so $(OBJ)

build/libpfasst.a: $(OBJ)
	$(STATIC) build/libpfasst.a $(OBJ)

build/%.o: src/%.f90
	@mkdir -p build
ifdef MKVERBOSE
	$(FC) $(FFLAGS) -c $< $(OUTPUT_OPTION)
else
	@echo FC $(notdir $<)
	@$(FC) $(FFLAGS) -c $< $(OUTPUT_OPTION)
endif

clean:
	rm -rf build libpfasst.*

#
# dependencies
#

build/pf_utils.o:       build/pf_dtype.o
build/pf_timer.o:       build/pf_dtype.o
build/pf_explicit.o:    build/pf_timer.o
build/pf_hooks.o:       build/pf_timer.o
build/pf_imex.o:        build/pf_timer.o
build/pf_implicit.o:    build/pf_timer.o
build/pf_mpi.o:         build/pf_timer.o
build/pf_restrict.o:    build/pf_utils.o build/pf_timer.o
build/pf_interpolate.o: build/pf_restrict.o
build/pf_parallel.o:    build/pf_interpolate.o build/pf_hooks.o
build/sdc_quadrature.o: build/pf_dtype.o build/sdc_poly.o
build/pf_quadrature.o:  build/sdc_quadrature.o
build/pf_pfasst.o:      build/pf_utils.o build/pf_quadrature.o

build/pfasst.o:         build/pf_parallel.o build/pf_pfasst.o build/pf_implicit.o build/pf_explicit.o build/pf_imex.o build/pf_mpi.o build/pf_version.o 

.PHONY: clean
