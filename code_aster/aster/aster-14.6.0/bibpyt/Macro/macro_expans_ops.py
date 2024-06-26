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

def macro_expans_ops(self,
                     MODELE_CALCUL,
                     MODELE_MESURE,
                     NUME_DDL,
                     RESU_NX,
                     RESU_EX,
                     RESU_ET,
                     RESU_RD,
                     MODES_NUM=None,
                     MODES_EXP=None,
                     RESOLUTION=None,
                     **args
                     ):
    """!macro MACRO_EXPANS """
    from code_aster.Cata.Syntax import _F, CO
    from code_aster.Cata.DataStructure import mode_meca, dyna_harmo
    from Utilitai.Utmess import UTMESS
    ier = 0

    import aster
    EXTR_MODE = self.get_cmd('EXTR_MODE')
    PROJ_MESU_MODAL = self.get_cmd('PROJ_MESU_MODAL')
    REST_GENE_PHYS = self.get_cmd('REST_GENE_PHYS')
    PROJ_CHAMP = self.get_cmd('PROJ_CHAMP')
    NORM_MODE = self.get_cmd('NORM_MODE')

    RESU_NUM = MODELE_CALCUL['BASE']
    RESU_EXP = MODELE_MESURE['MESURE']
    MOD_CALCUL = MODELE_CALCUL['MODELE']
    MOD_MESURE = MODELE_MESURE['MODELE']
    NOM_CHAM = MODELE_MESURE['NOM_CHAM']

    # La macro compte pour 1 dans la numerotation des commandes
    self.set_icmd(1)

    is_nume_num = is_nume_exp = 0
    if MODELE_CALCUL['NUME_MODE'] or MODELE_CALCUL['NUME_ORDRE']:
        # on cree un resultat RESU_NX par extraction de NUME_ORDREs
        is_nume_num = 1
    else:
        if RESU_NX:
            UTMESS('A', 'CALCESSAI0_6', valk=['MODELE_MESURE', 'RESU_EX'])

    if MODELE_MESURE['NUME_MODE'] or MODELE_MESURE['NUME_ORDRE']:
        # On cree un RESU_EX par extraction de NUME_ORDREs
        is_nume_exp = 1
        if isinstance(RESU_NUM, dyna_harmo):
            # on ne peut pas faire de EXTR_MODE  sur un DYNA_HARMO
            is_nume_exp = 0
            UTMESS('A', 'CALCESSAI0_13')
    else:
        if RESU_EX:
            UTMESS('A', 'CALCESSAI0_6', valk=['MODELE_CALCUL', 'RESU_NX'])

    # Extraction des modes numériques
    # -------------------------------
    if not is_nume_num:
        __resunx = RESU_NUM
    else:
        if RESU_NX:
            self.DeclareOut("__resunx", RESU_NX)
        mfact = {'MODE': RESU_NUM}
        if MODELE_CALCUL['NUME_MODE']:
            mfact.update({'NUME_MODE': MODELE_CALCUL['NUME_MODE']})
        elif MODELE_CALCUL['NUME_ORDRE']:
            mfact.update({'NUME_ORDRE': MODELE_CALCUL['NUME_ORDRE']})

        __resunx = EXTR_MODE(FILTRE_MODE=mfact)

    # Extraction des modes expérimentaux
    # ----------------------------------
    if not is_nume_exp:
        __resuex = RESU_EXP
    else:
        if RESU_EX:
            self.DeclareOut("__resuex", RESU_EX)
        mfact = {'MODE': RESU_EXP}
        if MODELE_MESURE['NUME_MODE']:
            mfact.update({'NUME_MODE': MODELE_MESURE['NUME_MODE']})
        elif MODELE_MESURE['NUME_ORDRE']:
            mfact.update({'NUME_ORDRE': MODELE_MESURE['NUME_ORDRE']})

        __resuex = EXTR_MODE(FILTRE_MODE=mfact)

    # Projection des modes experimentaux - on passe le mot-cle
    # RESOLUTION directement à PROJ_MESU_MODAL
    # --------------------------------------------------------
    # Mot-clé facteur de résolution
    for m in RESOLUTION:
        if m['METHODE'] == 'SVD':
            mfact = {'METHODE': 'SVD', 'EPS': m['EPS']}
            if m['REGUL'] != 'NON':
                mfact.update({'REGUL': m['REGUL']})
                if m['COEF_PONDER']:
                    mfact.update({'COEF_PONDER': m['COEF_PONDER']})
                if m['COEF_PONDER_F']:
                    mfact.update({'COEF_PONDER_F': m['COEF_PONDER_F']})
        elif m['METHODE'] == 'LU':
            mfact = {'METHODE': 'LU'}

    # Paramètres à garder : si on étend des mode_meca, on conserve les
    # freq propres, amortissements réduits, et masses généralisées. Pour
    # les dyna_harmo, on conserve les fréquences uniquement
    if isinstance(RESU_EXP, mode_meca):
        paras = ('FREQ', 'AMOR_REDUIT', 'MASS_GENE',)
    elif isinstance(RESU_EXP, dyna_harmo):
        paras = ('FREQ')
    else:
        paras = None
        #"LE MODELE MEDURE DOIT ETRE UN CONCEPT DE TYPE DYNA_HARMO OU MODE_MECA")
        UTMESS('A', 'CALCESSAI0_1')

    try:
        __PROJ = PROJ_MESU_MODAL(MODELE_CALCUL=_F(BASE=__resunx,
                                                  MODELE=MOD_CALCUL,
                                                  ),
                                 MODELE_MESURE=_F(MESURE=__resuex,
                                                  MODELE=MOD_MESURE,
                                                  NOM_CHAM=NOM_CHAM,
                                                  ),
                                 RESOLUTION=mfact,
                                 NOM_PARA=paras,
                                 )
    except Exception as err:
        raise Exception(err)

    # Phase de reconstruction des donnees mesurees sur le maillage
    # numerique
    # ------------------------------------------------------------
    if RESU_ET:
        self.DeclareOut("__resuet", RESU_ET)
    __resuet = REST_GENE_PHYS(RESU_GENE=__PROJ,
                              TOUT_ORDRE='OUI',
                              NOM_CHAM=NOM_CHAM)

    # Restriction des modes mesures etendus sur le maillage capteur
    # -------------------------------------------------------------
    if RESU_RD:
        self.DeclareOut("__resurd", RESU_RD)

    nume = None
    if NUME_DDL:
        nume = NUME_DDL
    if not nume:
        iret, ibid, tmp = aster.dismoi('NUME_DDL', self.nom, 'RESU_DYNA', 'C')
        if iret == 0:
            tmp = tmp.strip()
            if tmp:
                nume = self.get_concept(tmp)
        else:
            UTMESS('A', 'CALCESSAI0_5')
    __resurd = PROJ_CHAMP(METHODE='COLLOCATION',
                          RESULTAT=__resuet,
                          MODELE_1=MOD_CALCUL,
                          MODELE_2=MOD_MESURE,
                          NOM_CHAM=NOM_CHAM,
                          TOUT_ORDRE='OUI',
                          NUME_DDL=nume,
                          VIS_A_VIS=_F(TOUT_1='OUI',
                                       TOUT_2='OUI',),
                          NOM_PARA=paras,
                          )

    return ier
