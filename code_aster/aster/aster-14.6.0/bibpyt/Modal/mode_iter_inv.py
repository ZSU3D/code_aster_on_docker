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

from code_aster.Cata.Syntax import *
from code_aster.Cata.DataStructure import *
from code_aster.Cata.Commons import *


def mode_iter_inv_prod(TYPE_RESU, **args ):
    if args.get('__all__'):
        return (mode_flamb, mode_meca_c, mode_meca, mode_acou, mode_gene, ASSD)

    if (TYPE_RESU not in ["DYNAMIQUE","MODE_FLAMB","GENERAL"]):
       # on retourne un type fictif pour que le plantage aie lieu dans la lecture du catalogue
       return ASSD
    if TYPE_RESU == "MODE_FLAMB" : return mode_flamb
    if TYPE_RESU == "GENERAL"    : return mode_flamb
    # sinon on est dans le cas 'DYNAMIQUE' donc **args doit contenir les mots-clés
    # MATR_RIGI et (faculativement) MATR_AMOR, et on peut y accéder
    vale_rigi = args['MATR_RIGI']
    if (vale_rigi is None) : # si MATR_RIGI non renseigné
       # on retourne un type fictif pour que le plantage aie lieu dans la lecture du catalogue
       return ASSD
    vale_amor = args['MATR_AMOR']
    if AsType(vale_amor) == matr_asse_depl_r : return mode_meca_c
    if AsType(vale_rigi) == matr_asse_depl_r : return mode_meca
    if AsType(vale_rigi) == matr_asse_pres_r : return mode_acou
    if AsType(vale_rigi) == matr_asse_gene_r : return mode_gene
    raise AsException("type de concept resultat non prevu")

MODE_ITER_INV=OPER(nom="MODE_ITER_INV",op=  44,sd_prod=mode_iter_inv_prod
                    ,fr=tr("Calcul des modes propres par itérations inverses ; valeurs propres et modes réels ou complexes"),
                     reentrant='n',

         TYPE_RESU       =SIMP(statut='f',typ='TXM',defaut="DYNAMIQUE",
                               into=("MODE_FLAMB","DYNAMIQUE","GENERAL"),
                               fr=tr("Type d analyse") ),

         b_dynam         =BLOC(condition = "TYPE_RESU == 'DYNAMIQUE'",
           MATR_RIGI       =SIMP(statut='o',typ=(matr_asse_depl_r,matr_asse_gene_r,matr_asse_pres_r ) ),
           MATR_MASS       =SIMP(statut='o',typ=(matr_asse_depl_r,matr_asse_gene_r,matr_asse_pres_r ) ),
           MATR_AMOR       =SIMP(statut='f',typ=matr_asse_depl_r ),
           CALC_FREQ       =FACT(statut='o',fr=tr("Choix des paramètres pour le calcul des valeurs propres"),

             OPTION          =SIMP(statut='f',typ='TXM',defaut="AJUSTE",into=("SEPARE","AJUSTE","PROCHE"),
                                   fr=tr("Choix de l option pour estimer les valeurs propres")  ),
             FREQ            =SIMP(statut='o',typ='R',max='**',
                                   validators=AndVal((OrdList('croissant'), NoRepeat())),),
             AMOR_REDUIT     =SIMP(statut='f',typ='R',max='**'),
             NMAX_FREQ       =SIMP(statut='f',typ='I',defaut= 0,val_min=0 ),
             NMAX_ITER_SEPARE=SIMP(statut='f',typ='I' ,defaut= 30,val_min=1 ),
             PREC_SEPARE     =SIMP(statut='f',typ='R',defaut= 1.E-4,val_min=1.E-70 ),
             NMAX_ITER_AJUSTE=SIMP(statut='f',typ='I',defaut= 15,val_min=1 ),
             PREC_AJUSTE     =SIMP(statut='f',typ='R',defaut= 1.E-4,val_min=1.E-70 ),

             NMAX_ITER_SHIFT =SIMP(statut='f',typ='I',defaut= 3,val_min=0 ),
             PREC_SHIFT      =SIMP(statut='f',typ='R',defaut= 5.E-2,val_min=0.E+0, ),
             SEUIL_FREQ      =SIMP(statut='f',typ='R',defaut= 1.E-2,val_min=0.E+0, ),
             ),
           ),
         b_flamb        =BLOC(condition = "TYPE_RESU == 'MODE_FLAMB'",
           MATR_RIGI       =SIMP(statut='o',typ=(matr_asse_depl_r,matr_asse_gene_r,matr_asse_pres_r ) ),
           MATR_RIGI_GEOM  =SIMP(statut='o',typ=(matr_asse_depl_r,matr_asse_gene_r,matr_asse_pres_r ) ),
           ),

         b_general      =BLOC(condition = "TYPE_RESU == 'GENERAL'",
           MATR_A          =SIMP(statut='o',typ=(matr_asse_depl_r,matr_asse_gene_r,matr_asse_pres_r ) ),
           MATR_B          =SIMP(statut='o',typ=(matr_asse_depl_r,matr_asse_gene_r,matr_asse_pres_r ) ),
           ),

         b_flamb_general =BLOC(condition = "(TYPE_RESU == 'MODE_FLAMB') or (TYPE_RESU == 'GENERAL')",
           CALC_CHAR_CRIT  =FACT(statut='o',fr=tr("Choix des paramètres pour le calcul des valeurs propres"),

             OPTION          =SIMP(statut='f',typ='TXM',defaut="AJUSTE",into=("SEPARE","AJUSTE","PROCHE"),
                                 fr=tr("Choix de l option pour estimer les valeurs propres")  ),
             CHAR_CRIT       =SIMP(statut='o',typ='R',max='**',
                                   validators=AndVal((OrdList('croissant'), NoRepeat())),),
             NMAX_CHAR_CRIT  =SIMP(statut='f',typ='I',defaut= 0,val_min=0 ),
             NMAX_ITER_SEPARE=SIMP(statut='f',typ='I',defaut= 30,val_min=1 ),
             PREC_SEPARE     =SIMP(statut='f',typ='R',defaut= 1.E-4,val_min=1.E-70 ),
             NMAX_ITER_AJUSTE=SIMP(statut='f',typ='I',defaut= 15,val_min=1 ),
             PREC_AJUSTE     =SIMP(statut='f',typ='R',defaut= 1.E-4,val_min=1.E-70 ),

             NMAX_ITER_SHIFT =SIMP(statut='f',typ='I',defaut= 3,val_min=0 ),
             PREC_SHIFT      =SIMP(statut='f',typ='R',defaut= 5.E-2,val_min=0.E+0, ),
             SEUIL_CHAR_CRIT =SIMP(statut='f',typ='R',defaut= 1.E-2,val_min=0.E+0, ),
             ),
           ),

#-------------------------------------------------------------------
#        Catalogue commun SOLVEUR
         SOLVEUR         =C_SOLVEUR('MODE_ITER_INV'),
#-------------------------------------------------------------------

         CALC_MODE       =FACT(statut='d',min=0,fr=tr("Choix des paramètres pour le calcul des vecteurs propres"),
           OPTION          =SIMP(statut='f',typ='TXM',defaut="DIRECT",into=("DIRECT","RAYLEIGH") ),
           PREC            =SIMP(statut='f',typ='R',defaut= 1.E-5,val_min=1.E-70,fr=tr("Précision de convergence") ),
           NMAX_ITER       =SIMP(statut='f',typ='I',defaut= 30,val_min=1 ),
         ),
         VERI_MODE       =FACT(statut='d',min=0,
           STOP_ERREUR     =SIMP(statut='f',typ='TXM',defaut="OUI",into=("OUI","NON") ),
           SEUIL           =SIMP(statut='f',typ='R',defaut= 1.E-2,val_min=0.E+0,
                                 fr=tr("Valeur limite admise pour l ereur a posteriori des modes")  ),
           PREC_SHIFT      =SIMP(statut='f',typ='R',defaut= 5.E-3,val_min=0.E+0 ),
           STURM           =SIMP(statut='f',typ='TXM',defaut="NON",into=("OUI","NON") ),
         ),
         INFO            =SIMP(statut='f',typ='I',defaut= 1,into=( 1 , 2) ),
         TITRE           =SIMP(statut='f',typ='TXM',validators=NoRepeat(),max='**'),
)  ;
