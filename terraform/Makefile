AWS_PROFILE := default
-include ../.env

.PHONY: apply
apply:
	AWS_PROFILE=$(AWS_PROFILE) terraform apply -auto-approve

.PHONY: destroy
destroy:
	AWS_PROFILE=$(AWS_PROFILE) terraform destroy -auto-approve
