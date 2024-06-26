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
from SD.sd_maillage import sd_maillage


class sd_voisinage(AsBase):
#-------------------------------
    nomj = SDNom(fin=12)
    PTVOIS = AsVI()
    ELVOIS = AsVI()


class sd_ligrel(AsBase):
#-------------------------------
    nomj = SDNom(fin=19)

    LGRF = AsVK8(lonmax=3, docu=Parmi('ACOU', 'MECA', 'THER'), )
    NBNO = AsVI(lonmax=1,)
    PRNM = AsVI()

    # AU_MOINS_UN : LIEL, SSSA
    # LIEL : il existe des éléments finis
    # SSSA : il existe des sous-structures statiques
    LIEL = Facultatif(
        AsColl(acces='NU', stockage='CONTIG', modelong='VARIABLE', type='I', ))
    SSSA = Facultatif(AsVI())
    # ENSEMBLE  : LIEL, REPE
    REPE = Facultatif(AsVI())

    # si mailles tardives :
    NEMA = Facultatif(
        AsColl(acces='NU', stockage='CONTIG', modelong='VARIABLE', type='I', ))
    # si noeuds tardifs :
    PRNS = Facultatif(AsVI())
    LGNS = Facultatif(AsVI())

    # si le ligrel contient des éléments nécessitant le voisinage :
    NVGE = Facultatif(AsVK16(lonmax=1,))

    def exists(self):
        # retourne True si la SD semble exister.
        return self.LGRF.exists

    def check_NVGE(self, checker):
        if not self.exists():
            return
        nvge = self.NVGE.get_stripped()
        if len(nvge) > 0:
            sd2 = sd_voisinage(nvge[0])
            sd2.check(checker)

    def check_LGRF(self, checker):
        if not self.exists():
            return
        lgrf = self.LGRF.get_stripped()
        sd2 = sd_maillage(lgrf[0])
        sd2.check(checker)
        # assert lgrf[1] != ''   # on ne sait pas toujours "remonter" à un modèle (lgphmo.f)
        # Je n'arrive pas à importer sd_modele (cyclage des imports):
        # from SD.sd_modele    import sd_modele
        # sd2=sd_modele.sd_modele(lgrf[1]); sd2.check(checker)

    def check_presence(self, checker):
        if not self.exists():
            return
        exi_liel = self.LIEL.exists
        exi_sssa = self.SSSA.exists
        exi_repe = self.REPE.exists
        exi_nema = self.NEMA.exists
        exi_prns = self.PRNS.exists
        exi_lgns = self.LGNS.exists

        # AU_MOINS_UN : .LIEL, .SSSA
        assert exi_liel or exi_sssa

        # SI .LIEL AU_MOINS_UN : .REPE, .NEMA
        if exi_liel:
            assert exi_repe or exi_nema

        # .REPE => .LIEL
        if exi_repe:
            assert exi_liel

        # .NEMA => .LIEL
        if exi_nema:
            assert exi_liel

        # noeuds tardifs => .PRNS .LGNS et .NEMA
        nb_no_tard = self.NBNO.get()[0]
        if nb_no_tard > 0:
            assert exi_prns
            assert exi_lgns
            assert exi_nema
            assert self.LGNS.lonmax >= nb_no_tard   # .LGNS est surdimensionné
            nbec = self.PRNS.lonmax / nb_no_tard
            assert self.PRNS.lonmax == nb_no_tard * nbec, (nbec, nb_no_tard)
            assert nbec >= 1 and nbec < 10, nbec
