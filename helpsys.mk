
.DEFAULT_GOAL:=help
.PHONY: help

# we can use define to set up a multi line body
define _help_body

Examples:\033[36m
make install DRY_RUN=1
make install WITH_DOCS=1 DRY_RUN=1
make install CONTEXT=shared WITH_DOCS=1
make docs
make lint
\033[0m
endef
# but we have to export the multi line variable as an env var
# and access it via $$ in the target or it leads to issues
export _help_body

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo "$$_help_body"
