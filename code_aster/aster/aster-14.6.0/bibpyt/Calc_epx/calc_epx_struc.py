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
Structure de données pour stockage et écriture des informations traduites
"""
from Calc_epx.calc_epx_utils import tolist
#------------------------------------------------------------------------
#------------------------------------------------------------------------


class DIRECTIVE:

    """
        Objet permettant le stockage et l'écriture des informations
        nécessaires pour construire le fichier de commande EPX pour
        une directive donnée.
    """

    def __init__(self, nom, titre, type_dir=2):
        """
            Initialisation d'une directive, type 2 par défaut.
        """
        self.nom = nom
        # if not titre.startswith('*') : titre = '*'+titre
        self.titre = titre
        self.ldata = False
        self.mots_cles_simples = []
        self.liste_noms_mcfact = []
        self.mots_cles_facteurs = []
        self.fonction = None
        self.type_dir = type_dir
        self.info_dir = None

#------------------------------------------------------------------------
    def get_mcfact(self, nom_mc):
        """
            Renvoie l'objet correspondant au mot-clé facteur nom_mc s'il
            existe sinon False.
        """
        if self.type_dir != 2:
            raise Exception(
                'Pas de mot-clé facteur pour les directives autres que de type 2')
        if nom_mc in self.liste_noms_mcfact:
            ind = self.liste_noms_mcfact.index(nom_mc)
            exi = self.mots_cles_facteurs[ind]
        else:
            exi = False
        return exi
#------------------------------------------------------------------------

    def add_mcfact(self, nom_mc):
        """
            Ajoute d'un mot-clé facteur à la directive et renvoie l'objet
            de type MCFACT créé.
        """
        if self.get_mcfact(nom_mc):
            raise Exception('Mot clé facteur déjà présent')
        self.liste_noms_mcfact.append(nom_mc)
        self.mots_cles_facteurs.append(MCFACT(nom_mc))
        self.ldata = True
        return self.mots_cles_facteurs[-1]
#------------------------------------------------------------------------

    def add_bloc(self, bloc):
        """
            Ajoute un bloc de données à la directive en vérifiant qu'il n'y a
            pas de bloc dejà présent ayant le même attribut "mot_cle".
        """
        # EC : ajouter une verif sur le type
        if self.type_dir == 1:
            mot_cle = bloc.mot_cle
            for bloc_present in self.mots_cles_simples:
                mot_cle1 = bloc_present.mot_cle
                if mot_cle == mot_cle1:
                    raise Exception(
                        "Mot clé %s déjà présent dans l'objet DIRECTIVE de type 1"
                        % mot_cle)
        self.ldata = True
        self.mots_cles_simples.append(bloc)
#------------------------------------------------------------------------

    def add_void(self,):
        """
        Ajout de rien mais permet de considérer qu'il y a des données
        dans la directive, ce qui active la méthode write().
        """
        if self.type_dir == 2:
            self.ldata = True
        else:
            raise Exception(
                "la méthode add_void n'est permise que pour les directive de type 2")
#------------------------------------------------------------------------

    def add_info_dir(self, info):
        """
            Ajout d'une info à côté du nom de la directive
        """
        if type(info) != str and type(info) != int and type(info) != float:
            raise Exception('Type non accepté')
        self.info_dir = info
#------------------------------------------------------------------------

    def len_mcs(self,):
        """
            Récuperation de la longueur de self.mots_cles_simples.
        """
        return len(self.mots_cles_simples)
#-----------------------------------------------------------------------

    def write(self,):
        """
            Ecriture de la directive.
        """
        liste_ligne = []
        if self.ldata:
            liste_ligne.append('*--' + self.titre)
            if self.type_dir != 0:
                if self.info_dir is None:
                    liste_ligne.append(self.nom)
                else:
                    liste_ligne.append(self.nom + " %s" % (self.info_dir))
                decal = 4
            else:
                decal = 0

            for bloc in self.mots_cles_simples:
                liste_ligne.extend(bloc.write(decal))
            if self.fonction is not None:
                raise Exception(
                    "DIRECTIVE.write : décommenter l'impression des fonctions")
                # a decommenter si cela existe
                # li_resu.append(obj_directive.fonction.write(decal))

            for ifact, mfac in enumerate(self.mots_cles_facteurs):
                if mfac.nom != self.liste_noms_mcfact[ifact]:
                    raise Exception("Erreur de nom des mots-clés facteurs")
                liste_ligne.extend(mfac.write(decal))
            if self.type_dir == 1:
                liste_ligne.append("TERM")
            liste_ligne.append("\n")
        return liste_ligne
#------------------------------------------------------------------------
#------------------------------------------------------------------------


class MCFACT:

    """
        Objet mot-clé facteur pour les objets de type DIRECTIVE.
    """

    def __init__(self, nom):
        """
            Initialisation
        """

        self.nom = nom
        # self.fonction = None
        self.mots_cles_simples = []
#------------------------------------------------------------------------

    def add_bloc(self, bloc):
        """
            Ajoute un bloc de données.
        """
        self.mots_cles_simples.append(bloc)
#------------------------------------------------------------------------

    def write(self, decal):
        """
            Ecriture de l'objet.
        """
        liste_ligne = []
        liste_ligne.append(decal * ' ' + self.nom)
        decal += 4
        for bloc in self.mots_cles_simples:
            liste_ligne.extend(bloc.write(decal))
        # fonction
        # if self.fonction is not None:
            # liste_ligne.extend(self.fonction.write(decal))
        return liste_ligne
#------------------------------------------------------------------------
#------------------------------------------------------------------------


class FONCTION:

    """
        Objet permettant de stocker et écrire les données associées à
        une fonction.
    """

    def __init__(self, cle_fonc, temps, valeurs, nom_aster=None):
        """
            Initialisation
        """
        self.cle = cle_fonc
        self.temps = temps
        self.valeurs = valeurs
        if type(nom_aster) != str and nom_aster is not None:
            print(type(nom_aster))
            raise Exception(
                "Le nom aster d'une fonction doit être de type str")
        self.nom_aster = nom_aster
#------------------------------------------------------------------------

    def write(self, decal):
        """
            Ecriture de la fonction.
        """
        liste_ligne = []
        decal2 = 4
        if self.nom_aster is not None:
            liste_ligne.append('*' + decal * '-' + 'NOM DE LA FONCTION ASTER : '
                               + self.nom_aster)
        liste_ligne.append(decal * ' ' + self.cle + ' %s' % (len(self.temps)))
        for ival in range(len(self.temps)):
            liste_ligne.append((decal + decal2) * ' ' + '%s %s'
                               % (self.temps[ival], self.valeurs[ival]))
        return liste_ligne
#------------------------------------------------------------------------
#
#------------------------------------------------------------------------
#                                BLOC_DONNEES
#------------------------------------------------------------------------
# description du format :
# -----------------------
# mot_cle cle val_cle
#   cara[0] vale[0]
#   cara[1] vale[1]
#   lect
#     l_group[0]
#     l_group[1]
#   term
# -----------------------


class BLOC_DONNEES:

    """
        Bloc de données complet pour EPX.

        Description du format d'impression :
        -----------------------
        - si lect_term == 'fin'
        -----------------------
        * titre du bloc si présent
        mot_cle cle val_cle
          cara[0] vale[0]
          cara[1] vale[1]
          lect
            l_group[0]
            l_group[1]
          term
        -----------------------
        - si lect_term == 'debut'
        -----------------------
        * titre du bloc si présent
        mot_cle cle val_cle
          lect
            l_group[0]
            l_group[1]
          term
          cara[0] vale[0]
          cara[1] vale[1]
        -----------------------
    """

    def __init__(self, mot_cle, l_group=None, cle='', val_cle='', cara=[],
                 vale=[], titre=None, lect_term='fin', cle_l_group='LECT',
                 dispo_group='verti'):
        """
            Création de l'objet.
            Seul mot_cle est obligatoire.
        """

        if type(mot_cle) != str:
            raise Exception("BLOC_DONNEES : 1er arg doit être de type string.")
        elif mot_cle.strip() == '':
            raise Exception("BLOC_DONNEES : 1er arg de doit pas être '' .")
        if l_group is not None:
            l_group = tolist(l_group)
            if len(l_group) == 0:
                l_group = None
        cara = tolist(cara)
        vale = tolist(vale)
        if len(vale) != 0 and len(cara) != len(vale):
            raise Exception("BLOC_DONNEES : len(cara)!=len(vale)")
        self.groupes = l_group
        self.mot_cle = mot_cle
        self.cle = cle
        self.val_cle = val_cle
        self.cara = cara
        self.vale = vale
        self.titre = titre
        self.cle_groupes = cle_l_group
        if lect_term != 'fin' and lect_term != 'debut':
            raise Exception('lect_term doit etre egal à debut ou fin')
        self.lect_term = lect_term
        if dispo_group != 'verti' and dispo_group != 'hori':
            raise Exception('dispo_group doit etre egal à verti ou hori')
        self.dispo_group = dispo_group
        
        self.lenmax = 80

#------------------------------------------------------------------------
    def write(self, decal):
        """
            Ecriture du bloc de données
        """
        liste_ligne = []
        decal2 = 4
        decal3 = 2
        if self.titre:
            liste_ligne.append('*' + decal * '-' + self.titre)
        liste_ligne.append(decal * ' ' + self.mot_cle + ' %s %s'
                           % (self.cle, self.val_cle))

        if self.lect_term == 'fin':
            
            lignes_cara = self.write_cara_val(decal, decal3)
            liste_ligne.extend(lignes_cara)
            
            lignes_groupes = self.write_groupes(decal, decal2, decal3)
            liste_ligne.extend(lignes_groupes)
        else:
            lignes_groupes = self.write_groupes(decal, decal2, decal3)
            liste_ligne.extend(lignes_groupes)
            
            lignes_cara = self.write_cara_val(decal, decal3)
            liste_ligne.extend(lignes_cara)
        return liste_ligne
#------------------------------------------------------------------------    
    def write_cara_val(self, decal, decal3):
        """
            Ecriture des caracteristiques du bloc
        """
        lignes_cara = []
        for i, car in enumerate(self.cara):
            if len(self.vale) != 0:
                lignes_cara.append((decal + decal3) * ' ' + '%s %s'
                                   % (car, self.vale[i]))
            else:
                lignes_cara.append((decal + decal3) * ' ' + '%s' % (car,))
        return lignes_cara
#------------------------------------------------------------------------
    def write_groupes(self, decal, decal2, decal3):
        """
            Ecriture des groupes du bloc
        """
        lignes_groupes = []
        if self.groupes is not None:
            if self.dispo_group == 'verti':
                lignes_groupes.append((decal + decal3) * ' ' + self.cle_groupes)
                for gr in self.groupes:
                    lignes_groupes.append((decal + decal3 + decal2) * ' ' + '%s'
                                       % (str(gr).strip()))
                lignes_groupes.append((decal + decal3) * ' ' + 'TERM')
            else:
                
                ligne = (decal + decal3) * ' ' + self.cle_groupes
                for gr in self.groupes:
                    grs = str(gr).strip()
                    l = len(grs)
                    l_ligne = len(ligne)
                    if (l + l_ligne + 1) > self.lenmax:
                        lignes_groupes.append(ligne)
                        ligne = (decal + decal3 + len(self.cle_groupes)) * ' '
                        ligne += ' %s'%grs
                    else:
                        ligne+= ' %s'%grs
                l = len('TERM')
                l_ligne = len(ligne)
                if (l + l_ligne + 1) > self.lenmax:
                    lignes_groupes.append(ligne)
                    ligne = (decal + decal3) * ' ' + 'TERM'
                else:
                    ligne+=' TERM'
                lignes_groupes.append(ligne)
        return lignes_groupes
#------------------------------------------------------------------------
#
#------------------------------------------------------------------------
#                                BLOC_DONNEES_SUP
#------------------------------------------------------------------------


class BLOC_DONNEES_SUP:

    """
        Conteneur de BLOC_DONNEES

        Description du format :
        -----------------------
        mot_cle cle val_cle
          BLOC_DONNEES[0]
          BLOC_DONNEES[1]
        -----------------------
    """

    def __init__(self, mot_cle, l_BD, cle='', val_cle='', titre=None):
        """
            Création de l'objet
        """

        l_BD = tolist(l_BD)
        if len(l_BD) == 0:
            raise Exception("BLOC_DONNEES_SUP : liste de BLOC_DONNEES vide")
        self.mot_cle = mot_cle
        self.cle = cle
        self.val_cle = val_cle
        self.l_BD = l_BD
        self.titre = titre
#------------------------------------------------------------------------

    def write(self, decal):
        """
            Ecriture
        """
        liste_ligne = []
        decal2 = 4
        if self.titre:
            liste_ligne.append('*' + decal * '-' + self.titre)
        liste_ligne.append(decal * ' ' + self.mot_cle + ' %s %s'
                           % (self.cle, self.val_cle))
        for bloc in self.l_BD:
            liste_ligne.extend(bloc.write(decal + decal2))
        return liste_ligne
#------------------------------------------------------------------------
#
#------------------------------------------------------------------------
#                                BLOC_MATE
#------------------------------------------------------------------------


class BLOC_MATE:

    """
        Bloc complexe pour la gestion des matériaux.
        Structure mise en place à cause de GLRC_DAMAGE.
        -----------------------------------------------
        Description du format : si cle_bs == cara[i]
        -----------------------
        * titre
        mot_cle_mate
          cara[0] vale[0]
          cara[1] vale[1]
                ...
          cara[i] vale[i]
          -> impression des blocs de données BLOC_DONNEES
                ...
          cara[n] vale[n]
          lect
            l_group[0]
            l_group[1]
          term
        -----------------------
        Remarque; ordre_para contient la liste des caractéristiques ordonnées
        (comme cara mais avec un ordre différent). S'il est renseigné cara et
        vale seront imprimés selon cet ordre.
    """

    def __init__(self, mot_cle, l_group, cara=[], vale=[], cle_bs=None,
                 l_bs=[], ordre_para=None, titre=None):
        """
            Création de l'objet
        """
        l_group = tolist(l_group)
        if len(l_group) == 0:
            raise Exception('BLOC_MATE : l_group est vide')
        if len(cara) != len(vale):
            raise Exception("BLOC_MATE : len(cara)!= len(vale)")
        self.groupes = l_group
        self.mot_cle = mot_cle
        self.cara = cara
        self.vale = vale
        if cle_bs and len(l_bs) == 0:
            raise Exception(
                'l_bs ne doit pas être de longueur nulle si cle_bs')
        if cle_bs is None and len(l_bs) > 0:
            raise Exception('l_bs est présent, il faut renseigner cle_bs')
        if cle_bs and not ordre_para:
            raise Exception('renseignez ordre_para si vous donnez cle_bs')
        self.cle_bs = cle_bs
        self.l_bs = l_bs
        self.ordre_para = ordre_para
        self.titre = titre

#------------------------------------------------------------------------
    # ecriture du bloc de données
    def write(self, decal):
        liste_ligne = []
        decal2 = 4
        decal3 = 2
        if self.titre:
            liste_ligne.append('*' + decal * '-' + self.titre)
        liste_ligne.append(decal * ' ' + self.mot_cle)
        if self.ordre_para:
            for car in self.ordre_para:
                if car == self.cle_bs:
                    val = len(self.l_bs)
                else:
                    if car in self.cara:
                        i = self.cara.index(car)
                    else:
                        continue
                    val = self.vale[i]
                line = wr_line_cara(decal + decal3, car, val)
                liste_ligne.append(line)
                if car == self.cle_bs:
                    for bs in self.l_bs:
                        lignes = bs.write(decal + decal3)
                        liste_ligne.extend(lignes)
        else:
            for i, car in enumerate(self.cara):
                line = wr_line_cara(decal + decal3, car, self.vale[i])
                liste_ligne.append(line)

        liste_ligne.append((decal + decal3) * ' ' + 'LECT')
        for gr in self.groupes:
            liste_ligne.append(
                (decal + decal3 + decal2) * ' ' + '%s' % gr.strip())
        liste_ligne.append((decal + decal3) * ' ' + 'TERM')

        return liste_ligne
#------------------------------------------------------------------------
#------------------------------------------------------------------------


def wr_line_cara(decal, car, val):
    """
    Ecrit une ligne de type "caractérique" "valeur".
    """
    if type(val) is not list:
        line = decal * ' ' + '%s %s' % (car, val)
    else:
        line = decal * ' ' + '%s' % (car)
        for v in val:
            line += ' %s' % v
    return line
