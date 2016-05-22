# go-c-bindings-examples
Some examples to understand the workflow of using Go C Bindings

## What
In Go you can call C programs and functions using [cgo](https://golang.org/cmd/cgo/). This way you can easily create C bindings to other applications or libraries that provides C API.

## How

All you need to do is to add a `import "C"` at the beginning of your Go program **just** after including your C program:

```go
//#include <stdio.h>
import "C"
```

With the previous example you can use the `stdio` package in Go.

If you need to use an app that is on your same folder, you use the same syntax than in C (with the `"` instead of `<>`)

```go
//#include "hello.c"
import "C"
```

> **IMPORTANT**: Do **not leave a newline between the `include` and the `import "C"`** statements or you will get this type of errors on build:

```bash
# command-line-arguments
could not determine kind of name for C.Hello
could not determine kind of name for C.sum
```

## The example
On this folder you can find an example of C bindings. We have two very simple C "libraries" called `hello.c`:

```c
//hello.c
#include <stdio.h>

void Hello(){
    printf("Hello world\n");
}
```

That simply prints "hello world" in the console and `sum.c`

```c
//sum.c
#include <stdio.h>

int sum(int a, int b) {
    return a + b;
}
```

...that takes 2 arguments and returns its sum (do not print it).

We have a `main.go` program that will make use of this two files. First we import them as we mentioned before:
```go
//main.go
package main

/*
  #include "hello.c"
  #include "sum.c"
*/
import "C"
```

### Hello World!

Now we are ready to use the C programs in our Go app. Let's first try the Hello program:

```go
//main.go
package main

/*
  #include "hello.c"
  #include "sum.c"
*/
import "C"


func main() {
	//Call to void function without params
	err := Hello()
	if err != nil {
		log.Fatal(err)
	}
}

//Hello is a C binding to the Hello World "C" program. As a Go user you could
//use now the Hello function transparently without knowing that it is calling
//a C function
func Hello() error {
	_, err := C.Hello()	//We ignore first result as it is a void function
	if err != nil {
		return errors.New("error calling Hello function: " + err.Error())
	}

	return nil
}
```

Now run the main.go program using the `go run main.go` to get print of the C program: "Hello world!". Well done!

### Sum of ints
Let's make it a bit more complex by adding a function that sums its two arguments.

```c
//sum.c
#include <stdio.h>

int sum(int a, int b) {
  return a + b;
}
```

And we'll call it from our previous Go app.

```go
//main.go
package main

/*
#include "hello.c"
#include "sum.c"
*/
import "C"

import (
	"errors"
	"fmt"
	"log"
)

func main() {
	//Call to void function without params
	err := Hello()
	if err != nil {
		log.Fatal(err)
	}

	//Call to int function with two params
	res, err := makeSum(5, 4)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Sum of 5 + 4 is %d\n", res)
}

//Hello is a C binding to the Hello World "C" program. As a Go user you could
//use now the Hello function transparently without knowing that is calling a C
//function
func Hello() error {
	_, err := C.Hello() //We ignore first result as it is a void function
	if err != nil {
		return errors.New("error calling Hello function: " + err.Error())
	}

	return nil
}

//makeSum also is a C binding to make a sum. As before it returns a result and
//an error. Look that we had to pass the Int values sto C.int values before using
//the function and cast the result back to a Go int value
func makeSum(a, b int) (int, error) {
	//Convert Go ints to C ints
	aC := C.int(a)
	bC := C.int(b)

	sum, err := C.sum(aC, bC)
	if err != nil {
		return 0, errors.New("error calling Sum function: " + err.Error())
	}

	//Convert C.int result to Go int
	res := int(sum)

	return res, nil
}
```

Take a look at the "makeSum" function. It receives two `int` parameters that need to be converted to C `int` before by using the `C.int` function.
Also, the return of the call will give us a C `int` and an error in case something went wrong. We need to cast C response to a Go's int using `int()`.

Try running our go app by using `go run main.go`

```bash
$ go run main.go
Hello world!
Sum of 5 + 4 is 9
```

# Generating a binary
If you try a go build you could get multiple definition errors.
```bash
$ go build
# github.com/sayden/c-bindings
/tmp/go-build329491076/github.com/sayden/c-bindings/_obj/hello.o: In function `Hello':
../../go/src/github.com/sayden/c-bindings/hello.c:5: multiple definition of `Hello'
/tmp/go-build329491076/github.com/sayden/c-bindings/_obj/main.cgo2.o:/home/mariocaster/go/src/github.com/sayden/c-bindings/hello.c:5: first defined here
/tmp/go-build329491076/github.com/sayden/c-bindings/_obj/sum.o: In function `sum':
../../go/src/github.com/sayden/c-bindings/sum.c:5: multiple definition of `sum`
/tmp/go-build329491076/github.com/sayden/c-bindings/_obj/main.cgo2.o:/home/mariocaster/go/src/github.com/sayden/c-bindings/sum.c:5: first defined here
collect2: error: ld returned 1 exit status
```

The trick is to refer to the main file directly when using `go build`:
```bash
$ go build main.go
$ ./main
Hello world!
Sum of 5 + 4 is 9
```

> Remember that you can provide a name to the binary file by using `-o` flag `go build -o my_c_binding main.go`

I hope you enjoyed this tutorial.
