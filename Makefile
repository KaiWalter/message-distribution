SERVICE_DIRS=$(shell find ./src -name '*.csproj' -exec dirname {} \;)
DAPR_SERVICE_DIRS=$(shell find ./src -name 'dapr*.csproj' -exec dirname {} \;)
FUNC_SERVICE_DIRS=$(shell find ./src -name 'func*.csproj' -exec dirname {} \;)

all:
	@echo "Usage:   make <dotnet-command>"
	@echo "Example: make build - runs 'dotnet build' for all projects"

.PHONY: test

clean:
	for d in $(SERVICE_DIRS) ; do dotnet $@ $$d --nologo && rm -rf $$d/bin/ $$d/obj/; done ; 

build:
	for d in $(SERVICE_DIRS) ; do dotnet $@ $$d --nologo; done ; 

deploy-dapr:
	for d in $(DAPR_SERVICE_DIRS) ; do azd deploy --service `basename "$$d"` ; done ; 

deploy-functions:
	for d in $(FUNC_SERVICE_DIRS) ; do azd deploy --service `basename "$$d"` ; done ;
