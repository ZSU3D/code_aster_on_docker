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
  Erreur d'utilisation :
    Pour la méthodes itérative GCPC, on ne peut pas encore utiliser
    de matrice non-symétrique.

  Conseil : Changer de solveur
"""),

    2 : _("""
  Erreur d'utilisation :
    La matrice élémentaire %(k1)s n'est pas complète au sens MPI.
    La commande ASSE_MATRICE n'autorise pas cela.

  Conseil : Vous pouvez changer le mode de parallélisme dans AFFE_MODELE
  en choisissant METHODE='CENTRALISE'.
"""),

    3: _("""
 Le calcul est séquentiel, on ne peut donc pas utiliser MATR_DISTRIBUEE='OUI'.
 On force MATR_DISTRIBUEE='NON'.
"""),

    4: _("""
 L'utilisation de MATR_DISTRIBUEE='OUI' nécessite que chaque processeur ait
 au moins 1 degré de liberté qui lui soit alloué.
 Ici, le processeur %(i1)d ne s'est vu attribué aucun ddl.

 Conseil : Modifiez le partitionnement des mailles de votre modèle dans
           AFFE_MODELE/DISTRIBUTION/METHODE ou diminuez le nombre de processeurs.
"""),

    5 : _("""
 modèles discordants
"""),

    6 : _("""
 Il n'est pas possible de mélanger simple et double Lagrange.

 Conseil : Vérifiez le mot-clé DOUBLE_LAGRANGE de vos chargements issus d'AFFE_CHAR_MECA.
"""),





    8 : _("""
 le mot-clé %(k1)s  est incorrect.
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),


    11 : _("""
 on ne peut assembler que des vecteurs réels ou complexes
"""),




    13 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    14 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    15 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    16 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    18 : _("""
 Erreur développeur dans l'assemblage.
 Les vecteurs élémentaires ou les matrices élémentaires sont incohérentes: ils ne portent pas sur le même modèle ou ils ne calculent pas la même option.
"""),

    19 : _("""
 Erreur développeur dans l'assemblage.
 Les vecteurs élémentaires ou les matrices élémentaires ne contiennent ni sous-structures, ni objet LISTE_RESU.
"""),

    20 : _("""
  Erreur programmeur :
    lors d'un assemblage, dans la liste des MATR_ELEM (ou VECT_ELEM) que l'on veut
    assembler, on ne trouve aucun résultat élémentaire
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    21 : _("""
 modèles différents
"""),


    26 : _("""
 le noeud:  %(k1)s composante:  %(k2)s  est bloqué plusieurs fois.
"""),

    27 : _("""
 l'entier décrivant la position du premier Lagrange ne peut être égal qu'à +1 ou -1 .
"""),

    28 : _("""
 le nombre de noeuds effectivement numérotés ne correspond pas au nombre
 de noeuds à numéroter
"""),

    35 : _("""
 il n y a pas de modèle dans la liste  %(k1)s
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    36 : _("""
 noeud inexistant
"""),

    37 : _("""
 méthode :  %(k1)s  inconnue.
"""),

    38 : _("""
 noeud incorrect
"""),





    41 : _("""
 le noeud  %(i1)d  du  %(k1)s du VECT_ELEM  : %(k2)s  n'a pas d'adresse dans : %(k3)s
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    42 : _("""
 le noeud  : %(i1)d  du %(k1)s  du VECT_ELEM  : %(k2)s
   a une adresse  : %(i2)d  supérieur au nombre d'équations : %(i3)d
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    43 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    44 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    45 : _("""
Erreur Programmeur ou utilisateur :
-----------------------------------
 Le LIGREL    %(k1)s  référencé par le noeud supplémentaire %(i1)d
 de la maille %(i2)d  du  %(k2)s  du VECT_ELEM : %(k3)s
 n'est pas présent  dans le NUME_DDL : %(k4)s

Risques & conseils :
--------------------
 Si vous utilisez la commande MACRO_ELAS_MULT :
   Si %(k5)s est une charge contenant des conditions aux limites dualisées (DDL_IMPO, ...),
   Êtes-vous sur d'avoir indiqué cette charge derrière le mot clé CHAR_MECA_GLOBAL ?
   En effet, il faut indiquer TOUTES les charges dualisées derrière CHAR_MECA_GLOBAL.

 Si vous utilisez directement la commande ASSE_VECTEUR :
   Si %(k5)s est une charge contenant des conditions aux limites dualisées (DDL_IMPO, ...),
   Êtes-vous sur d'avoir indiqué cette charge derrière le mot clé CHARGE
   de la commande CALC_MATR_ELEM/OPTION='RIGI_MECA' ?
"""),

    46 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    47 : _("""
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    48 : _("""
 --- le noeud  : %(i1)d  du  %(k1)s  du VECT_ELEM   : %(k2)s
 --- n'a pas d''adresse  dans la numérotation : %(k3)s
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    49 : _("""
 --- le noeud  : %(i1)d  du  %(k1)s  du VECT_ELEM   : %(k2)s
 --- a une adresse : %(i2)d  supérieur au nombre d'équations : %(i3)d
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    63 : _("""
 erreur sur le premier Lagrange d'une LIAISON_DDL
 on a mis 2 fois le premier  Lagrange :  %(i1)d
 derrière le noeud :  %(i2)d
"""),

    64 : _("""
 erreur sur le  2ème Lagrange d'une LIAISON_DDL
 on a mis 2 fois le 2ème  Lagrange :  %(i1)d
 derrière le noeud :  %(i2)d
"""),

    65 : _("""
 incohérence dans le dénombrement des ddls
 nombre de ddl a priori    : %(i1)d
 nombre de ddl a posteriori: %(i2)d
"""),

}
