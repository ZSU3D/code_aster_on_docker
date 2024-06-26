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
    Ce module contient la classe de definition MACRO
    qui permet de spécifier les caractéristiques d'une macro-commande
"""

import traceback

from . import N_ENTITE
from . import N_MACRO_ETAPE
from . import nommage
from .strfunc import ufmt


class MACRO(N_ENTITE.ENTITE):

    """
     Classe pour definir une macro-commande

     Cette classe a trois attributs de classe

     - class_instance qui indique la classe qui devra etre utilisée
             pour créer l'objet qui servira à controler la conformité d'un
             macro-commande avec sa définition

     - label qui indique la nature de l'objet de définition (ici, MACRO)

     - nommage qui est un module Python qui fournit la fonctionnalité de nommage

     et les attributs d'instance suivants :

     - nom   : son nom

     - op   : le numéro d'opérateur

     - sd_prod : le type de concept produit. C'est une classe ou une fonction qui retourne
                       une classe

     - reentrant : vaut 'n' ou 'o'. Indique si l'opérateur est réentrant ou pas. Un opérateur
                         réentrant peut modifier un concept d'entrée et le produire comme concept de sortie

     - repetable : vaut 'n' ou 'o'. Indique si l'opérateur est répetable ou pas. Un opérateur
                         non répétable ne doit apparaitre qu'une fois dans une exécution. C'est du ressort
                         de l'objet gérant le contexte d'exécution de vérifier cette contrainte.

     - fr   : commentaire associé en francais

     - translation : traduction métier des mots-clés (en anglais)

     - docu : clé de documentation associée

     - regles : liste des règles associées

     - op_init : cet attribut vaut None ou une fonction. Si cet attribut ne vaut pas None, cette
                       fonction est exécutée lors des phases d'initialisation de l'étape associée.

     - niveau : indique le niveau dans lequel est rangé l'opérateur. Les opérateurs peuvent etre
                      rangés par niveau. Ils apparaissent alors exclusivement dans leur niveau de rangement.
                      Si niveau vaut None, l'opérateur est rangé au niveau global.

     - entites : dictionnaire dans lequel sont stockés les sous entités de l'opérateur. Il s'agit
                       des entités de définition pour les mots-clés : FACT, BLOC, SIMP. Cet attribut
                       est initialisé avec args, c'est à dire les arguments d'appel restants.


    """
    class_instance = N_MACRO_ETAPE.MACRO_ETAPE
    label = 'MACRO'
    nommage = nommage

    def __init__(
        self, nom, op, sd_prod=None, reentrant='n', repetable='o', fr="",
            docu="", regles=(), op_init=None, niveau=None, fichier_ini=0,
            translation=None, **args):
        """
           Méthode d'initialisation de l'objet MACRO. Les arguments sont utilisés pour initialiser
           les attributs de meme nom
        """
        # XXX fichier_ini n'est pas utilisé pour l'instant
        self.nom = nom
        # op est obligatoire et permet de spécifier la procédure de construction de la macro
        # - Si op est un entier la construction de la macro est réalisée par une subroutine fortran opsxxx ou
        # xxx est donné par la valeur absolue de op. L'execution est egalement effectuée via cette subroutine.
        # - Si op est une fonction Python, la construction de la macro est effectuée par l'appel à cette fonction
        # Suivant le cas on garde l info dans self.op ou dans self.proc
        if type(op) == int:
            self.proc = None
            self.op = op
        else:
            self.op = None
            self.proc = op

        self.sd_prod = sd_prod
        self.reentrant = reentrant
        self.fr = fr
        assert args.get('ang') is None, '"ang" does not exist anymore'
        assert args.get('UIinfo') is None, '"UIinfo" does not exist anymore'
        self.repetable = repetable
        self.docu = docu
        if type(regles) == tuple:
            self.regles = regles
        else:
            self.regles = (regles,)
        self.fichier_ini = fichier_ini
        # Attribut op_init : Fonction a appeler a la construction de l
        # operateur sauf si is None
        self.op_init = op_init
        self.entites = args
        current_cata = CONTEXT.get_current_cata()
        if niveau is None:
            self.niveau = None
            current_cata.enregistre(self)
        else:
            self.niveau = current_cata.get_niveau(niveau)
            self.niveau.enregistre(self)
        self.affecter_parente()
        self.check_definition(self.nom)

    def __call__(self, reuse=None, **args):
        """
            Construit l'objet MACRO_ETAPE a partir de sa definition (self),
            puis demande la construction de ses sous-objets et du concept produit.
        """
        nomsd = self.nommage.GetNomConceptResultat(self.nom)
        etape = self.class_instance(oper=self, reuse=reuse, args=args)
        etape.McBuild()
        return etape.Build_sd(nomsd)

    def make_objet(self, mc_list='oui'):
        """
             Cette méthode crée l'objet MACRO_ETAPE dont la définition est self sans
             créer sa sdprod.
             Normalement l'étape est enregistrée auprès de son parent.
             Si l'argument mc_list vaut 'oui', elle déclenche en plus la construction
             des objets MCxxx.
        """
        etape = self.class_instance(oper=self, reuse=None, args={})
        if mc_list == 'oui':
            etape.McBuild()
        return etape

    def verif_cata(self, dummy=None):
        """
            Méthode de vérification des attributs de définition
        """
        self.check_op(valmax=0)
        self.check_proc()
        self.check_regles()
        self.check_fr()
        self.check_docu()
        self.check_nom()
        self.check_reentrant()
        self.verif_cata_regles()

    def supprime(self):
        """
            Méthode pour supprimer les références arrières susceptibles de provoquer
            des cycles de références
        """
        self.niveau = None
