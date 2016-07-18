#!/bin/bash
#
# title             : ssh_notify
# description       : Notifies about a login via ssh.
# author            : Intellex
# date              : 20152205
# version           : 0.1.0
# usage             : place in /etc/profile.d/ssh.sh file
#===============================================================================

# Config {

	# Define the list of users to ignore, user space or , to separate users
	IGNORED_USERS="git"

	# Email {

		# Send email
		EMAIL_ENABLED=1

		# Email addresses to send a mail to, use , to separete multiple entries
		EMAIL_RECEPIENTS="admin@gmail.com"

		# No email for logging from this IPs, use , to separate multiple entries
		EMAIL_IGNORED_IPS="8.8.8.8"

	# }

	# Welcome message {

		# Show message
		MESSAGE_ENABLED=1

		# List of services to check, use space to separate multiple entries
		MESSAGE_SERVICES="nginx mysqld"

	# }

#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ }


# Definitions {

	# Colors
	RED=$(tput setaf 1)
	GREEN=$(tput setaf 2)
	YELLOW=$(tput setaf 3)
	CLEAR=$(tput sgr0)

	# Colors
	FILE="$HOME/.ssh/history";

#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ }


# Macros {

	# String in array  ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ |
	function inArray() {
		[[ `echo "${2}" | grep "\b${1}\b"` ]] && return 0
	}

	# Is a valid number  ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ |
	function isNumber() {
		[[ "$1" -eq "$1" ]] && return 0
	}

	# Chech if the input is a even number  ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ |
	function isEven() {
		return [ $((HISTORY_COUNTER%2)) -eq 0 ]
	}

	# Is IP valid  ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ |
	function isValidIp() {
		local ip=$1
		local stat=1

		if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			OIFS=$IFS
			IFS='.'
			ip=($ip)
			IFS=$OIFS
			[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
				&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
			stat=$?
		fi
		return $stat
	}

#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ }

# Validate the user
ME="`whoami`"
if [ "${SSH_CLIENT}" != "" ] && ! inArray ${ME} "${IGNORED_USERS}"; then

# Get the remote address
IP=`echo $SSH_CLIENT | awk '{ ip = $1 } END { print ip }'`
PTR=`dig +short -x ${IP} | sed s/\.$//`

# Get the number of previous logins {

	# Prepare
	HISTORY_IP=()
	HISTORY_COUNT=()
	HISTORY_COUNTER=0

	# Make sure the file exists
	touch $FILE

	# Get the current state
	if [ -f $FILE ]; then
		LIST=`cat "${FILE}"`
		for VALUE in $LIST; do

			# Get the pointer
			I=`expr $HISTORY_COUNTER / 2`

			# IP
			if [ $((HISTORY_COUNTER%2)) -eq 0 ]; then

				# Validate ip
				if isValidIp $VALUE; then
					HISTORY_IP[$I]=$VALUE
				fi

			# Count
			else

				# Validate count
				if isNumber $VALUE; then
					HISTORY_COUNT[$I]=$VALUE;
				fi

			fi;

			# Increment counter
			((HISTORY_COUNTER++))
		done
	fi

	# Write back
	echo '' > $FILE
	for I in "${!HISTORY_IP[@]}"; do
		C=${HISTORY_COUNT[$I]}

		#if [ -n "${HISTORY_IP[$I]}" ] && [ -n "$C" ]; then

			# Increment
			if [ ${HISTORY_IP[$I]} == ${IP} ]; then
				((C++))
				FOUND=$C
			fi

			# Write to file
			echo "${HISTORY_IP[$I]} ${C}" >> $FILE

		#fi;
	done

	# If IP not found
	if [ -z $FOUND ]; then
		echo "${IP} 1" >> $FILE
		FOUND=1
	fi;

# }


# Send email {
if ! [[ $EMAIL_ENABLED -eq 0 ]] && ! inArray ${IP} "${EMAIL_IGNORED_IPS}"; then

	# Email body
	echo "This is an automated message reporting that a user has logged into the system.

	Number of logins from this IP: ${FOUND}

	User :         `whoami`
	Remote IP :    ${IP}
	Remote port :  `echo ${SSH_CLIENT} | awk '{ port = $2 } END { print port }'`
	Reverse DNS :   ${PTR}

	Server name :  `uname -a | awk '{ name = $2 } END { print name }'`
	Server IP :    `dig +short myip.opendns.com @resolver1.opendns.com`
	Server port :  `echo ${SSH_CLIENT} | awk '{ port = $3 } END { print port }'`
	Server time :  `date +'%Y-%m-%d %T'`


--
Sent from `uname -a | awk '{ name = $2 } END { print name }'` [`dig +short myip.opendns.com @resolver1.opendns.com`]
" | mail -s "`whoami` has just logged on `uname -a | awk '{ name = $2 } END { print name }'`" "${EMAIL_RECEPIENTS}"

fi # }

# Print system info {
if ! [[ $MESSAGE_ENABLED -eq 0 ]]; then

	# Get the services
	[[ -z $(command -v service) ]] && SVC_CMD="/etc/init.d/" || SVC_CMD="service "

	for SERVICE in ${MESSAGE_SERVICES}; do
		STATUS=`${SVC_CMD}${SERVICE} status 2>&1`
		SERVICES="${SERVICES} ${STATUS}\n"
	done;

	echo " Uptime          :`uptime | grep -oP '^.*?(?=,)'`
 Load average    : `uptime | grep -oP '(?<=average: ).*'`
 Space available : `df -h / | awk '{ a = $4; } END { print a }'`"


	if ! [[ -z $SERVICES ]]; then
		echo -e "\n${SERVICES}"
	else
		echo
	fi

	echo " ${YELLOW}CAUTION: Admin has been notified of this login${CLEAR}
 Your IP address is ${YELLOW}${IP}${CLEAR}
 Total IP logins: ${YELLOW}${FOUND}${CLEAR}
"

fi

fi;
