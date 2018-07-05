#!/bin/bash
virtualenv deploy
source deploy/bin/activate

cp -r BaseA deploy/
pip install -r deploy/BaseA/requirements.txt -t deploy/BaseA/
zip -r -X terraform/basea.zip deploy/BaseA

cp -r BaseB deploy/
pip install -r deploy/BaseB/requirements.txt -t deploy/BaseB/
zip -r -X terraform/baseb.zip deploy/BaseB

cd terraform
pip install terraform
terraform init
terraform plan -out plan
terraform apply "plan"
cd ..

cp -r BaseC deploy/
pip install -r deploy/BaseC/requirements.txt
cd deploy/BaseC
zappa init
zappa deploy dev
