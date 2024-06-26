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

"""Module d'utilitaires pour la gestion des calculs Miss3D.

Les objets/fonctions définis sont :
    dict_format     : formats d'impression des réels et des entiers
    MISS_PARAMETERS : rassemble les paramètres pour un calcul
    lire_nb_valeurs : lit des valeurs dans un fichier texte
    en_ligne        : formatte des valeurs en colonnes
"""

import os.path as osp
import re
import pprint
from math import log
import shutil
import tempfile

import numpy as NP

try:
    import aster
    from Utilitai.UniteAster import UniteAster
except ImportError:
    # to make pure python unittests
    pass

from Noyau.N_types import force_list
from Utilitai.Utmess import UTMESS, ASSERT
from Utilitai.transpose import transpose
from Utilitai.utils import get_shared_tmpdir, _printDBG

dict_format = {
    'R': "15.6E",
    'sR': "%15.6E",
    'I': "6d",
    'sI': "%6d",
    'F': "6.6f",
}


def get_max_dabsc(fonction):
    """Retourne le maximum et le pas des abscisses de la fonction."""
    tfunc = fonction.convert()
    dx = tfunc.vale_x[1:] - tfunc.vale_x[:-1]
    dxmax = max(dx)
    dxmin = min(dx)
    if abs((dxmax - dxmin) / dxmax) > 1.e-3:
        raise aster.error('MISS0_9', valk=fonction.nom)
    return max(tfunc.vale_x), dxmax


class MISS_PARAMETER(object):

    """Stocke les paramètres nécessaires au calcul à partir des mots-clés.
    """

    def __init__(self, initial_dir, **kwargs):
        """Enregistrement des valeurs des mots-clés.
        - Comme il n'y a qu'une occurrence de PARAMETRE, cela permet de
          remonter tous les mots-clés dans un seul dictionnaire.
        - On peut ajouter des vérifications infaisables dans le capy.
        - On ajoute des paramètres internes.
        """
        # defauts hors du mot-clé PARAMETRE
        self._defaults = {
            '_INIDIR': initial_dir,
            '_WRKDIR': get_shared_tmpdir('tmp_miss3d', initial_dir),
            'NBM_TOT': None,
            'NBM_DYN': None,
            'NBM_STA': None,
            '_exec_Miss': False,
            'EXCIT_HARMO': None,
            'INST_FIN': None,
            'PAS_INST': None,
            'FICHIER_SOL_INCI': 'NON',
            'TOUT_CHAM': 'NON',
            # tâches élémentaires à la demande
            '_calc_impe': False,
            '_calc_forc': False,
            '_hasPC': False,
            '_nbPC': 0,
            '_nbfreq': 0,
            '_auto_first_LT': None,
            '_hasSL': False,
        }
        self._keywords = {}
        # une seule occurence du mcfact
        mcfact = kwargs.get('PARAMETRE')
        if mcfact is not None:
            mcfact = mcfact[0]
            self._keywords.update(mcfact.cree_dict_valeurs(mcfact.mc_liste))
        # autres mots-clés
        others = list(kwargs.keys())
        others.remove('PARAMETRE')
        for key in others + list(self._defaults.keys()):
            val = kwargs.get(key)
            if val is None:
                val = self._defaults.get(key)
            self._keywords[key] = val
        if self['REPERTOIRE']:
            self._keywords['_WRKDIR'] = self['REPERTOIRE']
        self.UL = UniteAster()
        self.check()

    def __del__(self):
        """A la destruction."""
        self.UL.EtatInit()

    def check(self):
        """Vérification des règles impossible à écrire dans le .capy"""
        # tâches à la demande
        if self['TYPE_RESU'] in ('HARM_GENE', 'TRAN_GENE', 'TABLE', 'CHARGE'):
            self.set('_calc_impe', True)
            self.set('_calc_forc', True)
        elif self['TYPE_RESU'] in ('FICHIER', 'TABLE_CONTROL'):
            if self.get('UNITE_RESU_IMPE') is not None:
                self.set('_calc_impe', True)
            if self.get('UNITE_RESU_FORC') is not None:
                self.set('_calc_forc', True)
        else:
            if self['EXCIT_SOL'] is not None:
                self.set('_calc_forc', True)
        self.set('_hasPC', self.get('GROUP_MA_CONTROL') is not None)
        self.set('_hasSL', self.get('GROUP_MA_SOL_SOL') is not None)
        # unités logiques
        if self.get('UNITE_RESU_IMPE') is None:
            self.set('_exec_Miss', True)
            self['UNITE_RESU_IMPE'] = self.UL.Libre(action='ASSOCIER',
                 ascii=self._keywords['TYPE'] == 'ASCII', new=True)
        elif self['TYPE_RESU'] in ('TABLE_CONTROL', ):
            self.set('_exec_Miss', True)

        if self.get('UNITE_RESU_FORC') is None:
            self.set('_exec_Miss', True)
            self['UNITE_RESU_FORC'] = self.UL.Libre(action='ASSOCIER', new=True)
        elif self['TYPE_RESU'] in ('TABLE_CONTROL', ):
            self.set('_exec_Miss', True)

        # fréquences
        if self['TYPE_RESU'] not in ('CHARGE', ):
            if (self['LIST_FREQ'] is not None and
                    self['TYPE_RESU'] not in ('FICHIER', 'HARM_GENE', 'TABLE_CONTROL')):
                raise aster.error('MISS0_17')

            # récupération des infos sur les modes
            if self['BASE_MODALE']:
                basemo = self['BASE_MODALE'].nom
            elif self['MACR_ELEM_DYNA']:
                basemo = self['MACR_ELEM_DYNA'].sdj.MAEL_REFE.get()[0]
            else:
                ASSERT(False)

            res = aster.dismoi('NB_MODES_TOT', basemo, 'RESULTAT', 'C')
            ASSERT(res[0] == 0)
            self['NBM_TOT'] = res[1]
            res = aster.dismoi('NB_MODES_STA', basemo, 'RESULTAT', 'C')
            ASSERT(res[0] == 0)
            self['NBM_STA'] = res[1]
            res = aster.dismoi('NB_MODES_DYN', basemo, 'RESULTAT', 'C')
            ASSERT(res[0] == 0)
            self['NBM_DYN'] = res[1]

            # si base modale, vérifier/compléter les amortissements réduits
            if self['BASE_MODALE']:
                if self['AMOR_REDUIT']:
                    self.set('AMOR_REDUIT', force_list(self['AMOR_REDUIT']))
                    nval = len(self['AMOR_REDUIT'])
                    if nval < self['NBM_DYN']:
                        # complète avec le dernier
                        nadd = self['NBM_DYN'] - nval
                        self._keywords['AMOR_REDUIT'].extend(
                            [self['AMOR_REDUIT'][-1], ] * nadd)
                        nval = self['NBM_DYN']
                    if nval < self['NBM_DYN'] + self['NBM_STA']:
                        # on ajoute 0.
                        self._keywords['AMOR_REDUIT'].append(0.)
            # la règle ENSEMBLE garantit que les 3 GROUP_MA_xxx sont tous absents
            # ou tous présents
            if self['ISSF'] != 'NON':
                if self['GROUP_MA_FLU_STR'] is None:
                    UTMESS('F', 'MISS0_22')
                if self['MATER_FLUIDE'] is None:
                    UTMESS('F', 'MISS0_23')

    def __iter__(self):
        """Itérateur simple sur le dict des mots-clés"""
        return iter(self._keywords)

    def __getitem__(self, key):
        return self._keywords[key]

    def __setitem__(self, key, value):
        ASSERT(self.get(key) is None)
        self.set(key, value)

    def set(self, key, value):
        self._keywords[key] = value

    def get(self, key):
        return self._keywords.get(key)

    def __repr__(self):
        return pprint.pformat(self._keywords)


def lire_nb_valeurs(file_object, nb, extend_to, conversion,
                    nb_bloc=1, nb_ignore=0, max_per_line=-1,
                    regexp_label=None):
    """Lit nb valeurs dans file_object et les ajoute à extend_to
    après les avoir converties en utilisant la fonction conversion.
    Ignore nb_ignore lignes pour chacun des nb_bloc lus et lit au
    maximum max_per_line valeurs par ligne.
    Retourne le nombre de lignes lues."""
    if max_per_line < 0:
        max_per_line = nb
    ln = 0
    _printDBG("LIRE_NB_VALEURS nb=", nb,
              ", nb_bloc=", nb_bloc, ", nb_ignore=", nb_ignore)
    for i in range(nb_bloc):
        val = []
        j = 0
        label = []
        while j < nb_ignore:
            ln += 1
            line = file_object.readline()
            if line.strip() == '':
                continue
            j += 1
            label.append(line)
        if nb_ignore:
            _printDBG("IGNORE", label)
            slabel = ''.join(label)
            if regexp_label:
                mat = re.search(regexp_label, slabel, re.M)
                if mat is None:
                    _printDBG("LABEL", regexp_label, "non trouve, recule de",
                              nb_ignore, "lignes.", i, "bloc(s) lu(s).")
                    curpos = file_object.tell()
                    file_object.seek(curpos - len(slabel))
                    return 0
        while len(val) < nb:
            ln += 1
            line = file_object.readline()
            if line.strip() == '':
                continue
            add = [conversion(v) for v in line.split()[:max_per_line]]
            val.extend(add)
        ASSERT(len(val) == nb, "%d valeurs attendues, %d valeurs lues" %
               (nb, len(val)))
        extend_to.extend(val)
        _printDBG("BLOC", i, ",", nb, "valeurs lues, debut :", repr(val[:3]))
    return ln


def en_ligne(valeurs, format, cols, separateur=" ", format_ligne="%(valeurs)s"):
    """Formatte valeurs en cols colonnes en utilisant le format.
    """
    res = []
    ind = -1
    while len(valeurs) > 0:
        lv = []
        for i in range(cols):
            if len(valeurs) == 0:
                break
            lv.append(format % valeurs.pop(0))
        ind += 1
        line = format_ligne % {
            "valeurs": separateur.join(lv),
            "index": ind,
            "index_1": ind + 1,
        }
        res.append(line)
    return res


def convert_double(fich1, fich2):
    """Convertit les 1.D+09 en 1.E+09"""
    with open(fich1, "r") as f:
        txt = f.read()
    # see python doc (module re)
    expr = re.compile(r"([\-\+]?\d+(\.\d*)?|\.\d+)([eEdD])([\-\+]?\d+)?")
    new = expr.sub("\\1E\\4", txt)
    with open(fich2, "w") as f:
        f.write(new)


def double(string):
    """Convertit la chaine en réelle (accepte le D comme exposant)"""
    string = re.sub(r'([0-9]+)([\-\+][0-9])', '\\1e\\2', string)
    return float(string.replace("D", "e"))


def get_puis2(nval):
    """Retourne N, la plus grande puissance de 2 telle que 2**N <= nval"""
    return int(log(nval, 2.))


def copie_fichier(src, dst):
    """Copie d'un fichier.
    """
    if src and dst:
        try:
            shutil.copyfile(src, dst)
        except:
            raise aster.error('MISS0_6', valk=(src, dst))

def l_coor_sort(l_coor):
    """Tri des coordonnees"""
    l_coor_xyz0 = []
    l_coor_xyz = []
    tole = 1.E-5
    for i in range(3):
        l_coor_xyz0=[l_coor[x] for x in range(len(l_coor)) if ((x+3-i)%3 == 0) ]
        l_coor_xyz1=[l_coor_xyz0[0]]
        if len(l_coor_xyz0) > 1:
            for coor in l_coor_xyz0[1:]:
                verif_tole = True
                for coor2 in l_coor_xyz1:
                    if abs(coor-coor2) < tole:
                        verif_tole = verif_tole and False
                if  verif_tole:
                    l_coor_xyz1.append(coor)
        l_coor_xyz.append(l_coor_xyz1)

    return l_coor_xyz[0], l_coor_xyz[1],l_coor_xyz[2]

def calc_param_auto(l_coor_x,l_coor_y,l_coor_z,surf,coef_offset):
    """Calcul des parametres RFIC, DREF, OFFSET_NB, OFFSET_MAX"""
    dx = abs(max(l_coor_x) - min(l_coor_x))
    dy = abs(max(l_coor_y) - min(l_coor_y))
    long = (dx*dx+dy*dy)**.5
    if surf == "OUI":
        dref = round(long / 6.,1)
        rfic = 0.
    else:
        dz = abs(max(l_coor_z) - min(l_coor_z))
        if len(l_coor_z) > 1:
            dref = round(dz / (len(l_coor_z)-1),1)
            rfic = dref
        else:
            UTMESS('F', 'MISS0_42')
    if round(long,0) < long:
        offset_max = int(round(long,0)+1.)
    else:
        offset_max = int(round(long,0))
    taille_elem = round(0.5*(dx/(len(l_coor_x)-1)+dy/(len(l_coor_y)-1)),2)
    offset_nb = int(round(offset_max*coef_offset/taille_elem,0))
    return dref, rfic, offset_max, offset_nb

def verif_sol_homogene(tab):
    """Verification si le sol est homogene"""
    sol_homogene = True
    for ic, row in enumerate(tab):
        if ic == 0:
            young = row['E']
            nu = row['NU']
            rho = row['RHO']
            hyst = row['AMOR_HYST']
        else:
            sol_homogene = sol_homogene and (row['E'] == young) and (row['NU'] == nu) and (row['RHO'] == rho) and (row['AMOR_HYST'] == hyst)
    vs = (young/(2.*(1.+nu)*rho))**.5
    return sol_homogene, vs
