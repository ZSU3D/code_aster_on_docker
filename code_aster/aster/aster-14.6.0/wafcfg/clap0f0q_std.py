# coding=utf-8
# --------------------------------------------------------------------
# Copyright (C) 1991 - 2019 - EDF R&D - www.code-aster.org
# This file is part of code_aster.
#
# code_aster is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# code_aster is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with code_aster.  If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------

"""
Configuration for clap0f0q (gfortran + openblas)

. $HOME/dev/codeaster/devtools/etc/env_unstable.sh

waf configure --use-config=clap0f0q_std --prefix=../install/std
waf install -p
"""

import os
ASTER_ROOT = os.environ['ASTER_ROOT']
YAMMROOT = os.environ['ROOT_SALOME']

import official_programs


def configure(self):
    opts = self.options

    official_programs.configure(self)
    official_programs.check_prerequisites_package(self, YAMMROOT, '20190507')

#   for using metis with standard integer (since Metis_aster-510_aster4)
    self.env.append_value('CFLAGS', ['-DINTSIZE32'])
 
#   adjust PATH to find gcc 4.9.2 in Mfront build
    self.env.append_value('OPT_ENV', [
        'export PATH=/home/aster/public/gcc_4_9_2/bin:' + YAMMROOT + '/prerequisites/Medfichier-400/bin:$PATH'])

    self.env['ADDMEM'] = 300

    TFELHOME = YAMMROOT + '/prerequisites/Mfront-TFEL321_aster'
    TFELVERS = '3.2.1'
    self.env.TFELHOME = TFELHOME
    self.env.TFELVERS = TFELVERS

    self.env.append_value('LIBPATH', [
        YAMMROOT + '/prerequisites/Python-365/lib',
        YAMMROOT + '/prerequisites/Hdf5-1103/lib',
        YAMMROOT + '/prerequisites/Medfichier-400/lib',
        YAMMROOT + '/prerequisites/Metis_aster-510_aster4/lib',
        YAMMROOT + '/prerequisites/Scotch_aster-604_aster7/SEQ/lib',
        YAMMROOT + '/prerequisites/Mumps-512_consortium_aster3/SEQ/lib',
        TFELHOME + '/lib',
        # for openblas
        ASTER_ROOT + '/public/lib',
    ])

    self.env.append_value('INCLUDES', [
        YAMMROOT + '/prerequisites/Python-365/include/python3.6',
        YAMMROOT + '/prerequisites/Hdf5-1103/include',
        YAMMROOT + '/prerequisites/Medfichier-400/include',
        YAMMROOT + '/prerequisites/Metis_aster-510_aster4/include',
        YAMMROOT + '/prerequisites/Scotch_aster-604_aster7/SEQ/include',
        YAMMROOT + '/prerequisites/Mumps-512_consortium_aster3/SEQ/include',
        YAMMROOT + '/prerequisites/Mumps-512_consortium_aster3/SEQ/include_seq',
        TFELHOME + '/include',
    ])

    # openblas from $ASTER_ROOT/public/lib embeds lapack
    opts.maths_libs = 'openblas'

    # to fail if not found
    opts.enable_hdf5 = True
    opts.enable_med = True
    opts.enable_metis = True
    opts.enable_mumps = True
    opts.enable_scotch = True
    opts.enable_mfront = True

    opts.enable_petsc = False
