#!/usr/bin/env bash

ICEORYX_ROOT_PATH=$(git rev-parse --show-toplevel)
EXIT_CODE=0
ENABLE_URL_CHECK=0

FILE_TO_SCAN=$1

setupTerminalColors()
{
    if [[ -t 1 ]]
    then
        COLOR_BLACK="\e[30m"
        COLOR_RED="\e[31m"
        COLOR_GREEN="\e[32m"
        COLOR_YELLOW="\e[33m"
        COLOR_BLUE="\e[34m"
        COLOR_MAGENTA="\e[35m"
        COLOR_CYAN="\e[36m"
        COLOR_LIGHT_GRAY="\e[37m"
        COLOR_GRAY="\e[90m"
        COLOR_LIGHT_RED="\e[91m"
        COLOR_LIGHT_GREEN="\e[92m"
        COLOR_LIGHT_YELLOW="\e[93m"
        COLOR_LIGHT_BLUE="\e[94m"
        COLOR_LIGHT_MAGENTA="\e[95m"
        COLOR_LIGHT_MAGENTA="\e[96m"
        COLOR_WHITE="\e[97m"
        COLOR_RESET="\e[0m"
    else
        COLOR_BLACK=""
        COLOR_RED=""
        COLOR_GREEN=""
        COLOR_YELLOW=""
        COLOR_BLUE=""
        COLOR_MAGENTA=""
        COLOR_CYAN=""
        COLOR_LIGHT_GRAY=""
        COLOR_GRAY=""
        COLOR_LIGHT_RED=""
        COLOR_LIGHT_GREEN=""
        COLOR_LIGHT_YELLOW=""
        COLOR_LIGHT_BLUE=""
        COLOR_LIGHT_MAGENTA=""
        COLOR_LIGHT_MAGENTA=""
        COLOR_WHITE=""
        COLOR_RESET=""
    fi
}

setupTerminalFormat()
{
    if [[ -t 1 ]]
    then
        STATUS_MSG_SPACING="             "
        STATUS_MSG_POSITION="\r"
    else
        STATUS_MSG_SPACING=""
        STATUS_MSG_POSITION=""
    fi
}

doesWebURLExist()
{
    if curl --connect-timeout 10 --retry 5 --retry-delay 0 --retry-max-time 30 --head --silent --fail $1 2> /dev/null 1>/dev/null ;
    then
        echo 1
    else
        echo 0
    fi
}

isWebLink()
{
    local RESULT
    RESULT=${RESULT}$(echo $1 | sed -n "s/^https:\/\/.*//p" | wc -l)
    RESULT=${RESULT}$(echo $1 | sed -n "s/^http:\/\/.*//p" | wc -l)
    echo $RESULT | grep 1 | wc -l
}

isMailLink()
{
    echo $1 | grep -E "^mailto:" | wc -l
}

isLinkToSection()
{
    echo $1 | grep -E "^#" | wc -l
}

isAbsolutePath()
{
    echo $1 | grep -E "^/" | wc -l
}

printLinkFailureSource()
{
    echo -e "  name:    ${COLOR_LIGHT_YELLOW} $LINK_NAME ${COLOR_RESET}"
    echo -e "  line:    ${COLOR_LIGHT_YELLOW} $LINE_NR ${COLOR_RESET}"
    echo -e "  link:    ${COLOR_LIGHT_RED} $LINK${COLOR_RESET}"
    echo

    EXIT_CODE=1
}

checkLinkToSection()
{
    local LOCAL_LINK_VALUE=$1
    local LOCAL_FILE=$2

    LINK=$(echo $LOCAL_LINK_VALUE | sed -n "s/^#\(.*\)/#\1/p" | tr - '.')
    local LOCAL_LINK=$(echo $LINK | cut -f 2 -d '#')
    if ! [[ $(cat $LOCAL_FILE | grep -iE "# $LOCAL_LINK\$" | wc -l ) == 1 ]]
    then
        printLinkFailureSource
    fi
}

checkLinkToUrl()
{
    if [[ $ENABLE_URL_CHECK == "1" ]]
    then
        LINK=$1
        if ! [[ $(doesWebURLExist $LINK) == "1" ]]
        then
            printLinkFailureSource
        fi
    fi
}

checkLinksInFile()
{
    FILE=$1

    FILE_DIRECTORY=$(dirname $FILE)
    IS_IN_CODE_ENV="0"

    readarray FILE_CONTENT < $FILE
    LINE_NR=0
    for LINE in "${FILE_CONTENT[@]}"
    do
        let LINE_NR=$LINE_NR+1

        if [[ $(echo $LINE | grep -E "^[ ]*\`\`\`" | wc -l) == "1" ]]
        then
            if [[ $IS_IN_CODE_ENV == "1" ]]
            then
                IS_IN_CODE_ENV="0"
            else
                IS_IN_CODE_ENV="1"
            fi
        fi

        if [[ $IS_IN_CODE_ENV == "1" ]]
        then
            continue
        fi

        ## sed -e 's/[^[]`[^`]*`//g' 
        ## remove inline code env like `auto bla = [blubb](auto i) ..` which could be mistaken as
        ## a markdown link like [linkName](linkValue)
        ##
        ## sed -n "s/.*\[\(.*\)](\([^)]*\)).*/\1[\2/p"
        ## extract markdown links
        link=$(echo $LINE | sed -e 's/[^[]`[^`]*`//g' | sed -n "s/.*\[\(.*\)](\([^)]*\)).*/\1[\2/p" | tr ' ' _)
        if [[ $link == "" ]]
        then
            continue
        fi

        LINK_NAME=$(echo $link | cut -f 1 -d '[')
        LINK_VALUE=$(echo $link | cut -f 2 -d '[')

        if [[ $(isMailLink $LINK_VALUE) == "1" ]]
        then
            continue
        elif [[ $(isWebLink $LINK_VALUE) == "1" ]]
        then
            checkLinkToUrl $LINK_VALUE
        elif [[ $(isLinkToSection $LINK_VALUE) == "1" ]]
        then
            checkLinkToSection $LINK_VALUE $FILE
        else
            if [[ ${isAbsolutePath} == "1" ]]
            then
                LINK=$LINK
            else
                LINK=${FILE_DIRECTORY}/${LINK_VALUE}
            fi

            if [[ $(echo $LINK | grep '#' | wc -l) == "1" ]]
            then
                SECTION_IN_FILE=$(echo $LINK | cut -f 2 -d '#')
                LINK=$(echo $LINK | cut -f 1 -d '#')
            fi

            if ! [ -f $LINK ] && ! [ -d $LINK ]
            then
                printLinkFailureSource
                continue
            fi

            if ! [[ $SECTION_IN_FILE == "" ]]
            then
                checkLinkToSection "#$SECTION_IN_FILE" $LINK
            fi

            SECTION_IN_FILE=""
        fi
    done
}

performLinkCheck()
{
    NUMBER_OF_FILES=$(find $ICEORYX_ROOT_PATH -type f -iname "*.md" | grep -v ${ICEORYX_ROOT_PATH}/build | grep -v ${ICEORYX_ROOT_PATH}/.github | wc -l)

    CURRENT_FILE=0
    for FILE in $(find $ICEORYX_ROOT_PATH -type f -iname "*.md" | grep -v ${ICEORYX_ROOT_PATH}/build | grep -v ${ICEORYX_ROOT_PATH}/.github)
    do
        let CURRENT_FILE=$CURRENT_FILE+1
        echo -e "[$CURRENT_FILE/$NUMBER_OF_FILES] ${COLOR_LIGHT_GREEN}$FILE${COLOR_RESET}"

        checkLinksInFile $FILE
    done
}

setupTerminalColors
setupTerminalFormat

if ! [ -z $1 ]
then
    checkLinksInFile $FILE_TO_SCAN
else
    performLinkCheck
fi

exit $EXIT_CODE
