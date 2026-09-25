{-# LANGUAGE BangPatterns #-}
import Foreign.Marshal.Alloc (mallocBytes)
import Foreign.Ptr (Ptr, plusPtr)
import Foreign.Storable (poke)
import Data.Word (Word8, Word64)
import System.IO (openBinaryFile, IOMode(WriteMode), hPutBuf, hClose)
import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Data.IORef (newIORef, readIORef, writeIORef)
import System.Directory (getFileSize)
import Text.Printf (printf)

-- I have not commented my whole learning process to save your eyes
-- in case you already read the Rust code.

main :: IO ()
main = do
    let benchTimeMs = 5000
    let bufSize = 8 * 1024 * 1024

    stopFlag <- newIORef False
    doneSignal <- newEmptyMVar

    putStrLn "Benchmarking fibonacci calculation performance"
    putStrLn "Test language: Haskell"

    _ <- forkIO $ do
        handle <- openBinaryFile "fib.txt" WriteMode
        ptr <- mallocBytes bufSize

        let fillBuffer !a !b !currPtr !bytesWritten = do
              stop <- readIORef stopFlag
              if stop
                 then do
                   hPutBuf handle ptr bytesWritten
                   hClose handle
                 else if bytesWritten >= bufSize - 16
                      then do
                        hPutBuf handle ptr bytesWritten
                        fillBuffer a b ptr 0
                      else do
                        poke (currPtr :: Ptr Word64) b
                        let commaPtr = currPtr `plusPtr` 8
                        poke (commaPtr :: Ptr Word8) (44 :: Word8)

                        let nextPtr = commaPtr `plusPtr` 1
                        fillBuffer b (a + b) nextPtr (bytesWritten + 9)

        fillBuffer 0 1 ptr 0
        putMVar doneSignal ()

    threadDelay (benchTimeMs * 1000)
    writeIORef stopFlag True

    takeMVar doneSignal
    size <- getFileSize "fib.txt"

    let finalSize = fromIntegral size :: Double
    let writtenMb = finalSize / (1024.0 * 1024.0)
    let seconds = fromIntegral benchTimeMs / 1000.0
    let mbPerSec = writtenMb / seconds

    putStrLn ("Benchmark completed in " ++ show benchTimeMs ++ "ms.")
    printf "Wrote %.0f MB\n" writtenMb
    printf "Speed: Approximately %.2f MB/s\n" mbPerSec
