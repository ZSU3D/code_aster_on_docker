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

# person_in_charge: nicolas.greffet at edf.fr
#
# MACRO DE COUPLAGE IFS AVEC SATURNE VIA YACS
#
import os


def calc_ifs_dnl_ops(self, GROUP_MA_IFS, NOM_CMP_IFS, UNITE_NOEUD, UNITE_ELEM, MODELE, ETAT_INIT, EXCIT, PAS_INIT, **args):
    # =================================================================#
    # Initialisations                                                 #
    # --------------------------------------------------------------- #
    """
       Corps de la macro CALC_IFS_DNL
    """
    ier = 0
    import aster
    import os
    from code_aster.Cata.Syntax import _F
    from Utilitai.Table import Table
    from Utilitai.Utmess import UTMESS
    from code_aster.Cata.Commands import EXTR_RESU, DEFI_LIST_ENTI, IMPR_RESU
    from SD.sd_maillage import sd_maillage
    #
    self.set_icmd(1)
    # =================================================================#
    # Liste des commandes ASTER utilisees                             #
    # --------------------------------------------------------------- #
    AFFE_CHAR_MECA = self.get_cmd('AFFE_CHAR_MECA')
    DEFI_GROUP = self.get_cmd('DEFI_GROUP')
    DEFI_LIST_REEL = self.get_cmd('DEFI_LIST_REEL')
    DYNA_NON_LINE = self.get_cmd('DYNA_NON_LINE')
    LIRE_MAILLAGE = self.get_cmd('LIRE_MAILLAGE')
    PROJ_CHAMP = self.get_cmd('PROJ_CHAMP')
    # Operateurs specifiques pour IFS
    from Contrib.impr_mail_yacs import IMPR_MAIL_YACS
    from Contrib.env_cine_yacs import ENV_CINE_YACS
    from Contrib.modi_char_yacs import MODI_CHAR_YACS
    from Contrib.recu_para_yacs import RECU_PARA_YACS
    # =================================================================#
    # Gestion des mots cles specifiques a CALC_IFS_DNL                #
    # --------------------------------------------------------------- #
    motscles = {}
    poidsMocle = {}
    grpRefeMocle = {}
    grpProjMocle = {}
    ifsCharMocle = {}
    tmpListe = []
    ifsCharList = []
    poidsMocle['VIS_A_VIS'] = []
    grpRefeMocle['CREA_GROUP_NO'] = []
    grpProjMocle['CREA_GROUP_NO'] = []
    ifsCharMocle['GROUP_NO'] = []

    ifsCharTuple = (GROUP_MA_IFS,)
    # print "ifsCharTuple=",ifsCharTuple
    ifsCharList = GROUP_MA_IFS
    # print "len(ifsCharList)=",len(ifsCharList)
    prefix = "_"
    for j in range(len(ifsCharTuple)):
        poidsDico = {}
        poidsDico['GROUP_MA_1'] = ifsCharTuple[j]
        poidsDico['GROUP_NO_2'] = 'GN' + str(j + 1)
        poidsMocle['VIS_A_VIS'].append(poidsDico)

        grpProjDico = {}
        grpProjDico['GROUP_MA'] = 'GM' + str(j + 1)
        grpProjDico['NOM'] = 'GN' + str(j + 1)
        grpProjMocle['CREA_GROUP_NO'].append(grpProjDico)

        if (not(ifsCharTuple[j] in tmpListe)):
            tmpListe.append(ifsCharTuple[j])
            grpRefeNode = prefix + ifsCharTuple[j][0]
        #  ifsCharTuple = ifsCharTuple[1:] + (grpRefeNode,)

            grpRefeDico = {}
            grpRefeDico['GROUP_MA'] = ifsCharTuple[j]
            grpRefeDico['NOM'] = grpRefeNode
            grpRefeMocle['CREA_GROUP_NO'].append(grpRefeDico)

    for j in range(len(tmpListe)):
        tmpListe[j] = prefix + tmpListe[j][0]
    ifsCharMocle['GROUP_NO'] = tuple(tmpListe)

    for j in range(len(NOM_CMP_IFS)):
        if (NOM_CMP_IFS[j] == 'FX'):
            ifsCharMocle['FX'] = 0.0
        elif (NOM_CMP_IFS[j] == 'FY'):
            ifsCharMocle['FY'] = 0.0
        elif (NOM_CMP_IFS[j] == 'FZ'):
            ifsCharMocle['FZ'] = 0.0
        else:
            raise AsException("MOT-CLE NON PERMIS : ", NOM_CMP_IFS[j])

    # =================================================================#
    # Gestion des mots cles de DYNA_NON_LINE                          #
    # --------------------------------------------------------------- #
    motCleSimpTuple = ('MODELE',
                       'CHAM_MATER',
                       'MODE_STAT',
                       'CARA_ELEM',
                       'MASS_DIAG',
                       'INFO',
                       'TITRE')

    motCleFactTuple = ('EXCIT',
                       'EXCIT_GENE',
                       'SOUS_STRUC',
                       'AMOR_MODAL',
                       'PROJ_MODAL',
                       'COMPORTEMENT',
                       'ETAT_INIT',
                       'SCHEMA_TEMPS',
                       'NEWTON',
                       'SOLVEUR',
                       'RECH_LINEAIRE',
                       'PILOTAGE',
                       'CONVERGENCE',
                       'OBSERVATION',
                       'AFFICHAGE',
                       'ARCHIVAGE',
                       'CRIT_FLAMB',
                       'MODE_VIBR')

    for i in range(len(motCleSimpTuple)):
        cle = motCleSimpTuple[i]
        if cle in args:
            motscles[cle] = args[cle]

    for i in range(len(motCleFactTuple)):
        cle = motCleFactTuple[i]
        if cle in args:
            if args[cle] is not None:
                dMotCle = []
                for j in args[cle]:
                    dMotCle.append(j.cree_dict_valeurs(j.mc_liste))
                    for k in list(dMotCle[-1].keys()):
                        if dMotCle[-1][k] is None:
                            del dMotCle[-1][k]
                motscles[cle] = dMotCle
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

    # ===============================#
    # INITIALISATION DE LA SD MACRO #
    # ----------------------------- #
    self.DeclareOut('resdnl', self.sd)

    # ============================================================#
    # GENERATION DES GROUPES DE NOEUDS SUR LE MAILLAGE STRUCTURE #
    # ---------------------------------------------------------- #
    # on recupere le concept maillage
    # print "MODELE=",MODELE
    # print "MODELE.strip()=",MODELE.strip()
    iret, ibid, nom_ma = aster.dismoi('NOM_MAILLA', MODELE.nom, 'MODELE', 'F')
    _strucMesh = self.get_concept(nom_ma.strip())
    # print "MAILLAGE STRUCTURE=",_strucMesh
    # print "DEFI_GROUP MAILLAGE STRUCTURE"
    # print "grpRefeMocle=",grpRefeMocle
    _strucMesh = DEFI_GROUP(reuse=_strucMesh,
                            MAILLAGE=_strucMesh,
                            **grpRefeMocle)

    # =============================================================================#
    # RECUPERATION DU MAILLAGE COUPLE POUR LES DEPLACEMENTS (NOEUDS Code_Saturne) #  !!! YACS COMMUNICATION !!!
    # --------------------------------------------------------------------------- #
    print("IMPR_MAIL_YACS MAILLAGE NOEUDS")
    IMPR_MAIL_YACS(UNITE_MAILLAGE=UNITE_NOEUD, TYPE_MAILLAGE='SOMMET',),
    print("LIRE_MAILLAGE MAILLAGE NOEUDS")
    _fluidNodeMesh = LIRE_MAILLAGE(FORMAT='ASTER',UNITE=UNITE_NOEUD)
    print("DEFI_GROUP MAILLAGE NOEUDS")
    # print "grpProjMocle=",grpProjMocle
    _fluidNodeMesh = DEFI_GROUP(reuse=_fluidNodeMesh,
                                MAILLAGE=_fluidNodeMesh,
                                **grpProjMocle)

    # ====================================================================================#
    # RECUPERATION DU MAILLAGE COUPLE POUR LES FORCES (CENTRE DES ELEMENTS Code_Saturne) #  !!! YACS COMMUNICATION !!!
    # ---------------------------------------------------------------------------------- #
    print("IMPR_MAIL_YACS MAILLAGE ELEMENTS")
    IMPR_MAIL_YACS(UNITE_MAILLAGE=UNITE_ELEM, TYPE_MAILLAGE='MILIEU',)
    print("LIRE_MAILLAGE MAILLAGE ELEMENTS")
    _fluidElemMesh = LIRE_MAILLAGE(FORMAT='ASTER',UNITE=UNITE_ELEM)
    print("DEFI_GROUP MAILLAGE ELEMENTS")
    # print "grpProjMocle=",grpProjMocle
    _fluidElemMesh = DEFI_GROUP(reuse=_fluidElemMesh,
                                MAILLAGE=_fluidElemMesh,
                                **grpProjMocle)

    # ==============================================#
    # CALCUL DES PROJECTEURS POUR LES DEPLACEMENTS #
    # ASTER -> CODE COUPLE                         #
    # -------------------------------------------- #
    print("PROJ_CHAMP MAILLAGE NOEUDS")
    # print "MAILLAGE_1=",_strucMesh.nom
    # print "MAILLAGE_2=",_fluidNodeMesh.nom
    _fluidNodePoids = PROJ_CHAMP(PROJECTION='NON',
                                 METHODE='COUPLAGE',
                                 MAILLAGE_1=_strucMesh,
                                 MAILLAGE_2=_fluidNodeMesh,
                                 **poidsMocle)

    # ========================================#
    # CALCUL DES PROJECTEURS POUR LES FORCES #
    # CODE COUPLE -> ASTER                   #
    # -------------------------------------- #
    print("PROJ_CHAMP MAILLAGE ELEMENTS")
    # print "MAILLAGE_1=",_strucMesh
    # print "MAILLAGE_2=",_fluidElemMesh
    _fluidElemPoids = PROJ_CHAMP(PROJECTION='NON',
                                 METHODE='COUPLAGE',
                                 MAILLAGE_1=_strucMesh,
                                 MAILLAGE_2=_fluidElemMesh,
                                 **poidsMocle)

    # ====================================================================================#
    # CREATION DE LA CARTES DES FORCES NODALES AVEC UNE INITIALISATION DES FORCES A ZERO #
    # ---------------------------------------------------------------------------------- #
    print("AFFE_CHAR_MECA")
    _ifsCharMeca = AFFE_CHAR_MECA(MODELE=MODELE,
                                  FORCE_NODALE=_F(**ifsCharMocle),)
    dExcit = []
    if (EXCIT is not None):
        for j in EXCIT:
            dExcit.append(j.cree_dict_valeurs(j.mc_liste))
            for i in list(dExcit[-1].keys()):
                if dExcit[-1][i] is None:
                    del dExcit[-1][i]
    dExcit.append(_F(CHARGE=_ifsCharMeca),)

    # ====================================#
    # ENVOIE DU MAILLAGE INITIAL DEFORME #  !!! YACS COMMUNICATION !!!
    # ---------------------------------- #
    dEtatInit = []
    dExtrInit = {}
    if (ETAT_INIT is not None):
        if (ETAT_INIT['DEPL'] is not None):
            dExtrInit['DEPL'] = ETAT_INIT['DEPL']
        if (ETAT_INIT['VITE'] is not None):
            dExtrInit['VITE'] = ETAT_INIT['VITE']
        if (ETAT_INIT['ACCE'] is not None):
            dExtrInit['ACCE'] = ETAT_INIT['ACCE']
        for j in ETAT_INIT:
            dEtatInit.append(j.cree_dict_valeurs(j.mc_liste))
            for i in list(dEtatInit[-1].keys()):
                if dEtatInit[-1][i] is None:
                    del dEtatInit[-1][i]

    # ======================================#
    # RECUPERATION DES DONNEES TEMPORELLES #  !!! YACS COMMUNICATION !!!
    # ------------------------------------ #
    print("Appel initialisation")

    _timeStepAster = PAS_INIT
    print("PAS=", _timeStepAster)
    _timeV = RECU_PARA_YACS(DONNEES='INITIALISATION',
                            PAS=_timeStepAster,)
    # print "__timeValues=",_timeV.Valeurs()
    _timeValues = _timeV.Valeurs()
    _nbTimeStep = int(_timeValues[0])

#  Ancien nommage
#   _timeStep    = _timeValues[1]
#   _tInitial    = _timeValues[2]
#   _nbSsIterMax = int(_timeValues[3])
#   _impMed  = int(_timeValues[4])
#   _PeriodImp   = int(_timeValues[5])
#   _StartImp    = int(_timeValues[6])
    _nbSsIterMax = int(_timeValues[1])
    _Epsilo = _timeValues[2]
    _impMed = int(_timeValues[3])
    _PeriodImp = int(_timeValues[4])
    _tInitial = _timeValues[5]
    _timeStep = _timeValues[6]
    _StartImp = _tInitial
    print('_nbTimeStep  = ', _nbTimeStep)
    print('_timeStep    = ', _timeStep)
    print('_tInitial    = ', _tInitial)
    print('_nbSsIterMax = ', _nbSsIterMax)
    print('_impMed  = ', _impMed)
    print('_PeriodImp   = ', _PeriodImp)
    print('_StartImp   = ', _StartImp)
    if (_nbSsIterMax == 0):
        _nbSsIterMax = 1

#  _endValue   = int(_timeValues[7])
#  _nbTimeStep = _endValue
    # print '_nbTimeStep 2  = ',_nbTimeStep

#  Compteur de pas :
    _numpas = 1
# Compteur pour le couplage : CP_ITERATION
    _ntcast = 0
# Compteur de sous-itearation
    _SousIterations = 1

    ticv = [None] * (_nbTimeStep + 1)
    endv = [None] * (_nbTimeStep + 1)

#
#   Envoi des donnees initiales si besoin est
#
#   print "ENV_CINE_YACS 1"
#   ENV_CINE_YACS(ETAT_INIT   = dExtrInit,
#                 MATR_PROJECTION       = _fluidNodePoids,
#                 NUME_ORDRE_YACS   = _numpas,
#                 INST     = _tInitial,
#                 PAS     = _timeStep,
#                 **poidsMocle)
#   print "RETOUR ENV_CINE_YACS 1"
    # =================================#
    # 1ER PASSAGE POUR L'ETAT INITIAL #
    # ------------------------------- #
    # ------------------------------------- #
    # CALCUL NON LINEAIRE AVEC ETAT INITIAL #
    # ------------------------------------- #
    if (_numpas <= _nbTimeStep):
        # ---------------------------------- #
        # Affectation de l'instant de calcul #
        # ---------------------------------- #
        print("RECU_PARA_YACS 1")
        _tStart = _tInitial
        _pastps = RECU_PARA_YACS(DONNEES='PAS',
                                 NUME_ORDRE_YACS=_numpas,
                                 INST=_tStart,
                                 PAS=_timeStepAster,
                                 )
        _pastps0 = _pastps.Valeurs()
        print("_pastps0[0]=", _pastps0[0])
        _timeStep = _pastps0[0]
        print("DEFI_LIST_REEL")
        _tEnd = _tInitial + _timeStep
        print("_tStart=", _tStart, " ; _tEnd=", _tEnd)
        _liste = DEFI_LIST_REEL(DEBUT=_tStart,
                                INTERVALLE=_F(JUSQU_A=_tEnd,
                                              NOMBRE=1,),)
#    _iter = 1
        _SousIterations = 0
        icv = 0
        while (_SousIterations < _nbSsIterMax):

            # Increment des sous-iterations
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            _SousIterations = _SousIterations + 1
            _ntcast = _ntcast + 1

            # Reception des forces nodales et projection !!! YACS COMMUNICATION !!!
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            print("MODI_CHAR_YACS")
            _ifsCharMeca = MODI_CHAR_YACS(reuse=_ifsCharMeca,
                                          CHAR_MECA=_ifsCharMeca,
                                          MATR_PROJECTION=_fluidElemPoids,
                                          NOM_CMP_IFS=NOM_CMP_IFS,
                                          NUME_ORDRE_YACS=_ntcast,
                                          INST=_tStart,
                                          PAS=_timeStep,
                                          **poidsMocle)

            # Resolution non-lineaire
            # ~~~~~~~~~~~~~~~~~~~~~~~
            print("DYNA_NON_LINE NUMPAS=", _numpas)
            #__rescur=DYNA_NON_LINE(
            __rescur = DYNA_NON_LINE(
                ETAT_INIT = dEtatInit,
                MODELE=MODELE,
                INCREMENT=_F(LIST_INST=_liste,),
                EXCIT=dExcit,
                **motscles)
            # test de convergence
            # ~~~~~~~~~~~~~~~~~~~
            _ticv = RECU_PARA_YACS(DONNEES='CONVERGENCE',
                                   NUME_ORDRE_YACS=_ntcast,
                                   INST=_tEnd,
                                   PAS=_timeStep,)
            __icv = _ticv.Valeurs()
            icv = int(__icv[0])
            print("Convergence=", icv)
            if (icv == 1 or _SousIterations == _nbSsIterMax):
                # Envoi des deplacements
                # ~~~~~~~~~~~~~~~~~~~~~~
                print("ENV_CINE_YACS ", _numpas)
                ENV_CINE_YACS(RESULTAT=_F(RESU=__rescur,
                                          # ENV_CINE_YACS(RESULTAT = _F(RESU
                                          # = resdnl,
                                          NUME_ORDRE=_numpas),
                              MATR_PROJECTION=_fluidNodePoids,
                              NUME_ORDRE_YACS=_ntcast,
                              INST=_tEnd,
                              PAS=_timeStep,
                              **poidsMocle)

                _SousIterations = _nbSsIterMax
                print("EXTR_RESU")
                resdnl = EXTR_RESU(RESULTAT=__rescur,
                                   ARCHIVAGE=_F(NUME_ORDRE=(0, 1),))
                # resdnl = __rescur

#     endv[0] = RECU_PARA_YACS(DONNEES='FIN',
#                         NUME_ORDRE_YACS = _iter,
#                         INST  = _tEnd,
#                         PAS  = _timeStep,)
#     __endv = endv[0].Valeurs()
#     _endValue   = __endv[0]
#     _nbTimeStep = _endValue
#     print "FIN=",_endValue
        _numpas = _numpas + 1

    # ===============================#
    # CALCUL NON-LINEAIRE PAS A PAS #
    # ----------------------------- #
    while (_numpas <= _nbTimeStep):

        # ------------------ #
        # Increment du temps #
        # ------------------ #
        _tStart = _tStart + _timeStep
        _tyacs = _tStart + _timeStep
        _pastps = RECU_PARA_YACS(DONNEES='PAS',
                                 NUME_ORDRE_YACS=_numpas,
                                 INST=_tyacs,
                                 PAS=_timeStepAster,
                                 )
        _pastps0 = _pastps.Valeurs()
        print("_pastps0[0]=", _pastps0[0])
        _timeStep = _pastps0[0]
        _tEnd = _tStart + _timeStep
        print("_tStart=", _tStart, " ; _tEnd=", _tEnd)
        _liste = DEFI_LIST_REEL(DEBUT=_tStart,
                                INTERVALLE=_F(JUSQU_A=_tEnd,
                                              NOMBRE=1,),)
#    _iter = _iter + 1
        _SousIterations = 0
        icv = 0
        while (_SousIterations < _nbSsIterMax):

            # Increment des sous-iterations
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            _SousIterations = _SousIterations + 1
            _ntcast = _ntcast + 1

            # Reception des forces nodales et projection !!! YACS COMMUNICATION !!!
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            print("MODI_CHAR_YACS_BOUCLE")
            _ifsCharMeca = MODI_CHAR_YACS(reuse=_ifsCharMeca,
                                          CHAR_MECA=_ifsCharMeca,
                                          MATR_PROJECTION=_fluidElemPoids,
                                          NOM_CMP_IFS=NOM_CMP_IFS,
                                          NUME_ORDRE_YACS=_ntcast,
                                          INST=_tStart,
                                          PAS=_timeStep,
                                          **poidsMocle)

            # Resolution non-lineaire
            # ~~~~~~~~~~~~~~~~~~~~~~~
            print("DYNA_NON_LINE_BOUCLE")
            resdnl = DYNA_NON_LINE(reuse=resdnl,
                                   MODELE=MODELE,
                                   ETAT_INIT=_F(EVOL_NOLI=resdnl,),
                                   INCREMENT=_F(LIST_INST=_liste,),
                                   EXCIT=dExcit,
                                   **motscles)

            # test de convergence
            # ~~~~~~~~~~~~~~~~~~~
            print("CONVERGENCE ", _SousIterations)
            # icv = cocas_fonctions.CONVERGENCE()
            _ticv = RECU_PARA_YACS(DONNEES='CONVERGENCE',
                                   NUME_ORDRE_YACS=_ntcast,
                                   INST=_tEnd,
                                   PAS=_timeStep,)
            __icv = _ticv.Valeurs()
            icv = int(__icv[0])
            print("Convergence=", icv)
            _ntcat = _ntcast + 1
            if (icv == 1 or _SousIterations == _nbSsIterMax):
                _SousIterations = _nbSsIterMax
                # Envoi des deplacements !!! YACS COMMUNICATION !!!
                # ~~~~~~~~~~~~~~~~~~~~~~
                print("ENV_CINE_YACS_BOUCLE")
                ENV_CINE_YACS(RESULTAT=_F(RESU=resdnl,
                                          NUME_ORDRE=_numpas),
                              MATR_PROJECTION=_fluidNodePoids,
                              NUME_ORDRE_YACS=_ntcast,
                              INST=_tEnd,
                              PAS=_timeStep,
                              **poidsMocle)

            else:
                _list2 = DEFI_LIST_ENTI(DEBUT=0,
                                        INTERVALLE=_F(JUSQU_A=_numpas - 1,
                                                      PAS=1,),)
                resdnl = EXTR_RESU(RESULTAT=resdnl,
                                   ARCHIVAGE=_F(LIST_ORDRE=_list2,))

#     endv[_iter] = RECU_PARA_YACS(DONNEES='FIN',
#                         NUME_ORDRE_YACS = _iter,
#                         INST  = _tEnd,
#                         PAS  = _timeStep,)
#     __endv = endv[_iter].Valeurs()
#     _endValue   = __endv[0]
#     _nbTimeStep = _endValue
        _numpas = _numpas + 1

        print("NUMPAS : ", _numpas, "nbTimeStep=", _nbTimeStep)

    # ========================================================================#
    # Impression Med si demandee                                             #
    # (premier et dernier pas d'impression pour coherence avec Code_Saturne) #
    # ---------------------------------------------------------------------- #
    print("impression med : ", _impMed)
    if (_impMed == 1):

        impEnsiMocle = {}
        impEnsiMocle['INTERVALLE'] = []

        if (_nbTimeStep < _PeriodImp):
            _StartImp = 0
            impEnsiDico = {}
            impEnsiDico['JUSQU_A'] = _nbTimeStep
            impEnsiDico['PAS'] = 1
            impEnsiMocle['INTERVALLE'].append(impEnsiDico)
        elif (_nbTimeStep == _PeriodImp and _nbTimeStep == _StartImp):
            _StartImp = 0
            impEnsiDico = {}
            impEnsiDico['JUSQU_A'] = _nbTimeStep
            impEnsiDico['PAS'] = 1
            impEnsiMocle['INTERVALLE'].append(impEnsiDico)
        elif (_PeriodImp == -1):
            if (_nbTimeStep == _StartImp):
                _StartImp = 0
            impEnsiDico = {}
            impEnsiDico['JUSQU_A'] = _nbTimeStep
            impEnsiDico['PAS'] = 1
            impEnsiMocle['INTERVALLE'].append(impEnsiDico)
        else:
            impEnsiDico = {}
            _reste = (_nbTimeStep - _StartImp) % _PeriodImp
            impEnsiDico['JUSQU_A'] = _nbTimeStep - _reste
            impEnsiDico['PAS'] = _PeriodImp
            impEnsiMocle['INTERVALLE'].append(impEnsiDico)
            if (_reste != 0):
                impEnsiDico = {}
                impEnsiDico['JUSQU_A'] = _nbTimeStep
                impEnsiDico['PAS'] = _reste
                impEnsiMocle['INTERVALLE'].append(impEnsiDico)

        print("Liste impEnsiMocle=", impEnsiMocle)
        _listImp = DEFI_LIST_ENTI(DEBUT=_StartImp,
                                  **impEnsiMocle)
        print("Liste impression=", _listImp)
        IMPR_RESU(FORMAT='MED',
                  RESU=_F(MAILLAGE=_strucMesh,
                          RESULTAT=resdnl,
                          LIST_ORDRE=_listImp,),)

    return ier
