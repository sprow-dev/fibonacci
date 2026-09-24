import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.math.BigInteger
import java.util.ArrayDeque
import java.util.Queue
import java.util.concurrent.atomic.AtomicBoolean

/*
This is a direct port from Java to Kotlin using Google Gemini.
The reason I did it this way is because I'm not putting the time,
nor the energy, to port between such similar languages.

This does not mean my other code is written by AI, just this one instance.
*/

class Fib {
    class WriteQueue {
        var q: Queue<ByteArray> = ArrayDeque()

        val mtx = Any()

        var chunk = ByteArrayOutputStream(1024 * 1024)
        var exp_buf = ByteArray(0)

        fun push(data: ByteArray) {
            synchronized(mtx) {
                q.add(data)
                (mtx as java.lang.Object).notify()
            }
        }

        fun pop(out_data_wrapper: Array<ByteArray?>, stop: AtomicBoolean): Boolean {
            synchronized(mtx) {
                while (q.isEmpty() && !stop.get()) {
                    try {
                        (mtx as java.lang.Object).wait()
                    } catch (e: InterruptedException) {
                        Thread.currentThread().interrupt()
                        return false
                    }
                }
                if (q.isEmpty() && stop.get()) {
                    return false
                }

                out_data_wrapper[0] = q.poll()

                return true
            }
        }

        fun push_bigint(val_arg: BigInteger) {
            if (exp_buf.size < 1024 * 1024) {
                exp_buf = ByteArray(1024 * 1024)
            }

            val cast_data = val_arg.toByteArray()
            val size = cast_data.size
            val count = 0
            chunk.write(cast_data, 0, size)
            chunk.write(exp_buf, 0, count)
            chunk.write(','.code)

            if (chunk.size() >= 1024 * 1024) {
                synchronized(mtx) {
                    q.add(chunk.toByteArray())

                    if (q.size > 1000) {
                        try {
                            Thread.sleep(1)
                        } catch (e: InterruptedException) {
                            Thread.currentThread().interrupt()
                        }
                    }

                    (mtx as java.lang.Object).notify()
                    chunk.reset()
                }
            }
        }

        fun flush_chunk() {
            if (chunk.size() > 0) {
                synchronized(mtx) {
                    q.add(chunk.toByteArray())
                    (mtx as java.lang.Object).notify()
                }
            }
        }
    }

    companion object {
        var wq = WriteQueue()
        var stop_flag = AtomicBoolean(false)

        @JvmStatic
        fun t_producer() {
            var a = BigInteger.ZERO
            var b = BigInteger.ONE
            var next: BigInteger

            while (!stop_flag.get()) {
                next = a.add(b)
                a = b
                b = next

                wq.push_bigint(b)
            }
        }

        @JvmStatic
        fun t_consumer() {
            val fileObj = File("fib.txt")

            // oh. my. java.
            // what the actual heck is this
            try {
                BufferedOutputStream(FileOutputStream(fileObj)).use { file ->
                    // keep in mind this line is unnecessary in c++
                    val chunkWrapper = arrayOfNulls<ByteArray>(1) // mmm mmm mmm double-bytes
                    while (wq.pop(chunkWrapper, stop_flag)) {
                        val chunk = chunkWrapper[0]!!
                        file.write(chunk, 0, chunk.size)
                    }
                    file.flush()
                }
            } catch (e: IOException) {
                System.err.println("Error: Could not create file handle.")
            }
        }

        @JvmStatic
        fun main(args: Array<String>) {
            val bench_time_ms = 5000

            println("Benchmarking fibonacci calculation performance")
            println("Test language: Java")

            val producer = Thread { t_producer() }
            val consumer = Thread { t_consumer() }

            producer.start()
            consumer.start()

            try {
                Thread.sleep(bench_time_ms.toLong())
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
            }

            stop_flag.set(true)

            synchronized(wq.mtx) {
                (wq.mtx as java.lang.Object).notifyAll()
            }

            try {
                producer.join()
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
            }

            wq.flush_chunk()

            try {
                consumer.join()
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
            }

            val fileObj = File("fib.txt")
            val final_size = fileObj.length()

            val written_mb = final_size.toDouble() / (1024.0 * 1024.0)
            val mb_per_sec = written_mb / (bench_time_ms / 1000.0)

            System.out.printf("Benchmark completed in %dms.%n", bench_time_ms)
            System.out.printf("Wrote %.2fmb%n", written_mb)
            System.out.printf("That's %.2f MB/s%n", mb_per_sec)
        }
    }
}
