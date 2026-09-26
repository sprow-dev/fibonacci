// Main -> Worker
export type MWMsg =
    | { action : "start" }
    | { action : "stop"  };

// Worker -> Main
export type WMMsg =
    | { type: "log"; message: string           }
    | { type: "complete"; bytesWritten: number };
