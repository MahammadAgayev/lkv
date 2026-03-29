.PHONY: build run test clean

build:
	docker build -t lkv .

run:
	docker build -q -t lkv . > /dev/null
	docker run --rm --security-opt seccomp=unconfined lkv

test: build
	docker run --rm lkv zig build test

clean:
	docker rmi -f lkv
