
export ENV_NAME=gamma
export APP_CODE=rek-poc
export AWS_REGION=us-east-1

ENV_NAME ?= gamma
APP_CODE ?= rek-poc
REGION ?= us-east-1
PROFILE ?= $(APP_CODE)-$(ENV_NAME)
ACCOUNT_ID := $(shell aws sts get-caller-identity --profile $(PROFILE) --query 'Account' --output text)
LAMBDA_BUILD := lambda-build-$(ACCOUNT_ID)-$(REGION)-$(APP_CODE)-$(ENV_NAME)


DETECT_FACES_ZIP := detect-faces.zip
DETECT_FACES_FUNCTION := $(PROFILE)-detect-faces

.PHONY: create-stack
create-stack:
	@aws cloudformation create-stack \
  --profile $(PROFILE) \
  --stack-name $(APP_CODE)-$(ENV_NAME) \
  --region $(REGION) \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file://poc.cfn.yml \
  --parameters file://$(APP_CODE)-$(ENV_NAME).json

.PHONY: update-stack
update-stack:
	@aws cloudformation update-stack \
  --profile $(PROFILE) \
  --stack-name $(APP_CODE)-$(ENV_NAME) \
  --region $(REGION) \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file://poc.cfn.yml \
  --parameters file://$(APP_CODE)-$(ENV_NAME).json

.PHONY: push-detect-faces
push-detect-faces:
	@python -m py_compile detect_faces.py
	@zip $(DETECT_FACES_ZIP) detect_faces.py
	@aws s3 cp --profile $(PROFILE) $(DETECT_FACES_ZIP) s3://$(LAMBDA_BUILD)/$(DETECT_FACES_ZIP)

.PHONY: update-detect-faces
update-detect-faces:
	@aws lambda update-function-code --profile $(PROFILE) --function-name $(DETECT_FACES_FUNCTION) --s3-bucket $(LAMBDA_BUILD) --s3-key $(DETECT_FACES_ZIP)
	@aws lambda publish-version --profile $(PROFILE) --function-name $(DETECT_FACES_FUNCTION)
