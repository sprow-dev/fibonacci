// fibonacci generator and writer
import { parentPort } from 'node:worker_threads';
import { WriteStream, createWriteStream } from 'node:fs';
import type { MainToWorkerMessage, WorkerToMainMessage } from './types.js';

let running = false;
// literally what is this
let stream: WriteStream | null = null;
let bytesWritten = 0;

// stupid typescript back at it again with null safety
if (!parentPort) {
    throw new Error('This file must be run as a worker thread.');
}

parentPort.on('message', async (data: MWMsg) => {
    if (data.action === 'start') {
        try {
            stream = createWriteStream('./fib.txt');
            running = true;

            let a = 0n;
            let b = 1n;

            while (running) {
                const next = a + b;
                a = b;
                b = next;

                const chunk = Buffer.from(b.toString() + ',');

                bytesWritten += chunk.byteLength;

                if (stream && !stream.write(chunk)) {
                    await new Promise<void>(resolve => stream?.once('drain', resolve));
                }
            }
        } catch (err: Error) {
            parentPort.postMessage({ type: 'log', message: `Error: ${err.message || err}` } as MWMsg);
        }
    }

    if (data.action === 'stop') {
        running = false;

        if (stream) {
            stream.end(() => {
                parentPort.postMessage({ type: 'complete', bytesWritten } as WMMsg);
                process.exit(0);
            });
        } else {
            process.exit(0);
        }
    }
});
