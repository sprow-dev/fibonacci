// main script

import { Worker } from 'node:worker_threads';
import type { MWMsg, WMMsg } from './types.ts';

const BENCH_TIME_MS = 5000;

async function init(): Promise<void> {
    try {
        console.log("Benchmarking fibonacci calculation performance");
        console.log("Test language: TypeScript");

        const worker = new Worker('./worker.ts');

        worker.on('message', (data: WMMsg) => {
            if (data.type === "log") {
                console.log(data.message);
            } else if (data.type === "complete") {
                const totalMB = data.bytesWritten / (1024 * 1024);
                const speedMBs = totalMB / (BENCH_TIME_MS / 1000);

                console.log(`Test completed in ${BENCH_TIME_MS}ms.`);
                console.log(`Wrote ${Math.floor(totalMB)} MB`);
                console.log(`That's ${speedMBs.toFixed(2)}MB/s`);
            }
        });

        worker.on("error", (err: Error) => console.log(`Worker Error: ${err.message || err}`));

        worker.postMessage({ action: 'start' } as MWMsg);

        await new Promise(resolve => setTimeout(resolve, BENCH_TIME_MS));

        worker.postMessage({ action: 'stop' } as MWMsg);

    } catch (err: Error) {
        console.log(`Error: ${err.message || err}`);
    }
}

init();
