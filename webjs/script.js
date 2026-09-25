// html script

var BENCH_TIME_MS = 5000;

var con = document.getElementById("con");
var worker = new Worker('worker.js');

function conLog(text) {
    if (!text) return;
    con.textContent += (con.textContent ? '\n' : '') + text;
    console.log(text);
}

async function init() {
    try {
        document.getElementById("init").remove();

        const fileHandle = await window.showSaveFilePicker({
            suggestedName: 'fib.txt',
            types: [{
                description: 'Text Files',
                accept: { 'text/plain': ['.txt'] },
            }],
        });

        conLog("Benchmarking fibonacci calculation performance");
        conLog("Test language: Web JS");

        worker.onmessage = function (e) {
            var data = e.data;
            if (data.type === 'log') {
                conLog(data.message);
            } else if (data.type === 'complete') {
                var totalBytes = data.bytesWritten;
                var totalMB = totalBytes / (1024 * 1024);
                var seconds = BENCH_TIME_MS / 1000;
                var speedMBs = totalMB / seconds;

                conLog(`Test completed in ${BENCH_TIME_MS}ms.`);
                conLog(`Wrote ${Math.floor(totalMB)} MB`);
                conLog(`Speed: Approximately ${speedMBs.toFixed(2)}MB/s`);
            }
        };

        worker.postMessage({ action: 'start', handle: fileHandle });
        await new Promise(resolve => setTimeout(resolve, BENCH_TIME_MS));
        worker.postMessage({ action: 'stop' });

    } catch (err) {
        if (err.name === 'AbortError') {
            conLog('Stopped. Reload the page to try again.');
        } else {
            conLog(`Error: ${err.message || err}`);
        }
    }
}

console.log("IHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORSIHATECORS");
