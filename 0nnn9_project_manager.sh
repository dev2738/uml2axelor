#!/bin/bash

program_name=$0
SOURCE_REPO_TO_CLONE="axelor/open-suite-webapp"
ADD_MODEL_CODE="false"
MGMT_BOOTSTRAP="false"
MGMT_ERASE="false"

usage () {
    echo "USAGE: $program_name --organization=[ORGANIZATION] --project-name=[PROJECT] OPTIONS";
    echo
    echo "  Organization options: pupunhatec, digibens";
    echo "  Project name | style: enter the model name of a prepared GenMyModel project | kebab";
    echo
    echo "  Management Options";
    echo "  [0] --bootstrap: Clones the github project $SOURCE_REPO_TO_CLONE locally and remotely at GitHub. Required flags: --organization, --project-name";
    echo "  [1] --add-model: Inserts the generated model code, downloaded from GMM and packed in zip files, to bootstraped project directory. Required flags: --project-name";
    echo "  [9] --erase-all: Flushes the project both from local storage as from remote at GitHub, plus its EE1 artifacts. Required flags: --organization, --project-name";
    echo "  -h --help: this screen";
    echo
    echo "  Example: bash $program_name --organization=pupunhatec --project-name=my-demo-order --bootstrap";
    echo
    exit 1
}

if [ $# == 0 ]; then
 usage
 exit
fi

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --bootstrap)
            MGMT_BOOTSTRAP=true
            ;;
        --add-model)
            ADD_MODEL_CODE=true
            ;;
        --erase-all)
            MGMT_ERASE=true
            ;;
        --organization)
            ORGANIZATION=$VALUE
            ;;
        --project-name)
            PROJECT=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

if [ $MGMT_BOOTSTRAP == true ]; then
 if [ -z $ORGANIZATION ] || [ -z $PROJECT ]; then
   echo -e "Full project id not specified. Exiting...\n"
   exit 1
 fi
 echo "    Cloning $SOURCE_REPO_TO_CLONE ..."
 hub clone $SOURCE_REPO_TO_CLONE $PROJECT
 if [ $? -ne 0 ];
 then
   echo -e "Exiting...\n"
   exit 1
 fi
 echo "    Project directory $PROJECT created."

 cd $PROJECT
 echo "    Removing ERP app specifics....";
 git remote remove origin		
 rm -rf modules/axelor-open-suite
 echo
 echo "    Creating a new repository on GitHub and adding a git remote for it....";
 hub create --private $ORGANIZATION/$PROJECT

 hub commit -m 'Initial commit'
 git push -u origin HEAD
 echo
 echo "    Your new local repository workspace/$PROJECT and remote repository https://github.com/$ORGANIZATION/$PROJECT are ready for use.";
 echo
 echo "    Next steps: ";
 echo "    -run the axl-prefixed application generators and move their downloaded zip files into here";
 echo "    -use the flag --add-model to extract and insert generated model code into $PROJECT project. ";
 echo
fi


if [ $ADD_MODEL_CODE == true ]; then
 if [ -z $PROJECT ]; then
   echo -e "Project directory name not specified. Exiting...\n"
   exit 1
 fi
 echo
 echo "Un-zipping generated packs";
 unzip -o \*.zip -d $PROJECT
 if [ $? -ne 0 ];
 then
   echo
   echo -e "Error: zipped file content not found, or no project directory not found.";
   echo -e "To fix this, run the axl-prefixed application generators and move their downloaded zip files into here";
   echo -e "Exiting...\n";
   exit 1
 fi
 echo
 echo "Erasing packs";
 rm -f *.zip
 echo
 cd $PROJECT
 find -name 2_build.sh
 echo "    Next steps: ";
 echo "    -select one of the above listed execution environments and build the project like this";
 echo "       $ cd [folder] && sh 2_build.sh";
 echo "    NOTE: do not build the project as ad-hoc, eg, by calling Gradle directly. Instead, build only by calling the above script.";
 echo
fi

if [ $MGMT_ERASE == true ]; then
 if [ -z $ORGANIZATION ] || [ -z $PROJECT ]; then
   echo -e "Full project id not specified. Exiting...\n"
   exit 1
 fi
 echo
 echo "    1/3: Undeploying the exec env artifacts WAR and DB from EE1 [localhost_hp_246g_notebook] [development] exec environment ...";
 WORKDIR=$(pwd)
 cd $PROJECT/98_management/EE1/hp_246g_notebook/
 bash 4_undeploy.sh
 if [ $? -ne 0 ];
 then
   echo -e "Exiting...\n"
   exit 1
 fi
 echo
 echo "    2/3: Deleting project directory: from local storage...";
 cd $WORKDIR
 rm -rf $PROJECT
 echo "Deleted directory '$PROJECT'."
 echo
 echo "    3/3: Deleting project from remote at GitHub...";
 hub delete -y $ORGANIZATION/$PROJECT
 echo "Operation completed.";
 exit
fi


