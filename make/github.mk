REPO_NAME=$(shell basename $$(git rev-parse --show-toplevel))
VISIBILITY ?= private

.PHONY: gh.create gh.var gh.vlist
gh.create:
	@gh repo create $(REPO_NAME) \
	--$(VISIBILITY) --source=.\
	--push
gh.var:
	@gh variable set $(VAR_KEY) \
	--body "$(VAR_VALUE)"
gh.vlist:
	@gh variable list
