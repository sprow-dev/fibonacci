// main script

const { Worker } = require('node:worker_threads');

const BENCH_TIME_MS = 5000;

async function init() {
    try {
        console.log("Benchmarking fibonacci calculation performance");
        console.log("Test language: Node.js");

        const worker = new Worker('./worker.js');

        worker.on('message', (data) => {
            if (data.type === 'log') {
                console.log(data.message);
            } else if (data.type === 'complete') {
                const totalMB = data.bytesWritten / (1024 * 1024);
                const speedMBs = totalMB / (BENCH_TIME_MS / 1000);

                console.log(`Test completed in ${BENCH_TIME_MS}ms.`);
                console.log(`Wrote ${Math.floor(totalMB)} MB`);
                console.log(`That's ${speedMBs.toFixed(2)}MB/s`);
            }
        });

        worker.on('error', (err) => console.log(`Worker Error: ${err.message || err}`));

        worker.postMessage({ action: 'start' });

        await new Promise(resolve => setTimeout(resolve, BENCH_TIME_MS));

        worker.postMessage({ action: 'stop' });

    } catch (err) {
        console.log(`Error: ${err.message || err}`);
    }
}

init();
