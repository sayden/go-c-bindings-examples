build:
	rm -f my_c_binding
	go build -o my_c_binding ./main.go

all: build
	# Execute the generated binary
	./my_c_binding
