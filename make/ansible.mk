ANSIBLE_DIR := $(CURDIR)/ansible

.PHONY: a.check a.lint a.apply
a.check:
	@ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini  $(ANSIBLE_DIR)/site.yml --syntax-check
a.lint:
	@ansible-lint $(ANSIBLE_DIR)
a.apply:
	@ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini  $(ANSIBLE_DIR)/site.yml
