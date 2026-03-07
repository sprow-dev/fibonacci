using System;
using System.IO;
using System.Numerics;
using System.Threading;

var benchTimeMs = 5000;

var stop_token = new CancellationTokenSource();

Console.WriteLine("Benchmarking fibonacci calculation performance");
Console.WriteLine("Test language: C# (.NET)");

var worker = new Thread(() => Worker("fib.txt",stop_token.Token));
worker.Start();
Thread.Sleep(benchTimeMs);
stop_token.Cancel();
worker.Join();

var fileInfo = new FileInfo("fib.txt");
double written_mb = fileInfo.Length / (1024.0*1024.0);
double mb_per_sec = written_mb / (benchTimeMs/1000.0);

Console.WriteLine($"Benchmark completed in {benchTimeMs}ms.");
Console.WriteLine($"Wrote {written_mb:F2}MB");
Console.WriteLine($"That's {mb_per_sec:F2} MB/s");

static void Worker(string path, CancellationToken stop)
{
    // the last arg is our cache, 1mb for this demo.
    using var f = new FileStream(path,FileMode.Create,FileAccess.Write,FileShare.None,1024*1024);

    BigInteger next;
    BigInteger a = 0;
    BigInteger b = 1;

    byte[] buf = new byte[1024*1024];
    ReadOnlySpan<byte> delim = ","u8;

    while (!stop.IsCancellationRequested) {
        next = a+b;
        a = b;
        b = next;

        if (b.TryWriteBytes(buf,out int bytesWritten,isUnsigned:true,isBigEndian:false)) {
            f.Write(buf,0,bytesWritten);
            f.Write(delim);
        }
    }
}
