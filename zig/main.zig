const std = @import("std");
const BigInt = std.math.big.int.Managed;
const time = std.time;
const Thread = std.Thread;
const Atomic = std.atomic.Value;

var stop_flag = Atomic(bool).init(false);

pub fn main() !void {
    var stdout = std.fs.File.stdout();

    try stdout.writeAll("Benchmarking fibonacci calculation performance\n");
    try stdout.writeAll("Test language: Zig\n");

    // leak check
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const thread = try Thread.spawn(.{},worker,.{allocator});

    Thread.sleep(5*time.ns_per_s);
    stop_flag.store(true,.release);

    thread.join();

    const file = try std.fs.cwd().openFile("fib.txt",.{});
    defer file.close();
    const final_size = try file.getEndPos();

    const size_mb = @as(f64,@floatFromInt(final_size))/(1024.0*1024.0);
    const mb_per_s = size_mb/5.0;

    var sbuf: [128]u8 = undefined;

    try stdout.writeAll("Test completed in 5s.\n");
    const mbw = try std.fmt.bufPrint(&sbuf, "Wrote {d:.2} MB\n", .{size_mb});
    try stdout.writeAll(mbw);
    const mbs = try std.fmt.bufPrint(&sbuf, "That's {d:.2} MB/s\n", .{mb_per_s});
    try stdout.writeAll(mbs);
}

fn worker(allocator:std.mem.Allocator) void {
    // init bigints
    var a = BigInt.initSet(allocator,0) catch return;
    var b = BigInt.initSet(allocator,1) catch return;
    var next = BigInt.init(allocator) catch return;
    defer a.deinit();
    defer b.deinit();
    defer next.deinit();
    next.ensureCapacity(1024*1024) catch return;
    a.ensureCapacity(1024*1024) catch return;
    b.ensureCapacity(1024*1024) catch return;

    const f = std.fs.cwd().createFile("fib.txt",.{}) catch return;
    defer f.close();

    var buf: [1024*1024]u8 = undefined;
    var bufwriter = f.writer(buf[0..]);
    var writer = &bufwriter.interface;

    while (!stop_flag.load(.acquire)) {
        next.add(&a,&b) catch break;
        a.copy(b.toConst()) catch break;
        b.copy(next.toConst()) catch break;

        const slice = b.limbs[0..b.limbs.len];
        const bytes = std.mem.sliceAsBytes(slice);

        writer.writeAll(bytes) catch break;
        writer.writeByte(',') catch break;
    }
}
