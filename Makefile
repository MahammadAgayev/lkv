.PHONY: build run test clean

build:
	docker build -t lkv .

run:
	docker build -q -t lkv . > /dev/null
	docker run --rm --security-opt seccomp=unconfined lkv

test:
	docker build --target builder -t lkv-test .
	docker run --rm --security-opt seccomp=unconfined lkv-test zig build test

clean:
	docker rmi -f lkv
