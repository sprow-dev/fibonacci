CFLAGS = -O3 -march=native -flto -fomit-frame-pointer -fno-stack-protector
LDFLAGS = -O3 -flto -pthread -no-pie

BD = build
OBJS = $(BD)/worker.o

all: $(BD) fib

$(BD):
	mkdir -p $(BD)

$(BD)/%.o: %.asm
	nasm -f elf64 $< -o $@

fib: $(OBJS)
	gcc $(CFLAGS) main.c $(OBJS) -o fib $(LDFLAGS)

clean:
	rm -rf $(BD) fib
