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

"""Module rassemblant des fonctions utilitaires de manipulations
de chaines de caractères
"""

import os


# existe aussi dans Noyau.N_types
# mais on ne souhaite pas que Noyau dépende d'Utilitai
def force_list(obj):
    """Retourne `obj` si c'est une liste ou un tuple,
    sinon retourne [obj,] (en tant que list).
    """
    if type(obj) not in (list, tuple):
        obj = [obj, ]
    return list(obj)


def clean_string(chaine):
    """Supprime tous les caractères non imprimables.
    """
    invalid = '?'
    txt = []
    for char in chaine:
        if ord(char) != 0:
            txt.append(char)
        else:
            txt.append(invalid)
    return ''.join(txt)

# existe dans asrun.mystring


def cut_long_lines(txt, maxlen, sep=os.linesep,
                   l_separ=(' ', ',', ';', '.', ':')):
    """Coupe les morceaux de `txt` (isolés avec `sep`) de plus de `maxlen`
    caractères.
    On utilise successivement les séparateurs de `l_separ`.
    """
    l_lines = txt.split(sep)
    newlines = []
    for line in l_lines:
        if len(line) > maxlen:
            l_sep = list(l_separ)
            if len(l_sep) == 0:
                newlines.extend(force_split(line, maxlen))
                continue
            else:
                line = cut_long_lines(line, maxlen, l_sep[0], l_sep[1:])
                line = maximize_lines(line, maxlen, l_sep[0])
            newlines.extend(line)
        else:
            newlines.append(line)
    # au plus haut niveau, on assemble le texte
    if sep == os.linesep:
        newlines = os.linesep.join(newlines)
    return newlines


def maximize_lines(l_fields, maxlen, sep):
    """Construit des lignes dont la longueur est au plus de `maxlen` caractères.
    Les champs sont assemblés avec le séparateur `sep`.
    """
    newlines = []
    if len(l_fields) == 0:
        return newlines
    # ceinture
    assert max([len(f)
               for f in l_fields]) <= maxlen, 'lignes trop longues : %s' % l_fields
    while len(l_fields) > 0:
        cur = []
        while len(l_fields) > 0 and len(sep.join(cur + [l_fields[0], ])) <= maxlen:
            cur.append(l_fields.pop(0))
        # bretelle
        assert len(cur) > 0, l_fields
        newlines.append(sep.join(cur))
    newlines = [l for l in newlines if l != '']
    return newlines


def force_split(txt, maxlen):
    """Force le découpage de la ligne à 'maxlen' caractères.
    """
    l_res = []
    while len(txt) > maxlen:
        l_res.append(txt[:maxlen])
        txt = txt[maxlen:]
    l_res.append(txt)
    return l_res


def copy_text_to(text, files):
    """Imprime le texte dans les fichiers.
    """
    files = force_list(files)
    for f_i in files:
        assert type(f_i) == str
        fobj = open(f_i, 'a')
        # should be closed automatically
        fobj.write(text)
        fobj.write(os.linesep)
        fobj.flush()
