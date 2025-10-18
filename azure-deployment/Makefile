.PHONY: help deploy destroy status ssh logs clean validate test

# Variables
RESOURCE_GROUP ?= portnox-containerlab-rg
VM_NAME ?= portnox-containerlab
LOCATION ?= eastus
VM_SIZE ?= Standard_D8s_v3
DISK_SIZE ?= 512
SSH_KEY_PATH ?= ~/.ssh/azure_portnox

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help message
	@echo "$(GREEN)Portnox ContainerLab Azure Deployment$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  RESOURCE_GROUP  Azure resource group (default: $(RESOURCE_GROUP))"
	@echo "  VM_NAME         VM name (default: $(VM_NAME))"
	@echo "  LOCATION        Azure region (default: $(LOCATION))"
	@echo "  VM_SIZE         VM size (default: $(VM_SIZE))"
	@echo "  DISK_SIZE       Data disk size in GB (default: $(DISK_SIZE))"
	@echo ""

check-az: ## Check if Azure CLI is installed
	@which az > /dev/null || (echo "$(RED)Azure CLI not found. Install from https://docs.microsoft.com/cli/azure/install-azure-cli$(NC)" && exit 1)
	@echo "$(GREEN)✓ Azure CLI found$(NC)"

check-login: check-az ## Check if logged into Azure
	@az account show > /dev/null 2>&1 || (echo "$(RED)Not logged into Azure. Run 'az login'$(NC)" && exit 1)
	@echo "$(GREEN)✓ Logged into Azure$(NC)"

generate-ssh-key: ## Generate SSH key pair
	@if [ ! -f $(SSH_KEY_PATH) ]; then \
		echo "$(YELLOW)Generating SSH key...$(NC)"; \
		ssh-keygen -t rsa -b 4096 -f $(SSH_KEY_PATH) -N ""; \
		echo "$(GREEN)✓ SSH key generated at $(SSH_KEY_PATH)$(NC)"; \
	else \
		echo "$(GREEN)✓ SSH key already exists at $(SSH_KEY_PATH)$(NC)"; \
	fi

validate: check-az ## Validate ARM template
	@echo "$(YELLOW)Validating ARM template...$(NC)"
	@az deployment group validate \
		--resource-group $(RESOURCE_GROUP) \
		--template-file templates/containerlab-vm.json \
		--parameters \
			vmName=$(VM_NAME) \
			vmSize=$(VM_SIZE) \
			adminUsername=azureuser \
			authenticationType=sshPublicKey \
			adminPasswordOrKey="$$(cat $(SSH_KEY_PATH).pub)" \
			dataDiskSizeGB=$(DISK_SIZE) \
		> /dev/null 2>&1 && echo "$(GREEN)✓ Template is valid$(NC)" || echo "$(RED)✗ Template validation failed$(NC)"

create-rg: check-login ## Create Azure resource group
	@echo "$(YELLOW)Creating resource group $(RESOURCE_GROUP)...$(NC)"
	@az group create \
		--name $(RESOURCE_GROUP) \
		--location $(LOCATION) \
		--output none
	@echo "$(GREEN)✓ Resource group created$(NC)"

deploy: check-login generate-ssh-key create-rg ## Deploy ContainerLab to Azure
	@echo "$(YELLOW)Deploying ContainerLab infrastructure...$(NC)"
	@az deployment group create \
		--resource-group $(RESOURCE_GROUP) \
		--template-file templates/containerlab-vm.json \
		--parameters \
			vmName=$(VM_NAME) \
			vmSize=$(VM_SIZE) \
			adminUsername=azureuser \
			authenticationType=sshPublicKey \
			adminPasswordOrKey="$$(cat $(SSH_KEY_PATH).pub)" \
			dataDiskSizeGB=$(DISK_SIZE) \
		--output table
	@echo ""
	@echo "$(GREEN)✓ Deployment complete!$(NC)"
	@echo ""
	@$(MAKE) info

deploy-quick: check-login generate-ssh-key ## Quick deploy with defaults
	@$(MAKE) deploy RESOURCE_GROUP=portnox-clab-rg VM_NAME=portnox-clab

info: ## Show deployment information
	@echo "$(GREEN)Deployment Information:$(NC)"
	@echo ""
	@VM_FQDN=$$(az deployment group show \
		--resource-group $(RESOURCE_GROUP) \
		--name containerlab-vm \
		--query properties.outputs.hostname.value -o tsv 2>/dev/null); \
	VM_IP=$$(az deployment group show \
		--resource-group $(RESOURCE_GROUP) \
		--name containerlab-vm \
		--query properties.outputs.publicIP.value -o tsv 2>/dev/null); \
	if [ -n "$$VM_FQDN" ]; then \
		echo "  Hostname:      $$VM_FQDN"; \
		echo "  Public IP:     $$VM_IP"; \
		echo "  SSH:           ssh -i $(SSH_KEY_PATH) azureuser@$$VM_FQDN"; \
		echo "  Antimony GUI:  http://$$VM_FQDN:8080"; \
		echo "  ContainerLab:  https://$$VM_FQDN:8443"; \
		echo ""; \
	else \
		echo "$(RED)Deployment not found$(NC)"; \
	fi

status: check-login ## Show VM status
	@echo "$(YELLOW)Checking VM status...$(NC)"
	@az vm get-instance-view \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VM_NAME) \
		--query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
		--output tsv 2>/dev/null || echo "$(RED)VM not found$(NC)"

ssh: ## SSH into the VM
	@VM_FQDN=$$(az deployment group show \
		--resource-group $(RESOURCE_GROUP) \
		--name containerlab-vm \
		--query properties.outputs.hostname.value -o tsv 2>/dev/null); \
	if [ -n "$$VM_FQDN" ]; then \
		ssh -i $(SSH_KEY_PATH) azureuser@$$VM_FQDN; \
	else \
		echo "$(RED)VM not found$(NC)"; \
	fi

ssh-cmd: ## Run command on VM (usage: make ssh-cmd CMD="command")
	@VM_FQDN=$$(az deployment group show \
		--resource-group $(RESOURCE_GROUP) \
		--name containerlab-vm \
		--query properties.outputs.hostname.value -o tsv 2>/dev/null); \
	if [ -n "$$VM_FQDN" ]; then \
		ssh -i $(SSH_KEY_PATH) azureuser@$$VM_FQDN "$(CMD)"; \
	else \
		echo "$(RED)VM not found$(NC)"; \
	fi

logs: ## View VM boot diagnostics
	@echo "$(YELLOW)Fetching boot diagnostics...$(NC)"
	@az vm boot-diagnostics get-boot-log \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VM_NAME) \
		2>/dev/null || echo "$(RED)Boot diagnostics not available$(NC)"

start: check-login ## Start the VM
	@echo "$(YELLOW)Starting VM...$(NC)"
	@az vm start \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VM_NAME) \
		--output none
	@echo "$(GREEN)✓ VM started$(NC)"

stop: check-login ## Stop the VM
	@echo "$(YELLOW)Stopping VM...$(NC)"
	@az vm stop \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VM_NAME) \
		--output none
	@echo "$(GREEN)✓ VM stopped$(NC)"

restart: check-login ## Restart the VM
	@echo "$(YELLOW)Restarting VM...$(NC)"
	@az vm restart \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VM_NAME) \
		--output none
	@echo "$(GREEN)✓ VM restarted$(NC)"

destroy: check-login ## Destroy all Azure resources
	@echo "$(RED)WARNING: This will delete all resources in $(RESOURCE_GROUP)$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Deleting resource group...$(NC)"; \
		az group delete \
			--name $(RESOURCE_GROUP) \
			--yes \
			--no-wait; \
		echo "$(GREEN)✓ Deletion initiated$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

clean: ## Clean local temporary files
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	@rm -rf /tmp/portnox-* || true
	@echo "$(GREEN)✓ Cleaned$(NC)"

list-rg: check-login ## List all resource groups
	@az group list --output table

list-vms: check-login ## List all VMs in resource group
	@az vm list \
		--resource-group $(RESOURCE_GROUP) \
		--output table 2>/dev/null || echo "$(RED)Resource group not found$(NC)"

cost: check-login ## Show estimated monthly cost
	@echo "$(YELLOW)Fetching cost information...$(NC)"
	@az consumption usage list \
		--start-date $$(date -d "30 days ago" +%Y-%m-%d) \
		--end-date $$(date +%Y-%m-%d) \
		--query "[?contains(instanceName, '$(VM_NAME)')].{Name:instanceName,Cost:pretaxCost,Currency:currency}" \
		--output table 2>/dev/null || echo "$(YELLOW)Cost data not available yet$(NC)"

test: ## Test deployment
	@echo "$(YELLOW)Testing deployment...$(NC)"
	@$(MAKE) ssh-cmd CMD="sudo containerlab version"
	@$(MAKE) ssh-cmd CMD="sudo docker ps"
	@$(MAKE) ssh-cmd CMD="curl -s http://localhost:8080 | head -n 1"
	@echo "$(GREEN)✓ Tests passed$(NC)"

backup: ## Backup lab configurations
	@echo "$(YELLOW)Backing up lab configurations...$(NC)"
	@VM_FQDN=$$(az deployment group show \
		--resource-group $(RESOURCE_GROUP) \
		--name containerlab-vm \
		--query properties.outputs.hostname.value -o tsv 2>/dev/null); \
	if [ -n "$$VM_FQDN" ]; then \
		mkdir -p backups/$$(date +%Y%m%d); \
		scp -i $(SSH_KEY_PATH) -r azureuser@$$VM_FQDN:/data/labs backups/$$(date +%Y%m%d)/; \
		echo "$(GREEN)✓ Backup saved to backups/$$(date +%Y%m%d)/$(NC)"; \
	else \
		echo "$(RED)VM not found$(NC)"; \
	fi

restore: ## Restore lab configurations (usage: make restore BACKUP_DATE=20231018)
	@echo "$(YELLOW)Restoring lab configurations...$(NC)"
	@VM_FQDN=$$(az deployment group show \
		--resource-group $(RESOURCE_GROUP) \
		--name containerlab-vm \
		--query properties.outputs.hostname.value -o tsv 2>/dev/null); \
	if [ -n "$$VM_FQDN" ] && [ -d "backups/$(BACKUP_DATE)" ]; then \
		scp -i $(SSH_KEY_PATH) -r backups/$(BACKUP_DATE)/labs azureuser@$$VM_FQDN:/data/; \
		echo "$(GREEN)✓ Backup restored$(NC)"; \
	else \
		echo "$(RED)VM or backup not found$(NC)"; \
	fi

open-gui: ## Open Antimony GUI in browser
	@VM_FQDN=$$(az deployment group show \
		--resource-group $(RESOURCE_GROUP) \
		--name containerlab-vm \
		--query properties.outputs.hostname.value -o tsv 2>/dev/null); \
	if [ -n "$$VM_FQDN" ]; then \
		open "http://$$VM_FQDN:8080" 2>/dev/null || xdg-open "http://$$VM_FQDN:8080" 2>/dev/null || echo "Open http://$$VM_FQDN:8080 in your browser"; \
	else \
		echo "$(RED)VM not found$(NC)"; \
	fi

.DEFAULT_GOAL := help
