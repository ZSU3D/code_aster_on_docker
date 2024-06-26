# coding=utf-8
# --------------------------------------------------------------------
# Copyright (C) 1991 - 2018 - EDF R&D - www.code-aster.org
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

from code_aster.Cata.Syntax import *
from code_aster.Cata.DataStructure import *
from code_aster.Cata.Commons import *


def macr_ecre_calc_prod(self,TABLE,DEBIT,**args):
  if args.get('__all__'):
      return ([None], [table_sdaster], [table_sdaster])

  self.type_sdprod(TABLE,table_sdaster)
  self.type_sdprod(DEBIT,table_sdaster)
  return None

MACR_ECRE_CALC=MACRO(nom="MACR_ECRE_CALC",
                     op=OPS('Macro.macr_ecre_calc_ops.macr_ecre_calc_ops'),
                     sd_prod=macr_ecre_calc_prod,
                     reentrant='n',
                     fr=tr("Procedure de couplage avec Ecrevisse"),

                     regles = (UN_PARMI('LOGICIEL','VERSION'),),

#      CONCEPTS SORTANT : 2 TABLES POUR LE POST-TRAITEMENT
#      ********************************************
         TABLE              =SIMP(statut='o',typ=CO),
         DEBIT              =SIMP(statut='o',typ=CO),

#      DONNEES GEOMETRIQUES RELATIVES A LA FISSURE
#      *******************************************

         FISSURE            =FACT(statut='o',min=1,max=1,
           LONGUEUR            =SIMP(statut='o',typ='R',val_min=0.E+0,fr=tr("Longueur de la fissure [zl]")),
           RUGOSITE            =SIMP(statut='o',typ='R',fr=tr("Rugosite absolu (metres) [eps]")),
           ANGLE               =SIMP(statut='o',typ='R',fr=tr("Angle par rapport a l'ascendante verticale (degres)")),
           ZETA                =SIMP(statut='o',typ='R',fr=tr("Coefficient de la perte de charge singuliere a l'entree [zeta]")),
           SECTION             =SIMP(statut='o',typ='TXM',into=("ELLIPSE","RECTANGLE"),fr=tr("Type de section [is]")),
           b_section_ellipse   =BLOC(condition="SECTION=='ELLIPSE'",fr=tr("Fissure a section elliptique"),
             LISTE_COTES_AH      =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des cotes des points definissant le grand axe de la section"),
                                       validators=NoRepeat()),
             LISTE_VAL_AH        =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des valeurs des points definissant le grand axe de la section"),),
             LISTE_COTES_BL      =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des cotes des points definissant le petit axe de la section"),
                                       validators=NoRepeat()),
             LISTE_VAL_BL        =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des valeurs des points definissant le petit axe de la section"),),
           ),
           b_section_rectangle =BLOC(condition="SECTION=='RECTANGLE'",fr=tr("Fissure a section rectangulaire"),
             LISTE_COTES_AH      =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des cotes des points definissant la hauteur de la section"),
                                       validators=NoRepeat()),
             LISTE_VAL_AH        =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des valeurs des points definissant la hauteur de la section"),),
             LISTE_COTES_BL      =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des cotes des points definissant la largeur de la section"),
                                       validators=NoRepeat()),
             LISTE_VAL_BL        =SIMP(statut='o',typ='R',max='**',
                                       fr=tr("Liste des valeurs des points definissant la largeur de la section"),),
           ),
         ),


#      DONNEES RELATIVES A L"ECOULEMENT
#      ********************************

         ECOULEMENT         =FACT(statut='f',min=1,max=1,
           PRES_ENTREE         =SIMP(statut='o',typ='R',fr=tr("Pression de stagnation a l'entree (Pa) [pe]") ),
           PRES_SORTIE         =SIMP(statut='o',typ='R',fr=tr("Pression de stagnation a la sortie (Pa) [ps]") ),
           FLUIDE_ENTREE       =SIMP(statut='o',typ='I',into=(1,2,3,4,5,6),fr=tr("Condition du fluide a l'entree [iflow]") ),
           b_condition_1       =BLOC(condition="FLUIDE_ENTREE==1",fr=tr("Eau sous-refroidie ou saturee"),
             TEMP_ENTREE         =SIMP(statut='o',typ='R',fr=tr("Temperature a l'entree (degres C) [te]") ),
           ),
           b_condition_2       =BLOC(condition="FLUIDE_ENTREE==2",fr=tr("Fluide diphasique"),
             TITR_MASS           =SIMP(statut='o',typ='R',fr=tr("Titre massique eau vap/eau tot a l'entree [xe]") ),
           ),
           b_condition_3       =BLOC(condition="FLUIDE_ENTREE==3",fr=tr("Vapeur saturee ou surchauffee"),
             TEMP_ENTREE         =SIMP(statut='o',typ='R',fr=tr("Temperature a l'entree (degres C) [te]") ),
           ),
           b_condition_4       =BLOC(condition="FLUIDE_ENTREE==4",fr=tr("Air + vapeur surchauffee"),
             TEMP_ENTREE         =SIMP(statut='o',typ='R',fr=tr("Temperature a l'entree (degres C) [te]") ),
             PRES_PART           =SIMP(statut='o',typ='R',fr=tr("Pression partielle air en entree (Pa) [pae]") ),
           ),
           b_condition_5       =BLOC(condition="FLUIDE_ENTREE==5",fr=tr("Air + vapeur saturee"),
             TITR_MASS           =SIMP(statut='o',typ='R',fr=tr("Titre massique eau vap/eau tot a l'entree [xe]") ),
             PRES_PART           =SIMP(statut='o',typ='R',fr=tr("Pression partielle air en entree (Pa) [pae]") ),
           ),
           b_condition_6       =BLOC(condition="FLUIDE_ENTREE==6",fr=tr("Air seul"),
             TEMP_ENTREE         =SIMP(statut='o',typ='R',fr=tr("Temperature a l'entree (degres C) [te]") ),
           ),
         ),


#      DONNEES RELATIVES AU PROFIL DE TEMPERATURE A TRAVERS LA PAROI
#      *************************************************************

         TEMPERATURE        =FACT(statut='f',min=1,max=1,
           GRADIENT            =SIMP(statut='o',typ='TXM',into=("FOURNI","IMPOSE","CALCULE"),
                                     fr=tr("Modele de calcul du gradient de temperature [imograd]") ),
           b_gradient_fourni   =BLOC(condition="GRADIENT=='FOURNI'",fr=tr("Distribution de temperature fournie [imograd=-1]"),
             LISTE_COTES_TEMP    =SIMP(statut='o',typ='R',max='**',fr=tr("Liste des cotes pour les temperatures"),
                                       validators=NoRepeat() ),
             LISTE_VAL_TEMP      =SIMP(statut='o',typ='R',max='**',fr=tr("Liste des valeurs de temperature"), ),
           ),
           b_gradient_impose   =BLOC(condition="GRADIENT=='IMPOSE'",fr=tr("Distribution imposee de temperature [imograd=0]"),
             TEMP1               =SIMP(statut='o',typ='R',
                                       fr=tr("Gradient de temperature de la paroi le long de l'ecoulement (degC/m) [tm1]"), ),
             TEMP2               =SIMP(statut='o',typ='R',fr=tr("Temperature de la paroi a l'entree (degC) [tm2]"), ),
           ),
           b_gradient_calcule  =BLOC(condition="GRADIENT=='CALCULE'",fr=tr("Profil de temperature calcule [imograd=1]"),
             EPAISSEUR_PAROI     =SIMP(statut='o',typ='R',fr=tr("Epaisseur de la paroi (m) [epp]"), ),
             CONVECTION_AMONT    =SIMP(statut='o',typ='R',
                                       fr=tr("Coefficient de convection a la surface de la paroi cote amont (W/degC/m2) [alphe]"), ),
             CONVECTION_AVAL     =SIMP(statut='o',typ='R',
                                       fr=tr("Coefficient de convection a la surface de la paroi cote aval (W/degC/m2) [alphs]"), ),
             LAMBDA              =SIMP(statut='o',typ='R',fr=tr("Conduction thermique de la paroi (W/degC/m) [lambd]"), ),
             TEMP_FLUIDE_AVAL    =SIMP(statut='o',typ='R',fr=tr("Temperature du fluide cote aval (degC) [ts]"), ),
           ),
         ),


#      CHOIX DES MODELES
#      *****************

         MODELE_ECRE        =FACT(statut='f',min=1,max=1,
           IVENAC              =SIMP(statut='f', typ='I', into=(0,1), defaut=0,
                                     fr=tr("Calcul ECREVISSE avec prise en compte de la vena contracta")),
           ECOULEMENT          =SIMP(statut='o',typ='TXM',into=("SATURATION","GELE"),
                                     fr=tr("Type de modele d'ecoulement diphasique [imod]") ),
           b_ecou_gele         =BLOC(condition="ECOULEMENT=='GELE'",fr=tr("Modele d'ecoulement gele"),
             PRESS_EBULLITION    =SIMP(statut='o',typ='R',fr=tr("Pression d'ebullition [corrp*psat(t)]")),
           ),
           FROTTEMENT          =SIMP(statut='o',typ='I',into=(-4,-3,-2,-1,0,1,2,3,4,11,12,13,14,21,22,23,24),fr=tr("Correlation de frottement [ifrot]")),
           b_frottement        =BLOC(condition="FROTTEMENT<0",fr=tr("Modele d'ecoulement gele"),
             REYNOLDS_LIM        =SIMP(statut='o',typ='R',fr=tr("Coefficient de Reynolds limite [relim]")),
             FROTTEMENT_LIM      =SIMP(statut='o',typ='R',fr=tr("Coefficient de frottement impose [frtlim]")),
           ),

           TRANSFERT_CHAL      =SIMP(statut='o',typ='I',into=(-12,-11,-2,-1,0,1,2,11,12),fr=tr("Transfert de chaleur [ichal]")),
           b_transchal         =BLOC(condition="TRANSFERT_CHAL<0", fr=tr("Cas diphasique"),
             XMINCH              =SIMP(statut='o',typ='R',fr=tr("Titre massique gazeux min [xminch]")),
             XMAXCH              =SIMP(statut='o',typ='R',fr=tr("Titre massique gazeux max [xmaxch]")),
           ),
         ),


#      DONNEES RELATIVES A LA CONVERGENCE NUMERIQUE
#      ********************************************

         CONVERGENCE        =FACT(statut='f',min=1,max=1,
           KGTEST              =SIMP(statut='f',typ='R',val_min=0.E+0,val_max=1.E+0,defaut= 0.5E+0,
                                     fr=tr("Parametre de l'algorithme iteratif [kgtest]") ),
           ITER_GLOB_MAXI      =SIMP(statut='f',typ='I',defaut= 400,
                                     fr=tr("Nombre maximum d'iterations de la methode de Newton [itnmax]") ),
           CRIT_CONV_DEBI      =SIMP(statut='f',typ='R',val_min=0.E+0,val_max=1.E+0,defaut= 1.E-5,
                                     fr=tr("Critere de convergence en debit [precdb]") ),
         ),


#      GENERAL
#      *******

         COURBES            =SIMP(statut='f',typ='TXM',into=("INTERACTIF","POSTSCRIPT","AUCUNE"),defaut="AUCUNE",
                                  fr=tr("Generation eventuelle des courbes") ),
         LOGICIEL           =SIMP(statut='f',typ='TXM',validators=LongStr(1,255),),
         VERSION            =SIMP(statut='f',typ='TXM',into = ("3.2.2",) ),
         ENTETE             =SIMP(statut='f',typ='TXM',max='**',defaut="Titre du calcul Ecrevisse" ),
         IMPRESSION         =SIMP(statut='f',typ='TXM',defaut='NON',into=( 'OUI','NON') ),
         INFO               =SIMP(statut='f',typ='I',defaut= 1,into=(1,2) ),

)  ;
