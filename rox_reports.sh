#!/bin/bash
##################################################################
# Script       # rox_reports.sh
# Description  # Help in generation and download of ROX reports
##################################################################
# @VERSION     # 0.1.1
##################################################################
# Changelog.md # List the modifications in the script.
# README.md    # Describes the repository usage
##################################################################

#Functions
fct_help(){
  Script=$(which $0 2>${STD_ERR})
  if [[ "${Script}" != "bash" ]] && [[ ! -z ${Script} ]]
  then
    ScriptName=$(basename $0)
  fi
  echo -e "usage: ${cyantext}${ScriptName} [-s <ROX_ENDPOINT_URL>] [-t <ROX_API_TOKEN>] ${purpletext}[-h]${resetcolor}\n"
  OPTION_TAB=8
  DESCR_TAB=63
  DEFAULT_TAB=40
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "Options" "Description" "Alternate way, setting variables"
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-s" "Set ROX Endpoint URL" "export ROX_ENDPOINT=<ROX_ENDPOINT_URL>"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-t" "ROX Token" "export ROX_API_TOKEN=<ROX_API_TOKEN>"
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "" "Additional Options:" ""
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|${purpletext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "-h" "display this help and check for updated version" ""
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DEFAULT_TAB}s|\n" |tr \  '-'

  Script=$(which $0 2>${STD_ERR})
  if [[ "${Script}" != "bash" ]] && [[ ! -z ${Script} ]]
  then
    VERSION=$(grep "@VERSION" ${Script} 2>${STD_ERR} | grep -Ev "VERSION=" | cut -d'#' -f3)
    VERSION=${VERSION:-" N/A"}
  fi
  echo -e "\nCurrent Version:\t${VERSION}"
}

fct_check_report_status() {
while [[ ! -z ${REPORT_JOB_STATUS} ]] && [[ $(echo "${REPORT_JOB_STATUS}" | jq -r '.status.runState') != "GENERATED" ]] && [[ ${LOOP_NUM} -lt ${MAX_LOOP} ]]
do
  LOOP_NUM=$[LOOP_NUM + 1] && printf '.' && sleep ${SLEEP_TIME}
  REPORT_JOB_STATUS=$(curl -fksLH "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v2/reports/jobs/${REPORT_JOB_ID}/status" 2>/dev/null)
done
}

#Global Variables
SLEEP_TIME="5"
MAX_LOOP=12

#Main
# Getops
if [[ $# != 0 ]]
then
  if [[ $1 == "-" ]] || [[ $1 =~ ^[a-zA-Z0-9] ]]
  then
    echo -e "Invalid option: ${1}\n"
    fct_help && exit 2
  fi
  while getopts :s:t:h arg; do
    case $arg in
      s)
        ROX_ENDPOINT=${OPTARG}
        ;;
      t)
        ROX_API_TOKEN=${OPTARG}
        ;;
      h)
        fct_help && exit 0
        ;;
      ?)
        echo -e "Invalid option\n"
        fct_help && exit 1
        ;;
    esac
  done
fi

if [[ -z ${ROX_ENDPOINT} ]] || [[ -z ${ROX_API_TOKEN} ]]
then
  fct_help && exit 1
fi

REPORT_CONFIGS=($(curl -fksH "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v2/reports/configurations" 2>/dev/null| jq -r '.reportConfigs | sort_by(.name) | .[] | "\(.name),\(.id)"' | sed -e "s/ /_/g"))
REPORT_CONFIGS_NUM=$(echo ${#REPORT_CONFIGS[@]})
if [[ ${REPORT_CONFIGS_NUM} == 0 ]]
then
  echo -e "Nothing ROX Report retrieved. Be sure that reports configurations have been created"
  exit 0
fi
while ([[ ${REP} != [qQ] ]] &&  [[ ${REPORT_CONFIG_ID} == "" ]])
do
  NUM=0
  echo -e " ,REPORT NAME, ID\n$(while [[ ${NUM} -lt ${REPORT_CONFIGS_NUM} ]]
  do
    echo "[$[NUM+1]],$(echo ${REPORT_CONFIGS[${NUM}]})" | sed -e "s/_/ /g"
    NUM=$[NUM+1]
  done)\n[q],Quit" | column -t -s','
  printf "Select the desired report [q]: "
  read REP
  REP=${REP:-"q"}
  if ([[ ${REP} != [qQ] ]] && (! [[ ${REP} =~ ^[0-9]+$ ]])) || ([[ ${REP} =~ ^[0-9]+$ ]] && ([[ ${REP} -gt ${REPORT_CONFIGS_NUM} ]] || [[ ${REP} -le 0 ]]))
  then
    clear
    echo "Invalid Choice: ${REP}"
  else
      if [[ ${REP} != [qQ] ]]
      then
        REPORT_CONFIG_NAME=$(echo ${REPORT_CONFIGS[$[REP-1]]} | cut -d',' -f1)
        REPORT_CONFIG_ID=$(echo ${REPORT_CONFIGS[$[REP-1]]} | cut -d',' -f2)
      else
        exit 0
      fi
  fi
done

REPORT_JOB_ID=$(curl -XPOST -fksH "Authorization: Bearer ${ROX_API_TOKEN}" -d "{ \"reportConfigId\": \"${REPORT_CONFIG_ID}\", \"reportNotificationMethod\": \"DOWNLOAD\" }" "https://${ROX_ENDPOINT}/v2/reports/run" 2>/dev/null | jq -r '.reportId')

printf "Awaiting for the job ${REPORT_JOB_ID} to be completed"
sleep ${SLEEP_TIME}
REPORT_JOB_STATUS=$(curl -fksLH "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v2/reports/jobs/${REPORT_JOB_ID}/status" 2>/dev/null)
LOOP_NUM=0
fct_check_report_status

if [[ -z ${REPORT_JOB_STATUS} ]]
then
  echo "ERR: Failed to retrieve the JOB status for JOB ${REPORT_JOB_ID}"
  exit 5
else
  JOB_RUNSTATE=$(echo ${REPORT_JOB_STATUS} | jq -r '.status.runState')
  if [[ ${JOB_RUNSTATE} != "GENERATED" ]]
  then
    echo "JOB ${REPORT_JOB_ID} is not generated, but in runState: ${JOB_RUNSTATE}\n${REPORT_JOB_STATUS}\nWould you like to continue to monitoring the job for another $[SLEEP_TIME * ${MAX_LOOP}] seconds? [y/n]"
    read REP
    if [[ ${REP} != [yY] ]]
    then
      exit 10
    else
      LOOP_NUM=0
      fct_check_report_status
    fi
  else
    COMPLETED_AT=$(echo ${REPORT_JOB_STATUS} | jq -r '.status.completedAt')
    echo -e "\nJOB ${REPORT_JOB_ID} ${JOB_RUNSTATE} at ${COMPLETED_AT}"
  fi
fi

REPORT_FILE="report-${REPORT_CONFIG_NAME}-${COMPLETED_AT}.zip"
curl -o ${REPORT_FILE} -fksH "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/api/reports/jobs/download?id=${REPORT_JOB_ID}" 2>/dev/null
RC=$?
if [[ ${RC} != 0 ]] || [[ ! -f ${REPORT_FILE} ]]
then
  echo "ERR: Unable to download the report"
  exit 15
else
  echo "The report has been successfully downloaded: ${REPORT_FILE}"
fi
