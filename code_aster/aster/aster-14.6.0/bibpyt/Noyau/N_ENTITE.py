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
    Ce module contient la classe ENTITE qui est la classe de base
    de toutes les classes de definition d'EFICAS.
"""

import re
from . import N_CR
from . import N_OPS
from . import N_VALIDATOR
from .N_VALIDATOR import ValError, TypeProtocol, listProto
from .strfunc import ufmt

stringTypes = (str, str)


class ENTITE:

    """
       Classe de base pour tous les objets de definition : mots cles et commandes
       Cette classe ne contient que des methodes utilitaires
       Elle ne peut être instanciee et doit d abord être specialisee
    """
    CR = N_CR.CR
    factories = {'validator': N_VALIDATOR.validatorFactory}

    def __init__(self, validators=None):
        """
           Initialise les deux attributs regles et entites d'une classe dérivée
           à : pas de règles et pas de sous-entités.

           L'attribut regles doit contenir la liste des regles qui s'appliquent
           sur ses sous-entités

           L'attribut entités doit contenir le dictionnaires des sous-entités
           (clé = nom, valeur=objet)
        """
        self.regles = ()
        self.entites = {}
        if validators:
            self.validators = self.factories['validator'](validators)
        else:
            self.validators = validators

    def affecter_parente(self):
        """
            Cette methode a pour fonction de donner un nom et un pere aux
            sous entités qui n'ont aucun moyen pour atteindre leur parent
            directement
            Il s'agit principalement des mots cles
        """
        for k, v in list(self.entites.items()):
            v.pere = self
            v.nom = k

    def verif_cata(self, nom=None):
        """
            Cette methode sert à valider les attributs de l'objet de définition.

            L'argument 'nom' est passé par l'objet parent et peut être utile
            aux objets qui ne possèdent pas un tel attribut.
        """
        raise NotImplementedError("La méthode verif_cata de la classe %s doit être implémentée"
                                  % self.__class__.__name__)

    def __call__(self):
        """
            Cette methode doit retourner un objet dérivé de la classe OBJECT
        """
        raise NotImplementedError("La méthode __call__ de la classe %s doit être implémentée"
                                  % self.__class__.__name__)

    def report(self, nom=None):
        """
           Cette méthode construit pour tous les objets dérivés de ENTITE un
           rapport de validation de la définition portée par cet objet
        """
        self.cr = self.CR()
        self.verif_cata(nom)
        for k, v in list(self.entites.items()):
            try:
                cr = v.report(k)
                cr.debut = "Début " + v.__class__.__name__ + ' : ' + k
                cr.fin = "Fin " + v.__class__.__name__ + ' : ' + k
                self.cr.add(cr)
            except:
                import traceback
                traceback.print_exc()
                self.cr.fatal(
                    _("Impossible d'obtenir le rapport de %s %s"), k, repr(v))
                print("Impossible d'obtenir le rapport de %s %s" % (k, repr(v)))
                print("père =", self)
        return self.cr

    def verif_cata_regles(self):
        """
           Cette méthode vérifie pour tous les objets dérivés de ENTITE que
           les objets REGLES associés ne portent que sur des sous-entités
           existantes
        """
        from code_aster.Cata.Syntax import SIMP, FACT
        for regle in self.regles:
            l = []
            for mc in regle.mcs:
                keyword = self.entites.get(mc)
                if not isinstance(keyword, (SIMP, FACT)):
                    l.append(mc)
            name = regle.__class__.__name__
            if l != []:
                self.cr.fatal(_("Argument(s) non permis : %r pour la "
                                "règle : %s"), l, name)
            err = regle.verif_cata_regles(self.entites)
            if err:
                self.cr.fatal(_("Un mot-clé impliqué dans une règle '%s' ne "
                                "peut pas avoir de valeur par défaut: %s"),
                              name, ', '.join(err))

    def check_definition(self, parent):
        """Verifie la definition d'un objet composite (commande, fact, bloc)."""
        args = self.entites.copy()
        mcs = set()
        for nom, val in list(args.items()):
            if val.label == 'SIMP':
                mcs.add(nom)
            elif val.label == 'FACT':
                val.check_definition(parent)
            else:
                continue
            del args[nom]
        # seuls les blocs peuvent entrer en conflit avec les mcs du plus haut
        # niveau
        for nom, val in list(args.items()):
            if val.label == 'BLOC':
                mcbloc = val.check_definition(parent)
                assert mcs.isdisjoint(mcbloc), "Commande %s : Mot(s)-clef(s) vu(s) plusieurs fois : %s" \
                    % (parent, tuple(mcs.intersection(mcbloc)))
        return mcs

    def check_op(self, valmin=-9999, valmax=9999):
        """Vérifie l'attribut op."""
        if self.op is not None and \
           (type(self.op) is not int or self.op < valmin or self.op > valmax):
            self.cr.fatal(_("L'attribut 'op' doit être un entier "
                            "compris entre %d et %d : %r"), valmin, valmax, self.op)

    def check_proc(self):
        """Vérifie l'attribut proc."""
        if self.proc is not None and not isinstance(self.proc, N_OPS.OPS):
            self.cr.fatal(
                _("L'attribut op doit être une instance d'OPS : %r"), self.proc)

    def check_regles(self):
        """Vérifie l'attribut regles."""
        if type(self.regles) is not tuple:
            self.cr.fatal(_("L'attribut 'regles' doit être un tuple : %r"),
                          self.regles)

    def check_fr(self):
        """Vérifie l'attribut fr."""
        if type(self.fr) not in stringTypes:
            self.cr.fatal(
                _("L'attribut 'fr' doit être une chaine de caractères : %r"),
                self.fr)

    def check_docu(self):
        """Vérifie l'attribut docu."""
        if type(self.docu) not in stringTypes:
            self.cr.fatal(
                _("L'attribut 'docu' doit être une chaine de caractères : %r"),
                self.docu)

    def check_nom(self):
        """Vérifie l'attribut proc."""
        if type(self.nom) is not str:
            self.cr.fatal(
                _("L'attribut 'nom' doit être une chaine de caractères : %r"),
                self.nom)

    def check_reentrant(self):
        """Vérifie l'attribut reentrant."""
        status = self.reentrant[0]
        if status not in ('o', 'n', 'f'):
            self.cr.fatal(
                _("L'attribut 'reentrant' doit valoir 'o','n' ou 'f' : %r"),
                status)
        if status != 'n' and 'reuse' not in list(self.entites.keys()):
            self.cr.fatal(_("L'opérateur est réentrant, il faut ajouter "
                            "le mot-clé 'reuse'."))
        if status != 'n':
            orig = self.reentrant.split(':')
            try:
                assert len(orig) in (2, 3), "un ou deux mots-clés attendus"
                orig.pop(0)
                msg = "Mot-clé inexistant {0!r}"
                for k1 in orig[0].split("|"):
                    key1 = self.get_entite(k1)
                    assert key1 is not None, msg.format(k1)
                    if len(orig) > 1:
                        key2 = key1.get_entite(orig[1])
                        assert key2 is not None, msg.format("/".join([k1, orig[1]]))
            except AssertionError as exc:
                self.cr.fatal(_("'reentrant' doit indiquer quel mot-clé "
                                "fournit le concept réentrant.\nPar exemple: "
                                "'o:MAILLAGE' pour un mot-clé simple ou "
                                "'o:ETAT_INIT:EVOL_NOLI' pour un mot-clé "
                                "facteur. Les mots-clés doivent exister.\n"
                                "Erreur: {0}"
                                .format(exc)))

    def check_statut(self, into=('o', 'f', 'c', 'd')):
        """Vérifie l'attribut statut."""
        if self.statut not in into:
            self.cr.fatal(_("L'attribut 'statut' doit être parmi %s : %r"),
                          into, self.statut)
        if self.nom == 'reuse' and self.statut != 'c':
            self.cr.fatal(_("L'attribut 'statut' doit être 'c' pour reuse."))

    def check_condition(self):
        """Vérifie l'attribut condition."""
        from .N_BLOC import block_utils
        if self.condition is not None:
            if type(self.condition) is not str:
                self.cr.fatal(
                    _("L'attribut 'condition' doit être une chaine de caractères : %r"),
                    self.condition)
            from code_aster.Cata import cata
            try:
                ctxt = {}
                ctxt.update(cata.__dict__)
                ctxt.update(block_utils({}))
                eval(self.condition, ctxt)
            except Exception as exc:
                self.cr.fatal(
                    _("L'attribut 'condition' ne peut être évalué : %r; Raison : %s"),
                    self.condition, str(exc))
        else:
            self.cr.fatal(_("La condition ne doit pas valoir None !"))

    def check_min_max(self):
        """Vérifie les attributs min/max."""
        if type(self.min) != int:
            if self.min != '**':
                self.cr.fatal(
                    _("L'attribut 'min' doit être un entier : %r"), self.min)
        if type(self.max) != int:
            if self.max != '**':
                self.cr.fatal(
                    _("L'attribut 'max' doit être un entier : %r"), self.max)
        if self.max != '**' and self.min > self.max:
            self.cr.fatal(
                _("Nombres d'occurrence min et max invalides : %r %r"),
                self.min, self.max)

    def check_validators(self):
        """Vérifie les validateurs supplémentaires"""
        if self.validators and not self.validators.verif_cata():
            self.cr.fatal(_("Un des validateurs est incorrect. Raison : %s"),
                          self.validators.cata_info)

    def check_homo(self):
        """Vérifie l'attribut homo."""
        if self.homo != 0 and self.homo != 1:
            self.cr.fatal(
                _("L'attribut 'homo' doit valoir 0 ou 1 : %r"), self.homo)

    def check_into(self):
        """Vérifie l'attribut into."""
        if self.into is not None:
            if type(self.into) not in (list, tuple):
                self.cr.fatal(
                    _("L'attribut 'into' doit être un tuple : %r"), self.into)
            if len(self.into) == 0:
                self.cr.fatal(
                    _("L'attribut 'into' doit contenir au moins une valeur"))

    def check_position(self):
        """Vérifie l'attribut position."""
        if self.position is not None:
            # a priori, 'global_jdc' est aussi autorisée mais ça ne me semble
            # pas une bonne idée !
            self.cr.fatal(_("l'attribut 'position' n'est plus autorisé"))


    def check_defaut(self):
        """Vérifie l'attribut defaut."""
        if self.defaut is not None:
            typeProto = TypeProtocol("type", typ=self.type)
            lval = listProto.adapt(self.defaut)
            for val in lval:
                try:
                    typeProto.adapt(val)
                except ValError:
                    self.cr.fatal(
                        _("La valeur de l'attribut 'defaut' n'est pas "
                          "cohérente avec le type %r : %r"), self.type, val)
                if self.into is not None and val not in self.into:
                    self.cr.fatal(_("La valeur par défaut doit être dans les "
                                    "valeurs autorisées par 'into' !"))
            if self.statut == 'o':
                self.cr.fatal(_("Un mot-clé avec valeur par défaut doit être "
                                "facultatif."))

    def check_inout(self):
        """Vérifie l'attribut inout."""
        from code_aster.Cata.DataStructure import UnitType
        if self.inout is None:
            return
        elif self.inout not in ('in', 'out'):
            self.cr.fatal(
                _("L'attribut 'inout' doit valoir 'in' ou 'out' : %r"),
                self.inout)
        elif UnitType() not in self.type or len(self.type) != 1:
            self.cr.fatal(
                _("L'attribut 'typ' doit valoir UnitType() : %r"),
                self.type)

    def check_unit(self, nom):
        """Vérification ayant besoin du nom"""
        from code_aster.Cata.DataStructure import UnitType
        # As UnitType() is not an object, this forbids UNITE* keywords
        # for another kind of 'int'.
        if nom.startswith('UNITE') and UnitType() in self.type:
            if not self.inout:
                self.cr.fatal(
                    _("L'attribut 'inout' est obligatoire pour le type "
                      "UnitType()."))
            if self.defaut == 6 :
                self.cr.fatal(
                    _("La valeur par défaut doit être différente de 6" ))
