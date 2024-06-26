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

cata_msg = {
    1: _("""
  Une divergence a été détectée à l'instant %(r1)f, inutile de poursuivre avec 
  l'intégration temporelle. 
  
  Conseil : réduire le pas de temps du schéma d'intégration ou choisir un schéma 
  adaptatif avec une valeur de tolérance adaptée à la raideur du système dynamique 
  aussi bien en vol libre qu'en état de choc.
"""),

    2: _("""
         Comportement %(k1)s non implanté pour l'élément d'interface
"""),

    3: _("""
         Choix de déformation %(k1)s non disponible pour l'élément CABLE_GAINE
"""),

    5 : _("""
  Le champ post-traité est un CHAM_ELEM, le calcul de moyenne ne fonctionne que
 sur les CHAM_NO. Pour les CHAM_ELEM utiliser POST_ELEM mot-clé INTEGRALE.
"""),

    6 : _("""
  Le calcul de la racine numéro %(i1)d par la méthode de la matrice compagnon a échoué.
"""),

    8 : _("""
  Il manque le NUME_DDL dans le concept %(k1)s.
  Propositions :
   - Si ce concept est issu de l'opérateur DEFI_BASE_MODALE, renseigner le mot-clé NUME_REF dans DEFI_BASE_MODALE.
   - Si ce concept est issu de l'opérateur CREA_RESU, utiliser les mots-clés MATR_RIGI et MATR_MASS dans CREA_RESU.
"""),

    10 : _("""
  La loi de comportement mécanique %(k1)s n'est pas compatible avec les
  éléments de joint avec couplage hydro-mécanique.
"""),
    11 : _("""
  La fermeture du joint sort des bornes [0,fermeture maximale] sur la maille %(k1)s.
  fermeture du joint = %(r1)f
  fermeture maximale = %(r2)f
  Vérifier la cohérence chargement mécanique, fermeture asymptotique et ouverture
  initiale.
"""),

    14 : _("""
  Les mots clés PRES_FLUIDE et PRES_CLAVAGE/SCIAGE sont incompatibles avec les modélisations xxx_JOINT_HYME
"""),

    15 : _("""
  Les données matériau RHO_FLUIDE, VISC_FLUIDE et OUV_MIN sont obligatoires avec les modélisations xxx_JOINT_HYME
"""),

    16 : _("""
  Les données matériau RHO_FLUIDE, VISC_FLUIDE et OUV_MIN sont incompatibles avec les modélisations xxx_JOINT
"""),


    18 : _("""
  La base de modes associée au résultat généralisé sous le mot-clé
  EXCIT_RESU %(i1)d n'est pas la même que celle utilisée pour la
  fabrication des matrices généralisées.
"""),

    19 : _("""
  La projection d'un résultat non réel sur une base de mode (de type
  résultat harmonique) n'est pas possible. Vous pouvez demander
  l'évolution.
"""),

    20 : _("""
  La prise en compte d'un amortissement équivalent a un amortissement modal par le mot-clé AMOR_MODAL nécessite
  une base de modes pré calculée sur laquelle est décomposé l'amortissement.
  Conseil: vérifiez qu'un base de modes est bien renseignée sous le mot-clé MODE_MECA.
"""),
    21 : _("""
  Aucune valeur d'amortissement modal n'a été trouvée sous le mot-clé AMOR_MODAL.
  Cette information est nécessaire pour la prise en compte d'un amortissement de type modal.

"""),

    22 : _("""
  Il y a %(i1)d points de Gauss sur l'axe de rotation. En ces points les axes Or et suivant thêta ne sont pas définis. On prend
   un axe Or quelconque normal à Oz pour continuer le changement de repère mais seules les composantes suivant z ont un sens en ces points.
"""),
    23 : _("""
    Vous effectuez un changement de repère %(k1)s. Le repère est défini par %(i1)d occurrences du mot-clé AFFE : or une seule occurrence de ce mot-clé est autorisée pour ce type de changement de repère. 
"""),
    25 : _("""
  Lors de la reprise du calcul, la liste des champs calculés (DEPL, VITE, ACCE) doit être la même
  pour le concept entrant et sortant.
"""),
    26 : _("""
  La structure de données résultat est corrompue. Elle ne contient pas d'objet avec la liste des numéros d'ordre.
"""),
    27 : _("""
  La structure de données résultat est corrompue. La liste des numéros d'ordres ne correspond pas
  à la liste des discrétisations temporelles ou fréquentielles.
"""),
    28 : _("""
  La structure de données en entrée ne contient aucun des champs requis pour la restitution temporelle.
  Conseil: vérifiez la liste des champs renseignée sous NOM_CHAM, ou bien testez l'option TOUT_CHAM='OUI'.
"""),
    29 : _("""
  Erreur dans l'allocation de la structure de données dynamique. La liste des champs à allouer n'est pas valide.
"""),

    31 : _("""
  Il faut donner autant de coefficients pour le paramètre %(k1)s
  qu'il y a de modes propres dans la base sur laquelle est fabriquée
  le macro-élément.
   - Nombre de modes de la base : %(i1)d
   - Nombre de coefficients donnés : %(i2)d.
"""),
    32 : _("""
  Le macro-élément est assemblé à partir de données mesurées.
  Le calcul des masses effectives est impossible. Ne pas en tenir
  compte dans les calculs postérieurs.
"""),

    41 : _("""
   Le type de résultat %(k1)s (mot clé TYPE_RESU) n'est pas autorisé pour le mot clé facteur %(k2)s (mot clé OPERATION)
"""),
    42 : _("""
   On doit obligatoirement trouver le mot-clé F_MRR_RR ou le mot-clé F_MXX_XX
"""),
    
}
