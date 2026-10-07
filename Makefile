# CUDA worker — freeze dispatch from git bash / mac; scripts are PowerShell.

CI_WORKFLOW := .github/workflows/ci.yml
RELEASE_WORKFLOW := .github/workflows/release.yml

REPO ?= $(shell git remote get-url origin 2>/dev/null | sed -E 's|git@github\.com:||; s|https://github\.com/||; s|\.git$$||')
GH_R := $(if $(REPO),-R "$(REPO)",)
REF ?= $(shell git branch --show-current 2>/dev/null)
PUBLISH_GH_RELEASE ?= true

.PHONY: ci ci-watch release release-watch

ci:
	@test -n "$(REPO)" || (echo "ERROR: could not resolve origin repo; set REPO=owner/name" >&2; exit 1)
	gh $(GH_R) workflow run "$(CI_WORKFLOW)" \
		$(if $(REF),-r "$(REF)",) \
		$(if $(VERSION),-f version="$(VERSION)",)

ci-watch: ci
	@sleep 2
	@RID=$$(gh $(GH_R) run list --workflow="$(CI_WORKFLOW)" -L 1 --json databaseId -q '.[0].databaseId'); \
		test -n "$$RID"; \
		gh $(GH_R) run watch "$$RID"

release:
	@test -n "$(REPO)" || (echo "ERROR: could not resolve origin repo; set REPO=owner/name" >&2; exit 1)
	gh $(GH_R) workflow run "$(RELEASE_WORKFLOW)" \
		$(if $(REF),-r "$(REF)",) \
		-f publish_gh_release="$(PUBLISH_GH_RELEASE)" \
		$(if $(VERSION),-f version="$(VERSION)",)

release-watch: release
	@sleep 2
	@RID=$$(gh $(GH_R) run list --workflow="$(RELEASE_WORKFLOW)" -L 1 --json databaseId -q '.[0].databaseId'); \
		test -n "$$RID"; \
		gh $(GH_R) run watch "$$RID"
