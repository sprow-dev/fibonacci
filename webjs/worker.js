// script worker

var running = false;
var stream = null;
var bytesWritten = 0;

self.onmessage = async function (e) {
    var action = e.data.action;

    if (action === "start") {
        try {
            var handle = e.data.handle;
            stream = await handle.createWritable();
            running = true;

            var a = 0n; var b = 1n; var next = 0n;

            var encoder = new TextEncoder();

            while (running) {
                next = a+b;
                a=b;
                b=next;

                var chunk = encoder.encode(b.toString()+',');

                await stream.write(chunk);
                bytesWritten += chunk.byteLength;
            }
        } catch (err) {
            self.postMessage({ type: 'log', message: `Error (t2): ${err.message || err}`});
        }
    }

    if (action === 'stop') {
        isRunning = false;

        if (stream) {
            await stream.close();
            stream = null;
        }

        self.postMessage({
            type: 'complete',
            bytesWritten: bytesWritten
        });

        self.close();
    }
}
