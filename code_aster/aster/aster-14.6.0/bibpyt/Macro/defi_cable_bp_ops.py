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

# person_in_charge: mathieu.courtois@edf.fr

# ===========================================================================
#           CORPS DE LA MACRO "DEFI_CABLE_BP"
#           -------------------------------------
# USAGE :
# Entrée :
#  - MODELE
#  - CABLE
#  - CHAM_MATER
#  - CARA_ELEM
#  - GROUP_MA_BETON
#  - DEFI_CABLE
#  - ADHERENT
#  - TYPE_ANCRAGE
#  - TENSION_INIT
#  - RECUL_ANCRAGE
#  - RELAXATION
#  - CONE
#      RAYON
#      LONGUEUR
#      PRESENT          OUI ou NON deux fois
#  - TITRE
#  - INFO               1 / 2
#
# ===========================================================================


def defi_cable_bp_ops(self, MODELE, CHAM_MATER, CARA_ELEM, GROUP_MA_BETON,
                      DEFI_CABLE, ADHERENT, TYPE_ANCRAGE, TENSION_INIT,
                      RECUL_ANCRAGE, TYPE_RELAX, TITRE, INFO, CONE=None,
                      **args):
    """
       Ecriture de la macro DEFI_CABLE_BP
    """
    from code_aster.Cata.Syntax import _F
    import aster
    from Utilitai.Utmess import UTMESS
    ier = 0

    # On importe les definitions des commandes a utiliser dans la macro
    DEFI_GROUP = self.get_cmd('DEFI_GROUP')
    IMPR_RESU = self.get_cmd('IMPR_RESU')
    from Contrib.defi_cable_op import DEFI_CABLE_OP

    # La macro compte pour 1 dans la numerotation des commandes
    self.set_icmd(1)

    # Le concept sortant (de type char_meca) est nomme CHCABLE dans
    # le contexte de la macro

    self.DeclareOut('__DC', self.sd)

    # ---------------------------------------------------------------------------- #
    #                  Début de la Macro :

    motscles = {}

    keys = list(args.keys())

    # RECUPERATION DES INFOS DONNEES PAR LE MOT-CLE "CONE"

    if CONE:
        dCONE = CONE[0].cree_dict_valeurs(CONE[0].mc_liste)
        for i in list(dCONE.keys()):
            if dCONE[i] is None:
                del dCONE[i]

        RAYON = dCONE['RAYON']
        LONGUEUR = dCONE['LONGUEUR']

        motscles['CONE'] = []
        motscles['CONE'].append(dCONE)

        # RECUPERATION DU MAILLAGE A PARTIR DU MODELE
        __MAIL = aster.getvectjev(
            MODELE.nom.ljust(8) + '.MODELE    .LGRF        ')
        __MAIL = __MAIL[0].strip()
        MAILLAGE = self.get_sd_avant_etape(__MAIL, self)

        # DEFINITION DU NOM DES GROUP_NO
        __NOM = 'AN__'
        __LGNO = MAILLAGE.LIST_GROUP_NO()
        __LGN1 = []
        for i in __LGNO:
            __LGN1.append(i[0][:len(__NOM)])

        __NB = __LGN1.count(__NOM)

# FIN RECUPERATION DES INFOS DONNEES PAR LE MOT-CLE "CONE"

    # RECUPERATION DES INFOS DONNEES PAR LE MOT-CLE "DEFI_CABLE"
    dDEFI_CABLE = []
    for j in DEFI_CABLE:
        dDEFI_CABLE.append(j.cree_dict_valeurs(j.mc_liste))
        for i in list(dDEFI_CABLE[-1].keys()):
            if dDEFI_CABLE[-1][i] is None:
                del dDEFI_CABLE[-1][i]

    # BOUCLE SUR LES FACTEURS DU MOT-CLE "DEFI_CABLE"
    motscles['DEFI_CABLE'] = []

    for i in dDEFI_CABLE:
#   CAS OU ON RENTRE UNE TENSION INITIALE DU CABLE (TYPE_RELAX='ETCC_REPRISE')
        motscle3 = {}
        if ('TENSION_CT' in i) == 1:
            motscle3 = {'TENSION_CT': i['TENSION_CT']}

        # CAS OU L'ON A DEFINI LE MOT-CLE "CONE"
        if CONE:

        # CREATION DU PREMIER TUNNEL

            if dCONE['PRESENT'][0] == 'OUI':
                __NB = __NB + 1
                __NOM1 = __NOM + str(int(__NB))

                motscle2 = {}
                motscle2['CREA_GROUP_NO'] = []

                if ('GROUP_MA' in i) == 1:
                    __CAB = i['GROUP_MA']

                    if type(GROUP_MA_BETON) in [tuple, list]:
                        gma = list(GROUP_MA_BETON)
                    else:
                        gma = [GROUP_MA_BETON]
                    gma.insert(0, __CAB)

                    motscle2 = {
                        'CREA_GROUP_NO': [{'LONGUEUR': LONGUEUR, 'RAYON': RAYON, 'OPTION': 'TUNNEL', 'GROUP_MA': gma, 'GROUP_MA_AXE': __CAB, 'NOM': __NOM1}]}
                if ('MAILLE' in i) == 1:
                    UTMESS('F', 'CABLE0_2')
                if ('GROUP_NO_ANCRAGE' in i) == 1:
                    __PC1 = i['GROUP_NO_ANCRAGE'][0]
                    motscle2['CREA_GROUP_NO'][0]['GROUP_NO_ORIG'] = __PC1
                if ('NOEUD_ANCRAGE' in i) == 1:
                    __PC1 = i['NOEUD_ANCRAGE'][0]
                    motscle2['CREA_GROUP_NO'][0]['NOEUD_ORIG'] = __PC1

                DEFI_GROUP(reuse=MAILLAGE,
                           MAILLAGE=MAILLAGE,
                           INFO=INFO,
                           ALARME='NON',
                           **motscle2
                           )

            # CREATION DU DEUXIEME TUNNEL

            if dCONE['PRESENT'][1] == 'OUI':
                __NB = __NB + 1
                __NOM2 = __NOM + str(int(__NB))

                motscle2 = {}
                motscle2['CREA_GROUP_NO'] = []

                if ('GROUP_MA' in i) == 1:
                    __CAB = i['GROUP_MA']

                    if type(GROUP_MA_BETON) in [tuple, list]:
                        gma = list(GROUP_MA_BETON)
                    else:
                        gma = [GROUP_MA_BETON]
                    gma.insert(0, __CAB)

                    motscle2 = {
                        'CREA_GROUP_NO': [{'LONGUEUR': LONGUEUR, 'RAYON': RAYON, 'OPTION': 'TUNNEL', 'GROUP_MA': gma, 'GROUP_MA_AXE': __CAB, 'NOM': __NOM2}]}
                if ('MAILLE' in i) == 1:
                    UTMESS('F', 'CABLE0_2')
                if ('GROUP_NO_ANCRAGE' in i) == 1:
                    __PC1 = i['GROUP_NO_ANCRAGE'][1]
                    motscle2['CREA_GROUP_NO'][0]['GROUP_NO_ORIG'] = __PC1
                if ('NOEUD_ANCRAGE' in i) == 1:
                    __PC1 = i['NOEUD_ANCRAGE'][1]
                    motscle2['CREA_GROUP_NO'][0]['NOEUD_ORIG'] = __PC1

                DEFI_GROUP(reuse=MAILLAGE,
                           MAILLAGE=MAILLAGE,
                           INFO=INFO,
                           ALARME='NON',
                           **motscle2
                           )

            # CREATION DES NOUVEAUX FACTEURS DU MOT-CLE "DEFI_CABLE" POUR
            # DEFI_CABLE_BP
            if dCONE['PRESENT'][0] == 'OUI' and dCONE['PRESENT'][1] == 'OUI':
                if ('GROUP_MA' in i) == 1 and ('GROUP_NO_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     GROUP_NO_ANCRAGE=i[
                                                     'GROUP_NO_ANCRAGE'],
                                                     GROUP_NO_FUT=(
                                                     __NOM1, __NOM2, ),
                                                     **motscle3), )
                if ('GROUP_MA' in i) == 1 and ('NOEUD_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     NOEUD_ANCRAGE=i[
                                                     'NOEUD_ANCRAGE'],
                                                     GROUP_NO_FUT=(
                                                     __NOM1, __NOM2, ),
                                                     **motscle3), )

            if dCONE['PRESENT'][0] == 'OUI' and dCONE['PRESENT'][1] == 'NON':
                if ('GROUP_MA' in i) == 1 and ('GROUP_NO_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     GROUP_NO_ANCRAGE=i[
                                                     'GROUP_NO_ANCRAGE'],
                                                     GROUP_NO_FUT=(__NOM1, ),
                                                     **motscle3), )
                if ('GROUP_MA' in i) == 1 and ('NOEUD_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     NOEUD_ANCRAGE=i[
                                                     'NOEUD_ANCRAGE'],
                                                     GROUP_NO_FUT=(__NOM1, ),
                                                     **motscle3), )

            if dCONE['PRESENT'][0] == 'NON' and dCONE['PRESENT'][1] == 'OUI':
                if ('GROUP_MA' in i) == 1 and ('GROUP_NO_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     GROUP_NO_ANCRAGE=i[
                                                     'GROUP_NO_ANCRAGE'],
                                                     GROUP_NO_FUT=(__NOM2, ),
                                                     **motscle3), )
                if ('GROUP_MA' in i) == 1 and ('NOEUD_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     NOEUD_ANCRAGE=i[
                                                     'NOEUD_ANCRAGE'],
                                                     GROUP_NO_FUT=(__NOM2, ),
                                                     **motscle3), )

            if dCONE['PRESENT'][0] == 'NON' and dCONE['PRESENT'][1] == 'NON':
                if ('GROUP_MA' in i) == 1 and ('GROUP_NO_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     GROUP_NO_ANCRAGE=i[
                                                     'GROUP_NO_ANCRAGE'],
                                                     **motscle3), )
                if ('GROUP_MA' in i) == 1 and ('NOEUD_ANCRAGE' in i) == 1:
                    motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                     NOEUD_ANCRAGE=i[
                                                     'NOEUD_ANCRAGE'],
                                                     **motscle3), )

        # CAS OU L'ON A PAS DEFINI LE MOT-CLE "CONE"
        else:
            if ('GROUP_MA' in i) == 1 and ('GROUP_NO_ANCRAGE' in i) == 1:
                motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                 GROUP_NO_ANCRAGE=i[
                                                 'GROUP_NO_ANCRAGE'],
                                                 **motscle3), )

            if ('GROUP_MA' in i) == 1 and ('NOEUD_ANCRAGE' in i) == 1:
                motscles['DEFI_CABLE'].append(_F(GROUP_MA=i['GROUP_MA'],
                                                 NOEUD_ANCRAGE=i[
                                                 'NOEUD_ANCRAGE'],
                                                 **motscle3), )

            if ('MAILLE' in i) == 1 and ('GROUP_NO_ANCRAGE' in i) == 1:
                motscles['DEFI_CABLE'].append(_F(MAILLE=i['MAILLE'],
                                                 GROUP_NO_ANCRAGE=i[
                                                 'GROUP_NO_ANCRAGE'],
                                                 **motscle3), )

            if ('MAILLE' in i) == 1 and ('NOEUD_ANCRAGE' in i) == 1:
                motscles['DEFI_CABLE'].append(_F(MAILLE=i['MAILLE'],
                                                 NOEUD_ANCRAGE=i[
                                                 'NOEUD_ANCRAGE'],
                                                 **motscle3), )

# FIN BOUCLE sur i in DEFI_CABLE
    # LANCEMENT DE DEFI_CABLE_BP
#    TRAITEMENT DE LA RELAXATION
    if TYPE_RELAX == 'ETCC_DIRECT':
        motscles['NBH_RELAX'] = args['NBH_RELAX']

    if TYPE_RELAX == 'ETCC_REPRISE':
        motscles['NBH_RELAX'] = args['NBH_RELAX']

    if TYPE_RELAX == 'BPEL':
        motscles['R_J'] = args['R_J']

#  if PERT_ELAS=='OUI':
#    motscles['ESP_CABLE']=args['ESP_CABLE'] ;
#    motscles['EP_BETON']=args['EP_BETON'] ;

#    dRelaxation=RELAXATION[0].cree_dict_valeurs(RELAXATION[0].mc_liste)
#    for i in dRelaxation.keys():
#      if dRelaxation[i] is None : del dRelaxation[i]
#  if TYPE_RELAX!='SANS':
    __DC = DEFI_CABLE_OP(MODELE=MODELE,
                         CHAM_MATER=CHAM_MATER,
                         CARA_ELEM=CARA_ELEM,
                         GROUP_MA_BETON=GROUP_MA_BETON,
                         ADHERENT=ADHERENT,
                         TYPE_ANCRAGE=TYPE_ANCRAGE,
                         TENSION_INIT=TENSION_INIT,
                         RECUL_ANCRAGE=RECUL_ANCRAGE,
                         TYPE_RELAX=TYPE_RELAX,
                         #  RELAXATION=dRelaxation,
                         INFO=INFO,
                         **motscles
                         )

#  else:

#    __DC=DEFI_CABLE_OP(MODELE=MODELE,
#                       CHAM_MATER=CHAM_MATER,
#                       CARA_ELEM=CARA_ELEM,
#                       GROUP_MA_BETON=GROUP_MA_BETON,
#                       TYPE_ANCRAGE=TYPE_ANCRAGE,
#                       TENSION_INIT=TENSION_INIT,
#                       RECUL_ANCRAGE=RECUL_ANCRAGE,
#                       PERT_ELAS=PERT_ELAS,
#                       INFO=INFO,
#                       **motscles
#                       );

    return ier
