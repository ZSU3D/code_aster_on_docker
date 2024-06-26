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

# person_in_charge: josselin.delmas at edf.fr

cata_msg = {

    1 : _("""
   La projection d'un vecteur complexe sur une base de RITZ n'est pas développée dans l'opérateur PROJ_VECT_BASE.
   Contactez l'équipe de développement CODE-ASTER.
 """),



    8 : _("""
 nombre de vecteurs demandé inférieur au nombre de modes du concept MODE_MECA
 on tronque la base modale
"""),

    9 : _("""
 nombre de coordonnées généralisées différent du nombre de modes de base de projection
"""),

    10 : _("""
 nombre de vecteurs demandé trop grand
 on prend tous les modes du concept MODE_MECA
"""),

    12 : _("""
 La borne inférieure est incorrecte.
"""),

    15 : _("""
 Le pas (%(r3)f) est plus grand que l'intervalle [%(r1)f, %(r2)f].
"""),

    16 : _("""
 Le pas est nul.
"""),

    17 : _("""
 Le nombre de pas est négatif.
"""),




    30 : _("""
 argument en double pour "NOM_CHAM"
"""),


    34 : _("""
Les matrices ne possèdent pas toutes la même numérotation.
"""),

    39 : _("""
 base modale et MATR_ASSE avec numérotations différentes
"""),

    40 : _("""
  type de matrice inconnu:  %(k1)s
"""),

    41 : _("""
 base modale et VECT_ASSE avec  numérotations différentes
"""),

    42 : _("""
 la base constituée ne forme pas une famille libre
"""),

    43 : _("""
 le nombre de valeurs doit être pair.
"""),

    44 : _("""
 trop d'arguments pour "NOM_CHAM"
"""),

    45 : _("""
 pour calculer une ACCE_ABSOLU, il faut "ACCE_MONO_APPUI"
"""),

    46 : _("""
 pour restituer sur un squelette, il faut "MODE_MECA"
"""),

    47 : _("""
 mots-clés 'SOUS_STRUC' et 'SQUELETTE' interdits
"""),

    48 : _("""
 le mot-clé 'MODE_MECA' doit être présent
"""),

    49 : _("""
 l'instant de récupération est en dehors du domaine de calcul.
"""),

    50 : _("""
 la fréquence  de récupération n'a pas été calculée.
"""),

    51 : _("""
 Vous avez demandé de restituer sur une fréquence (mot-clé FREQ) pour un concept transitoire
 sur base généralisée. Pour ce type de concept vous devez utiliser le mot-clé 'INST'.
"""),
    52 : _("""
 Vous avez demandé de restituer sur un instant (mot-clé INST) pour un concept harmonique
 sur base généralisée. Pour ce type de concept vous devez utiliser le mot-clé 'FREQ'.
"""),

    55 : _("""
 mauvaise définition de l'interspectre.
"""),

    56 : _("""
 le "NB_POIN" doit être une puissance de 2.
"""),

    57 : _("""
 si les mots-clés NUME_ORDRE et AMOR_REDUIT sont utilisés,
 il faut autant d'arguments pour l'un et l'autre
"""),

    58 : _("""
 le concept MODE_MECA d'entrée doit être celui correspondant à la base modale initiale
 pour le calcul de couplage fluide-structure
"""),

    60 : _("""
 tous les modes non couplés étant retenus, le nombre d'arguments valide
 pour le mot-clé AMOR_REDUIT est la différence entre le nombre de modes
 de la base modale initiale et le nombre de modes pris en compte pour
 le couplage fluide-structure
"""),

    61 : _("""
 les numéros d'ordre fournis ne correspondent pas à des modes non perturbés
"""),

    62 : _("""
 option symétrie : la dimension de POINT et AXE_1 doit être identique.
"""),

    63 : _("""
 option symétrie : AXE_2 est inutile en 2D, il est ignoré.
"""),

    64 : _("""
 option symétrie : la dimension de POINT et AXE_2 doit être identique.
"""),
    65 : _("""
 La dimension de la matrice de norme n'est pas compatible
 avec la dimension de l'espace d'observation. Vérifiez la
 cohérence dimensionnelle de vos informations.
"""),
    66 : _("""
 La matrice de projection renseignée ne semble pas correspondre aux maillages
 associés aux modèles numérique et expérimental.
"""),
    67 : _("""
 Les données expérimentales ne contiennent pas d'information quant au maillage
 expérimental associé, où elles sont incohérentes. On ne peut pas construire la
 matrice d'observation.
"""),
    68 : _("""
 Vos données expérimentales semblent comporter des degrés de liberté de Lagrange.
 On ne peut pas traiter ce cas. Le code s'arrête.
"""),
    69 : _("""
 on ne sait pas traiter le champ de type:  %(k1)s
 champ :  %(k2)s
"""),
    70 : _("""
 Vous n'avez pas assez de mesures correspondant à la liste de fréquences demandées.
"""),
    71 : _("""
 Problème lors de la construction de la matrice d'observation. Le code s'arrête.
 Contactez l'assistance technique.
"""),

    81 : _("""
 le vecteur directeur est nul.
"""),

    84 : _("""
 précision machine dépassée
"""),








    91 : _("""
 le nombre de noeuds mesuré doit être inférieur au nombre de noeuds du modèle
"""),

    92 : _("""
 maille SEG2 non trouvée
"""),

    93 : _("""
 intégration élastoplastique de loi BETON_DOUBLE_DP :
 pas de convergence lors de la projection au sommet des cônes de traction et de compression
 --> utiliser le redécoupage automatique du pas de temps.
"""),

    94 : _("""
 intégration élastoplastique de loi BETON_DOUBLE_DP :
 pas de convergence lors de la résolution pour %(k1)s
 --> utiliser le redécoupage automatique du pas de temps.
"""),

    95 : _("""
 non convergence à la maille:  %(k1)s
"""),

    96 : _("""
 la saturation n'est pas une variable interne pour la loi de couplage  %(k1)s
"""),

    97 : _("""
 la pression de vapeur n'est pas une variable interne pour la loi de couplage  %(k1)s
"""),

    99 : _("""
 la variable  %(k1)s  n'existe pas dans la loi CJS en 2D
"""),

    100 : _("""
 Vous ne pouvez pas mélanger deux modélisations avec et sans dépendance
des paramètres matériau à la température (mots-clés ELAS, ELAS_FO).
"""),

}
