import os
import sys
import time
import threading

BUF_SIZE_KB = 1024
MAX_FILE_BYTES = 1024*1024*1024 # 0 for infinite
BENCH_TIME_MS = 5000

sys.set_int_max_str_digits(0) # do not remove this line unless you like broken code

def worker(stop):
    a,b = 0,1

    with open("fib.txt", "wb", buffering=BUF_SIZE_KB*1024) as f:
        while not stop.is_set():
            a,b=b,a+b

            f.write((b.to_bytes((b.bit_length()+7)//8,'big') + b'\x2C'))

trigger_stop = threading.Event()
t = threading.Thread(target=worker,args=(trigger_stop,))

try:
    print("Deleting old fibonacci data")
    os.remove("fib.txt")
except FileNotFoundError:
    pass

print("Benchmarking fibonacci calculation performance")
print("Test language: Python")

t.start()
time.sleep(BENCH_TIME_MS/1000)
trigger_stop.set()
t.join()

final_size = os.path.getsize("fib.txt")

print(f"Test completed in {BENCH_TIME_MS}ms.")
print(f"Wrote {final_size // (1024*1024)} MB")
print(f"Speed: Approximately {(final_size/(BENCH_TIME_MS/1000))/(1024*1024):.2f}MB/s")
