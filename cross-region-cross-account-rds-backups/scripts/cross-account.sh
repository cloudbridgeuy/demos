#!/usr/bin/env bash
# This script was generated by rargs 0.0.0 (https://rargs.cloudbridge.uy)
# Modifying it manually is not recommended

if [[ "${BASH_VERSINFO:-0}" -lt 4 ]]; then
  printf "bash version 4 or higher is required\n" >&2
  exit 1
fi

if [[ -n "${DEBUG:-}" ]]; then
  set -x
fi
set -e


normalize_input() {
  local arg flags

  while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ $arg =~ ^(--[a-zA-Z0-9_\-]+)=(.+)$ ]]; then
      input+=("${BASH_REMATCH[1]}")
      input+=("${BASH_REMATCH[2]}")
    elif [[ $arg =~ ^(-[a-zA-Z0-9])=(.+)$ ]]; then
      input+=("${BASH_REMATCH[1]}")
      input+=("${BASH_REMATCH[2]}")
    elif [[ $arg =~ ^-([a-zA-Z0-9][a-zA-Z0-9]+)$ ]]; then
      flags="${BASH_REMATCH[1]}"
      for ((i = 0; i < ${#flags}; i++)); do
        input+=("-${flags:i:1}")
      done
    else
      input+=("$arg")
    fi

    shift
  done
}

inspect_args() {
  prefix="rargs_"
  args="$(set | grep ^$prefix || true)"
  if [[ -n "$args" ]]; then
    echo
    echo args:
    for var in $args; do
      echo "- $var" | sed 's/=/ = /g'
    done
  fi

  if ((${#deps[@]})); then
    readarray -t sorted_keys < <(printf '%s\n' "${!deps[@]}" | sort)
    echo
    echo deps:
    for k in "${sorted_keys[@]}"; do echo "- \${deps[$k]} = ${deps[$k]}"; done
  fi

  if ((${#other_args[@]})); then
    echo
    echo other_args:
    echo "- \${other_args[*]} = ${other_args[*]}"
    for i in "${!other_args[@]}"; do
      echo "- \${other_args[$i]} = ${other_args[$i]}"
    done
  fi
}

set -eo pipefail
ROOT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DEMO_NAME="${DEMO_NAME:-"cross-region-cross-account-rds-backups-ca"}"
secondary="aws --profile cloudbridge-dba-secondary"

version() {
  echo "0.1.0"
}
usage() {
  printf "Handle the cross-account resources\n"
  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  cross-account [OPTIONS] [COMMAND] [COMMAND_OPTIONS]\n"
  printf "  cross-account -h|--help\n"
  printf "  cross-account -v|--version\n"
  printf "\n\033[4m%s\033[0m\n" "Commands:"
  cat <<EOF
  create ......... Deploy the cross-account resources using CloudFormation
  destroy ........ Destroys the cross-account resources using CloudFormation
  log-groups ..... Get the list of log groups
  log-streams .... Get the log-streams of one of the events lamda function
  logs ........... Get the logs of one of the events lamda function
  status ......... Get the status of the deployed cross-account resources
  track .......... Track the update of a CloudFormation template
  update ......... Update the cross-account resources using CloudFormation
EOF

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -h --help\n"
  printf "    Print help\n"
  printf "  -v --version\n"
  printf "    Print version\n"
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -v|--version)
        version
        exit
        ;;
      -h|--help)
        usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done
  action="${1:-}"

  case $action in
    create)
      action="create"
      input=("${input[@]:1}")
      ;;
    destroy)
      action="destroy"
      input=("${input[@]:1}")
      ;;
    log-groups)
      action="log-groups"
      input=("${input[@]:1}")
      ;;
    log-streams)
      action="log-streams"
      input=("${input[@]:1}")
      ;;
    logs)
      action="logs"
      input=("${input[@]:1}")
      ;;
    status)
      action="status"
      input=("${input[@]:1}")
      ;;
    track)
      action="track"
      input=("${input[@]:1}")
      ;;
    update)
      action="update"
      input=("${input[@]:1}")
      ;;
    -h|--help)
      usage
      exit
      ;;
    "")
      ;;
    *)
      printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid command: " "$action" >&2
      exit 1
      ;;
  esac
}
create_usage() {
  printf "Deploy the cross-account resources using CloudFormation\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  create [OPTIONS]\n"
  printf "  create -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -e --environment [<ENVIRONMENT>]\n"
  printf "    The name of the environment to depoy to.\n"
  printf "    [@default dev]\n"
  printf "  -l --lambda [<LAMBDA>]\n"
  printf "    The name of the lambda function to use.\n"
  printf "  -p --parameters [<PARAMETERS>]\n"
  printf "    The name of the parameters file to use.\n"
  printf "  -s --stack-name [<STACK-NAME>]\n"
  printf "    The name of the stack to use.\n"
  printf "  -t --template [<TEMPLATE>]\n"
  printf "    The name of the template to use.\n"
  printf "  --no-track\n"
  printf "    Don't track update changes.\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_create_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        create_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      --no-track)
        rargs_no_track=1
        shift
        ;;
      -e | --environment)
        rargs_environment="$2"
        shift 2
        ;;
      -l | --lambda)
        rargs_lambda="$2"
        shift 2
        ;;
      -p | --parameters)
        rargs_parameters="$2"
        shift 2
        ;;
      -s | --stack-name)
        rargs_stack_name="$2"
        shift 2
        ;;
      -t | --template)
        rargs_template="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Deploy the cross-account resources using CloudFormation
create() {
  local rargs_no_track
  local rargs_environment
  local rargs_lambda
  local rargs_parameters
  local rargs_stack_name
  local rargs_template
  # Parse command arguments
  parse_create_arguments "$@"

  # Check dependencies
  dependency="jo"
  if ! command -v $dependency >/dev/null 2>&1; then
    printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Missing dependency: " "$dependency" >&2
    printf "You need to install jo to use this command.\n" >&2
    exit 1
  else
    deps["$dependency"]="$(command -v $dependency | head -n1)"
  fi

  
    
  if [[ -z "$rargs_environment" ]]; then
    rargs_environment="dev"
  fi
    
	if [[ -z "$rargs_stack_name" ]]; then
		rargs_stack_name="$DEMO_NAME-$rargs_environment"
	fi
	if [[ -z "$rargs_template" ]]; then
		rargs_template="$ROOT_DIRECTORY/../cross-account-cf-template.yaml"
	fi
	if [[ -z "$rargs_parameters" ]]; then
		rargs_parameters="$ROOT_DIRECTORY/../cross-account-parameters.$rargs_environment.json"
	fi
	if [[ -z "$rargs_lambda" ]]; then
		rargs_lambda="$ROOT_DIRECTORY/cross_account_rds_snapshot_copy.py"
	fi
	tmp="$(mktemp)"
	LAMBDA_CONTENTS="$(awk 'NR == 1 {print $0; next} {printf "          %s\n", $0}' "$rargs_lambda")"
	export LAMBDA_CONTENTS
	envsubst <"$rargs_template" >"$tmp"
	echo "Attempting to create stack $rargs_stack_name" >&2
	if ! $secondary cloudformation create-stack \
		--stack-name "$rargs_stack_name" \
		--template-body "file://$tmp" \
		--parameters "file://$rargs_parameters" \
		--capabilities CAPABILITY_IAM; then
		update \
			--environment "$rargs_environment" \
			--stack-name "$rargs_stack_name" \
			--template "$rargs_template" \
			--parameters "$rargs_parameters" \
			--no-track
	fi
	if [[ -z "$rargs_no_track" ]]; then
		track -s "$rargs_stack_name"
	fi
	exit $?
}
destroy_usage() {
  printf "Destroys the cross-account resources using CloudFormation\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  destroy [OPTIONS]\n"
  printf "  destroy -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -e --environment [<ENVIRONMENT>]\n"
  printf "    The name of the environment to depoy to.\n"
  printf "    [@default dev]\n"
  printf "  -s --stack-name [<STACK-NAME>]\n"
  printf "    The name of the stack to use.\n"
  printf "  --no-track\n"
  printf "    Don't track update changes.\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_destroy_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        destroy_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      --no-track)
        rargs_no_track=1
        shift
        ;;
      -e | --environment)
        rargs_environment="$2"
        shift 2
        ;;
      -s | --stack-name)
        rargs_stack_name="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Destroys the cross-account resources using CloudFormation
destroy() {
  local rargs_no_track
  local rargs_environment
  local rargs_stack_name
  # Parse command arguments
  parse_destroy_arguments "$@"

  
    
  if [[ -z "$rargs_environment" ]]; then
    rargs_environment="dev"
  fi
    
	if [[ -z "$rargs_stack_name" ]]; then
		rargs_stack_name="$DEMO_NAME-$rargs_environment"
	fi
	$secondary cloudformation delete-stack \
		--stack-name "$rargs_stack_name"
	if [[ -z "$rargs_no_track" ]]; then
		track -s "$rargs_stack_name"
	fi
}
log-groups_usage() {
  printf "Get the list of log groups\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  log-groups [OPTIONS]\n"
  printf "  log-groups -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -l --lambda [<LAMBDA>]\n"
  printf "    The name of the lambda function to get the logs from.\n"
  printf "    [@default [=SnapshotLambdaFunction]]\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_log-groups_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        log-groups_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      -l | --lambda)
        rargs_lambda="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Get the list of log groups
log-groups() {
  local rargs_lambda
  # Parse command arguments
  parse_log-groups_arguments "$@"

  
    
  if [[ -z "$rargs_lambda" ]]; then
    rargs_lambda="[=SnapshotLambdaFunction]"
  fi
    
	$primary logs describe-log-groups \
		--query 'logGroups[].{logGroupName: logGroupName, creationTime: creationTime}' |
		yq '.[] | .logGroupName + "|" + .creationTime ' |
		sort -r |
		grep "$rargs_lambda" |
		column -t -s'|' |
		sort -k2,2nr
}
log-streams_usage() {
  printf "Get the log-streams of one of the events lamda function\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  log-streams [OPTIONS]\n"
  printf "  log-streams -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -g --group [<GROUP>]\n"
  printf "    The name of the log group to use.\n"
  printf "  -l --lambda [<LAMBDA>]\n"
  printf "    The name of the lambda function to get the logs from.\n"
  printf "    [@default [=SnapshotLambdaFunction]]\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_log-streams_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        log-streams_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      -g | --group)
        rargs_group="$2"
        shift 2
        ;;
      -l | --lambda)
        rargs_lambda="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Get the log-streams of one of the events lamda function
log-streams() {
  local rargs_group
  local rargs_lambda
  # Parse command arguments
  parse_log-streams_arguments "$@"

  
    
  if [[ -z "$rargs_lambda" ]]; then
    rargs_lambda="[=SnapshotLambdaFunction]"
  fi
    
	if [[ -z "$rargs_group" ]]; then
		rargs_group="$(log-groups | grep "$rargs_lambda" | head -n 1 | cut -d' ' -f1)"
	fi
	$primary logs describe-log-streams \
		--log-group-name "$rargs_group" \
		--order-by LastEventTime \
		--descending \
		--query 'logStreams[].{logStreamName: logStreamName, creationTime: creationTime}' |
		yq '.[] | .logStreamName + "|" + .creationTime ' |
		column -t -s'|' |
		sort -k2,2nr
}
logs_usage() {
  printf "Get the logs of one of the events lamda function\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  logs [OPTIONS]\n"
  printf "  logs -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -g --group [<GROUP>]\n"
  printf "    The name of the log group to use.\n"
  printf "  -l --lambda [<LAMBDA>]\n"
  printf "    The name of the lambda function to get the logs from.\n"
  printf "    [@default [=SnapshotLambdaFunction]]\n"
  printf "  -s --stream [<STREAM>]\n"
  printf "    The name of the log stream to use.\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_logs_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        logs_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      -g | --group)
        rargs_group="$2"
        shift 2
        ;;
      -l | --lambda)
        rargs_lambda="$2"
        shift 2
        ;;
      -s | --stream)
        rargs_stream="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Get the logs of one of the events lamda function
logs() {
  local rargs_group
  local rargs_lambda
  local rargs_stream
  # Parse command arguments
  parse_logs_arguments "$@"

  
    
  if [[ -z "$rargs_lambda" ]]; then
    rargs_lambda="[=SnapshotLambdaFunction]"
  fi
    
	if [[ -z "$rargs_group" ]]; then
		rargs_group="$(log-groups -l "$rargs_lambda" | head -n 1 | cut -d' ' -f1)"
	fi
	if [[ -z "$rargs_stream" ]]; then
		rargs_stream="$(log-streams -g "$rargs_group" | head -n 1 | cut -d' ' -f1)"
	fi
	$primary logs get-log-events \
		--log-group-name "$rargs_group" \
		--log-stream-name "$rargs_stream" |
		jq -r '.events[].message'
}
status_usage() {
  printf "Get the status of the deployed cross-account resources\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  status [OPTIONS]\n"
  printf "  status -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -e --environment [<ENVIRONMENT>]\n"
  printf "    The name of the environment to depoy to.\n"
  printf "    [@default dev]\n"
  printf "  -s --stack-name [<STACK-NAME>]\n"
  printf "    The name of the stack to use.\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_status_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        status_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      -e | --environment)
        rargs_environment="$2"
        shift 2
        ;;
      -s | --stack-name)
        rargs_stack_name="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Get the status of the deployed cross-account resources
status() {
  local rargs_environment
  local rargs_stack_name
  # Parse command arguments
  parse_status_arguments "$@"

  
    
  if [[ -z "$rargs_environment" ]]; then
    rargs_environment="dev"
  fi
    
	if [[ -z "$rargs_stack_name" ]]; then
		rargs_stack_name="$DEMO_NAME-$rargs_environment"
	fi
	status="$(
		$secondary cloudformation describe-stacks \
			--stack-name "$rargs_stack_name" \
			--query "Stacks[0].StackStatus" \
			--output text
	)"
	parameters="$($secondary cloudformation describe-stacks \
		--stack-name "$rargs_stack_name" \
		--query "Stacks[0].Parameters")"
	resources="$(
		$secondary cloudformation describe-stack-resources \
			--stack-name "$rargs_stack_name"
	)"
	outputs="$($secondary cloudformation describe-stacks \
		--stack-name "$rargs_stack_name" \
		--query "Stacks[0].Outputs")"
	{
		echo "---"
		echo "Name: $rargs_stack_name"
		echo "Status: $status"
		if [[ "$parameters" != "null" ]]; then
			echo "Parameters: "
			echo "$parameters" | yq -P
		fi
		if [[ "$resources" != "null" ]]; then
			echo "$resources" | yq -P
		fi
		if [[ "$outputs" != "null" ]]; then
			echo "Outputs: "
			echo "$outputs" | yq -P
		fi
		echo "..."
	} | yq -P
}
track_usage() {
  printf "Track the update of a CloudFormation template\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  track [OPTIONS]\n"
  printf "  track -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -e --environment [<ENVIRONMENT>]\n"
  printf "    The name of the environment to depoy to.\n"
  printf "    [@default dev]\n"
  printf "  -s --stack-name [<STACK-NAME>]\n"
  printf "    The name of the stack to use.\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_track_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        track_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      -e | --environment)
        rargs_environment="$2"
        shift 2
        ;;
      -s | --stack-name)
        rargs_stack_name="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Track the update of a CloudFormation template
track() {
  local rargs_environment
  local rargs_stack_name
  # Parse command arguments
  parse_track_arguments "$@"

  
    
  if [[ -z "$rargs_environment" ]]; then
    rargs_environment="dev"
  fi
    
	local EXIT_STATUS
	EXIT_STATUS=0
	tmp="$(mktemp)"
	if [[ -z "$rargs_stack_name" ]]; then
		rargs_stack_name="$DEMO_NAME-$rargs_environment"
	fi
	while True; do
		status="$(
			$secondary cloudformation describe-stacks \
				--stack-name "$rargs_stack_name" \
				--query 'Stacks[].StackStatus' | yq -r '.[]'
		)"
		case "$status" in
		UPDATE_COMPLETE | CREATE_COMPLETE)
			echo "Deployment complete"
			break
			;;
		UPDATE_FAILED | CREATE_FAILED | UPDATE_ROLLBACK_COMPLETE | ROLLBACK_COMPLETE | ROLLBACK_FAILED)
			echo "Deployment failed"
			EXIT_STATUS=1
			break
			;;
		DELETE_COMPLETE | DELETE_FAILED)
			echo "Deployment failed and needs to be deleted"
			EXIT_STATUS=2
			DESTROY=1
			break
			;;
		esac
		$secondary cloudformation describe-stack-events \
			--stack-name "$rargs_stack_name" \
			--query 'StackEvents[].{LogicalResourceId: LogicalResourceId, ResourceStatus: ResourceStatus, ResourceStatusReason: ResourceStatusReason}' | yq '.[] | .LogicalResourceId + "|" + .ResourceStatus + "|" + .ResourceStatusReason' |
			column -t -s'|' |
			sort -r |
			while read -r line; do
				id="$(base64 <<<"$(echo -n "$line" | tr -d ' ')")"
				if ! grep -q "$id" "$tmp"; then
					echo "$id" >>"$tmp"
					echo "$line"
				fi
			done
		sleep 5
	done
	if [[ "$DESTROY" == 1 ]]; then
		destroy -s "$rargs_stack_name"
	fi
	return $EXIT_STATUS
}
update_usage() {
  printf "Update the cross-account resources using CloudFormation\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  update [OPTIONS]\n"
  printf "  update -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -e --environment [<ENVIRONMENT>]\n"
  printf "    The name of the environment to depoy to.\n"
  printf "    [@default dev]\n"
  printf "  -l --lambda [<LAMBDA>]\n"
  printf "    The name of the lambda function to use.\n"
  printf "  -p --parameters [<PARAMETERS>]\n"
  printf "    The name of the parameters file to use.\n"
  printf "  -s --stack-name [<STACK-NAME>]\n"
  printf "    The name of the stack to use.\n"
  printf "  -t --template [<TEMPLATE>]\n"
  printf "    The name of the template to use.\n"
  printf "  --no-track\n"
  printf "    Don't track update changes.\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_update_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        update_usage
        exit
        ;;
      *)
        break
        ;;
    esac
  done

  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      --no-track)
        rargs_no_track=1
        shift
        ;;
      -e | --environment)
        rargs_environment="$2"
        shift 2
        ;;
      -l | --lambda)
        rargs_lambda="$2"
        shift 2
        ;;
      -p | --parameters)
        rargs_parameters="$2"
        shift 2
        ;;
      -s | --stack-name)
        rargs_stack_name="$2"
        shift 2
        ;;
      -t | --template)
        rargs_template="$2"
        shift 2
        ;;
      -?*)
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid option: " "$key" >&2
        exit 1
        ;;
      *)
        if [[ "$key" == "" ]]; then
          break
        fi
        printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Invalid argument: " "$key" >&2
        exit 1
        ;;
    esac
  done
}
# Update the cross-account resources using CloudFormation
update() {
  local rargs_no_track
  local rargs_environment
  local rargs_lambda
  local rargs_parameters
  local rargs_stack_name
  local rargs_template
  # Parse command arguments
  parse_update_arguments "$@"

  # Check dependencies
  dependency="jo"
  if ! command -v $dependency >/dev/null 2>&1; then
    printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Missing dependency: " "$dependency" >&2
    printf "You need to install jo to use this command.\n" >&2
    exit 1
  else
    deps["$dependency"]="$(command -v $dependency | head -n1)"
  fi

  
    
  if [[ -z "$rargs_environment" ]]; then
    rargs_environment="dev"
  fi
    
	if [[ -z "$rargs_stack_name" ]]; then
		rargs_stack_name="$DEMO_NAME-$rargs_environment"
	fi
	if [[ -z "$rargs_template" ]]; then
		rargs_template="$ROOT_DIRECTORY/../cross-account-cf-template.yaml"
	fi
	if [[ -z "$rargs_parameters" ]]; then
		rargs_parameters="$ROOT_DIRECTORY/../cross-account-parameters.$rargs_environment.json"
	fi
	if [[ -z "$rargs_lambda" ]]; then
		rargs_lambda="$ROOT_DIRECTORY/cross_account_rds_snapshot_copy.py"
	fi
	tmp="$(mktemp)"
	LAMBDA_CONTENTS="$(awk 'NR == 1 {print $0; next} {printf "          %s\n", $0}' "$rargs_lambda")"
	export LAMBDA_CONTENTS
	envsubst <"$rargs_template" >"$tmp"
	change_set_name="$rargs_stack_name-change-set-$(date +%s)"
	echo "Creating change set $change_set_name" >&2
	$secondary cloudformation create-change-set \
		--stack-name "$rargs_stack_name" \
		--template-body "file://$tmp" \
		--parameters "file://$rargs_parameters" \
		--change-set-name "$change_set_name" \
		--capabilities CAPABILITY_NAMED_IAM
	echo "Waiting for change set to be created" >&2
	$secondary cloudformation wait change-set-create-complete \
		--stack-name "$rargs_stack_name" \
		--change-set-name "$change_set_name"
	echo "Change set details" >&2
	$secondary cloudformation describe-change-set \
		--stack-name "$rargs_stack_name" \
		--change-set-name "$change_set_name" | yq -P '.Changes'
	echo "Executing change set $change_set_name" >&2
	$secondary cloudformation execute-change-set \
		--stack-name "$rargs_stack_name" \
		--change-set-name "$change_set_name"
	if [[ -z "$rargs_no_track" ]]; then
		track -s "$rargs_stack_name"
	fi
	exit $?
}

run() {
  declare -A deps=()
  declare -a input=()
  normalize_input "$@"
  parse_arguments "${input[@]}"
  # Call the right command action
  case "$action" in
    "create")
      create "${input[@]}"
      exit
      ;;
    "destroy")
      destroy "${input[@]}"
      exit
      ;;
    "log-groups")
      log-groups "${input[@]}"
      exit
      ;;
    "log-streams")
      log-streams "${input[@]}"
      exit
      ;;
    "logs")
      logs "${input[@]}"
      exit
      ;;
    "status")
      status "${input[@]}"
      exit
      ;;
    "track")
      track "${input[@]}"
      exit
      ;;
    "update")
      update "${input[@]}"
      exit
      ;;
    "")
      printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Missing command. Select one of " "create, destroy, log-groups, log-streams, logs, status, track, update" >&2
      usage >&2
      exit 1
      ;;
    
  esac
}

run "$@"
