-- This code is mostly C with a bit of Lua.
-- That's like making a skyscraper with legos and gorilla glue.
-- Main reason is GMP and multithreading because Lua is
-- monolithic by design.

local ffi = require ("ffi") -- my eyes are already bleeding

local CACHE_SIZE = 8*1024*1024 -- help lua with 8mb cache
ffi.cdef[[
    // GMP support
    typedef unsigned long mp_limb_t;
    typedef struct { int _mp_alloc; int _mp_size; mp_limb_t * _mp_d; } __mpz_struct;
    typedef __mpz_struct mpz_t[1];

    void __gmpz_init(mpz_t x);
    void __gmpz_init_set_ui(mpz_t x, unsigned long val);
    void __gmpz_add(mpz_t rop, const mpz_t op1, const mpz_t op2);
    void __gmpz_set(mpz_t rop, const mpz_t op1);
    void __gmpz_clear(mpz_t x);

    // C stdio
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    int fclose(FILE *stream);
    int fflush(FILE *stream);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fputc(int c, FILE *stream);
    int setvbuf(FILE *stream, char *buf, int mode, size_t size);
    void *malloc(size_t size);
    void free(void *ptr);
]] -- relief for 1 millisecond

local gmp = ffi.load("gmp") -- and back to my eyes are bleeding land

print("Benchmarking fibonacci calculation performance") -- python statement at last
print("Test language: Lua (Well, mostly C with Lua glue)")

-- do our gross c dance for gmp
local a,b,tmp = ffi.new("mpz_t"),ffi.new("mpz_t"),ffi.new("mpz_t")
gmp.__gmpz_init_set_ui(a, 0)
gmp.__gmpz_init_set_ui(b, 1)
gmp.__gmpz_init(tmp)

local f = ffi.C.fopen("fib.txt", "wb") -- C has better syscall and buffer support
if f == nil then return nil end -- data sanitization

local buf = ffi.C.malloc(CACHE_SIZE)
ffi.C.setvbuf(f, ffi.cast("char*", buf), ffi.cast("int", 0), CACHE_SIZE)

local size = ffi.sizeof("mp_limb_t")

local start_time = os.clock()
while (os.clock() - start_time) < 5 do
    gmp.__gmpz_add(tmp, a, b)
    gmp.__gmpz_set(a, b)
    gmp.__gmpz_set(b, tmp)

    -- these are zero-indexed for c (thank goodness for my eyes)
    local count = ffi.cast("size_t", math.abs(b[0]._mp_size)) -- cast for c-ness
    local data = b[0]._mp_d

    ffi.C.fwrite(data,size,count,f)
    ffi.C.fputc(44,f) -- ','
end

ffi.C.fflush(f)
ffi.C.fclose(f)
ffi.C.free(buf)

gmp.__gmpz_clear(a)
gmp.__gmpz_clear(b)
gmp.__gmpz_clear(tmp)

local f = io.open("fib.txt","rb")
local final_size = f:seek("end")
f:close()

print("Test completed in 5s.")
print(string.format("Wrote %.2f MB", final_size / (1024*1024)))
print(string.format("Speed: Approximately %.2f MB/s", (final_size/5)/(1024*1024)))

