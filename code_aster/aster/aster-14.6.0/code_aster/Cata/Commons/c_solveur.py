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

# person_in_charge: olivier.boiteau at edf.fr

from code_aster.Cata.Syntax import *
from code_aster.Cata.DataStructure import *


def C_SOLVEUR(COMMAND, BASE=None):  # COMMUN#

# --------------------------------------------------------------------
#
# VERIFICATIONS
#
# --------------------------------------------------------------------
    if BASE is not None:
        assert COMMAND == 'DYNA_LINE_HARM'
        assert BASE in ('GENE', 'PHYS')

# --------------------------------------------------------------------
#
# CLASSIFICATION EN 3 CATEGORIES :
#  - solveurs directs uniquement
#  - solveurs pour le lineaire
#  - solveurs pour le non-lineaire
#
# GESTION DES EXCEPTIONS
#
# --------------------------------------------------------------------

    _type = None

#  Classification ('SD'/'LIN'/'NL')
    if COMMAND in ('CREA_ELEM_SSD',
                   'CALC_CORR_SSD',
                   'DEFI_BASE_MODALE',
                   'DYNA_LINE_HARM',
                   'DYNA_TRAN_MODAL',
                   'INFO_MODE',
                   'MODE_ITER_SIMULT',
                   'MODE_ITER_INV',
                   'MODE_ITER_INV_SM',
                   'CALC_ERC_DYN',
                   ):
        _type = 'SD'
    elif COMMAND in ('CALC_ERREUR',
                     'CALC_FORC_AJOU',
                     'CALC_MATR_AJOU',
                     'MACRO_MATR_AJOU',
                     'MECA_STATIQUE',
                     'MODE_STATIQUE',
                     'THER_LINEAIRE',
                     'THER_NON_LINE_MO',
                     ):
        _type = 'LIN'
    elif COMMAND in ('CALC_IFS_DNL',
                     'CALC_PRECONT',
                     'DYNA_LINE_TRAN',
                     'DYNA_NON_LINE',
                     'MACR_ASCOUF_CALC',
                     'MACR_ASPIC_CALC',
                     'MACRO_BASCULE_SCHEMA',
                     'STAT_NON_LINE',
                     'THER_NON_LINE',
                     'MODE_NON_LINE',
                     ):
        _type = 'NL'
    else:
        assert False

# --------------------------------------------------------------------

    _dist = False

#  MATR_DISTRIBUEE ne fonctionnent que dans MECA_STATIQUE et MECA_NON_LINE
    if COMMAND in ('CALC_IFS_DNL',
                   'CALC_PRECONT',
                   'DYNA_NON_LINE',
                   'MACR_ASCOUF_CALC',
                   'MACR_ASPIC_CALC',
                   'MACRO_BASCULE_SCHEMA',
                   'MECA_STATIQUE',
                   'STAT_NON_LINE',
                   'THER_NON_LINE',
                   'THER_LINEAIRE',
                   ):
        _dist = True

# --------------------------------------------------------------------

    _gene = False
    _ldlt = False

# Avec des matrices generalisees, MULT_FRONT n'est pas permis, LDLT est
# donc par defaut
    if BASE == 'GENE':
        _gene = True
        _ldlt = True

# LDLT est le solveur par defaut dans DYNA_TRAN_MODAL (systemes lineaires
# petits)
    if COMMAND == 'DYNA_TRAN_MODAL':
        _ldlt = True

# --------------------------------------------------------------------

    _singu  = True
    _resol  = True
    _cmodal = False

#  Avec les solveurs modaux STOP_SINGULIER n'existe pas
    if COMMAND in ('INFO_MODE', 'MODE_ITER_INV', 'MODE_ITER_SIMULT','MODE_ITER_INV_SM',):
        _cmodal = True
        _singu = False

#     Dans INFO_MODE on ne fait que factoriser
        if COMMAND == 'INFO_MODE':
            _resol = False

# --------------------------------------------------------------------

    _singu_non = False

#  Dans DEFI_BASE_MODALE, NON est le defaut de STOP_SINGULIER
    if COMMAND == 'DEFI_BASE_MODALE':
        _singu_non = True

# --------------------------------------------------------------------
#
# INITIALISATIONS
#
# --------------------------------------------------------------------

#  Mot-cles simples
    _MotCleSimples = {}

#  Solveurs
    _BlocMF = {}
    _BlocLD = {}
    _BlocMU = {}
    _BlocGC = {}
    _BlocPE = {}

#  Preconditionneurs
    _BlocGC_INC = {}
    _BlocPE_INC = {}
    _BlocXX_SP = {}
    _BlocPE_ML = {}
    _BlocPE_BOOMER = {}
    _BlocPE_GAMG = {}
    _BlocPE_LAGAUG = {}
    _BlocXX_Autres = {}

# --------------------------------------------------------------------
#
# MOT-CLES SIMPLES : METHODE
#
# --------------------------------------------------------------------

#  METHODE
# CAS GENERAL
    if (_ldlt):
        _defaut = "LDLT"
    else:
        _defaut = "MUMPS"

    if _type == 'SD':
        _into = ("MULT_FRONT", "LDLT", "MUMPS", )
        if _gene:
            _into = ("LDLT", "MUMPS", )
    else:
        _into = ("MULT_FRONT", "LDLT", "MUMPS", "GCPC", "PETSC", )

#CAS PARTICULIERS
    if COMMAND in ['MODE_NON_LINE']:
        _defaut = "MUMPS"
        _into = ("MUMPS", )
    if COMMAND in ['CALC_ERC_DYN']:
        _defaut = "MUMPS"
        _into = ("MUMPS", "LDLT")
    if COMMAND in ['MODE_ITER_INV_SM']:
        _defaut = "MULT_FRONT"
        _into = ("MULT_FRONT", "LDLT",)
    _MotCleSimples['METHODE'] = SIMP(
        statut='f', typ='TXM', defaut=_defaut, into=_into, )

# --------------------------------------------------------------------
#
# MULT_FRONT/LDLT/MUMPS (RENUM/NPREC/STOP_SINGULIER)
#
# --------------------------------------------------------------------

#  RENUM
    _BlocMF['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="METIS", into=("MD", "MDA", "METIS", ), )

    _BlocLD['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="RCMK", into=("RCMK",), )

    _BlocMU['RENUM'] = SIMP(statut='f', typ='TXM', defaut="AUTO", into=(
        "AMD", "AMF", "PORD", "METIS", "QAMD", "SCOTCH", "AUTO", "PARMETIS", "PTSCOTCH"), )

# --------------------------------------------------------------------
#  NPREC
    _BlocMF['NPREC'] = SIMP(statut='f', typ='I', defaut=8, )
    _BlocLD['NPREC'] = SIMP(statut='f', typ='I', defaut=8, )
    _BlocMU['NPREC'] = SIMP(statut='f', typ='I', defaut=8, )

# --------------------------------------------------------------------
#  ELIM_LAGR

    if not _cmodal:
        _BlocPE['ELIM_LAGR'] = SIMP(
            statut='f', typ='TXM', defaut="NON", into=("OUI", "NON"), )
        _BlocMF['ELIM_LAGR'] = SIMP(
            statut='f', typ='TXM', defaut="NON", into=("OUI", "NON"), )
        _BlocLD['ELIM_LAGR'] = SIMP(
            statut='f', typ='TXM', defaut="NON", into=("OUI", "NON"), )
        _BlocGC['ELIM_LAGR'] = SIMP(
            statut='f', typ='TXM', defaut="NON", into=("OUI", "NON"), )
        _BlocMU['ELIM_LAGR'] = SIMP(
            statut='f', typ='TXM', defaut="LAGR2", into=("OUI", "NON", "LAGR2"), )
    else:
        _BlocMU['ELIM_LAGR'] = SIMP(
            statut='f', typ='TXM', defaut="LAGR2", into=("NON", "LAGR2"), )


# --------------------------------------------------------------------
#  STOP_SINGULIER
    _into = ("OUI", "NON", )
    _defaut = "OUI"

    if _singu_non:
        _defaut = "NON"

    if _singu:
        _BlocMF['STOP_SINGULIER'] = SIMP(
            statut='f', typ='TXM', defaut=_defaut, into=_into, )
        _BlocLD['STOP_SINGULIER'] = SIMP(
            statut='f', typ='TXM', defaut=_defaut, into=_into, )
        _BlocMU['STOP_SINGULIER'] = SIMP(
            statut='f', typ='TXM', defaut=_defaut, into=_into, )

# --------------------------------------------------------------------
#
# MUMPS (MOT-CLES RESTANT)
#
# --------------------------------------------------------------------

    _BlocMU['TYPE_RESOL'] = SIMP(
        statut='f', typ='TXM', defaut="AUTO", into=("NONSYM", "SYMGEN", "SYMDEF", "AUTO", ), )


# --------------------------------------------------------------------

    _BlocMU['ACCELERATION'] = SIMP(
        statut='f', typ='TXM', defaut='AUTO', into=('AUTO', 'FR', 'FR+', 'LR', 'LR+'))
    _BlocMU['LOW_RANK_SEUIL'] = SIMP(statut='f', typ='R', defaut=0.0, )

# --------------------------------------------------------------------

    _BlocMU['PRETRAITEMENTS'] = SIMP(
        statut='f', typ='TXM', defaut="AUTO", into=("SANS", "AUTO", ), )

# --------------------------------------------------------------------

    if _resol:
        _BlocMU['POSTTRAITEMENTS'] = SIMP(
            statut='f', typ='TXM', defaut="AUTO",
            into=("SANS", "AUTO", "FORCE", "MINI"), )

# --------------------------------------------------------------------

    _BlocMU['PCENT_PIVOT'] = SIMP(
        statut='f', typ='I', defaut=20, val_min=1, )

# --------------------------------------------------------------------

    if _resol:
        if _type == 'LIN':
            _BlocMU['RESI_RELA'] = SIMP(statut='f', typ='R', defaut=1.0E-6, )
        else:
            _BlocMU['RESI_RELA'] = SIMP(statut='f', typ='R', defaut=-1.0, )

# --------------------------------------------------------------------

    _BlocMU['GESTION_MEMOIRE'] = SIMP(
        statut='f', typ='TXM', defaut="AUTO", into=("IN_CORE", "OUT_OF_CORE", "AUTO", "EVAL"), )

# --------------------------------------------------------------------

    if _type == 'NL':
        _BlocMU['FILTRAGE_MATRICE'] = SIMP(statut='f', typ='R', defaut=-1.0, )
        _BlocMU['MIXER_PRECISION'] = SIMP(
            statut='f', typ='TXM', defaut="NON", into=("OUI", "NON", ), )

# --------------------------------------------------------------------

    if _dist:
        _BlocMU['MATR_DISTRIBUEE'] = SIMP(
            statut='f', typ='TXM', defaut="NON", into=("OUI", "NON", ), )
        _BlocPE['MATR_DISTRIBUEE'] = SIMP(
            statut='f', typ='TXM', defaut="NON", into=("OUI", "NON", ), )

# --------------------------------------------------------------------
#
# GCPC/PETSC
#
# --------------------------------------------------------------------

    _BlocPE['ALGORITHME'] = SIMP(statut='f', typ='TXM', defaut="FGMRES", into=(
        "CG", "CR", "GMRES", "GCR", "FGMRES", "GMRES_LMP"), )

# --------------------------------------------------------------------

    _BlocGC['PRE_COND'] = SIMP(
        statut='f', typ='TXM', defaut="LDLT_INC", into=("LDLT_INC", "LDLT_SP"), )
    _BlocPE['PRE_COND'] = SIMP(statut='f', typ='TXM', defaut="LDLT_SP",
                               into=("LDLT_INC", "LDLT_SP", "JACOBI", "SOR", "ML", "BOOMER", "GAMG", "BLOC_LAGR", "FIELDSPLIT", "SANS", ), )

# --------------------------------------------------------------------

    _BlocGC['RESI_RELA'] = SIMP(statut='f', typ='R', defaut=1.E-6, )
    _BlocPE['RESI_RELA'] = SIMP(statut='f', typ='R', defaut=1.E-6, )

# --------------------------------------------------------------------

    _BlocGC['NMAX_ITER'] = SIMP(statut='f', typ='I', defaut=0, )
    _BlocPE['NMAX_ITER'] = SIMP(statut='f', typ='I', defaut=0, )

# --------------------------------------------------------------------
# Mot-cle cache pour desactiver le critere en norme non preconditionnee
# dans PETSC

    if _type == 'NL':
        _BlocPE['RESI_RELA_PC'] = SIMP(statut='c', typ='R', defaut=-1.0, )
    else:
        _BlocPE['RESI_RELA_PC'] = SIMP(statut='c', typ='R', defaut=0.0, )

# --------------------------------------------------------------------

    _BlocGC_INC['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="RCMK", into=("RCMK",), )
    _BlocPE_INC['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="RCMK", into=("RCMK",), )

# --------------------------------------------------------------------

    _BlocGC_INC['NIVE_REMPLISSAGE'] = SIMP(statut='f', typ='I', defaut=0, )
    _BlocPE_INC['NIVE_REMPLISSAGE'] = SIMP(statut='f', typ='I', defaut=0, )

# --------------------------------------------------------------------

    _BlocPE_INC['REMPLISSAGE'] = SIMP(statut='f', typ='R', defaut=1.0, )

# --------------------------------------------------------------------

    _BlocXX_SP['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="SANS", into=("SANS",), )
    _BlocXX_SP['REAC_PRECOND'] = SIMP(statut='f', typ='I', defaut=30, )
    _BlocXX_SP['PCENT_PIVOT'] = SIMP(
        statut='f', typ='I', defaut=20, val_min=1, )
    _BlocXX_SP['GESTION_MEMOIRE'] = SIMP(
        statut='f', typ='TXM', defaut="AUTO", into=("IN_CORE", "AUTO"), )

# --------------------------------------------------------------------

    _BlocPE_ML['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="SANS", into=("SANS",), )

# --------------------------------------------------------------------

    _BlocPE_BOOMER['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="SANS", into=("SANS",), )
# --------------------------------------------------------------------

    _BlocPE_GAMG['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="SANS", into=("SANS",), )

# --------------------------------------------------------------------

    _BlocPE_LAGAUG['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="SANS", into=("SANS",), )

# --------------------------------------------------------------------

    _BlocXX_Autres['RENUM'] = SIMP(
        statut='f', typ='TXM', defaut="SANS", into=("SANS", "RCMK", ), )

# --------------------------------------------------------------------

    _BlocXX_Autres['NOM_CMP'] = SIMP(
        statut='f', typ='TXM', max='**',)

# --------------------------------------------------------------------

    _BlocXX_Autres['OPTION_PETSC'] = SIMP(
        statut='f', typ='TXM', max=1,)

# --------------------------------------------------------------------

    _BlocXX_Autres['PARTITION_CMP'] = SIMP(
        statut='f', typ='I',  max='**',)


# --------------------------------------------------------------------
#
# PREPARATION DU MOT-CLE FACTEUR
#
# --------------------------------------------------------------------

    mcfact = FACT(statut='d',
                  b_mult_front=BLOC(
                      condition="""equal_to("METHODE", 'MULT_FRONT') """,
                                      fr=tr(
                                          "Paramètres de la méthode multi frontale"),
                                      **_BlocMF
                  ),
                  b_ldlt=BLOC(
                      condition="""equal_to("METHODE", 'LDLT') """,
                                      fr=tr("Paramètres de la méthode LDLT"),
                                      **_BlocLD
                  ),
                  b_mumps=BLOC(
                      condition="""equal_to("METHODE", 'MUMPS') """,
                                      fr=tr("Paramètres de la méthode MUMPS"),
                                      **_BlocMU
                  ),
                  b_gcpc=BLOC(
                      condition="""equal_to("METHODE", 'GCPC') """,
                                       fr=tr(
                                           "Paramètres de la méthode du gradient conjugué"),
                                      b_ldltinc=BLOC(
                                          condition="""equal_to("PRE_COND", 'LDLT_INC') """,
                                                          fr=tr(
                                                              "Paramètres de la factorisation incomplète"),
                                                          **_BlocGC_INC
                                      ),
                                      b_simple=BLOC(
                                          condition="""equal_to("PRE_COND", 'LDLT_SP') """,
                                                          fr=tr(
                                                              "Paramètres de la factorisation simple précision"),
                                                          **_BlocXX_SP
                                      ),
                                      **_BlocGC
                  ),
                  b_petsc=BLOC(
                      condition="""equal_to("METHODE", 'PETSC') """,
                                      fr=tr("Parametres de la methode PETSC"),
                                      b_ldltinc=BLOC(
                                          condition="""equal_to("PRE_COND", 'LDLT_INC') """,
                                                          fr=tr(
                                                              "Paramètres de la factorisation incomplète"),
                                                          **_BlocPE_INC
                                      ),
                                      b_simple=BLOC(
                                          condition="""equal_to("PRE_COND", 'LDLT_SP') """,
                                                          fr=tr(
                                                              "Paramètres de la factorisation simple précision"),
                                                          **_BlocXX_SP
                                      ),
                                      b_ml=BLOC(
                                          condition="""equal_to("PRE_COND", 'ML') """,
                                                          fr=tr(
                                                              "Paramètres du multigrille algébrique ML"),
                                                          **_BlocPE_ML
                                      ),
                                      b_boomer=BLOC(
                                          condition="""equal_to("PRE_COND", 'BOOMER') """,
                                                          fr=tr(
                                                              "Paramètres du multigrille algébrique HYPRE"),
                                                          **_BlocPE_BOOMER
                                      ),
                                      b_gamg=BLOC(
                                          condition="""equal_to("PRE_COND", 'GAMG') """,
                                                          fr=tr(
                                                              "Paramètres du multigrille algébrique GAMG"),
                                                          **_BlocPE_GAMG
                                      ),
                                      b_lagaug=BLOC(
                                          condition="""equal_to("PRE_COND", 'BLOC_LAGR') """,
                                                          fr=tr(
                                                              "Paramètres du préconditionneur Lagrangien Augmenté BLOC_LAGR"),
                                                          **_BlocPE_LAGAUG
                                      ),
                                      b_autres=BLOC(
                                          condition="""is_in("PRE_COND", ('JACOBI','SOR','FIELDSPLIT', 'SANS'))""",
                                                          **_BlocXX_Autres
                                      ),
                                      **_BlocPE
                  ),
                  **_MotCleSimples
                  )

    return mcfact
