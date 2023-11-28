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


normalize_rargs_input() {
  local arg flags

  while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ $arg =~ ^(--[a-zA-Z0-9_\-]+)=(.+)$ ]]; then
      rargs_input+=("${BASH_REMATCH[1]}")
      rargs_input+=("${BASH_REMATCH[2]}")
    elif [[ $arg =~ ^(-[a-zA-Z0-9])=(.+)$ ]]; then
      rargs_input+=("${BASH_REMATCH[1]}")
      rargs_input+=("${BASH_REMATCH[2]}")
    elif [[ $arg =~ ^-([a-zA-Z0-9][a-zA-Z0-9]+)$ ]]; then
      flags="${BASH_REMATCH[1]}"
      for ((i = 0; i < ${#flags}; i++)); do
        rargs_input+=("-${flags:i:1}")
      done
    else
      rargs_input+=("$arg")
    fi

    shift
  done
}

inspect_args() {
  prefix="rargs_"
  args="$(set | grep ^$prefix | grep -v rargs_run || true)"
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

  if ((${#rargs_other_args[@]})); then
    echo
    echo rargs_other_args:
    echo "- \${rargs_other_args[*]} = ${rargs_other_args[*]}"
    for i in "${!rargs_other_args[@]}"; do
      echo "- \${rargs_other_args[$i]} = ${rargs_other_args[$i]}"
    done
  fi
}

set -eo pipefail
DEMO_NAME="${DEMO_NAME:-"cross-region-cross-account-rds-backups"}"
primary="aws --profile cloudbridge-dba-primary"
primary2="aws --profile cloudbridge-dba-primary-2"

version() {
  echo "0.1.0"
}
usage() {
  printf "Handle the snapshots\n"
  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  snapshots [OPTIONS] [COMMAND] [COMMAND_OPTIONS]\n"
  printf "  snapshots -h|--help\n"
  printf "  snapshots -v|--version\n"
  printf "\n\033[4m%s\033[0m\n" "Commands:"
  cat <<EOF
  create ............ Creates a new snapshot
  delete ............ Deletes a snapshot
  list-instances .... Shows the list of RDS instances
  list-snapshots .... List snapshots
  purge ............. Cleans up all snapshots
  status ............ Gets the status of an existing snapshot
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
      rargs_input=("${rargs_input[@]:1}")
      ;;
    delete)
      action="delete"
      rargs_input=("${rargs_input[@]:1}")
      ;;
    list-instances)
      action="list-instances"
      rargs_input=("${rargs_input[@]:1}")
      ;;
    list-snapshots)
      action="list-snapshots"
      rargs_input=("${rargs_input[@]:1}")
      ;;
    purge)
      action="purge"
      rargs_input=("${rargs_input[@]:1}")
      ;;
    status)
      action="status"
      rargs_input=("${rargs_input[@]:1}")
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
  printf "Creates a new snapshot\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  create [OPTIONS]\n"
  printf "  create -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -d --db-instance-identifier [<DB-INSTANCE-IDENTIFIER>]\n"
  printf "    The name of the database instance\n"
  printf "  -n --db-snapshot-identifier [<DB-SNAPSHOT-IDENTIFIER>]\n"
  printf "    A unique snapshot identifier\n"
  printf "  -e --environment [<ENVIRONMENT>]\n"
  printf "    The name of the environment to depoy to.\n"
  printf "    [@default dev]\n"
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
      -d | --db-instance-identifier)
        rargs_db_instance_identifier="$2"
        shift 2
        ;;
      -n | --db-snapshot-identifier)
        rargs_db_snapshot_identifier="$2"
        shift 2
        ;;
      -e | --environment)
        rargs_environment="$2"
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
# Creates a new snapshot
create() {
  local rargs_db_instance_identifier
  local rargs_db_snapshot_identifier
  local rargs_environment
  # Parse command arguments
  parse_create_arguments "$@"

  
    
  if [[ -z "$rargs_environment" ]]; then
    rargs_environment="dev"
  fi
    
	if [[ -z "$rargs_db_instance_identifier" ]]; then
		rargs_db_instance_identifier="$(list-instances | tail -n+2 | head -n1 | cut -d' ' -f1)"
	fi
	if [[ -z "$rargs_db_snapshot_identifier" ]]; then
		rargs_db_snapshot_identifier="$DEMO_NAME-$rargs_environment-snapshot-$(date +%s)"
	fi
	$primary rds create-db-snapshot \
		--db-snapshot-identifier "$rargs_db_snapshot_identifier" \
		--db-instance-identifier "$rargs_db_instance_identifier"
	status -n "$rargs_db_snapshot_identifier" --watch
}
delete_usage() {
  printf "Deletes a snapshot\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  delete [OPTIONS]\n"
  printf "  delete -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -n --db-snapshot-identifier [<DB-SNAPSHOT-IDENTIFIER>]\n"
  printf "    A unique snapshot identifier\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_delete_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        delete_usage
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
      -n | --db-snapshot-identifier)
        rargs_db_snapshot_identifier="$2"
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
# Deletes a snapshot
delete() {
  local rargs_db_snapshot_identifier
  # Parse command arguments
  parse_delete_arguments "$@"

	$primary rds delete-db-snapshot \
		--db-snapshot-identifier "$rargs_db_snapshot_identifier"
}
list-instances_usage() {
  printf "Shows the list of RDS instances\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  list-instances [OPTIONS]\n"
  printf "  list-instances -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_list-instances_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        list-instances_usage
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
# Shows the list of RDS instances
list-instances() {
  # Parse command arguments
  parse_list-instances_arguments "$@"

	{
		echo "DBInstanceIdentifier|DBInstanceStatus"
		$primary rds describe-db-instances \
			--query 'DBInstances[*].{DBInstanceIdentifier: DBInstanceIdentifier, DBInstanceStatus: DBInstanceStatus}' |
			yq -r '.[] | .DBInstanceIdentifier + "|" + .DBInstanceStatus'
	} |
		column -t -s'|'
}
list-snapshots_usage() {
  printf "List snapshots\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  list-snapshots [OPTIONS]\n"
  printf "  list-snapshots -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -n --db-snapshot-identifier [<DB-SNAPSHOT-IDENTIFIER>]\n"
  printf "    A unique snapshot identifier\n"
  printf "  --secondary\n"
  printf "    Use the secondary account\n"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_list-snapshots_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        list-snapshots_usage
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
      --secondary)
        rargs_secondary=1
        shift
        ;;
      -n | --db-snapshot-identifier)
        rargs_db_snapshot_identifier="$2"
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
# List snapshots
list-snapshots() {
  local rargs_secondary
  local rargs_db_snapshot_identifier
  # Parse command arguments
  parse_list-snapshots_arguments "$@"

	if [[ -z "$rargs_secondary" ]]; then
		client="$primary"
	else
		client="$primary2"
	fi
	{
		echo "DBSnapshotIdentifier|DBInstanceIdentifier|SnapshotType|SnapshotCreateTime|Engine|AllocatedStorage|Status"
		$client rds describe-db-snapshots \
			--db-instance-identifier "$rargs_db_snapshot_identifier" \
			--query 'DBSnapshots[*].{id: DBSnapshotIdentifier, instance: DBInstanceIdentifier, type: SnapshotType, created: SnapshotCreateTime, engine: Engine, storage: AllocatedStorage, status: Status}' |
			yq -r '.[] | .id + "|" + .instance + "|" + .type + "|" + .created + "|" + .engine + "|" + .storage + "|" + .status'
	} |
		column -t -s'|'
}
purge_usage() {
  printf "Cleans up all snapshots\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  purge [OPTIONS]\n"
  printf "  purge -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -h --help\n"
  printf "    Print help\n"
}
parse_purge_arguments() {
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -h|--help)
        purge_usage
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
# Cleans up all snapshots
purge() {
  # Parse command arguments
  parse_purge_arguments "$@"

	list-snapshots --secondary | tail -n+2 | grep -v automated | cut -d' ' -f1 | xargs -I{} $primary2 rds delete-db-snapshot --db-snapshot-identifier {}
	list-snapshots | tail -n+2 | grep -v automated | cut -d' ' -f1 | xargs -I{} $primary rds delete-db-snapshot --db-snapshot-identifier {}
}
status_usage() {
  printf "Gets the status of an existing snapshot\n"

  printf "\n\033[4m%s\033[0m\n" "Usage:"
  printf "  status [OPTIONS]\n"
  printf "  status -h|--help\n"

  printf "\n\033[4m%s\033[0m\n" "Options:"
  printf "  -n --db-snapshot-identifier [<DB-SNAPSHOT-IDENTIFIER>]\n"
  printf "    A unique snapshot identifier\n"
  printf "  --watch\n"
  printf "    Watch the status of the snapshot\n"
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
      --watch)
        rargs_watch=1
        shift
        ;;
      -n | --db-snapshot-identifier)
        rargs_db_snapshot_identifier="$2"
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
# Gets the status of an existing snapshot
status() {
  local rargs_watch
  local rargs_db_snapshot_identifier
  # Parse command arguments
  parse_status_arguments "$@"

	if [[ -z "$rargs_watch" ]]; then
		$primary rds describe-db-snapshots \
			--db-snapshot-identifier "$rargs_db_snapshot_identifier" \
			--query 'DBSnapshots[*].Status' --output text
	else
		while true; do
			status="$(status -n "$rargs_db_snapshot_identifier")"
			case "$status" in
			available)
				echo "Snapshot created"
				break
				;;
			*)
				echo "Snapshot creation in progress [$status]"
				sleep 5
				;;
			esac
		done
	fi
}

rargs_run() {
  declare -A deps=()
  declare -a rargs_input=()
  normalize_rargs_input "$@"
  parse_arguments "${rargs_input[@]}"
  # Call the right command action
  case "$action" in
    "create")
      create "${rargs_input[@]}"
      exit
      ;;
    "delete")
      delete "${rargs_input[@]}"
      exit
      ;;
    "list-instances")
      list-instances "${rargs_input[@]}"
      exit
      ;;
    "list-snapshots")
      list-snapshots "${rargs_input[@]}"
      exit
      ;;
    "purge")
      purge "${rargs_input[@]}"
      exit
      ;;
    "status")
      status "${rargs_input[@]}"
      exit
      ;;
    "")
      printf "\e[31m%s\e[33m%s\e[31m\e[0m\n\n" "Missing command. Select one of " "create, delete, list-instances, list-snapshots, purge, status" >&2
      usage >&2
      exit 1
      ;;
    
  esac
}

rargs_run "$@"
