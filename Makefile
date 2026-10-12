# Deploy the LargeRDFBench QLever SPARQL endpoints.
# Machines come from INVENTORY; which dataset runs where comes from ENDPOINTS.

INVENTORY ?= inventory.yml
ENDPOINTS ?= sparql-endpoints.yml

.PHONY: deps ping check deploy health stop

deps:        # Install the Ansible collections this repo needs
	ansible-galaxy collection install -r requirements.yml

ping:        # Reachability of all machines
	ansible qlever -i $(INVENTORY) -m ping

check:       # Syntax-check the playbook
	ansible-playbook -i $(INVENTORY) -e @$(ENDPOINTS) --syntax-check deploy.yml

deploy: deps # Provision the machines, download the data, index and serve every endpoint
	ansible-playbook -i $(INVENTORY) -e @$(ENDPOINTS) deploy.yml

health:      # Per container: status, restart count, OOM-killed
	ansible qlever -i $(INVENTORY) -m shell -a 'for c in $$(docker ps -aq --filter name=^qlever-); do docker inspect -f "{% raw %}{{.Name}} {{.State.Status}} restarts={{.RestartCount}} oom_killed={{.State.OOMKilled}}{% endraw %}" $$c; done'

stop:        # Remove every QLever container (indexes and data are kept)
	ansible qlever -i $(INVENTORY) -m shell -a 'docker rm -f $$(docker ps -aq --filter name=^qlever-) 2>/dev/null || true'
