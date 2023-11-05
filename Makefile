SERVICE_DIRS=$(shell find ./src -name '*.csproj' -exec dirname {} \;)
DAPR_SERVICE_DIRS=$(shell find ./src -name 'dapr*.csproj' -exec dirname {} \;)
FUNC_SERVICE_DIRS=$(shell find ./src -name 'func*.csproj' -exec dirname {} \;)

all:
	@echo "Usage:   make <dotnet-command>"
	@echo "Example: make build - runs 'dotnet build' for all projects"

.PHONY: clean
clean:
	for d in $(SERVICE_DIRS) ; do dotnet $@ $$d --nologo && rm -rf $$d/bin/ $$d/obj/; done ; 

.PHONY: build
build:
	for d in $(SERVICE_DIRS) ; do dotnet $@ $$d --nologo; done ;

.PHONY: azfull
azfull:
	./scripts/cli/deploy-infra.sh
	./scripts/cli/deploy-apps.sh build

.PHONY: azbuild
azbuild:
	for d in $(SERVICE_DIRS) ; do ./scripts/cli/build-app.sh `basename "$$d"`; done ;

.PHONY: azdeploy
azdeploy:
	./scripts/cli/deploy-apps.sh

# deploy-dapr:
# 	for d in $(DAPR_SERVICE_DIRS) ; do azd deploy --service `basename "$$d"` ; done ; 
#
# deploy-functions:
# 	for d in $(FUNC_SERVICE_DIRS) ; do azd deploy --service `basename "$$d"` ; done ;
