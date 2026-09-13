TERRAFORM ?= terraform

.PHONY: fmt check test example ci
fmt:
	$(TERRAFORM) fmt -recursive

check:
	$(TERRAFORM) fmt -check -recursive
	$(TERRAFORM) init -backend=false
	$(TERRAFORM) validate

test:
	$(TERRAFORM) test

example:
	$(TERRAFORM) -chdir=examples/consumer init -backend=false
	$(TERRAFORM) -chdir=examples/consumer validate

ci: check test example
