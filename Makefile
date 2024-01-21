ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD_DIR=build

all: build

build: src/*.pyx
	python setup.py build_ext --build-lib $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

run:
	sudo python run.py

emu:
	sudo -E PILED_EMULATE=1 python run.py