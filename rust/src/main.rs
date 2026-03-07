use dashu::integer::UBig;
use std::fs::File;
use std::io::{BufWriter,Write};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;
use std::time::Duration;

// please excuse the messy code, i am new to rust and have excessive commenting to help me learn

fn main() {
    let bench_time_ms = 5000;

    // Arc allows more than one thread to use data
    // AtomicBool is a bool you change on multiple threads
    // We make a new Arc with an AtomicBool initialized to false.
    let stop = Arc::new(AtomicBool::new(false));

    // clone allows you to make a mutable copy of the Arc we just made.
    // Well, it actually points to a memory address but the term mutable
    // makes more sense to me.
    // This allows both the main and worker thread to access stop.
    let trigger_stop = Arc::clone(&stop);

    // the ! tells rust: this isn't a func, its a "placeholder".
    // The official term is "Macro" if you were curious.
    println!("Benchmarking fibonacci calculation performance");
    println!("Test language: Rust");

    let handle = thread::spawn(move || {
        // Note: mut yells to the compiler "YOU CAN CHANGE THIS".

        // Devs like Zero::zero() and One::one() because it
        // is the universal 0 and 1 implementation that works everywhere.
        let mut a = UBig::from(0u8);
        let mut b = UBig::from(1u8);


        // expect is python except but in a parallel universe
        // anyway, we create our fib file.
        let file = File::create("fib.txt").expect("Error: File cannot be created.");

        // This makes our writer object with a buffer. Change the first number
        // (1024 most of the time) to anything but expect strange results.
        let mut writer = BufWriter::with_capacity(1024*1024,file);

        while !trigger_stop.load(Ordering::Relaxed) {
            // We use &b because b is mutable and we don't want to overwrite it.
            // We also just move pointers with this instead of wasting cpu cycles
            // on complex math.
            // Finally, dashu prefers pointers over values.
            let next = &a + &b;
            a = b;
            b = next;

            let bytes =  b.to_be_bytes();

            // To avoid overwriting bytes, we use an immutable reference.
            // .ok() yells "STFU IF ERROR" at the compiler
            writer.write_all(&bytes).ok();
            // this is purely for delimiting, for max speed remove it.
            writer.write_all(b",").ok();
        }

        // We tell the compiler to shut up because we need to flush ram
        // and if there is nothing to flush we just ignore it.
        writer.flush().ok();
    });

    // sleep 5 seconds
    thread::sleep(Duration::from_millis(bench_time_ms));

    // set our thread's pointer to the stop trigger to true
    stop.store(true, Ordering::Relaxed);

    // let it finish its job before shooting it dead
    handle.join().expect("Worker thread couldn't exit gracefully.");

    // Metadata line is so long we need to shorten the string contained.
    let file_meta = std::fs::metadata("fib.txt").expect("Couldn't read file, please check access.");
    let final_size = file_meta.len();

    // these are the values we print
    let written_mb = (final_size as f64) / (1024.0 * 1024.0);
    let mb_per_sec = written_mb / (bench_time_ms as f64 / 1000.0);

    println!("Benchmark completed in {bench_time_ms}ms.");
    println!("Wrote {written_mb:.2}mb");
    println!("That's {mb_per_sec:.2} MB/s");
}
