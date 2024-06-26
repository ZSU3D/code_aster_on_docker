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

    2 : _("""
 -------------------- PARAMÈTRES DE CHOC --------------------
 Informations sur les noeuds de choc
 lieu de choc   :  %(i1)d
 noeud de choc  :  %(k1)s
"""),

    3 : _("""
 sous-structure : %(k1)s
"""),

    4 : _("""
 coordonnées    : x :  %(r1)f
                  y :  %(r2)f
                  z :  %(r3)f
"""),

    5 : _("""
 noeud de choc  : %(k1)s
"""),

    8 : _("""
 amortissement tangent utilise :  %(r1)f

 origine choc x : %(r2)f
              y : %(r3)f
              z : %(r4)f

 NORM_OBST sin(alpha) : %(r5)f
           cos(alpha) : %(r6)f
           sin(bêta)  : %(r7)f
           cos(bêta)  : %(r8)f

 ANGL_VRILLE : sin(gamma) : %(r9)f
               cos(gamma) : %(r10)f
"""),

    9 : _("""
 jeu initial :  %(r1)f
 ----------------------------------------------------------
"""),

    10 : _("""
 <INFO> Pour l'occurrence numéro %(i1)d du mot-clé facteur CHOC, RIGI_TAN est
 renseigné mais pas AMOR_TAN. Le code a donc attribué à AMOR_TAN une valeur
 optimisée : %(r1)f
"""),

    14 : _("""
 pas de temps utilisateur trop grand :   %(r1)e
 pas de temps nécessaire pour le calcul: %(r2)e
 risques de problèmes de précision

"""),

    15 : _("""
 pas de temps utilisateur trop grand :   %(r1)e
 pas de temps nécessaire pour le calcul: %(r2)e
 paramètres de calcul dans ce cas
 nombre de pas de calcul :  %(i1)d

"""),

    16 : _("""
 pas de temps utilisateur trop grand   : %(r1)e
 pas de temps nécessaire pour le calcul: %(r2)e
"""),

    17 : _("""
 paramètres de calcul dans ce cas
 nombre de pas de calcul :  %(i1)d

"""),

    18 : _("""
 le nombre d'amortissements réduits est trop grand
 le nombre de modes propres vaut  %(i1)d
 et le nombre de coefficients :  %(i2)d
 on ne garde donc que les  %(i3)d
   %(k1)s

"""),

    19 : _("""
 le nombre d'amortissements réduits est insuffisant il en manque :  %(i1)d
 car le nombre de modes vaut :  %(i2)d
 on rajoute  %(i3)d
 amortissements réduits avec la valeur du dernier mode propre

"""),

    20 : _("""
 mode dynamique           :  %(i1)d
 amortissement trop grand :  %(r1)f
 amortissement critique   :  %(r2)f
 problèmes de convergence possibles %(k1)s

"""),


    21 : _("""
 taux de souplesse négligée : %(r1)f
"""),


    22 : _("""
 La matrice de masse fournie est singulière, un pivot nul a été détecté, au moins pour le mode numéro %(i1)d.
 Le calcul va poursuivre avec l'extrait diagonal de la matrice de masse. La dynamique associée aux modes
 sans masses sera artificiellement supprimée en imposant une valeur critique de l'amortissement.
"""),

    44 : _("""
 les interfaces de la liaison n'ont pas la même longueur
  sous-structure 1 -->  %(k1)s
  interface 1      -->  %(k2)s
  sous-structure 2 -->  %(k3)s
  interface 2      -->  %(k4)s

"""),

    45 : _("""
 conflit dans les VIS_A_VIS des noeuds le noeud  %(k1)s
 est le vis-à-vis des noeuds  %(k2)s
 et  %(k3)s

"""),

    46 : _("""
 Le critère de vérification ne peut être relatif dans votre cas,
 la longueur caractéristique de l'interface de la sous-structure étant nulle.
  sous-structure 1 -->  %(k1)s
  interface 1      -->  %(k2)s
  sous-structure 2 -->  %(k3)s
  interface 2      -->  %(k4)s

"""),

    47 : _("""
 les interfaces ne sont pas compatibles sous-structure 1 -->  %(k1)s
  interface 1      -->  %(k2)s
  sous-structure 2 -->  %(k3)s
  interface 2      -->  %(k4)s

"""),

    48 : _("""
 les interfaces ne sont pas compatibles sous-structure 1 -->  %(k1)s
  interface 1      -->  %(k2)s
  sous-structure 2 -->  %(k3)s
  interface 2      -->  %(k4)s

"""),


    50 : _("""
 les deux interfaces ont pas même nombre de noeuds
 nombre noeuds interface droite -->  %(i1)d
 nombre noeuds interface gauche -->  %(i2)d

"""),

    51 : _("""
 conflit dans les VIS_A_VIS des noeuds
 le noeud  %(k1)s
 est le vis-à-vis des noeuds  %(k2)s et  %(k3)s

"""),

    52 : _("""
 axe de symétrie cyclique différent de Oz
 numéro du couple de noeuds :  %(i1)d
 noeud droite -->  %(k1)s
 noeud gauche -->  %(k2)s

"""),

    53 : _("""
  problème de rayon droite gauche différents
  numéro du couple de noeuds :  %(i1)d
 noeud droite -->  %(k1)s
 noeud gauche -->  %(k2)s

"""),

    54 : _("""
 problème signe angle entre droite et gauche
 numéro du couple de noeuds:  %(i1)d
 noeud droite -->  %(k1)s
 noeud gauche -->  %(k2)s

"""),

    55 : _("""
 problème valeur angle répétitivité cyclique
 numéro du couple de noeuds:  %(i1)d
 noeud droite -->  %(k1)s
 noeud gauche -->  %(k2)s

"""),

    56 : _("""
  vérification répétitivité : aucune erreur détectée
"""),

    57 : _("""
 les noeuds des interfaces ne sont pas alignés en vis-à-vis
 les noeuds ont été réordonnés

"""),

    58 : _("""
  arrêt sur problème répétitivité cyclique
  tentative de diagnostic:  %(k1)s
"""),

    60 : _("""
 VISCOCHAB : erreur d'intégration
  - Essai d'intégration numéro :  %(i1)d
  - Convergence vers une solution non conforme,
  - Incrément de déformation cumulée négative = %(r1)f,
  - Changer la taille d'incrément.
"""),

    68 : _("""
 Arrêt par manque de temps CPU au numéro d'ordre %(i1)d

   - Temps moyen par incrément de temps : %(r1)f
   - Temps restant                      : %(r2)f

 La base globale est sauvegardée, elle contient les pas archivés avant l'arrêt

 """),

    72 : _("""
Erreur utilisateur :
  On veut déplacer "au quart" les noeuds milieux des arêtes près du fond de fissure
  (MODI_MAILLAGE / MODI_MAILLE / OPTION='NOEUD_QUART') pour obtenir des éléments de Barsoum.

  Mais on ne trouve aucun noeud à déplacer !

Risques & conseils :
  * Avez-vous vérifié que le maillage est "quadratique" ?
  * Si votre maillage est linéaire et que vous souhaitez une solution précise
    grâce aux éléments de Barsoum, vous devez au préalable utiliser la commande :
      CREA_MAILLAGE / LINE_QUAD  pour rendre le maillage quadratique.
 """),




    77 : _("""
   Arrêt par manque de temps CPU au numéro d'ordre : %(i1)d
     - Dernier instant archivé :      %(r1)f
     - Numéro d'ordre correspondant : %(i2)d
     - Temps moyen par pas de temps : %(r2)f
     - Temps restant     :            %(r3)f
  """),

    88 : _("""
   Arrêt par manque de temps CPU au pas de temps : %(i1)d
     - A l'instant  :                %(r1)f
     - Temps moyen par pas :         %(r2)f
     - Temps restant     :           %(r3)f
  """),

    89 : _("""
   On passe outre car VERI_PAS = NON
  """),




    97 : _("""
 Comportement unidirectionnel activé :
 Le coefficient de frottement est nul suivant l'axe X local.
 En repère global cet axe correspond à :  x :  %(r1)f
                                          y :  %(r2)f
                                          z :  %(r3)f
"""),




}
