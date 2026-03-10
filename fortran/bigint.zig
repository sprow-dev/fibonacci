const std = @import("std");
const BigInt = std.math.big.int.Managed;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

var a: BigInt = undefined;
var b: BigInt = undefined;
var n: BigInt = undefined;

pub export fn init() void {
    a = BigInt.initSet(allocator, 0) catch unreachable;
    b = BigInt.initSet(allocator, 1) catch unreachable;
    n = BigInt.init(allocator) catch unreachable;

    // prealloc for speed
    n.ensureCapacity(1024*1024) catch unreachable;
    a.ensureCapacity(1024*1024) catch unreachable;
    b.ensureCapacity(1024*1024) catch unreachable;
}

pub export fn step(out_len:*usize) [*]const u8 {
    n.add(&a,&b) catch unreachable;
    a.copy(b.toConst()) catch unreachable;
    b.copy(n.toConst()) catch unreachable;

    const limbs = b.limbs;
    const bytes = std.mem.sliceAsBytes(limbs);
    out_len.* = bytes.len;
    return bytes.ptr;
}

pub export fn deinit() void {
    a.deinit();
    b.deinit();
    n.deinit();
}
