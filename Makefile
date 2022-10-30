SERVICE_DIRS=$(shell find ./src -name '*.csproj' -exec dirname {} \;)

all:
	@echo "Usage:   make <dotnet-command>"
	@echo "Example: make build - runs 'dotnet build' for all projects"

.PHONY: test

clean:
	for d in $(SERVICE_DIRS) ; do dotnet $@ $$d --nologo && rm -rf $$d/bin/ $$d/obj/; done ; 

build:
	for d in $(SERVICE_DIRS) ; do dotnet $@ $$d --nologo; done ; 