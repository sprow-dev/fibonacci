package main

// Go is officially one of my least favorite languages.
// Many reasons. Inconsistent null application, complexity
// added for the sake of saving keywords, inconsistent casing
// rules, the list goes on.

import (
	"bufio"
	"context"
	"fmt"
	"math/big"
	"os"
	"time"
	"slices"
)

const benchTimeMs = 5000

func main( ) {
	contx, stop := context.WithTimeout( context.Background( ), benchTimeMs * time.Millisecond )
	defer stop( )

	fmt.Println( "Benchmarking fibonacci calculation performance" )
	fmt.Println( "Test language: Go"                              )

	done := make(chan struct{ })
	go func( ) {
		worker( "fib.txt", contx )
		close( done )
	}( )

	<-done

	fileInfo, err := os.Stat( "fib.txt" )
	if err != nil {
		fmt.Printf( "Error Checking file stats: %v\n", err)
		return
	}

	MBWritten := float64( fileInfo.Size( ) ) / ( 1024.0 * 1024.0 )
	mbPerSec := MBWritten / ( float64( benchTimeMs ) / 1000.0 )

	fmt.Printf( "Benchmark completed in %dms.\n", benchTimeMs )
	fmt.Printf( "Wrote %.2fMB\n",                   MBWritten )
	fmt.Printf( "That's %.2f MS/s\n",                mbPerSec )
}

func worker( path string, contx context.Context ) {
	file, err := os.Create( path )
	if err != nil {
		fmt.Printf("Error file creation: %v\n", err)
		return
	}

	defer file.Close()

	f := bufio.NewWriterSize( file, 1024 * 1024 )
	defer f.Flush()

	a := big.NewInt(0)
	b := big.NewInt(1)
	d := []byte( "," )

	for {
		select {
			case <-contx.Done( ):
				return
			default:
				a.Add( a, b )
				a,b = b, a

				bytes := b.Bytes()
				// thank goodness for modern go
				slices.Reverse(bytes)

				f.Write(bytes)
				f.Write(d)
		}
	}
}
