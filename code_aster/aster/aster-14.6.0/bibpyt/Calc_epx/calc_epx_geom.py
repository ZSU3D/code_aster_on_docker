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

# person_in_charge: serguei.potapov at edf.fr

"""
Traitement du modèle
"""
from Calc_epx.calc_epx_cata import cata_modelisa, mode_epx_fin
from Calc_epx.calc_epx_struc import BLOC_DONNEES
from Calc_epx.calc_epx_utils import recupere_structure, tolist, get_group_ma
from Calc_epx.calc_epx_utils import extract_from_tuple
from Utilitai.partition import MAIL_PY
import aster
from Utilitai.Utmess import UTMESS
from code_aster.Cata.Syntax import _F
from code_aster.Cata.Commands import DEFI_GROUP


def export_modele(epx, MAILLAGE, MODELE, gmaInterfaces, info_mode_compl):
    """
        Traitement du concept MODELE et traduction pour EPX
    """
    directive = 'GEOM'

    # Recuperer la structure sous le mot_cle facteur AFFE de AFFE_MODELE
    affe_modele = recupere_structure(MODELE, 'AFFE')
    affe_modele = tolist(affe_modele)

    # initialisation du dictionnaire qui contient les group_ma en fonction
    # de la modelisation
    epx_geom = {}

    MApyt = MAIL_PY()
    MApyt.FromAster(MAILLAGE)

    len_str_gr_med_max = 24
    gr_cr_noms_coupes = []
    veri_gr_from_compl = []
    ltyma = aster.getvectjev("&CATA.TM.NOMTM")
    modi_repere = {'COQUE': False}
    etat_init_cont = []
    for affe in affe_modele:
        modelisation = extract_from_tuple(affe['MODELISATION'])
        phenomene = affe['PHENOMENE']
        if phenomene != 'MECANIQUE':
            UTMESS('F', 'PLEXUS_24', valk=phenomene)
        if modelisation not in list(cata_modelisa.keys()):
            UTMESS('F', 'PLEXUS_6', valk=modelisation)
        if 'TOUT' in affe:
            if 'TOUT' not in MApyt.gma:
                DEFI_GROUP(reuse=MAILLAGE, MAILLAGE=MAILLAGE,
                           CREA_GROUP_MA=(_F(NOM='TOUT', TOUT='OUI',),
                           ))
            else:
                UTMESS('A', 'PLEXUS_3')
            group_ma = ['TOUT']
        else:
            group_ma = get_group_ma(affe, mcfact='AFFE_MODELE/AFFE')
        if not cata_modelisa[modelisation]['ETAT_INIT']:
            etat_init_cont.append(modelisation)
        if 'MODI_REPERE' in cata_modelisa[modelisation]:
            type_modi = cata_modelisa[modelisation]['MODI_REPERE']
            modi_repere[type_modi] = True

        li_ty_ma_mode = list(cata_modelisa[modelisation]['MODE_EPX'].keys())

        nb_type_ma = len(li_ty_ma_mode)
        ltyma_maya = MAILLAGE.sdj.TYPMAIL.get()
        # vérification de la présence des différents type de mailles possibles
        # dans le groupe
        for gr in group_ma:
            lgeom = [False] * nb_type_ma
            l_ma_gr = MAILLAGE.sdj.GROUPEMA.get()[gr.ljust(24)]
            for m in l_ma_gr:
                typ_ok = False
                typ_m = ltyma[ltyma_maya[m - 1] - 1].strip()
                for i_typ, typma in enumerate(li_ty_ma_mode):
                    if typ_m == typma:
                        lgeom[i_typ] = True
                        typ_ok = True
                        break
                if not typ_ok:
                    UTMESS('F', 'PLEXUS_23', valk=(typ_m, gr, modelisation))
            if lgeom.count(True) == 0:
                UTMESS('F', 'PLEXUS_25', valk=(gr, modelisation))

            l_gr = len(gr)
            for i_typ, typma in enumerate(li_ty_ma_mode):
                if lgeom[i_typ] and lgeom.count(True) > 1:
                    ll = len(typma)
                    if l_gr <= len_str_gr_med_max - ll:
                        nom_gr = gr + typma
                    else:
                        nom_gr = gr[:len_str_gr_med_max - ll] + typma
                        num = 1
                        # traitement d'un cas vraiment peu probable mais pas
                        # impossible
                        while nom_gr in gr_cr_noms_coupes:
                            suffi = typma + "%s" % num
                            nom_gr = gr[
                                :len_str_gr_med_max - len(suffi)] + suffi
                            num += 1
                            if num == 20:
                                raise Exception(
                                    'Problème de noms de groupes de mailles')
                        gr_cr_noms_coupes.append(nom_gr)

                    if nom_gr.rstrip() not in MApyt.gma:
                        DEFI_GROUP(reuse=MAILLAGE, MAILLAGE=MAILLAGE,
                                   CREA_GROUP_MA=(
                                   _F(NOM=nom_gr, GROUP_MA=gr,
                                      TYPE_MAILLE=typma),
                                   ))
                elif lgeom[i_typ]:
                    nom_gr = gr
                else:
                    continue

                if len(cata_modelisa[modelisation]['MODE_EPX'][typma]) == 1:
                    mode_epx = cata_modelisa[
                        modelisation]['MODE_EPX'][typma][0]
                elif len(cata_modelisa[modelisation]['MODE_EPX'][typma]) == 0:
                    # elements a ne pas inclure dans GEOM
                    # face de 3D par exemple
                    continue
                else:
                    # cas ou la modelisation dépend du CARA_ELEM
                    mode_epx_dispo = cata_modelisa[
                        modelisation]['MODE_EPX'][typma]
                    if not gr in list(info_mode_compl.keys()):
                        UTMESS('F', 'PLEXUS_26', valk=gr)
                    else:
                        veri_gr_from_compl.append(gr)
                    mode_epx = info_mode_compl[gr]
                    if mode_epx not in mode_epx_dispo:
                        raise Exception(
                            "Modélisation epx %s non permise pour la modélidation %s"
                            % (mode_epx, modelisation))

                if mode_epx not in epx_geom:
                    if 'RESU_POIN' in cata_modelisa[modelisation]:
                        resu_poin = cata_modelisa[modelisation]['RESU_POIN']
                    else:
                        resu_poin = True
                    epx_geom[mode_epx] = {
                        'GROUP_MA': [],
                        'RESU_ELEM': cata_modelisa[modelisation]['RESU_ELEM'],
                        'RESU_POIN': resu_poin,
                    }
                epx_geom[mode_epx]['GROUP_MA'].append(nom_gr)

    # verif info_mode_compl
    for gr in info_mode_compl:
        if gr not in veri_gr_from_compl:
            UTMESS('F', 'PLEXUS_34', valk=gr)

    # liste comportant les modelisations definis dans le module GEOMETRIE
    # Ecriture sous format europlexus
    for mode_epx in list(epx_geom.keys()):
        if mode_epx in mode_epx_fin:
            continue
        len_groups = len(epx_geom[mode_epx]['GROUP_MA'])
        if len_groups == 0:
            raise Exception('Erreur de programmation : liste de groupe vide')
        bloc_simple = BLOC_DONNEES(
            mode_epx, cara=epx_geom[mode_epx]['GROUP_MA'])
        epx[directive].add_bloc(bloc_simple)
    for mode_epx in mode_epx_fin:
        if mode_epx in list(epx_geom.keys()):
            len_groups = len(epx_geom[mode_epx]['GROUP_MA'])
            if len_groups == 0:
                raise Exception('Erreur de programmation : liste de groupe vide')
            bloc_simple = BLOC_DONNEES(
                mode_epx, cara=epx_geom[mode_epx]['GROUP_MA'])
            epx[directive].add_bloc(bloc_simple)

    # INTERFACES
    if gmaInterfaces:
        bloc_simple = BLOC_DONNEES('CL3L', cara=gmaInterfaces)
        epx[directive].add_bloc(bloc_simple)

    return epx, epx_geom, modi_repere, etat_init_cont
