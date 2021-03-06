#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#
# This script tests that the proc:::signal-send and proc:::signal-handle
# probes fire correctly and with the correct arguments.
#
# If this fails, the script will run indefinitely; it relies on the harness
# to time it out.
#
script()
{
if [ -f /usr/lib/dtrace/darwin.d ]; then
	$dtrace -s /dev/stdin <<EOF
	proc:::signal-send
	/execname == "kill" && curpsinfo->pr_ppid == $child  &&
	    args[1]->pr_psargs == "sleep" && args[2] == SIGUSR1/
	{
		/*
		 * This is guaranteed to not race with signal-handle.
		 */
		target = args[1]->pr_pid;
	}

	proc:::signal-handle
	/target == pid && args[0] == SIGUSR1/
	{
		exit(0);
	}
EOF
else
	$dtrace -s /dev/stdin <<EOF
	proc:::signal-send
	/execname == "kill" && curpsinfo->pr_ppid == $child &&
	    args[1]->pr_psargs == "$longsleep" && args[2] == SIGUSR1/
	{
		/*
		 * This is guaranteed to not race with signal-handle.
		 */
		target = args[1]->pr_pid;
	}

	proc:::signal-handle
	/target == pid && args[0] == SIGUSR1/
	{
		exit(0);
	}
EOF
fi
}

sleeper()
{
	while true; do
		if [ -f /usr/lib/dtrace/darwin.d ]; then
			$longsleep &
			sleep 1
			/bin/kill -USR1 $!
		else
			$longsleep &
			sleep 1
			/usr/bin/kill -USR1 $!
		fi
	done
}

dtrace=/usr/sbin/dtrace
if [ -f /usr/lib/dtrace/darwin.d ]; then
	longsleep="/bin/sleep 10000"
else
	longsleep="/usr/bin/sleep 10000"
fi

sleeper &
child=$!

script
status=$?

pstop $child
pkill -P $child
kill $child
prun $child

exit $status
