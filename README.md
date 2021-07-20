## Instructions

Run the roles.sh file once before running the menu.sh


## Create a lambda function from github

### Pre-reqs

- deploy.json must be there in the root folder (along with requirements.txt if python)
- handler file should also be present in root folder 

### Paramaters in deploy.json

- runtime
  - Examples: java8, java11, nodejs10.x, nodejs12.x, python2.7, python3.6, python3.7, python3.8, dotnetcore2.1, go1.x, ruby2.5

- handler
  - Examples: fileName.funtionName if I have a file "fileName" in the root folder and function "funtionName" in that file.
  - Note that the signature of handler should have two arguments as event and context