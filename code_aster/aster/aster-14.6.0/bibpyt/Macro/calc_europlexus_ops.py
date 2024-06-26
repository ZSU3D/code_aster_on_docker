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
    CALC_EUROPLEXUS
"""

debug = False

import os
import os.path as osp
import tempfile

import aster
import aster_core
import med_aster
from Calc_epx.calc_epx_utils import tolist
from code_aster.Cata.Commands import (DEFI_FICHIER, DETRUIRE,
                                      IMPR_RESU,
                                      INFO_EXEC_ASTER,
                                      MODI_REPERE)
from code_aster.Cata.Syntax import _F
from Utilitai.partition import MAIL_PY
from Utilitai.Utmess import UTMESS, MasquerAlarme, RetablirAlarme

#-----------------------------------------------------------------------
#----------------------------- Operateur de la Macro-commande ----------
#-----------------------------------------------------------------------


def calc_europlexus_ops(self, NOM_CAS, EXCIT, COMPORTEMENT, ARCHIVAGE, CALCUL,
                        CARA_ELEM=None, MODELE=None,
                        CHAM_MATER=None, FONC_PARASOL=None,
                        OBSERVATION=None, COURBE=None,
                        DOMAINES=None, INTERFACES=None,
                        ETAT_INIT=None, AMORTISSEMENT=None,
                        INFO=1, **args):
    """
        Macro-commande CALC_EUROPLEXUS.
    """

    #
    # PREPARATION
    #

    ier = 0
    # La macro compte pour 1 dans la numerotation des commandes
    self.set_icmd(1)

    # Commandes pour le cas parallele
    rank, size = aster_core.MPI_CommRankSize()
    if size > 1:
        UTMESS('F', 'PLEXUS_59')

    # Pour la gestion des Exceptions
    prev_onFatalError = aster.onFatalError()
    aster.onFatalError('EXCEPTION')

    # Pour masquer certaines alarmes
    MasquerAlarme('MED_1')
    MasquerAlarme('ALGELINE4_43')
    MasquerAlarme('JEVEUX_57')

    # Chemin du repertoire REPE_OUT de l'execution courante d'Aster
    REPE_OUT = os.path.join(os.getcwd(), 'REPE_OUT')

    #
    # TRADUCTION DES INFORMATIONS
    #

    EPX = EUROPLEXUS(ETAT_INIT, MODELE, CARA_ELEM, CHAM_MATER, COMPORTEMENT,
                     FONC_PARASOL, EXCIT, OBSERVATION, ARCHIVAGE, COURBE,
                     CALCUL, AMORTISSEMENT, DOMAINES, INTERFACES,
                     INFO=INFO, REPE_epx=REPE_OUT,
                     NOM_RESU=NOM_CAS,
                     args=args)

    #
    # ERITURE DU FICHIER DE COMMANDE EUROPLEXUS
    #

    EPX.ecrire_fichier()

    # Pour la gestion des Exceptions
    aster.onFatalError(prev_onFatalError)

    # Pour la gestion des alarmes
    RetablirAlarme('MED_1')
    RetablirAlarme('ALGELINE4_43')
    RetablirAlarme('JEVEUX_57')

    return ier

#-----------------------------------------------------------------------
#----------------------------- class EUROPLEXUS ------------------------
#-----------------------------------------------------------------------

class EUROPLEXUS:
    """
        Classe gérant la traduction d'un calcul Code_Aster en EPX,
        le lancement du calcul,
        la traduction des résultats dans un concept Aster.
    """

    def __init__(self, ETAT_INIT, MODELE, CARA_ELEM, CHAM_MATER, COMPORTEMENT,
                 FONC_PARASOL, EXCIT, OBSERVATION, ARCHIVAGE, COURBE,
                 CALCUL, AMORTISSEMENT, DOMAINES, INTERFACES,
                 INFO, REPE_epx, NOM_RESU, args):
        """
            Met toutes les entrées en attributs.
            Crée les directives EPX.
            Définie les fichiers de sortie.
        """
        from Calc_epx.calc_epx_cata import cata_directives
        from Calc_epx.calc_epx_struc import DIRECTIVE

        if debug:
            print('args_key %s'%list(args.keys()))

        # Récuperation des concepts de la base
        macro = CONTEXT.get_current_step()

        # Résultat initial
        # MODELE, CARA_ELEM, CHAM_MATER
        self.ETAT_INIT = ETAT_INIT
        if ETAT_INIT is not None:

            RESULTAT = ETAT_INIT['RESULTAT']
            nom_RESU_INIT = RESULTAT.get_name()

            # MODELE
            iret, ibid, nomsd = aster.dismoi('MODELE', nom_RESU_INIT,
                                             'RESULTAT', 'F')
            nomsd = nomsd.strip()
            if nomsd[0] == '#':
                UTMESS('F', 'PLEXUS_37', valk='MODELE')
            self.MODELE = macro.get_concept(nomsd)

            # CARA_ELEM
            if CARA_ELEM is None :
                iret, ibid, nomsd = aster.dismoi('CARA_ELEM', nom_RESU_INIT, 'RESULTAT', 'F')
                nomsd = nomsd.strip()
                if nomsd[:8] == '#PLUSIEU':
                    UTMESS('F', 'PLEXUS_37', valk=[nom_RESU_INIT, 'CARA_ELEM'])
                elif nomsd[:6] == '#AUCUN':
                    self.CARA_ELEM = None
                else:
                    self.CARA_ELEM = macro.get_concept(nomsd)
            else:
                self.CARA_ELEM = CARA_ELEM
                UTMESS('A','PLEXUS_53')

            # CHAM_MATER
            iret, ibid, nomsd = aster.dismoi('CHAM_MATER', nom_RESU_INIT, 'RESULTAT', 'F')
            nomsd = nomsd.strip()
            if nomsd[:8] == '#PLUSIEU':
                UTMESS('F', 'PLEXUS_37', valk=[nom_RESU_INIT, 'CHAM_MATER'])
            self.CHAM_MATER = macro.get_concept(nomsd)
        else:
            self.MODELE     = MODELE
            self.CARA_ELEM  = CARA_ELEM
            self.CHAM_MATER = CHAM_MATER
        #
        # Recherche dans le jdc la création du concept CARA_ELEM
        if ( self.CARA_ELEM is not None ):
            FindEtape = False
            self.CARA_ELEM_CONCEPT = self.CARA_ELEM
            nomsd = self.CARA_ELEM.get_name()
            jdc = CONTEXT.get_current_step().jdc
            for UneEtape in jdc.etapes:
                if (UneEtape.nom=='AFFE_CARA_ELEM') and (UneEtape.sdnom==nomsd):
                    self.CARA_ELEM = UneEtape
                    FindEtape = True
                    break
            #
            if ( not FindEtape ):
                UTMESS('F', 'PLEXUS_20', valk=[nomsd, 'CARA_ELEM'])
            #
        else:
            self.CARA_ELEM_CONCEPT = None
        #
        # récuperation du maillage
        nom_MODELE = self.MODELE.get_name()
        iret, ibid, nomsd = aster.dismoi('NOM_MAILLA', nom_MODELE, 'MODELE', 'F')
        nomsd = nomsd.strip()
        self.MAILLAGE = macro.get_concept(nomsd)

        # Autres entrées
        self.FONC_PARASOL = FONC_PARASOL
        self.EXCIT = EXCIT
        self.OBSERVATION = OBSERVATION
        self.ARCHIVAGE = ARCHIVAGE
        self.COURBE = COURBE
        self.CALCUL = CALCUL
        self.DOMAINES = DOMAINES
        self.INTERFACES = INTERFACES
        self.INFO = INFO
        self.COMPORTEMENT = COMPORTEMENT
        self.AMORTISSEMENT = AMORTISSEMENT

        self.REPE_epx = REPE_epx

        # COURBE
        if 'UNITE_COURBE' in args:
            self.UNITE_COURBE = args['UNITE_COURBE']
        else:
            self.UNITE_COURBE = None

        if 'PAS_INST_COURBE' in args:
            self.PAS_INST_COURBE = args['PAS_INST_COURBE']
        else:
            self.PAS_INST_COURBE = None

        if 'PAS_NBRE_COURBE' in args:
            self.PAS_NBRE_COURBE = args['PAS_NBRE_COURBE']
        else:
            self.PAS_NBRE_COURBE = None

        if 'INST_COURBE' in args:
            self.INST_COURBE = args['INST_COURBE']
        else:
            self.INST_COURBE = None

        if 'NUME_ORDRE_COURBE' in args:
            self.NUME_ORDRE_COURBE = args['NUME_ORDRE_COURBE']
        else:
            self.NUME_ORDRE_COURBE = None

        # Création des directives EPX
        self.epx = {}
        for direc in cata_directives:
            titre = cata_directives[direc]['TITRE']
            type_dir = cata_directives[direc]['TYPE_DIR']
            self.epx[direc] = DIRECTIVE(direc, titre, type_dir)

        # Nom des fichiers de Europlexus (commande et sorties)
        nom_fichiers = {'COMMANDE': 'commandes_%s.epx'%NOM_RESU,
                        'MAILLAGE': 'commandes_%s.msh'%NOM_RESU,
                        'SAUV': 'resu_%s.sau'%NOM_RESU,
                        'MED': 'champ_%s.e2m'%NOM_RESU,
                        'PUN': 'courbes_%s.pun'%NOM_RESU,
                        }
        for fic in list(nom_fichiers.keys()):
            nom_fic = nom_fichiers[fic]
            nom_fichiers[fic] = os.path.join(self.REPE_epx, nom_fic)
        self.nom_fichiers = nom_fichiers

        # creation du dictionnaire de données complementaires sur les modélisations
        self.info_mode_compl = {}


  #-----------------------------------------------------------------------
    def get_unite_libre(self,):
        """
            Retoune une unité de fichier libre.
        """
        _UL = INFO_EXEC_ASTER(LISTE_INFO='UNITE_LIBRE')
        unite = _UL['UNITE_LIBRE', 1]
        DETRUIRE(CONCEPT=(_F(NOM=_UL),), INFO=1)
        return unite
  #-----------------------------------------------------------------------
    def export_DEBUT(self):
        """
            Ecrit les mot-clés d'initialisation du calcul dans la fausse
            directive DEBUT.
            Active la directive FIN
        """

        from Calc_epx.calc_epx_struc import BLOC_DONNEES
        epx = self.epx

        directive = 'DEBUT'

        vale = ''
        for mcle in ['TITRE', 'ECHO', 'TRID']:
            bloc = BLOC_DONNEES(mcle)
            epx[directive].add_bloc(bloc)

        # lecture fichier MED
        bloc = BLOC_DONNEES('MEDL', cle='28')
        epx[directive].add_bloc(bloc)

        # écriture des résultats EPX en MED
        champ_fact = self.ARCHIVAGE
        if champ_fact is not None:
            bloc = BLOC_DONNEES('MEDE')
            epx[directive].add_bloc(bloc)

        # on traite la directive fin maintenant car elle est toujours présente
        # à la fin
        directive = 'FIN'
        epx[directive].add_void()

  #-----------------------------------------------------------------------
    def export_MAILLAGE(self,):
        """
            Imprime le maillage et le résultat initial aster au format MED
            s'il y a un état initial.
        """
        from Calc_epx.trans_var_int import var_int_a2e

        epx = self.epx

        # Donner un nom au fichier de maillage parce que le fort.unite peut
        # être ecrasée par d'autre operation d'ecriture.
        unite = self.get_unite_libre()
        fichier_maillage = self.nom_fichiers['MAILLAGE']
        DEFI_FICHIER(UNITE=unite, FICHIER=fichier_maillage, ACTION='ASSOCIER', TYPE='BINARY')

        if self.ETAT_INIT is not None:
            RESULTAT = self.ETAT_INIT['RESULTAT']
            res_imp = RESULTAT
            list_cham = ['DEPL']
            if self.ETAT_INIT['CONTRAINTE'] == 'OUI':
                if self.etat_init_cont != []:
                    valk = ', '.join(self.etat_init_cont)
                    UTMESS('A', 'PLEXUS_17', valk = valk)
                list_cham.append('SIEF_ELGA')
                nume_ordre = RESULTAT.LIST_PARA()['NUME_ORDRE'][-1]
                if self.modi_repere['COQUE']:
                    MODI_REPERE(RESULTAT=RESULTAT, reuse=RESULTAT,
                                REPERE='COQUE_UTIL_INTR',
                                AFFE=_F(TOUT='OUI'),
                                NUME_ORDRE = nume_ordre,
                                MODI_CHAM=_F(TYPE_CHAM='COQUE_GENE',
                                             NOM_CHAM='SIEF_ELGA',
                                             NOM_CMP=('NXX', 'NYY', 'NXY',
                                                      'MXX', 'MYY', 'MXY',
                                                      'QX', 'QY')))
                if self.ETAT_INIT['VARI_INT'] == 'OUI':
                    list_cham.append('VARI_ELGA')
                    res_imp = var_int_a2e(self.compor_gr, RESULTAT, self.MODELE,
                                          nume_ordre)
                    nume_ordre = 1

            if self.ETAT_INIT['CONTRAINTE'] == 'OUI':
                if self.ETAT_INIT['VITESSE'] == 'OUI':
                    list_cham.append('VITE')

            # Impression des champs du dernier instant de calcul.
            nume_ordre = RESULTAT.LIST_PARA()['NUME_ORDRE'][-1]
            IMPR_RESU(UNITE=unite,
                      FORMAT='MED',
                      RESU=_F(NUME_ORDRE=nume_ordre, RESULTAT=res_imp,
                              NOM_CHAM=list_cham)
                 )

            # on remet les contraintes des coques dans le repère utilisateur
            # pour ne pas modifier le resultat.
            if self.ETAT_INIT['CONTRAINTE'] == 'OUI':
                if self.modi_repere['COQUE']:
                    MODI_REPERE(RESULTAT=RESULTAT, reuse=RESULTAT,
                                REPERE='COQUE_INTR_UTIL',
                                AFFE=_F(TOUT='OUI'),
                                NUME_ORDRE = nume_ordre,
                                MODI_CHAM=_F(TYPE_CHAM='COQUE_GENE',
                                             NOM_CHAM='SIEF_ELGA',
                                             NOM_CMP=('NXX', 'NYY', 'NXY',
                                                      'MXX', 'MYY', 'MXY',
                                                      'QX', 'QY')))
        else:
            # Impression
            IMPR_RESU(UNITE=unite,
                  FORMAT='MED',
                  RESU=_F(MAILLAGE=self.MAILLAGE)
                 )

        DEFI_FICHIER(UNITE=unite, ACTION='LIBERER')

  #-----------------------------------------------------------------------
    def export_MODELE(self):
        """
            Traduction du modèle Code_Aster dans la directive GEOM d'EPX.
        """
        from Calc_epx.calc_epx_geom import export_modele

        [self.epx, self.dic_epx_geom, self.modi_repere,
         self.etat_init_cont] = export_modele(self.epx, self.MAILLAGE,
                                              self.MODELE, self.gmaInterfaces,
                                              self.info_mode_compl)

   #-----------------------------------------------------------------------
    def export_CARA_ELEM(self):
        """
            Traduction des caractéristiques élémentaires de Code_Aster dans
            les directives EPX correspondantes.
        """

        from Calc_epx.calc_epx_cata import cata_cara_elem
        from Calc_epx.calc_epx_cara import export_cara, get_FONC_PARASOL
        from Calc_epx.calc_epx_utils import recupere_structure, angle2vectx
        from Calc_epx.calc_epx_utils import get_group_ma, tolist
        from Calc_epx.calc_epx_poutre import POUTRE
        epx = self.epx

        dic_gr_cara_supp = {}
        # Récuperer s'il a lieu les fonctions de ressorts de sol et discrets
        if self.FONC_PARASOL is not None:
            dic_gr_cara_supp = get_FONC_PARASOL(epx, self.FONC_PARASOL,
                                                dic_gr_cara_supp)
        # récupérer les orientations des poutres
        if self.CARA_ELEM:
            class_poutre = POUTRE(MAILLAGE=self.MAILLAGE, CARA_ELEM=self.CARA_ELEM)
            dic_gr_cara_supp = class_poutre.get_orie_poutre(dic_gr_cara_supp)

        mode_from_cara = {}

        self.dicOrthotropie = None
        # Recuperer la structure du concept sorti de AFFE_CARA_ELEM
        if self.CARA_ELEM is not None:
            cara_elem_struc = recupere_structure(self.CARA_ELEM)

            for cle in list(cara_elem_struc.keys()):
                if cle in ['INFO', 'MODELE']:
                    continue
                if cle not in cata_cara_elem:
                    UTMESS('F', 'PLEXUS_18', valk=cle)
                if cata_cara_elem[cle] is None:
                    continue
                [epx, mode_from_cara] = export_cara(cle, epx,
                                              cara_elem_struc[cle],
                                              self.MAILLAGE, self.CARA_ELEM_CONCEPT,
                                              dic_gr_cara_supp, mode_from_cara)

                if cle == 'COQUE':
                    # récupérer les orientations des coques
                    # utilisées pour GLRC_DAMAGE
                    dicOrthotropie = {}
                    donnees_coque = tolist(cara_elem_struc[cle])
                    for elem in donnees_coque:
                        l_group = get_group_ma(elem, mcfact='AFFE_CARA_ELEM/COQUE')

                        if 'VECTEUR' in elem:
                            for group in l_group:
                                dicOrthotropie[group] = elem['VECTEUR']
                        elif 'ANGL_REP' in elem:
                            alpha, beta = elem['ANGL_REP']
                            vect = angle2vectx(alpha, beta)
                            for group in l_group:
                                dicOrthotropie[group] = vect

                    self.dicOrthotropie = dicOrthotropie

        self.info_mode_compl.update(mode_from_cara)


    #-----------------------------------------------------------------------
    def export_CHAM_MATER(self):
        """
            Traduction des comportements de Code_Aster dans la directive MATE.
            Impression des fonctions s'il a lieu.
            Traduction des orientations pour GLRC.
        """
        from Calc_epx.calc_epx_mate import export_mate

        self.epx, self.compor_gr, mode_from_compor, self.gmaInterfaces = export_mate(self.epx, self.CHAM_MATER,
                  self.COMPORTEMENT,self.INTERFACES, self.dicOrthotropie)

        self.info_mode_compl.update(mode_from_compor)

  #-----------------------------------------------------------------------
    def export_EXCIT(self):
        """
            Traduction des chargements et conditions limites de Code_Aster dans
            les directives EPX correspondantes.
        """
        from Calc_epx.calc_epx_char import export_charge
        epx = self.epx
        epx = export_charge(epx, self.EXCIT, self.MAILLAGE)
  #-----------------------------------------------------------------------
    def export_ECRITURE(self):
        """
            Gestion de l'écriture des résultats dans les différents formats
            et fichiers.
        """
        from Calc_epx.calc_epx_struc import BLOC_DONNEES
        from Calc_epx.calc_epx_cata import cata_champs
        from Calc_epx.calc_epx_utils import ctime
        epx = self.epx

        directive = 'ECRITURE'
        # blocs d'écriture de tous les noeuds et toutes les mailles
        [bloc_poin, bloc_elem] = self.write_all_gr()

        # Traitement du mot-cle facteur OBSERVATION (EPX = LISTING)
        # Ecriture LISTING
        if self.OBSERVATION is not None:
            listing_fact = self.OBSERVATION.List_F()[0]
            nom_cham = tolist(listing_fact['NOM_CHAM'])

            # champs
            for cham_aster in nom_cham:
                cham_epx = cata_champs[cham_aster]
                bloc_champ = BLOC_DONNEES(cham_epx)
                epx[directive].add_bloc(bloc_champ)

            # instants
            blocs_inst = ctime(listing_fact)
            for bloc in blocs_inst:
                epx[directive].add_bloc(bloc)

            # noeuds
            if 'TOUT_GROUP_NO' in listing_fact:
                # tous les noeuds du modèle
                if bloc_poin is not None:
                    epx[directive].add_bloc(bloc_poin)
                else:
                    bloc = BLOC_DONNEES('NOPO')
                    epx[directive].add_bloc(bloc)
            elif 'GROUP_NO' in listing_fact:
                gr_no = tolist(listing_fact['GROUP_NO'])
                bloc = BLOC_DONNEES('POIN', l_group=gr_no,)
                epx[directive].add_bloc(bloc)
            else:
                bloc = BLOC_DONNEES('NOPO')
                epx[directive].add_bloc(bloc)

            # mailles
            if 'TOUT_GROUP_MA' in listing_fact:
                # toutes les mailles du modèle
                if bloc_elem is not None:
                    epx[directive].add_bloc(bloc_elem)
                else:
                    bloc = BLOC_DONNEES('NOEL')
                    epx[directive].add_bloc(bloc)
            elif 'GROUP_MA' in listing_fact:
                gr_ma = tolist(listing_fact['GROUP_MA'])
                bloc = BLOC_DONNEES('ELEM', l_group=gr_ma,)
                epx[directive].add_bloc(bloc)
            else:
                bloc = BLOC_DONNEES('NOEL')
                epx[directive].add_bloc(bloc)


        # Ecriture FICHIER ALICE utilisé par le mot-cle facteur COURBE
        courbe_fact = self.COURBE
        if courbe_fact is not None:

            concept_bid = {}
            if self.PAS_NBRE_COURBE:
                concept_bid['PAS_NBRE'] = self.PAS_NBRE_COURBE
            if self.PAS_INST_COURBE:
                concept_bid['PAS_INST'] = self.PAS_INST_COURBE
            if self.INST_COURBE:
                concept_bid['INST'] = self.INST_COURBE
            if self.NUME_ORDRE_COURBE:
                concept_bid['NUME_ORDRE'] = self.NUME_ORDRE_COURBE

            mot_cle = "FICHIER ALIT 11"
            objet = epx[directive].add_mcfact(mot_cle)

            # instants
            blocs_inst = ctime(concept_bid)
            for bloc in blocs_inst:
                objet.add_bloc(bloc)

            # Liste les noeuds a postraiter
            lnoeuds = set()
            lmailles = set()
            for courbe in courbe_fact:
                if courbe['GROUP_NO'] is not None:
                    grno = courbe['GROUP_NO']
                    if type(grno) == tuple:
                        for el in grno:
                            lnoeuds.add(el)
                    else:
                        lnoeuds.add(grno)
                elif courbe['GROUP_MA'] is not None:
                    grma = courbe['GROUP_MA']
                    if type(grma) == tuple:
                        for el in grma:
                            lmailles.add(el)
                    else:
                        lmailles.add(grma)
                else:
                    raise Exception('Erreur : ni noeud ni maille')

            if lnoeuds:
                bloc = BLOC_DONNEES('POIN', l_group=lnoeuds,)
                objet.add_bloc(bloc)
            if lmailles:
                bloc = BLOC_DONNEES('ELEM', l_group=lmailles,)
                objet.add_bloc(bloc)

        # FICHIER MED
        champ_fact = self.ARCHIVAGE
        if champ_fact is not None:

            mot_cle = "FICHIER MED"
            objet = epx[directive].add_mcfact(mot_cle)

            fichier_med = repr(self.nom_fichiers['MED'])
            bloc_fic = BLOC_DONNEES(fichier_med)
            objet.add_bloc(bloc_fic)
            # instants
            blocs_inst = ctime(champ_fact)
            for bloc in blocs_inst:
                objet.add_bloc(bloc)

            # tous les groupes de mailles du modèle
            if bloc_poin is not None:
                objet.add_bloc(bloc_poin)
            if bloc_elem is not None:
                objet.add_bloc(bloc_elem)

        # FICHIER SAUV
        mot_cle = 'FICHIER SAUV'
        nom_fic = repr(self.nom_fichiers['SAUV'])
        data = [nom_fic, 'LAST']
        bloc = BLOC_DONNEES(mot_cle, cara=data)
        epx[directive].add_bloc(bloc)


    def export_POST_COURBE(self):

        """
            Traitement du mot-clé COURBE dans la directive SORTIE.
        """
        from Calc_epx.calc_epx_struc import BLOC_DONNEES
        from Calc_epx.calc_epx_cata import cata_champs, cata_compo

        # Suite de postraitement permettant d'ecrire des fichiers ASCII
        # des grandeurs demandees

        # Tester si le mot_cle facteur COURBE a ete renseigne
        courbe_fact = self.COURBE
        if courbe_fact is None:
            return

        courbe_fact = courbe_fact.List_F()
        self.nb_COURBE = len(courbe_fact)
        epx = self.epx

        # SUITE
        directive = 'SUITE'
        epx[directive].add_void()

        # INFO_SORTIE
        directive = 'INFO_SORTIE'
        if self.UNITE_COURBE:
            fichier_courbes = os.path.join(self.REPE_epx, 'fort.%s'
                                           % str(self.UNITE_COURBE))
        else:
            fichier_courbes = self.nom_fichiers['PUN']

        bloc = BLOC_DONNEES('RESULTAT', cara='ALICE TEMPS', vale='11')
        epx[directive].add_bloc(bloc)
        bloc = BLOC_DONNEES('OPNF', cara=['FORMAT', "'%s'"%fichier_courbes],
                                    vale=['17', ''])
        epx[directive].add_bloc(bloc)

        # SORTIE
        directive = 'SORTIE'
        objet = epx[directive].add_mcfact('GRAPHIQUES')
        bloc = BLOC_DONNEES('AXTEMPS', cle="1. 'TEMPS(s)'")
        objet.add_bloc(bloc)

        # Dictionnaire décrivant les légendes des abscisses et ordonnees
        # des courbes imprimées et utilisées dans get_table.
        dic_entite = {'GROUP_NO' : 'NOEUD', 'GROUP_MA' : 'ELEM'}
        nb_courbe = 0
        lnoeuds = []
        nb_char_lim_pun = 16
        for i_courbe,courbe in enumerate(courbe_fact):
            for entite_type in list(dic_entite.keys()):
                if entite_type in courbe:
                    entite = courbe[entite_type]
                    cham_aster = courbe['NOM_CHAM']
                    cmp_aster = courbe['NOM_CMP']
                    cham_epx = cata_champs[cham_aster]
                    if cmp_aster not in cata_compo[cham_aster]:
                        UTMESS('F', 'PLEXUS_38', valk=[cham_aster, cmp_aster])
                    cmp_epx = cata_compo[cham_aster][cmp_aster]
                    label = courbe['NOM_COURBE']
                    entite = tolist(entite)
                    ll = len(label)
                    if ll > nb_char_lim_pun:
                        UTMESS('A', 'PLEXUS_21', vali = [i_courbe+1, nb_char_lim_pun])
#                   on laisse la boucle meme s'il ne peut y avoir qu'un seul groupe
                    for el in entite:
                        # COURBE
                        nb_courbe += 1
                        mot_cle = 'COURBE'
                        cara = [cham_epx, 'COMP', ]
                        vale = ['', cmp_epx, ]
                        if entite_type == 'GROUP_MA':
                            cara.append('GAUSS')
                            num_gauss = courbe['NUM_GAUSS']
                            if type(num_gauss) is tuple:
                                num_gauss = num_gauss[0]
                            vale.append(num_gauss)
                        cara.append(dic_entite[entite_type])
                        vale.append('')
                        val_cle = "'%s'"%label
                        bloc_courbe = BLOC_DONNEES(mot_cle, l_group=el,
                                                   cle=nb_courbe,
                                                   val_cle=val_cle, cara=cara,
                                                   vale=vale)
                        objet.add_bloc(bloc_courbe)
                        # LIST
                        mot_cle = 'LIST'
                        cara = 'AXES 1.'
                        vale = "'%s'"%label
                        bloc_liste = BLOC_DONNEES(mot_cle, val_cle=nb_courbe,
                                                  cara=cara, vale=vale)
                        objet.add_bloc(bloc_liste)

  #-----------------------------------------------------------------------
    def export_CALCUL(self):
        """
            Traduit les informations de lancement du calcul.
        """

        from Calc_epx.calc_epx_struc import BLOC_DONNEES, BLOC_DONNEES_SUP
        from Calc_epx.calc_epx_cata import cata_calcul

        epx = self.epx

        liste_mots_cles_CALCUL = self.CALCUL.List_F()[0]

        # ETAT_INIT
        if self.ETAT_INIT is not None:
            directive = 'INIT'
            epx[directive].add_info_dir('MEDL')
            if self.ETAT_INIT['CONTRAINTE'] == 'OUI':
                bloc = BLOC_DONNEES('CONT')
                epx[directive].add_bloc(bloc)
                if self.ETAT_INIT['VARI_INT'] == 'OUI':
                    bloc = BLOC_DONNEES('ECRO')
                    epx[directive].add_bloc(bloc)
            else:
                niter = self.ETAT_INIT['NITER']
                bloc = BLOC_DONNEES('NITER', cle=niter)
                epx[directive].add_bloc(bloc)
            if self.ETAT_INIT['EQUILIBRE'] == 'OUI':
                bloc = BLOC_DONNEES('EQUI')
                epx[directive].add_bloc(bloc)

        # OPTION
        directive = 'OPTION'
        type_discr = liste_mots_cles_CALCUL['TYPE_DISCRETISATION']
        bloc = BLOC_DONNEES('PAS', cle=type_discr)
        epx[directive].add_bloc(bloc)

        if  type_discr == 'AUTO':
            cstab = liste_mots_cles_CALCUL['CSTAB']
            bloc = BLOC_DONNEES('CSTAB', cle=cstab)
            epx[directive].add_bloc(bloc)

        if self.AMORTISSEMENT is not None:
            liste_mots_cles_AMOR = self.AMORTISSEMENT.List_F()[0]
            type_amor = liste_mots_cles_AMOR['TYPE_AMOR']
            if type_amor == 'QUASI_STATIQUE':
                freq = liste_mots_cles_AMOR['FREQUENCE']
                coef = liste_mots_cles_AMOR['COEF_AMOR']
                if 'INST_DEB_AMOR' in liste_mots_cles_AMOR:
                    deb_amor = liste_mots_cles_AMOR['INST_DEB_AMOR']
                    fin_amor = liste_mots_cles_AMOR['INST_FIN_AMOR']
                    cara = ['FROM', 'UPTO']
                    vale = [deb_amor, fin_amor]
                else:
                    cara = []
                    vale = []
                coef = liste_mots_cles_AMOR['COEF_AMOR']
                bloc = BLOC_DONNEES('QUASI STATIQUE', cle=freq, val_cle=coef,
                                    cara=cara, vale=vale)
                epx[directive].add_bloc(bloc)
            else:
                raise Exception("Type d'amortissement non programmé")

        # STRUCTURE
        directive = 'STRUCTURE'
        listInterfaces = self.INTERFACES
        listDomaines = self.DOMAINES
        domaineInterfaces = {}
        if listDomaines:
            epx[directive].add_info_dir(len(listDomaines))
            for interface in listInterfaces:
                Lgma1 = tolist(interface['GROUP_MA_1'])
                Lgma2 = tolist(interface['GROUP_MA_2'])
                idS1 = interface['IDENT_DOMAINE_1']
                idS2 = interface['IDENT_DOMAINE_2']
                if idS1 not in domaineInterfaces:
                    domaineInterfaces[idS1] = []
                if idS2 not in domaineInterfaces:
                    domaineInterfaces[idS2] = []
                domaineInterfaces[idS1].extend(Lgma1)
                domaineInterfaces[idS2].extend(Lgma2)
        else:
            listDomaines = []
        for domaine in listDomaines:
            Lgma = tolist(domaine['GROUP_MA'])
            id = domaine['IDENTIFIANT']
            Lgma.extend(domaineInterfaces[id])

            mot_cle = 'DOMA'
            cara = 'IDENTIFIANT'
            vale = id
            bloc = BLOC_DONNEES(mot_cle, l_group=Lgma, cara=cara, vale=vale,
                              lect_term='debut')
            epx[directive].add_bloc(bloc)

        # INTERFACE
        directive = 'INTERFACE'
        if listInterfaces:
            epx[directive].add_info_dir(len(listInterfaces))
        else:
            listInterfaces = []
        for interface in listInterfaces:
            Lgma1 = tolist(interface['GROUP_MA_1'])
            Lgma2 = tolist(interface['GROUP_MA_2'])
            idS1 = interface['IDENT_DOMAINE_1']
            idS2 = interface['IDENT_DOMAINE_2']
            tole = interface['TOLE']
            mot_cle = 'DOMA'
            bloc1 = BLOC_DONNEES(mot_cle, l_group=Lgma1, val_cle=idS1)
            bloc2 = BLOC_DONNEES(mot_cle, l_group=Lgma2, val_cle=idS2)
            mot_cle = 'MORTAR'
            cle = 'TOLE'
            bloc_sup = BLOC_DONNEES_SUP(mot_cle, cle=cle, val_cle=tole,
                                      l_BD=[bloc1, bloc2])
            epx[directive].add_bloc(bloc_sup)

        # CALCUL
        directive = 'CALCUL'
        for cle in list(cata_calcul.keys()):
            if cle in liste_mots_cles_CALCUL:
                vale = liste_mots_cles_CALCUL[cle]
                bloc = BLOC_DONNEES(cata_calcul[cle], cle=vale)
                epx[directive].add_bloc(bloc)

  #-----------------------------------------------------------------------
    def ecrire_fichier(self,):
        """
            Lance la traduction des données et leurs stockages.
            Ecrit le fichier de commande directive par directive dans l'ordre
            donné par la liste locale 'directives'.
        """
        fichier = self.nom_fichiers['COMMANDE']

        # Les modules MODELE et RIGI_PARASOL doivent être exécutés avant
        # MAILLAGE car le maillage peut être modifié dans ces modules (ajout de
        # groupes uniquement).
        # Les modules CARA_ELEM et CHAM_MATER doivent être exécutés avant MODELE
        # pour connaître la modelisation à affecter à certains éléments.
        # Le module CHAM_MATER doit être exécuté avant MAILLAGE pour avoir
        # les infos permettant de traduire les variables internes.

        modules_exe = ['DEBUT', 'CARA_ELEM', 'CHAM_MATER', 'MODELE',
                       'MAILLAGE', 'EXCIT', 'ECRITURE', 'CALCUL',
                       'POST_COURBE']
        directives = ['DEBUT', 'GEOM', 'COMPLEMENT', 'FONC', 'MATE',
                      'ORIENTATION', 'CHARGE', 'LINK', 'ECRITURE', 'OPTION',
                      'INIT', 'STRUCTURE', 'INTERFACE', 'CALCUL', 'SUITE',
                      'INFO_SORTIE', 'SORTIE', 'FIN']

        # Excecution des differentes modules
        for module in modules_exe:
            fct = 'export_%s' % module
            if hasattr(self, fct):
                eval('self.'+fct+'()')
            else:
                raise Exception("La classe EUROPLEXUS n'a pas de méthode %s"
                                                                       % fct)

        # Ecriture des directives
        with open(fichier, 'w') as fd:
            for directive in directives:
                liste_lignes = self.epx[directive].write()
                for ll in liste_lignes:
                    fd.write('%s\n'%ll)

#-----------------------------------------------------------------------
    def write_all_gr(self,):
        """
            Renvoie deux blocs de données indiquand que la commande
            s'applique à tous les noeuds et mailles du modèle.
        """

        from Calc_epx.calc_epx_struc import BLOC_DONNEES

        entite_geo = {}
        entite_geo['ELEM'] = []
        for model in list(self.dic_epx_geom.keys()):
            if self.dic_epx_geom[model]['RESU_ELEM']:
                entite_geo['ELEM'].extend(self.dic_epx_geom[model]
                                                     ['GROUP_MA'])
        entite_geo['POIN'] = []
        for model in list(self.dic_epx_geom.keys()):
            if self.dic_epx_geom[model]['RESU_POIN']:
                entite_geo['POIN'].extend(self.dic_epx_geom[model]
                                                       ['GROUP_MA'])
        li_blocs = []
        for cle in ['POIN', 'ELEM']:
            if entite_geo[cle] != []:
                bloc = BLOC_DONNEES(cle, l_group=entite_geo[cle],)
            else:
                bloc = None
            li_blocs.append(bloc)

        return li_blocs
