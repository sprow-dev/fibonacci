import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.util.ArrayDeque;
import java.util.Queue;
import java.util.concurrent.atomic.AtomicBoolean;

/*
This has taken me a while to write because life got in the way.
I finally found the time to resume the project so here I am again.

If you want comments/documentation for the code, please cite the C++ implementation.
This is a direct transcription from that to Java.
*/

public class Fib
{
    static class WriteQueue {
        public Queue<byte[]> q = new ArrayDeque<>();

        public final Object mtx = new Object();

        public ByteArrayOutputStream chunk = new ByteArrayOutputStream(1024*1024);
        public byte[] exp_buf = new byte[0];

        public void push(byte[] data) {
            synchronized (mtx) {
                q.add(data);
                mtx.notify();
            }
        }

        public boolean pop(byte[] out_data_wrapper[], AtomicBoolean stop) {
            synchronized (mtx) {
                while (q.isEmpty() && !stop.get()) {
                    try {
                        mtx.wait();
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        return false;
                    }
                }
                if (q.isEmpty() && stop.get()) {
                    return false;
                }

                out_data_wrapper[0] = q.poll();

                return true;
            }
        }

        public void push_bigint(BigInteger val) {
            if (exp_buf.length < 1024*1024) {
                exp_buf = new byte[1024*1024];
            }

            byte[] cast_data = val.toByteArray();
            int size = cast_data.length;
            int count = 0;
            chunk.write(cast_data, 0, size);
            chunk.write(exp_buf, 0, count);
            chunk.write((byte) ',');

            if (chunk.size() >= 1024*1024) {
                synchronized (mtx) {
                    q.add(chunk.toByteArray());

                    if (q.size() > 1000) {
                        try {
                            Thread.sleep(1);
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                        }
                    }

                    mtx.notify();
                    chunk.reset();
                }
            }
        }

        public void flush_chunk() {
            if (chunk.size() > 0) {
                synchronized (mtx) {
                    q.add(chunk.toByteArray());
                    mtx.notify();
                }
            }
        }
    }

    static WriteQueue wq = new WriteQueue();
    static AtomicBoolean stop_flag = new AtomicBoolean(false);

    public static void t_producer() {
        BigInteger a = BigInteger.ZERO;
        BigInteger b = BigInteger.ONE;
        BigInteger next;

        while (!stop_flag.get()) {
            next=a.add(b);
            a=b;
            b=next;

            wq.push_bigint(b);
        }
    }

    public static void t_consumer() {
        File fileObj = new File("fib.txt");

        // oh. my. java.
        // what the actual heck is this
        try (BufferedOutputStream file = new BufferedOutputStream(new FileOutputStream(fileObj))) {
            // keep in mind this line is unnecessary in c++
            byte[][] chunkWrapper = new byte[1][]; // mmm mmm mmm double-bytes
            while(wq.pop(chunkWrapper,stop_flag)){
                byte[] chunk=chunkWrapper[0];
                file.write(chunk,0,chunk.length);
            }
            file.flush();
        } catch (IOException e) {
            System.err.println("Error: Could not create file handle.");
        }
    }

    public static void main(String[] args) {
        int bench_time_ms = 5000;

        System.out.println("Benchmarking fibonacci calculation performance");
        System.out.println("Test language: Java");

        Thread producer = new Thread(Fib::t_producer);
        Thread consumer = new Thread(Fib::t_consumer);

        producer.start();
        consumer.start();

        try {
            Thread.sleep(bench_time_ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        stop_flag.set(true);

        synchronized (wq.mtx) {
            wq.mtx.notifyAll();
        }

        try {
            producer.join();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        wq.flush_chunk();

        try {
            consumer.join();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        File fileObj = new File("fib.txt");
        long final_size = fileObj.length();

        double written_mb = (double) final_size / (1024.0 * 1024.0);
        double mb_per_sec = written_mb / (bench_time_ms / 1000.0);

        System.out.printf("Benchmark completed in %dms.%n", bench_time_ms);
        System.out.printf("Wrote %.2fmb%n", written_mb);
        System.out.printf("That's %.2f MB/s%n", mb_per_sec);
    }
}
