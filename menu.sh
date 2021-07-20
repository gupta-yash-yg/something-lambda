#!/bin/bash

# TODO: Install dependencies
# node, python, jq, aws confidured

# Main options

function CreateLambdaFunction {
    functionName=$1

    echo -e "\t1. From zip file\n"
    echo -e "\t2. From github\n"
    echo -e "\t0. To return to previous menu\n\n"
    echo -e "Enter option: "

    read option
    if [ $option -eq 1 ]
    then
        clear
        CreateLambdaFunctionFromZip $functionName
        CreateLambdaFunction
    elif [ $option -eq 2 ]
    then
        clear
        CreateLambdaFunctionFromGitHub $functionName
        CreateLambdaFunction
    fi
    
}

function InvokeLambdaFunction {
    functionName=$1

    # TODO: change the payload to accept a file
    echo -e "Enter the payload: "
    echo "Example payload: { \"name\": \"Bob\" }"
    read payload
    # echo $payload
    payload=`echo $payload | base64`
    # echo $payload

    # TODO: aacept a generic file for output

    aws lambda invoke --function-name $functionName \
                      --payload $payload \
                        response.json
    
    echo "Output stored in response.json file"
}


function UpdateLambdaFunction {
    functionName=$1

    echo -n "Enter the updated code .zip file path : "
    read zipPath

    aws lambda update-function-code --function-name $functionName \
                                    --zip-file "fileb://$zipPath"

    if [ $? -eq 0 ]
    then
        echo "THe $functionName function is updated"
    fi
    
}

function DeleteLambdaFunction {
    functionName=$1

    echo "Deleting Function $functionName"

    aws lambda delete-function --function-name $functionName
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function is deleted"
    fi
}


function ListLambdaFunctions {
    list=`aws lambda list-functions --output "json" | jq '.Functions | map(.FunctionName)'`

    list=(${list//[\[\],]/})

    for i in ${!list[@]}
    do 
        printf "%s\t%s\n $i: ${list[$i]}"
    done

    max=$((${#list[@]} - 1))
}


# Sub options for creating lambda function

function CreateLambdaFunctionFromZip {
    functionName=$1

    echo "Enter the zip path of the function: "
    echo "Example: Zipfile.zip "
    read zipPath

    echo "Removing Temp folder if any ..."
    rm -r Temp

    unzip $zipPath -d Temp
    cd Temp

    GetRuntimeNHandler

    aws lambda create-function --function-name $functionName \
                                --zip-file "fileb://$zipPath" \
                                --handler $handler \
                                --runtime $runtime \
                                # --role arn:aws:iam::557151867487:role/MyLambdaRole
                                --role arn:aws:iam::785584775161:role/roleforlambda
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function is created!"
    fi

    cd ..
    rm -rf Temp
}

function CreateLambdaFunctionFromGitHub {
    functionName=$1

    echo "Enter github repo name: "
    read githubName
    echo "Enter github repo owner: "
    read githubOwner
    echo "Enter github branch: "
    read githubBranch
    echo "Enter the github personal access token of the user: "
    read githubPAT
    
    git clone "https://$githubPAT@github.com/$githubOwner/$githubName.git"
    cd $githubName && git checkout $githubBranch

    GetRuntimeNHandler

    if [[ $runtime == *"python"* ]]
    then
        npm i
    elif [[ $runtime == *"node"* ]]
    then
        pip3 install --target ./package -r requirements.txt
    fi

    zip lambda.zip *

    aws lambda create-function --function-name $functionName \
                                --zip-file "fileb://lambda.zip" \
                                --handler $handler \
                                --runtime $runtime \
                                # --role arn:aws:iam::557151867487:role/MyLambdaRole
                                --role arn:aws:iam::785584775161:role/roleforlambda
    
    if [ $? -eq 0 ]
    then
        echo "The $functionName function is created!"
    fi

    cd ..
    rm -rf $githubName
}


# Helper functions

function ChooseLambdaFunction {
    ListLambdaFunctions
    echo -e "\nChoose a lambda function with key (max: $max): "
    read functionKey

    # Assuming a number input
    if [ $functionKey -gt $max ] || [ $functionKey -lt 0 ]
    then
        ListLambdaFunctions
    fi

    functionName=`echo ${list[functionKey]} | sed -e 's/^"//' -e 's/"$//'`
}

function GetRuntimeNHandler {
    runtime=`cat deploy.json | jq '.runtime' | sed -e 's/^"//' -e 's/"$//'`
    handler=`cat deploy.json | jq '.handler' | sed -e 's/^"//' -e 's/"$//'`
}

# function for lambda versions

function LambdaVersion {
	functionName=$1
	echo -e "\nA new version of the function is being created...\n"
	aws lambda publish-version --function-name $functionName
}

# Main menu function

function menu {
	clear
	echo -e "\t\t\tMain Menu\n\n"
	echo -e "\t1. Create a Lambda function\n"
	echo -e "\t2. Invoke a Lambda function\n"
	echo -e "\t3. Update a Lambda function\n"
	echo -e "\t4. Delete a Lambda function\n"
	echo -e "\t5. List all Lambda functions\n"
	echo -e "\t6. Make a version of the lambda functions\n"
	echo -e "\t0. To Exit\n\n"
	echo -e "Enter option: "

	read option
	
	if [ $option -eq 1 ]
	then
        	clear
        	echo "Enter a function name: "
        	read functionName
        	CreateLambdaFunction $functionName
        	menu

	elif [ $option -eq 2 ]
	then
        	clear
        	ChooseLambdaFunction
        	echo "Invoking $functionName ..."
        	InvokeLambdaFunction $functionName
        	menu

	elif [ $option -eq 3 ]
	then
        	clear
        	ChooseLambdaFunction
        	echo "Updating $functionName ..."
        	UpdateLambdaFunction $functionName
        	menu

	elif [ $option -eq 4 ]
	then
        	clear
        	ChooseLambdaFunction
        	echo "Deleting $functionName ..."
        	DeleteLambdaFunction $functionName
        	menu
	
	elif [ $option -eq 5 ]
	then
        	clear
        	ListLambdaFunctions
        	menu
	elif [ $option -eq 6 ]
	then
		clear
		ChooseLambdaFunction
		LambdaVersion $functionName
		sleep 3
		menu
	fi
}


menu
