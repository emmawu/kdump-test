#!/usr/bin/env bash

# Copyright (c) 2016 Red Hat, Inc. All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Qiao Zhao <qzhao@redhat.com>

. ../lib/crash.sh

analyse_live()
{
    crash_prepare

    # Prepare crash-simple.cmd/crash.cmd
    # Check only return code of this session.
    # From the maintainer, Dave Anderson:
    #
    #  foreach bt
    #  foreach files
    #
    # Any "foreach" command option should *expect* to fail given that the
    # underlying set of tasks are changing while the command is being run.
    #
    #  runq
    #
    # The runq will constantly be changing, so results are indeterminate.
    #
    #  kmem -i
    #  kmem -s
    #  kmem -S - The "kmem -S" test is invalid when runing on a live system.
    #
    # The VM, and the slab subsystem specifically, is one of the most active
    # areas in the kernel, and so the commands above are very likely to run
    # into stale/changing pointers and such, and may fail as a result.
    cat <<EOF > "${K_TMP_DIR}/crash-simple.cmd"
sym -l
exit
EOF


    # Check command output of this session.
    cat <<EOF >> "${K_TMP_DIR}/crash.cmd"
pte e00000039f470105
EOF

    # In order for the "irq -u" option to work, the architecture
    # must have either the "no_irq_chip" or the "nr_irq_type" symbols to exist.
    # But s390x has none of them.
    if [ "$(uname -m)" != "s390x" ]; then
        cat <<EOF >>"${K_TMP_DIR}/crash.cmd"
irq
exit
EOF
    fi

# RHEL5/6/7 takes different version of crash utility respectively.
# So here adding cmds specific to each version.

    if [[ $K_DIST_VER -eq 6 ]]; then
        cat <<EOF >>"${K_TMP_DIR}/crash.cmd"
exit
EOF
    fi

    if [[ $K_DIST_VER -eq 7 ]]; then
        cat <<EOF >>"${K_TMP_DIR}/crash.cmd"
exit
EOF
    fi

    export SKIP_ERROR_PAT="kmem:.*error.*encountered\|kmem:.*slab.*invalid freepointer.*"
    crash_cmd "" "" "" "${K_TMP_DIR}/crash-simple.cmd"
    crash_cmd "" "" "" "${K_TMP_DIR}/crash.cmd" check_crash_output
    export SKIP_ERROR_PAT=""
}

run_test analyse_live
