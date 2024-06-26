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

# person_in_charge: samuel.geniaut at edf.fr

from code_aster.Cata.Syntax import *
from code_aster.Cata.DataStructure import *
from code_aster.Cata.Commons import *


POST_RUPTURE=MACRO(nom="POST_RUPTURE",
                   op=OPS("Macro.post_rupture_ops.post_rupture_ops"),
                   sd_prod=table_sdaster,
                   fr=tr("post-traitements en Rupture"),
                   reentrant='f:TABLE',

      reuse=SIMP(statut='c', typ=CO),
      TABLE     = SIMP(statut='o',typ=table_sdaster,max='**'),

      OPERATION = SIMP(statut='o',typ='TXM',into=(
                                                  'ABSC_CURV_NORM',
                                                  'ANGLE_BIFURCATION',
                                                  'K_EQ',
                                                  'DELTA_K_EQ',
                                                  'COMPTAGE_CYCLES',
                                                  'LOI_PROPA',
                                                  'CUMUL_CYCLES',
                                                  'PILO_PROPA',
                                                  'K1_NEGATIF',
                                                 )
                       ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'ABSC_CURV_NORM'
#-----------------------------------------------------------------------------------------------------------------------------------


      b_absc = BLOC(condition="""equal_to("OPERATION", 'ABSC_CURV_NORM')""",fr=tr("normalise l'abscisse curviligne"),

                   NOM_PARA = SIMP(statut='f',typ='TXM',max=1,defaut="ABSC_CURV_NORM",fr=tr("Nom de la nouvelle colonne")),

                   ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'ANGLE_BIFURCATION'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_angle = BLOC(condition="""equal_to("OPERATION", 'ANGLE_BIFURCATION')  """,fr=tr("Angle de bifurcation"),

                   NOM_PARA = SIMP(statut='f',typ='TXM',max=1,defaut="BETA",fr=tr("Nom de la nouvelle colonne")),
                   CRITERE  = SIMP(statut='f',typ='TXM',max=1,defaut="SITT_MAX",into=('SITT_MAX','SITT_MAX_DEVER','K1_MAX','K2_NUL','PLAN'),),
                   MATER = SIMP(statut='f',typ=mater_sdaster,),
                   #b_mater = BLOC(condition="""equal_to("CRITERE", SITT_MAX_DEVER)""",fr=tr("materiau du fond de fissure"),
                   #                 MATER = SIMP(statut='o',typ=mater_sdaster,),
                   #                ),
                   ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'K_EQ'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_Keq = BLOC(condition="""equal_to("OPERATION", 'K_EQ')  """,fr=tr("Cumul sur les modes : calcul du K equivalent"),

                   NOM_PARA = SIMP(statut='f',typ='TXM',max=1,defaut="K_EQ",fr=tr("Nom de la nouvelle colonne")),
                   CUMUL    = SIMP(statut='f',typ='TXM',max=1,defaut="CUMUL_G",fr=tr("Formule de cumul des modes"),
                                   into=('LINEAIRE','QUADRATIQUE','CUMUL_G','MODE_I'),),

                     b_mater = BLOC(condition="""is_in("CUMUL", ('QUADRATIQUE','CUMUL_G'))""",fr=tr("materiau du fond de fissure"),
                                    MATER = SIMP(statut='o',typ=mater_sdaster,),
                                   ),
                   ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'DELTA_K_EQ'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_DeltaKeq = BLOC(condition="""equal_to("OPERATION", 'DELTA_K_EQ')  """,fr=tr("Cumul sur les modes : calcul du DeltaK equivalent"),

                   NOM_PARA = SIMP(statut='f',typ='TXM',max=1,defaut="DELTA_K_EQ",fr=tr("Nom de la nouvelle colonne")),
                   CUMUL    = SIMP(statut='f',typ='TXM',max=1,defaut="CUMUL_G",fr=tr("Formule de cumul des modes"),
                                       into=('QUADRATIQUE','CUMUL_G','MODE_I'),),

                     b_mater = BLOC(condition="""is_in("CUMUL", ('QUADRATIQUE','CUMUL_G'))""",fr=tr("materiau du fond de fissure"),
                                      MATER = SIMP(statut='o',typ=mater_sdaster,),
                                    ),

                   ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'COMPTAGE_CYCLES'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_Comptage = BLOC(condition="""equal_to("OPERATION", 'COMPTAGE_CYCLES')  """,fr=tr("Comptage des cycles"),

                   NOM_PARA   = SIMP(statut='o',typ='TXM',validators=NoRepeat(),max='**',
                                     fr=tr("Nom des quantités sur lesquelles s'effectuent le comptage")),
                   COMPTAGE   = SIMP(statut='o',typ='TXM',into=("RAINFLOW","RCCM","NATUREL","UNITAIRE")),
                   DELTA_OSCI = SIMP(statut='f',typ='R',defaut= 0.0E+0),

                     b_Comptage_Unitaire = BLOC(condition="""equal_to("COMPTAGE", 'UNITAIRE')""",
                                                fr=tr("comptage unitaire pour les amplitudes constantes"),

                                                COEF_MULT_MINI = SIMP(statut='o',typ='R',),
                                                COEF_MULT_MAXI = SIMP(statut='o',typ='R',),

                                               ),

                   ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'LOI_PROPA'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_Loi_Propa   = BLOC(condition="""equal_to("OPERATION", 'LOI_PROPA')  """,fr=tr("calcul de l'incrément d'avancée de fissure par cycle"),

                   NOM_PARA       = SIMP(statut='f',typ='TXM',defaut="DELTA_A"   ,max=1,fr=tr("Nom de la nouvelle colonne")),
                   NOM_DELTA_K_EQ = SIMP(statut='f',typ='TXM',defaut="DELTA_K_EQ",max=1,
                                                                              fr=tr("Nom de la quantité correspondant au Delta_K_eq")),
                   LOI            = SIMP(statut='o',typ='TXM',into=("PARIS",)),

                     b_paris = BLOC(condition = """equal_to("LOI", 'PARIS')""",
                                    C = SIMP(statut='o',typ='R',),
                                    M = SIMP(statut='o',typ='R',),
                                    DELTA_K_SEUIL = SIMP(statut='f',typ='R',max=1,defaut=0.,val_min=0.),
                                   ),

      ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'CUMUL_CYCLES'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_cumul = BLOC(condition="""equal_to("OPERATION", 'CUMUL_CYCLES')  """,fr=tr("Cumul sur les cycles"),

                   NOM_PARA = SIMP(statut='f',typ='TXM',max=1,defaut="DELTA_A",fr=tr("Nom de la colonne à traiter")),
                   CUMUL    = SIMP(statut='f',typ='TXM',max=1,defaut="LINEAIRE",into=('LINEAIRE',)),

                   ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'PILO_PROPA'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_pilo_propa = BLOC(condition="""equal_to("OPERATION", 'PILO_PROPA')  """,fr=tr("Pilotage de la propagation"),

                   regles      = UN_PARMI('DELTA_A_MAX','DELTA_N'),
                   DELTA_A_MAX = SIMP(statut='f',typ='R',max=1,val_min=0.,fr=tr("Pilotage en incrément d'avancée max")),
                   DELTA_N     = SIMP(statut='f',typ='R',max=1,val_min=1 ,fr=tr("Pilotage en incrément de nombre de blocs")),

                   ),

#-----------------------------------------------------------------------------------------------------------------------------------
#                 'K1_NEGATIF'
#-----------------------------------------------------------------------------------------------------------------------------------

      b_k1_neg = BLOC(condition="""equal_to("OPERATION", 'K1_NEGATIF')  """,fr=tr("Mise a zero des valeurs negatives de K1"),

                   MODELISATION = SIMP(statut='o',typ='TXM',into=("C_PLAN","D_PLAN","3D","AXIS")),
                   MATER        = SIMP(statut='o',typ=mater_sdaster,),

                   ),

#-----------------------------------------------------------------------------------------------------------------------------------

)  ;
