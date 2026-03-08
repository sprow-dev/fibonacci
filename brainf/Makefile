CC = gcc
CFLAGS = -O3 -pthread
BUILD_DIR = build

all: fib

fib: $(BUILD_DIR)/brainf_logic.o main.c
	$(CC) $(CFLAGS) main.c $(BUILD_DIR)/brainf_logic.o -o fib

$(BUILD_DIR)/brainf_logic.o: $(BUILD_DIR)/brainf_logic.c
	$(CC) $(CFLAGS) -c $(BUILD_DIR)/brainf_logic.c -o $(BUILD_DIR)/brainf_logic.o

$(BUILD_DIR)/brainf_logic.c: $(BUILD_DIR)/converter $(BUILD_DIR)/fib.opt
	./$(BUILD_DIR)/converter $(BUILD_DIR)/fib.opt $(BUILD_DIR)/brainf_logic.c

$(BUILD_DIR)/fib.opt: $(BUILD_DIR)/optimizer fib.bf
	./$(BUILD_DIR)/optimizer fib.bf $(BUILD_DIR)/fib.opt

$(BUILD_DIR)/optimizer: optimizer.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) optimizer.c -o $(BUILD_DIR)/optimizer

$(BUILD_DIR)/converter: converter.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) converter.c -o $(BUILD_DIR)/converter

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR) fib fib.txt
