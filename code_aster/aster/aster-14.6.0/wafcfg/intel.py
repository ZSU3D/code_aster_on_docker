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
Configuration using Intel compilers

Use automatically MPI wrappers if opt.parallel was previously set.

You may want to add the following line in your ``wafcfg/`` file to reduce
the memory consumption during link::

    self.env.append_value('LINKFLAGS', ('--no-keep-memory'))

or set the environment variable before running ``./waf configure``::

    export LINKFLAGS=--no-keep-memory
"""

def configure(self):
    opts = self.options
    mpi = 'mpi' if opts.parallel else ''
    # Configure.find_program uses first self.environ, then os.environ
    self.environ['FC'] = mpi + 'ifort'
    self.environ['CC'] = mpi + 'icc'
    self.environ['CXX'] = mpi + 'icpc'
