# Compiler settings
FC = gfortran
ZC = zig
FFLAGS = -O3 -march=native -no-pie -fopenmp
ZFLAGS = build-obj -O ReleaseFast -fno-PIC

# Files
TARGET = fib
Z_OBJ = bigint.o
F_SRC = main.f90

all: $(TARGET)

$(TARGET): $(Z_OBJ) $(F_SRC)
	$(FC) $(FFLAGS) $(F_SRC) $(Z_OBJ) -o $(TARGET)

$(Z_OBJ): bigint.zig
	$(ZC) $(ZFLAGS) bigint.zig -femit-bin=$(Z_OBJ)

clean:
	rm -f $(TARGET) $(Z_OBJ)

run: all
	./$(TARGET)
