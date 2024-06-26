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
    Ce module contient la classe de definition PROC
    qui permet de spécifier les caractéristiques d'une procédure
"""

import traceback

from . import N_ENTITE
from . import N_PROC_ETAPE
from .strfunc import ufmt


class PROC(N_ENTITE.ENTITE):

    """
     Classe pour definir un opérateur

     Cette classe a deux attributs de classe

     - class_instance qui indique la classe qui devra etre utilisée
             pour créer l'objet qui servira à controler la conformité d'un
             opérateur avec sa définition

     - label qui indique la nature de l'objet de définition (ici, PROC)


     et les attributs d'instance suivants :

     - nom   : son nom

     - op   : le numéro d'opérateur

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
    class_instance = N_PROC_ETAPE.PROC_ETAPE
    label = 'PROC'

    def __init__(self, nom, op, reentrant='n', repetable='o', fr="",
                 docu="", regles=(), op_init=None, niveau=None,
                 translation=None, **args):
        """
           Méthode d'initialisation de l'objet PROC. Les arguments sont utilisés pour initialiser
           les attributs de meme nom
        """
        self.nom = nom
        self.op = op
        self.reentrant = reentrant
        self.repetable = repetable
        self.fr = fr
        assert args.get('ang') is None, '"ang" does not exist anymore'
        assert args.get('UIinfo') is None, '"UIinfo" does not exist anymore'
        self.docu = docu
        if type(regles) == tuple:
            self.regles = regles
        else:
            self.regles = (regles,)
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

    def __call__(self, **args):
        """
            Construit l'objet PROC_ETAPE a partir de sa definition (self),
            puis demande la construction de ses sous-objets et du concept produit.
        """
        etape = self.class_instance(oper=self, args=args)
        etape.McBuild()
        return etape.Build_sd()

    def make_objet(self, mc_list='oui'):
        """
             Cette méthode crée l'objet PROC_ETAPE dont la définition est self sans
              l'enregistrer ni créer sa sdprod.
             Si l'argument mc_list vaut 'oui', elle déclenche en plus la construction
             des objets MCxxx.
        """
        etape = self.class_instance(oper=self, args={})
        if mc_list == 'oui':
            etape.McBuild()
        return etape

    def verif_cata(self, dummy=None):
        """
            Méthode de vérification des attributs de définition
        """
        self.check_regles()
        self.check_fr()
        self.check_reentrant()
        self.check_docu()
        self.check_nom()
        self.check_op(valmin=0)
        self.verif_cata_regles()

    def supprime(self):
        """
            Méthode pour supprimer les références arrières susceptibles de provoquer
            des cycles de références
        """
        self.niveau = None
