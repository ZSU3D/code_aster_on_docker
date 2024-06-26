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
 La grandeur fournie : %(k1)s ne figure pas dans le catalogue des grandeurs
"""),

    2 : _("""
 Erreur utilisateur (CREA_CHAMP/AFFE) :
   Le type du champ que l'on cherche à créer (réel, entier, complexe, fonction)
   n'est pas compatible avec le mot clé utilisé (VALE, VALE_I, VALE_C, VALE_F).

 Il faut respecter la correspondance suivante :
    - champ réel        -> VALE
    - champ complexe    -> VALE_C
    - champ entier      -> VALE_I
    - champ fonction    -> VALE_F
"""),

    3 : _("""
 la liste de composantes et la liste des valeurs n'ont pas la même dimension
 occurrence de AFFE numéro  %(i1)d
"""),

    4 : _("""
 une composante n'appartient pas à la grandeur
 occurrence de AFFE numéro  %(i1)d
 grandeur   :  %(k1)s
 composante :  %(k2)s
"""),

    5 : _("""
 le NUME_DDL en entrée ne s'appuie pas sur la même grandeur que celle de la commande
 grandeur associée au NUME_DDL : %(k1)s
 grandeur de la commande       :  %(k2)s
"""),

    11 : _("""
 une composante n'appartient pas à la grandeur
 grandeur   :  %(k1)s
 composante :  %(k2)s
"""),

    12 : _("""
 variable inconnue:  %(k1)s  pour le résultat :  %(k2)s
"""),

    13 : _("""
 problème rencontré lors de la recherche de la variable :  %(k1)s
         DEBUT :  %(k2)s
           fin :  %(k3)s
"""),

    15 : _("""
 interpolation log impossible : présence d'une valeur négative ou nulle
 valeur à interpoler : %(r1)f
 borne inférieure    : %(r2)f
 borne supérieure    : %(r3)f
"""),

    16 : _("""
 interpolation impossible
 instant à interpoler:  %(r1)f
"""),

    17 : _("""
 interpolation impossible
 instant à interpoler:  %(r1)f
 borne inférieure    :  %(r2)f
"""),

    18 : _("""
 interpolation impossible
 instant à interpoler:  %(r1)f
 borne supérieure    : %(r2)f
"""),

    37 : _("""
 la fonction  %(k1)s  a  %(i1)d arguments
 le maximum exploitable est  %(i2)d
"""),

    44 : _("""
 trop d'amortissements modaux
 nombre d'amortissements :  %(i1)d
 nombre de modes         :  %(i2)d
"""),

    48 : _("""
 méthode de Newton
 exposant de la loi  = %(r1)f
 nombre d'itérations = %(i1)d
 résidu fonction = %(r2)f
 résidu = %(r3)f
 précision = %(r4)f
"""),

    51 : _("""
 pas de champ correspondant à l'instant demandé.
 résultat  %(k1)s
 accès "INST_INIT" : %(r1)f
"""),

    52 : _("""
 plusieurs champs correspondant à l'instant demandé
 résultat  %(k1)s
 accès "INST_INIT" : %(r1)f
 nombre : %(i1)d
"""),

    53 : _("""
 le premier instant de rupture n'est pas dans la liste des instants de calcul
 premier instant de rupture =  %(r1)f
 premier instant de calcul  =  %(r2)f
"""),

    54 : _("""
 le dernier instant de rupture n'est pas dans la liste des instants de calcul
 dernier instant de rupture =  %(r1)f
 dernier instant de calcul  =  %(r2)f
"""),

    55 : _("""
 paramètres initiaux de WEIBULL
 exposant de la loi      = %(r1)f
 volume de référence     = %(r2)f
 contrainte de référence = %(r3)f
"""),

    56 : _("""
 statistiques recalage :
 nombre d'itérations  = %(i1)d
 convergence atteinte = %(r1)f
"""),

    59 : _("""
 La définition des paramètres du comportement %(k1)s n'a pas été trouvée
 dans le champ de matériau %(k2)s
"""),


    60 : _("""
 homogénéité du champ de matériaux pour WEIBULL
 nombre de RC WEIBULL trouvées =  %(i1)d
 les calculs sont valables pour  un seul comportement WEIBULL %(k1)s
 on choisit la première relation du type WEIBULL %(k2)s
"""),

    61 : _("""
 paramètres de la RC WEIBULL_FO
 exposant de la loi      = %(r1)f
 volume de référence     = %(r2)f
 contrainte de référence conventionnelle = %(r3)f
"""),

    62 : _("""
 paramètres de la RC WEIBULL
 exposant de la loi      = %(r1)f
 volume de référence     = %(r2)f
 contrainte de référence = %(r3)f
"""),




    72 : _("""
 trop de mailles dans le GROUP_MA
 maille utilisée:  %(k1)s
"""),

    77 : _("""
Concept résultat %(k1)s :
le numéro d'ordre %(i1)d est inconnu.
"""),

    78 : _("""
Concept résultat %(k1)s :
le numéro d'archivage %(i1)d est supérieur au max %(i2)d.
"""),

    79 : _("""
Concept résultat %(k1)s :
le numéro de rangement %(i1)d est supérieur au max %(i2)d.
"""),

    80 : _("""
Concept résultat %(k1)s :
la variable %(k2)s est inconnue pour le type %(k3)s.
"""),

    84 : _("""
 le "NOM_PARA_RESU"  %(k1)s n'est pas un paramètre du résultat  %(k2)s
"""),

    89 : _("""
 erreur dans les données
 le paramètre  %(k1)s n'existe pas
"""),

    93 : _("""
 le paramètre  %(k1)s n'existe pas dans la table %(k2)s
 il est nécessaire
 veuillez consulter la documentation de la commande
"""),

    99 : _("""
 erreur dans les données
 paramètre :  %(k1)s
 plusieurs valeurs trouvées
 pour le paramètre : %(k3)s
 et le paramètre   : %(k4)s
"""),

}
