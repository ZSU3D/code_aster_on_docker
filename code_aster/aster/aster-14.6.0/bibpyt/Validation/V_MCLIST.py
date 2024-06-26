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

# person_in_charge: mathieu.courtois at edf.fr


"""
   Ce module contient la classe mixin MCList qui porte les méthodes
   nécessaires pour réaliser la validation d'un objet de type MCList
   dérivé de OBJECT.

   Une classe mixin porte principalement des traitements et est
   utilisée par héritage multiple pour composer les traitements.
"""
# Modules Python
import traceback

# Modules EFICAS
from Noyau import MAXSIZE, MAXSIZE_MSGCHK
from Noyau import N_CR
from Noyau.N_Exception import AsException
from Noyau.strfunc import ufmt


class MCList:

    """
       Cette classe a deux attributs de classe :

       - CR qui sert à construire l'objet compte-rendu

       - txt_nat qui sert pour les comptes-rendus liés à cette classe
    """

    CR = N_CR.CR
    txt_nat = "Mot clé Facteur Multiple :"

    def isvalid(self, cr='non'):
        """
           Methode pour verifier la validité du MCList. Cette méthode
           peut etre appelée selon plusieurs modes en fonction de la valeur
           de cr.

           Si cr vaut oui elle crée en plus un compte-rendu.

           On n'utilise pas d'attribut pour stocker l'état et on ne remonte pas
           le changement d'état au parent (pourquoi ??)
           MCLIST est une liste de MCFACT. Les MCFACT ont le meme parent
           que le MCLIST qui les contient. Il n'est donc pas necessaire de
           remonter le changement d'etat au parent. C'est deja fait
           par les MCFACT.
        """
        if len(self.data) == 0:
            return 0

        valid = 1
        definition = self.data[0].definition
        # Verification du nombre des mots cles facteurs
        if definition.min is not None and len(self.data) < definition.min:
            valid = 0
            if cr == 'oui':
                self.cr.fatal(
                    _("Nombre de mots clés facteurs insuffisant minimum : %s"),
                    definition.min)
        if definition.max is not None and definition.max != "**" and len(self.data) > definition.max:
            valid = 0
            if cr == 'oui':
                self.cr.fatal(
                    _("Nombre de mots clés facteurs trop grand maximum : %s"),
                    definition.max)
        num = 0
        for i in self.data:
            num = num + 1
            if not i.isvalid():
                valid = 0
                if cr == 'oui' and len(self) > 1:
                    self.cr.fatal(
                        _("L'occurrence numéro %d du mot-clé facteur : %s n'est pas valide"),
                        num, self.nom)
        return valid

    def report(self):
        """
            Génère le rapport de validation de self
        """
        if len(self) > 1:
            # Mot cle facteur multiple
            self.cr = self.CR(
                debut="Mot-clé facteur multiple : " + self.nom,
                fin="Fin Mot-clé facteur multiple : " + self.nom)
            j = 0
            for i in self.data:
                j += 1
                if j > MAXSIZE:
                    print(MAXSIZE_MSGCHK.format(MAXSIZE, len(self.data)))
                    break
                self.cr.add(i.report())
        elif len(self) == 1:
            # Mot cle facteur non multiple
            self.cr = self.data[0].report()
        else:
            self.cr = self.CR(debut="Mot-clé facteur : " + self.nom,
                              fin="Fin Mot-clé facteur : " + self.nom)

        try:
            self.isvalid(cr='oui')
        except AsException as e:
            if CONTEXT.debug:
                traceback.print_exc()
            self.cr.fatal(_("Mot-clé facteur multiple : %s, %s"), self.nom, e)
        return self.cr
