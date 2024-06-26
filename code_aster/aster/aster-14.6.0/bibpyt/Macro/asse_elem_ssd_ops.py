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

def asse_elem_ssd_ops(self, RESU_ASSE_SSD, SOUS_STRUC, LIAISON, VERIF, **args):
    """
     Echainement des commandes :
       DEFI_MODELE_GENE + NUME_DDL_GENE + ASSE_MATR_GENE
    """

    from code_aster.Cata.Syntax import _F

    # On importe les definitions des commandes a utiliser dans la macro
    DEFI_MODELE_GENE = self.get_cmd('DEFI_MODELE_GENE')
    NUME_DDL_GENE = self.get_cmd('NUME_DDL_GENE')
    ASSE_MATR_GENE = self.get_cmd('ASSE_MATR_GENE')

    # La macro compte pour 1 dans la numerotation des commandes
    self.set_icmd(1)

    self.DeclareOut('modele', RESU_ASSE_SSD['MODELE'])
    self.DeclareOut('nugene', RESU_ASSE_SSD['NUME_DDL_GENE'])
    if RESU_ASSE_SSD['RIGI_GENE']:
        self.DeclareOut('rigidite', RESU_ASSE_SSD['RIGI_GENE'])
    if RESU_ASSE_SSD['MASS_GENE']:
        self.DeclareOut('masse', RESU_ASSE_SSD['MASS_GENE'])

    modl_gene = {}
    mcfact = []
    for i in range(len(SOUS_STRUC)):
        arg_sstruc = {}
        if SOUS_STRUC[i]['ANGL_NAUT']:
            arg_sstruc['ANGL_NAUT'] = SOUS_STRUC[i]['ANGL_NAUT']
        else:  # on impose un angle nul
            arg_sstruc['ANGL_NAUT'] = (0., 0., 0.,)
        if SOUS_STRUC[i]['TRANS']:
            arg_sstruc['TRANS'] = SOUS_STRUC[i]['TRANS']
        else:  # on impose une translation nulle
            arg_sstruc['TRANS'] = (0., 0., 0.,)
        mcfact.append(_F(NOM=SOUS_STRUC[i]['NOM'],
                         MACR_ELEM_DYNA=SOUS_STRUC[i]['MACR_ELEM_DYNA'],
                         **arg_sstruc))
    modl_gene['SOUS_STRUC'] = mcfact

    mcfact = []
    for i in range(len(LIAISON)):
        arg_liaison = {}
        if LIAISON[i]['GROUP_MA_MAIT_1']:
            arg_liaison['GROUP_MA_MAIT_1'] = LIAISON[i]['GROUP_MA_MAIT_1']
        if LIAISON[i]['MAILLE_MAIT_1']:
            arg_liaison['MAILLE_MAIT_1'] = LIAISON[i]['MAILLE_MAIT_1']
        if LIAISON[i]['GROUP_MA_MAIT_2']:
            arg_liaison['GROUP_MA_MAIT_2'] = LIAISON[i]['GROUP_MA_MAIT_2']
        if LIAISON[i]['MAILLE_MAIT_2']:
            arg_liaison['MAILLE_MAIT_2'] = LIAISON[i]['MAILLE_MAIT_2']
        if LIAISON[i]['OPTION']:
            arg_liaison['OPTION'] = LIAISON[i]['OPTION']
            if arg_liaison['OPTION'] == 'CLASSIQUE' and args['METHODE'] == 'ELIMINE':
                print('ALARME : methode ELIMINE non adaptee a OPTION : ', \
                      arg_liaison['OPTION'])
        mcfact.append(_F(SOUS_STRUC_1=LIAISON[i]['SOUS_STRUC_1'],
                         INTERFACE_1=LIAISON[i]['INTERFACE_1'],
                         SOUS_STRUC_2=LIAISON[i]['SOUS_STRUC_2'],
                         INTERFACE_2=LIAISON[i]['INTERFACE_2'],
                         **arg_liaison))
    modl_gene['LIAISON'] = mcfact

    modele = DEFI_MODELE_GENE(
        SOUS_STRUC=modl_gene['SOUS_STRUC'],
        LIAISON=modl_gene['LIAISON'],
        VERIF=VERIF,
    )

    nugene = NUME_DDL_GENE(MODELE_GENE=modele,
                           METHODE=args['METHODE'],
                           STOCKAGE=args['STOCKAGE'],
                           )

    if RESU_ASSE_SSD['RIGI_GENE']:
        rigidite = ASSE_MATR_GENE(NUME_DDL_GENE=nugene,
                                  OPTION='RIGI_GENE')
    if RESU_ASSE_SSD['MASS_GENE']:
        masse = ASSE_MATR_GENE(NUME_DDL_GENE=nugene,
                               OPTION='MASS_GENE')

    return
