AWS_ACCOUNT_ID=`aws sts get-caller-identity | jq '.Account' -r`

.PHONY: build
build:
	docker build --platform linux/x86_64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/csv-database-importer:latest .

.PHONY: push
push:
	aws ecr get-login-password \
		| docker login \
			--username AWS \
			--password-stdin https://${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com \
	&& docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/csv-database-importer:latest

lint:
	flake8 --max-line-length=120 app
	isort --check --diff app
	black --check app

format:
	isort app
	black app
