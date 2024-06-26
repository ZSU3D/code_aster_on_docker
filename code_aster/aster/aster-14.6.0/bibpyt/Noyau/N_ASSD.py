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

"""

from .N_utils import import_object
from .N_info import message, SUPERV


class ASSD(object):

    """
       Classe de base pour definir des types de structures de donnees ASTER
       equivalent d un concept ASTER
    """
    idracine = "SD"

    def __init__(self, etape=None, sd=None, reg='oui'):
        """
          reg est un paramètre qui vaut oui ou non :
            - si oui (défaut) : on enregistre la SD auprès du JDC
            - si non : on ne l'enregistre pas
        """
        self.etape = etape
        self.sd = sd
        self.nom = None
        if etape:
            self.parent = etape.parent
        else:
            self.parent = CONTEXT.get_current_step()
        if self.parent:
            self.jdc = self.parent.get_jdc_root()
        else:
            self.jdc = None

        if not self.parent:
            self.id = None
        elif reg == 'oui':
            self.id = self.parent.reg_sd(self)
        else:
            self.id = self.parent.o_register(self)
        # permet de savoir si le concept a été calculé (1) ou non (0)
        self.executed = 0
        if self.parent:
            self.order = self.parent.icmd
        else:
            self.order = 0
        # attributs pour le Catalogue de Structure de Données Jeveux
        # "self.cata_sdj" est un attribut de classe
        self.ptr_class_sdj = None
        self.ptr_sdj = None
        # construit en tant que CO('...')
        # 0 : assd normal, 1 : type CO, 2 : type CO typé
        # une fois exécuté, doit se comporter comme un assd normal
        self._as_co = 0

    def _get_sdj(self):
        """Retourne le catalogue de SD associé au concept."""
        if self.ptr_sdj is None:
            cata_sdj = getattr(self, 'cata_sdj', None)
            assert cata_sdj, "The attribute 'cata_sdj' must be defined in the class %s" \
                % self.__class__.__name__
            assert self.nom, "The attribute 'nom' has not been filled!"
            if self.ptr_class_sdj is None:
                self.ptr_class_sdj = import_object(cata_sdj)
            self.ptr_sdj = self.ptr_class_sdj(nomj=self.nom)
        return self.ptr_sdj

    def _del_sdj(self):
        """Suppression du catalogue de SD."""
        if self.ptr_sdj is not None:
            self.ptr_sdj.supprime(True)
            self.ptr_sdj = None
        self.ptr_class_sdj = None

    sdj = property(_get_sdj, None, _del_sdj)

    def __getitem__(self, key):
        from .strfunc import convert
        text_error = convert(_("ASSD.__getitem__ est déprécié car la référence à "
                               "l'objet ETAPE parent sera supprimée."))
        # raise NotImplementedError(text_error)
        from warnings import warn
        warn(text_error, DeprecationWarning, stacklevel=2)
        return self.etape[key]

    def set_name(self, nom):
        """Positionne le nom de self (et appelle sd_init)
        """
        self.nom = nom

    def is_typco(self):
        """Permet de savoir si l'ASSD est issu d'un type CO.
        Retourne:
           0 : ce n'est pas un type CO ou bien déjà exécuté (et donc doit être
               traité comme un ASSD normal)
           1 : c'est un type CO, non encore typé
           2 : c'est un type CO retypé
        """
        if self.executed:
            return 0
        return self._as_co

    def change_type(self, new_type):
        """Type connu a posteriori (type CO)."""
        self.__class__ = new_type
        assert self._as_co != 0, 'it should only be called on CO object.'
        self._as_co = 2

    def get_name(self):
        """
            Retourne le nom de self, éventuellement en le demandant au JDC
        """
        if not self.nom:
            try:
                self.nom = self.parent.get_name(self) or self.id
            except:
                self.nom = ""
        if self.nom.find('sansnom') != -1 or self.nom == '':
            self.nom = self.id
        return self.nom

    def supprime(self, force=False):
        """
        Cassage des boucles de références pour destruction du JDC.
        'force' est utilisée pour faire des suppressions complémentaires
        (voir les formules dans N_FONCTION).
        """
        self.supprime_sd()
        self.etape = None
        self.sd = None
        self.jdc = None
        self.parent = None

    def supprime_sd(self):
        """Supprime la partie du catalogue de SD."""
        # 'del self.sdj' appellerait la méthode '_get_sdj()'...
        self._del_sdj()

    def __del__(self):
        # message.debug(SUPERV, "__del__ ASSD %s <%s>", getattr(self, 'nom',
        # 'unknown'), self)
        pass

    def accept(self, visitor):
        """
           Cette methode permet de parcourir l'arborescence des objets
           en utilisant le pattern VISITEUR
        """
        visitor.visitASSD(self)

    def __getstate__(self):
        """
            Cette methode permet de pickler les objets ASSD
            Ceci est possible car on coupe les liens avec les objets
            parent, etape et jdc qui conduiraient à pickler de nombreux
            objets inutiles ou non picklables.
            En sortie, l'objet n'est plus tout à fait le même !
        """
        d = self.__dict__.copy()
        for key in ('parent', 'etape', 'jdc'):
            if key in d:
                del d[key]
        for key in list(d.keys()):
            if key in ('_as_co', ):
                continue
            if key[0] == '_':
                del d[key]
        return d

    def accessible(self):
        """Dit si on peut acceder aux "valeurs" (jeveux) de l'ASSD.
        """
        if CONTEXT.debug:
            print('| accessible ?', self.nom)
        is_accessible = CONTEXT.get_current_step().sd_accessible()
        if CONTEXT.debug:
            print('  `- is_accessible =', repr(is_accessible))
        return is_accessible

    def filter_context(self, context):
        """Filtre le contexte fourni pour retirer (en gros) ce qui vient du catalogue."""
        from .N_ENTITE import ENTITE
        import types
        ctxt = {}
        for key, value in list(context.items()):
            if type(value) is type:
                continue
            if type(value) is types.ModuleType and value.__name__.startswith('Accas'):
                continue
            if issubclass(type(value), type):
                continue
            if isinstance(value, ENTITE):
                continue
            ctxt[key] = value
        return ctxt

    def par_lot(self):
        """Conserver uniquement pour la compatibilite avec le catalogue v9 dans eficas."""
        # XXX eficas
        if not hasattr(self, 'jdc') or self.jdc is None:
            val = None
        else:
            val = self.jdc.par_lot
        return val == 'OUI'

    def rebuild_sd(self):
        """Conserver uniquement pour la compatibilite avec le catalogue v10 dans eficas."""


class assd(ASSD):

    def __convert__(cls, valeur):
            # On accepte les vraies ASSD et les objets 'entier' et 'reel'
            # qui font tout pour se faire passer pour de vrais entiers/réels.
        if isinstance(valeur, ASSD) or type(valeur) in (int, float):
            return valeur
        raise ValueError(_("On attend un objet concept."))
    __convert__ = classmethod(__convert__)


class not_checked(ASSD):

    def __convert__(cls, valeur):
        return valeur
    __convert__ = classmethod(__convert__)
