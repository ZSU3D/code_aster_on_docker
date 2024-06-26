# coding=utf-8
# --------------------------------------------------------------------
# Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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

# person_in_charge: mathieu.courtois at edf.fr


import aster
from code_aster.Cata.Syntax import ASSD, AsException


class table_sdaster(ASSD):
    cata_sdj = "SD.sd_table.sd_table"

    def __getitem__(self, key):
        """Retourne la valeur d'une cellule de la table.
        Exemple : TAB['INST', 1] retourne la 1ère valeur de la colonne 'INST'."""
        from Utilitai.Utmess import UTMESS
        if not self.accessible():
            raise AsException("Erreur dans table.__getitem__ en PAR_LOT='OUI'")
        assert len(key) == 2
        para, numlign = key
        tabnom = self.sdj.TBLP.get()
        try:
            i = tabnom.index('%-24s' % para)
            resu = aster.getvectjev(tabnom[i + 2])
            exist = aster.getvectjev(tabnom[i + 3])
            assert resu is not None
            assert exist is not None
            assert exist[numlign - 1] != 0
            res = resu[numlign - 1]
        except (IndexError, AssertionError):
            # pour __getitem__, il est plus logique de retourner KeyError.
            raise KeyError
        return res

    def TITRE(self):
        """Retourne le titre d'une table Aster
        (Utile pour récupérer le titre et uniquement le titre d'une table dont
        on souhaite manipuler la dérivée).
        """
        if not self.accessible():
            raise AsException("Erreur dans table.TITRE en PAR_LOT='OUI'")
        #titj = aster.getvectjev('%-19s.TITR' % self.get_name())
        titj = self.sdj.TITR.get()
        if titj is not None:
            titr = '\n'.join(titj)
        else:
            titr = ''
        return titr

    def get_nom_para(self):
        """Produit une liste des noms des colonnes
        """
        if not self.accessible():
            raise AsException("Erreur dans table.get_nom_para en PAR_LOT='OUI'")
        l_name = []
        shape = self.sdj.TBNP.get()
        desc  = self.sdj.TBLP.get()
        for n in range(shape[0]):
            nom = desc[4*n]
            l_name.append( nom.strip() )
        return l_name

    def EXTR_TABLE(self, para=None) :
        """Produit un objet Table à partir du contenu d'une table Aster.
        On peut limiter aux paramètres listés dans 'para'.
        """
        def Nonefy(l1,l2) :
            if l2 == 0:
                return None
            else:
                return l1
        if not self.accessible():
            raise AsException("Erreur dans table.EXTR_TABLE en PAR_LOT='OUI'")
        from Utilitai.Table import Table
        # titre
        titr = self.TITRE()
        # récupération des paramètres
        #v_tblp = aster.getvectjev('%-19s.TBLP' % self.get_name())
        v_tblp = self.sdj.TBLP.get()
        if v_tblp is None:
            # retourne une table vide
            return Table(titr=titr, nom=self.nom)
        tabnom=list(v_tblp)
        nparam=len(tabnom)//4
        lparam=[tabnom[4*i:4*i+4] for i in range(nparam)]
        # restriction aux paramètres demandés
        if para is not None:
            if type(para) not in (list, tuple):
                para = [para, ]
            para = [p.strip() for p in para]
            restr = []
            for ip in lparam:
                if ip[0].strip() in para:
                    restr.append(ip)
            lparam = restr
        dval={}
        # liste des paramètres et des types
        lpar=[]
        ltyp=[]
        for i in lparam :
            value=list(aster.getvectjev(i[2]))
            if i[1].strip().startswith("K"):
                value = [j.strip() for j in value]
            exist=aster.getvectjev(i[3])
            dval[i[0].strip()] = list(map(Nonefy, value, exist))
            lpar.append(i[0].strip())
            ltyp.append(i[1].strip())
        n=len(dval[lpar[0]])
        # contenu : liste de dict
        lisdic=[]
        for i in range(n) :
            d={}
            for p in lpar:
               d[p]=dval[p][i]
            lisdic.append(d)
        return Table(lisdic, lpar, ltyp, titr, self.nom)


class table_fonction(table_sdaster):
    """Table contenant une colonne FONCTION et/ou FONCTION_C dont les
    valeurs des cellules sont des noms de fonction_sdaster ou
    fonction_c."""
    cata_sdj = "SD.sd_table_fonction.sd_table_fonction"


class table_container(table_sdaster):
    """Table contenant les colonnes NOM_OBJET, TYPE_OBJET et NOM_SD."""
    cata_sdj = "SD.sd_table_container.sd_table_container"
