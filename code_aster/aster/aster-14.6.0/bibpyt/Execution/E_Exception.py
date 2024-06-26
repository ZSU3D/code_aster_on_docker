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

"""Définition des exceptions utilisées par le module 'aster'.
Elles sont enregistrées avec un numéro qui permet de les lever
depuis le fortran.
"""

import os
from .strfunc import convert


class error(Exception):

    """Exception levée par toutes les erreurs.
    Arguments = (id_message, valk, vali, valr) ou bien une liste de 'error'.
    """

    def __init__(self, arg0, valk=(), vali=(), valr=()):
        """Initialization."""
        Exception.__init__(self)
        self.related = []
        if type(arg0) in (list, tuple):
            for err in arg0[:-1]:
                assert type(err) is error, err
                self.related.append(err)
            err = arg0[-1]
            arg0, valk, vali, valr = err.id_message, err.valk, err.vali, err.valr
        assert type(arg0) in (str, str), arg0
        self.id_message = arg0.strip()
        self.valk = valk or ()
        self.vali = vali or ()
        self.valr = valr or ()

    def __repr__(self):
        """Return the representation of the exception formatted as <EXCEPTION>."""
        return self.format('Z')

    def __str__(self):
        """Return the representation of the exception formatted as <I>."""
        return self.format('I')

    def basic_format(self):
        """Return a minimal representation."""
        repr = []
        for err in self.related:
            repr.append((err.id_message, err.valk, err.vali, err.valr))
        repr.append((self.id_message, self.valk, self.vali, self.valr))
        return str(repr)

    def format(self, code):
        """Return the related message of the exception with formatting
        as `code` says."""
        try:
            from Utilitai.Utmess import message_exception
            txt = []
            for err in self.related:
                txt.append(message_exception(code, err))
            txt.append(message_exception(code, self))
            txt = os.linesep.join(txt)
        except:
            txt = self.basic_format()
        return convert(txt)

    def __reduce__(self):
        """Pickle an error"""
        return (self.__class__, (self.id_message, ))


class FatalError(error):

    """Uniquement définie pour assurer la compatibilité.
    Utiliser plutôt error"""


class NonConvergenceError(error):

    """Levée en cas de non convergence"""


class EchecComportementError(error):

    """En cas d'échec d'intégration du comportement"""


class BandeFrequenceVideError(error):

    """Aucune fréquence trouvée"""


class MatriceSinguliereError(error):

    """Matrice Singulière"""


class TraitementContactError(error):

    """Echec dans le traitement du contact"""


class MatriceContactSinguliereError(error):

    """Matrice de contact singulière"""


class ArretCPUError(error):

    """Arrêt par manque de temps CPU"""


class PilotageError(error):

    """Echec du pilotage"""


class BoucleGeometrieError(error):

    """Echec dans la boucle de point fixe sur la géométrie"""


class BoucleFrottementError(error):

    """Echec dans la boucle de point fixe sur le seuil de frottement"""


class BoucleContactError(error):

    """Echec dans la boucle de point fixe sur le statut de contact"""


class EventError(error):

    """Arrêt par évènement déclenché"""


class ActionError(error):

    """Arrêt par échec de l'action"""


class ResolutionError(error):

    """Échec lors de la résolution du système linéaire"""


class ExceptionsStore(object):

    """Class to store the exceptions of 'aster' module.
    """

    def __init__(self):
        """Intialization."""
        self._dict_exc = {}
        self._default = (None, RuntimeError)

    def register(self, code, name, exception, default=False):
        """Register an exception with its public name under the `code` number
        used in fortran."""
        self._dict_exc[code] = (name, exception)
        if default:
            self._default = (name, exception)

    def add_to_dict_module(self, dictmodule):
        """Add registered exceptions to `dictmodule`."""
        for name, exc in list(self._dict_exc.values()):
            if name:
                dictmodule[name] = exc

    def get_exception(self, code):
        """Return the exception corresponding to `code`."""
        name, exc = self._dict_exc.get(code, self._default)
        return exc

    def get_exception_name(self, code):
        """Return the exception corresponding to `code`."""
        return self._dict_exc.get(code, self._default)


# Singleton object
ST = ExceptionsStore()

# register exceptions
# (the first two numbers are defined in astermodule.c but not used elsewhere)
# ST.register(19, None, EOFError)
ST.register(18, "FatalError", FatalError)  # for backward compatibility only
ST.register(21, "error", error, default=True)
ST.register(22, "NonConvergenceError", NonConvergenceError)
ST.register(23, "EchecComportementError", EchecComportementError)
ST.register(24, "BandeFrequenceVideError", BandeFrequenceVideError)
ST.register(25, "MatriceSinguliereError", MatriceSinguliereError)
ST.register(26, "TraitementContactError", TraitementContactError)
ST.register(27, "MatriceContactSinguliereError", MatriceContactSinguliereError)
ST.register(28, "ArretCPUError", ArretCPUError)
ST.register(29, "PilotageError", PilotageError)
ST.register(30, "BoucleGeometrieError", BoucleGeometrieError)
ST.register(31, "BoucleFrottementError", BoucleFrottementError)
ST.register(32, "BoucleContactError", BoucleContactError)
ST.register(33, "EventError", EventError)
ST.register(34, "ActionError", ActionError)
ST.register(35, "ResolutionError", ResolutionError)


def add_to_dict_module(dictmodule):
    """Wrapper to ExceptionsStore method to simplify call from astermodule."""
    return ST.add_to_dict_module(dictmodule)


def get_exception(code):
    """Wrapper to ExceptionsStore method to simplify call from astermodule."""
    return ST.get_exception(code)
