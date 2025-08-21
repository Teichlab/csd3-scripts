#!/bin/bash

# List of partitions to check
partitions=("cclake" "cclake-himem" "icelake" "icelake-himem" "ampere" "sapphire" "desktop")

# Header
echo -e "Partition\tCount_Priority_Jobs\tHighest_Priority"

for part in "${partitions[@]}"; do
  # Get job ID and priority for PENDING jobs due to Priority in this partition
  job_data=$(squeue -h -p "$part" --states=PENDING -o "%i %r %Q" | awk '$2 == "Priority" {print $1, $3}')

  count=0
  max_priority=-1

  while read -r jobid prio; do
    [[ -z "$jobid" || -z "$prio" ]] && continue
    ((count++))
    if [[ "$prio" =~ ^[0-9]+$ ]] && (( prio > max_priority )); then
      max_priority=$prio
    fi
  done <<< "$job_data"

  # Output result
  if (( count == 0 )); then
    echo -e "${part}\t0\tN/A"
  else
    echo -e "${part}\t${count}\t${max_priority}"
  fi
done
