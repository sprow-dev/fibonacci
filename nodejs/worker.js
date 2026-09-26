// fibonacci generator and writer
const { parentPort } = require('node:worker_threads');
const fs = require('node:fs');

let running = false;
let stream = null;
let bytesWritten = 0;

parentPort.on('message', async (data) => {
    if (data.action === 'start') {
        try {
            stream = fs.createWriteStream('./fib.txt');
            running = true;

            let a = 0n;
            let b = 1n;

            while (running) {
                const next = a + b;
                a = b;
                b = next;

                const chunk = Buffer.from(b.toString() + ',');

                bytesWritten += chunk.byteLength;

                if (!stream.write(chunk)) {
                    await new Promise(resolve => stream.once('drain', resolve));
                }
            }
        } catch (err) {
            parentPort.postMessage({ type: 'log', message: `Error: ${err.message || err}` });
        }
    }

    if (data.action === 'stop') {
        running = false;

        if (stream) {
            stream.end(() => {
                parentPort.postMessage({ type: 'complete', bytesWritten });
                process.exit(0);
            });
        } else {
            process.exit(0);
        }
    }
});
