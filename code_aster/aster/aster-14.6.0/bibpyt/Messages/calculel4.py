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

#

cata_msg = {

    1 : _("""
 Erreur utilisateur :
   Le CHAM_ELEM %(k1)s a des valeurs indéfinies.
 Conseils :
   * Si le problème concerne la commande CREA_CHAMP :
     1) Vous devriez imprimer le contenu du champ créé pour vérifications (INFO=2) ;
     2) Vous devriez peut-être utiliser le mot clé PROL_ZERO='OUI' .
"""),

    2 : _("""
CALC_CHAMP :
 Vous demandez le calcul du champ %(k1)s aux noeuds.
 Votre modèle contient des éléments de structure, il est recommandé de donner le CARA_ELEM.
"""),

    4 : _("""
Erreur :
  On cherche à modifier le "type" (réel(R), complexe(C), entier(I), fonction(K8)) d'un champ.
  C'est impossible.
  Types incriminés : %(k1)s et %(k2)s
Conseils :
  Il s'agit peut-être d'une erreur de programmation.
  S'il s'agit de la commande CREA_CHAMP, vérifiez le mot clé TYPE_CHAM.

"""),

    6 : _("""
Erreur utilisateur (ou programmeur) :
 On veut imposer la numérotation des ddls du CHAM_NO %(k1)s
 avec le NUME_DDL %(k2)s.
 Mais ces deux structures de données sont incompatibles.
 Par exemple :
    - ce n'est pas le même maillage sous-jacent
    - ce n'est pas la même grandeur sous-jacente.
"""),


    8 : _("""
 Le résultat %(k1)s n'existe pas.
"""),

    9 : _("""
Problème lors de la projection d'un champ aux noeuds de la grandeur (%(k1)s) sur un autre maillage.
 Pour le noeud "2" %(k2)s (et pour la composante %(k3)s) la somme des coefficients de pondération
 des noeuds de la maille "1" en vis à vis est très faible (inférieure à 1.e-3).

 Cela peut arriver par exemple quand le champ à projeter ne porte pas la composante sur
 tous les noeuds de la maille "1" et que le noeud "2"  sur lequel on cherche à projeter
 se trouve tout près d'un noeud "1" qui ne porte pas la composante.
 Quand cela arrive, la projection est imprécise sur le noeud.

Risques et conseils :
 Si le champ à projeter a des composantes qui n'existent que sur les noeuds sommets des éléments,
 on peut faire une double projection en passant par un maillage intermédiaire linéaire.
"""),




    14 : _("""
 Erreur d'utilisation de la commande CREA_RESU / PREP_VRC[1|2] :
    Le CARA_ELEM (%(k1)s) ne contient pas d'éléments à "couches"
 Il n'y a aucune raison d'utiliser l'option PREP_VRC[1|2]
"""),

    15 : _("""
 Erreur d'utilisation (CREA_RESU/PREP_VRC.) :
   Le modèle associé au CARA_ELEM (%(k1)s) est différent de celui fourni à la commande.
"""),

    16 : _("""
 Erreur d'utilisation :
   L'option %(k1)s est nécessaire pour le calcul de l'option %(k2)s.
   Or %(k1)s est un champ qui ne contient que des sous-points, ce cas n'est pas traité.
   Vous devez d'abord extraire %(k1)s sur un sous-point avec la commande POST_CHAMP.
"""),

    17 : _("""
 Erreur d'utilisation :
   Le mot-clé VIS_A_VIS de la commande PROJ_CHAMP est interdit si
   la méthode de projection est 'ECLA_PG'.
"""),










    21 : _("""
 Erreur utilisateur :
   La commande CREA_RESU / ASSE concatène des structures de données résultat.
   Mais il faut que les instants consécutifs soient croissants (en tenant compte de TRANSLATION).
   Ce n'est pas le cas ici pour les instants : %(r1)f  et %(r2)f
"""),

    22 : _("""
 Information utilisateur :
   La commande CREA_RESU / ASSE concatène des structures de données résultat.
   Mais il faut que les instants consécutifs soient croissants (en tenant compte de TRANSLATION).
   Ici, l'instant %(r1)f  est affecté plusieurs fois.
   Pour cet instant, les champs sont écrasés.
"""),

    23 : _("""
 Erreur utilisateur :
   Incohérence du MODELE et du CHAM_MATER :
     Le MODELE de calcul est associé au maillage %(k1)s
     Le CHAM_MATER de calcul est associé au maillage %(k2)s
"""),

    24 : _("""
 Alarme utilisateur :
   IMPR_RESU / CONCEPT / FORMAT='MED'
     Le format MED n'accepte pas plus de 80 composantes pour un champ.
     Le champ %(k1)s ayant plus de 80 composantes, on n'imprime
     que les 80 premières.
"""),

    25 : _("""
 Erreur utilisateur (variables de commandes) :
   Le champ %(k1)s est associé à un LIGREL %(k2)s qui n'est pas celui du calcul %(k3)s
"""),

    26 : _("""
 Erreur utilisateur (variables de commandes) :
   Le champ %(k1)s est associé à une OPTION %(k2)s qui n'est pas 'INIT_VARC'
   Ce champ n'a sans doute pas été produit par PROJ_CHAMP / METHODE='SOUS_POINT'
"""),








    43 : _("""
 le NOM_PARA n'existe pas
"""),

    44 : _("""
Aucune ligne trouvée pour le NOM_PARA
"""),

    45 : _("""
 plusieurs lignes trouvées
"""),

    46 : _("""
 code retour de inconnu
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    47 : _("""
 TYPE_RESU inconnu:  %(k1)s
"""),

    53 : _("""
 longueurs des modes locaux incompatibles entre eux.
"""),

    54 : _("""
 aucuns noeud sur lesquels projeter.
"""),

    55 : _("""
 Pas de mailles à projeter ou en correspondance.

 Dans le cas de l'utilisation de AFFE_CHAR_MECA / LIAISON_MAIL, les mailles maîtres
 doivent avoir la même dimension que l'espace de modélisation :
 - mailles volumiques pour un modèle 3D
 - mailles surfaciques pour un modèle 2D
"""),

    56 : _("""
  %(k1)s  pas trouvé.
"""),

    57 : _("""
 Aucune des mailles du maillage 1 fournies ne permet d'effectuer la projection souhaitée.    
 
 Conseil :
    Vérifiez que les mailles fournies ne sont pas toutes ponctuelles (POI1).
"""),

    58 : _("""
 les maillages a projeter sont ponctuels.
"""),

    59 : _("""
Erreur utilisateur :
 Les maillages associés aux concepts %(k1)s et %(k2)s sont différents : %(k3)s et %(k4)s.
"""),

    60 : _("""
 maillages 2 différents.
"""),

    61 : _("""
 problème dans l'examen de  %(k1)s
"""),

    62 : _("""
 aucun numéro d'ordre dans  %(k1)s
"""),

    63 : _("""
 On n'a pas pu projeter le champ %(k1)s de la SD_RESULTAT %(k2)s
 vers la SD_RESULTAT %(k3)s pour le numéro d'ordre %(i1)d
"""),

    64 : _("""
 Aucun champ projeté.
"""),

    65 : _("""
  maillages non identiques :  %(k1)s  et  %(k2)s
"""),

    66 : _("""
 pas de champ de matériau
"""),

    67 : _("""
 erreur pour le problème primal
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    68 : _("""
 erreur pour le problème dual
Ce message est un message d'erreur développeur.
Contactez le support technique.
"""),

    69 : _("""
Erreur utilisateur dans la commande CREA_CHAMP :
 Le mot clé NUME_DDL (%(k1)s) est associé au maillage (%(k2)s).
 Il est incompatible avec le mot clé MAILLAGE (%(k3)s).
"""),

    70 : _("""
Erreur utilisateur dans CREA_CHAMP :
  Vous avez demandé la création d'un champ '%(k1)s' (mot clé TYPE_CHAM)
  Mais le code a créé un champ '%(k2)s'.
Conseil :
  Il faut sans doute modifier la valeur de TYPE_CHAM
"""),

    71 : _("""
Erreur utilisateur dans CREA_CHAMP :
  Vous avez demandé la création d'un champ de %(k1)s (mot clé TYPE_CHAM)
  Mais le code a créé un champ de %(k2)s.
Conseil :
  Il faut sans doute modifier la valeur de TYPE_CHAM
"""),

    72 : _("""
Erreur utilisateur dans la commande PROJ_CHAMP :
 Le mot clé MODELE_2 a été utilisé. Le maillage associé à ce modèle (%(k1)s)
 est différent du maillage "2" (%(k1)s)  qui a servi à fabriquer la matrice de projection.
"""),

    73 : _("""
Erreur utilisateur dans la commande PROJ_CHAMP :
   On veut projeter des champs aux éléments (CHAM_ELEM), le mot clé MODELE_2
   est alors obligatoire.
"""),

    74 : _("""
Alarme utilisateur dans la commande CALC_CHAMP / REAC_NODA + GROUP_MA:
   La maille %(k2)s du modèle %(k1)s ne fait pas partie des mailles
   désignées par le mot clé GROUP_MA.
   Pourtant, elle semble être une maille de bord de l'une de ces mailles.

Risques et conseils :
   Le calcul des réactions d'appui est faux si cette maille est affectée
   par un chargement en "force" non nul.
"""),

    75 : _("""
Erreur utilisateur dans la commande PROJ_CHAMP :
  Le programme ne trouve aucun champ à projeter dans %(k1)s.

Conseils :
  Les champs dont vous demandez la projection (mot clé NOM_CHAM)
  ont-ils été calculés ?
"""),


    78 : _("""
Erreur utilisateur dans CREA_CHAMP :
  Le maillage associé au champ créé par la commande (%(k1)s) est différent
  de celui qui est fourni par l'utilisateur via les mots clés MAILLAGE ou MODELE (%(k2)s).
Conseil :
  Il faut vérifier les mots clés MAILLAGE ou MODELE.
  Remarque : ces mots clés sont peut être inutiles pour cette utilisation de CREA_CHAMP.
"""),

    80 : _("""
 le nom de la grandeur  %(k1)s  ne respecte pas le format XXXX_c
"""),

    81 : _("""
 problème dans le catalogue des grandeurs simples, la grandeur complexe %(k1)s
 ne possède pas le même nombre de composantes que son homologue réelle %(k2)s
"""),

    82 : _("""
 Problème dans le catalogue des grandeurs simples, la grandeur %(k1)s
 ne possède pas les mêmes champs que son homologue réelle %(k2)s
"""),

    83 : _("""
 erreur: le calcul des contraintes ne fonctionne que pour le phénomène mécanique
"""),

    84 : _("""
 erreur numéros des noeuds bords
"""),

    85 : _("""
 erreur: les éléments supportes sont tria3 ou tria6
"""),

    86 : _("""
 erreur: les éléments supportes sont QUAD4 ou QUAD8 ou QUAD9
"""),

    87 : _("""
 maillage mixte TRIA-QUAD non supporte pour l estimateur ZZ2
"""),

    88 : _("""
 erreur: les mailles supportées sont tria ou QUAD
"""),

    89 : _("""
 Erreur: un élément du maillage possède tous ses sommets sur une frontière.
 Il faut au moins un sommet interne.
 Pour pouvoir utiliser ZZ2 il faut remailler le coin de telle façon que
 tous les triangles aient au moins un sommet intérieur.
"""),


    92 : _("""
  relation :  %(k1)s  non implantée sur les poulies
"""),

    93 : _("""
  déformation :  %(k1)s  non implantée sur les poulies
"""),

    98 : _("""
 on n'a pas pu récupérer le paramètre THETA dans le résultat  %(k1)s
 valeur prise pour THETA: 0.57
"""),

}
