# coding=utf-8
# --------------------------------------------------------------------
# Copyright (C) 1991 - 2017 - EDF R&D - www.code-aster.org
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

from SD import *
from SD.sd_titre import sd_titre


class sd_listr8(sd_titre):
#----------------------------------
    nomj = SDNom(fin=19)
    LPAS = AsVR()
    BINT = AsVR()
    NBPA = AsVI()
    VALE = AsVR()

    def proche(self, a, b):
        # retourne  1  si a est proche de b
        # retourne -1  si a est loin de b
        # retourne  0  si a = 0. (ou b = 0.)
        if a != 0. and b != 0.:
            erreur = abs(a - b) / (abs(a) + abs(b))
            if erreur < 1.e-12:
                return 1
            else:
                return -1
        else:
            return 0

    def check_1(self, checker):
        nbpa = self.NBPA.get()
        bint = self.BINT.get()
        lpas = self.LPAS.get()
        vale = self.VALE.get()

        # cas général :
        if len(vale) > 1:
            assert len(bint) == len(nbpa) + 1
            assert len(nbpa) == len(lpas)

            n1 = 0
            assert self.proche(vale[0], bint[0]) in (1, 0)
            for k in range(len(nbpa)):
                npas = nbpa[k]
                assert npas > 0
                n1 = n1 + npas
                assert self.proche(vale[n1], bint[k + 1]) in (
                    1, 0), (k + 1, vale[n1], bint[k + 1],)

            assert len(vale) == n1 + 1

        # cas particulier :
        if len(vale) == 1:
            assert len(bint) == 1
            assert len(nbpa) == 1
            assert len(lpas) == 1
            assert vale[0] == bint[0]
