
.DEFAULT_GOAL:=help
.PHONY: help

define _help_pre

This Makefile wraps the pk command, attempting to normalize the targets between
Makefile3 and the new extended manifest enabling automated builds on Cent 7.

endef
export _help_pre
# we can use define to set up a multi line body
define _help_body

Examples:\033[36m
make install DRY_RUN=1
make install WITH_DOCS=1 DRY_RUN=1
make install CONTEXT=shared WITH_DOCS=1
make docs
make lint
\033[0m

Note: We have done our best to match traditional targets. To see what is getting
called under the hood, use VERBOSE=1. Questions? Send mail to \033[36mamg@d2.com\033[0m

endef
# but we have to export the multi line variable as an env var
# and access it via $$ in the target or it leads to issues
export _help_body

help:  ## Display this help
	@echo "$$_help_pre"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo "$$_help_body"
