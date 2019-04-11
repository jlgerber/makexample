# Build a package	make build	pk build
# Build a package with documentation	make build WITH_DOCS=1	pk build --with-docs
# Build documentation alone	make build && make docs	pk run-recipe docs
# Install a package to the workarea	make install	pk build && pk install private/dist/foo-1.2.3
# Install a package to the facility	make install CONTEXT=facility	svn-tag && pk build --with-docs && pk install --level=facility private/dist/foo-1.2.3
# Release a previously installed package	make announce	pk release

# Notes:

#     We are likely going to migrate from Subversion to Gitlab in the next few months, the svn-tag command used to tag a package will then become git tag -fa && git push.

_truthy := YES yes 1 T t true TRUE y Y True
_falsy := NO no 0 F f false FALSE n N False
_space := $(_space) $(_space)
_comma := ,

DD_OS ?= cent6_64

#
# find manifest and extract information
#
_manifest := $(shell find . -iname manifest.yaml)

ifeq ($(_manifest),)
  $(error "unable to find manifest.yaml")
endif

_version := $(shell cat $(_manifest) | grep -E "^version:" | cut -f 2 -d ' ' | sed "s/'//g")
_package_name := $(shell cat $(_manifest) | grep 'name:' | cut -f 2 -d ' ' | sed "s/'//g")
# Verbosity Level
ifneq ($(filter $(VERBOSE),$(_truthy)),)
  _verbose := yes
else
  _verbose := no
endif

ifeq ($(_verbose),yes)
  $(info manifest "$(_manifest)")
  $(info package: $(_package_name)-$(_version))
endif

# Perform ops or just pretend?
ifneq ($(filter $(DRY_RUN),$(_truthy)),)
  _dryRun := yes
else
  _dryRun := no
endif

ifneq ($(TERM),)
  ifneq ($(wildcard $(shell which tput)),)
    usNormal := $(shell tput sgr0)
	usRed := $(shell tput setaf 1)
	usYellow := $(shell tput setaf 3)
	usBlue := $(shell tput setaf 4)
	usBold := $(shell tput bold)
	normal = '$(usNormal)'
	red = '$(usRed)'
	yellow = '$(usYellow)'
	blue = '$(usBlue)'
	bold = '$(usBold)'
  endif
endif

# Output formatting
uiyellow := $(yellow)
ifeq ($(_verbose),no)
  _echo := @
  _shellEchoTail := >& /dev/null
else
  uibold := $(bold)
  uired := $(red)
  uiblue := $(blue)
endif

ifneq ($(filter $(VERBOSE),$(_truthy)),)
  _verbose := yes
endif

ifeq ($(origin SHOW),undefined)
  _show = $(DD_SHOW)
else
  _show = $(SHOW)
endif

ifneq ($(CONTEXT),)
  _context := $(shell echo $(CONTEXT) | tr A-Z a-z)
else
  _context := user
endif

ifeq ($(filter $(_context),facility shared user),)
  $(error unrecognized CONTEXT, must be facility shared or user)
endif

ifneq ($(filter $(WITH_DOCS),$(_truthy)),)
  _withDocs := yes
else
  _withDocs := no
endif

ifneq ($(filter $(CLEAN),$(_truthy)),)
  _noTag := yes
else
  _noTag := no
endif
_noGitTag := $(_noTag)
_noSvnTag := $(_noTag)
ifneq ($(filter $(NO_GIT),$(_truthy)),)
  _noGitTag := yes
endif

ifneq ($(filter $(NO_SVN),$(_truthy)),)
  _noSvnTag := yes
endif

ifneq ($(SITES),)
  _sites := $(SITES)
else ifeq ($(_context), user)
  _sites := local
endif
_sites := $(subst $(_space),$(_comma),$(_sites))

ifneq ($(findstring local,$(_sites)),)
  _installLocally = yes
else ifneq ($(findstring all,$(_sites)),)
  _installLocally = yes
else ifneq ($(findstring $(DD_LOCATION),$(_sites)),)
  _installLocally = yes
endif

ifeq ($(_withDocs),yes)
  _docsStr := "--with-docs"
else
  _docsStr :=
endif

ifeq ($(DD_OS), cent7_64)
  ifeq ($(_context), facility)
    _installTarget := "pk tag"
  else
    _installTarget := "pk build $(_docsStr) && pk install --level=$(_context)"
  endif
else ifeq ($(DD_OS), cent6_64)
  ifeq ($(_context),facility)
    _installTarget := "pk tag && pk build $(_docsStr) && pk install --level=$(_context)"
  else
    _installTarget := "pk build $(_docsStr) && pk install --level=$(_context)"
  endif
else
  $(error invalid os: "$(DD_OS)")
endif

build: ## Generate a build locally. This accepts CONTEXT, which defaults to user
ifeq ($(_dryRun),yes)
	@echo pk build $(_docsStr)
else
	pk build $(_docsStr)
endif

docs: ## Generate documentation only. This calls pk run-recipe docs under the hood.
ifeq ($(_dryRun),yes)
	@echo pk run-recipe docs
else
	pk run-recipe docs
endif

install: ## Build and install. On cent 7, if the CONTEXT=facility, this will create in the vcs, kicking off a build on the build server.
ifeq ($(_dryRun),yes)
	@echo $(_installTarget)
else
	@echo $(_installTarget)
	@eval $(_installTarget)
endif

print-%: ; @echo $* = $($*)

.PHONY: printvars install docs build

printvars:
	@$(foreach V,$(sort $(.VARIABLES)), \
	$(if $(filter-out environ% default automatic, \
	$(origin $V)),$(info $V=$($V) ($(value $V)))))
	@$(normal)
