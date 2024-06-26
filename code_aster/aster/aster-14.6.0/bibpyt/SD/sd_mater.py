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

from SD import *

from SD.sd_fonction import sd_fonction
from SD.sd_table import sd_table


class sd_mater_LISV(AsBase):
#---------------------------
    nomj = SDNom(fin=16)
    LISV_R8 = Facultatif(AsVR())
    LISV_FO = Facultatif(AsVK8())

class sd_mater_XDEP(AsBase):
#---------------------------
    # on dirait une fonction, mais c'est plutot la concaténation de plusieurs
    # fonctions
    nomj = SDNom(fin=19)
    PROL = AsVK24()
    VALE = AsVR()


class sd_compor1(AsBase):
#-----------------------
    nomj = SDNom(fin=19)
    VALC = AsVC(SDNom())
    VALK = AsVK16(SDNom())
    VALR = AsVR(SDNom())
    ORDR =Facultatif(AsVK16(SDNom()))
    KORD =Facultatif(AsVI(SDNom()))

    # parfois, comme dans THER_NL on crée une sd_fonction pour BETA
    def check_compor1_i_VALK(self, checker):
        nom = self.nomj().strip()
        valk = list(self.VALK.get_stripped())
        assert self.VALC.lonmax == self.VALR.lonmax
        assert self.VALK.lonmax == 2*self.VALR.lonmax
        nbk2 = self.VALK.lonuti
        nbr = self.VALR.lonuti
        nbc = self.VALC.lonuti
        nbk = nbk2 - nbr - nbc
        for k in range(nbk // 2):
            nomcon = valk[nbr + nbc + nbk // 2 + k]
            # La SD nomcon est une sd_fonction, une sd_table ou un sd_mater_LISV :
            sd2 = sd_fonction(nomcon)
            if sd2.PROL.exists:
                # parfois, la fonction a ete cree en sous-terrain et n'a
                # pas encore ete verifiee :
                sd2.check(checker)
            else:
                sd3 = sd_table(nomcon)
                if sd3.exists():
                    pass # normalement,la table a deja ete verifiee
                else :
                    sd4 = sd_mater_LISV(nomcon)
                    sd4.check(checker)


class sd_mater(AsBase):
#----------------------
    nomj = SDNom(fin=8)
    NOMRC = AsVK32(SDNom(nomj='.MATERIAU.NOMRC'), )
    rdep = Facultatif(sd_mater_XDEP(SDNom(nomj='.&&RDEP')))  # à documenter
    mzp = Facultatif(sd_mater_XDEP(SDNom(nomj='.&&MZP')))  # à documenter

    # existence possible de la SD :
    def exists(self):
        return self.NOMRC.exists

    # indirection vers les sd_compor1 de NOMRC :
    def check_mater_i_NOMRC(self, checker):
        nbc = self.NOMRC.lonuti
        for i in range(1, nbc + 1):
            ns = '{:06d}'.format(i)
            nomc1 = self.nomj()[:8] + '.CPT.' + ns
            comp1 = sd_compor1(nomc1)

            # parfois, comp1 est vide : ssls115g/DEFI_COQU_MULT
            if comp1.VALK.get():
                comp1.check(checker)
