# coding=utf-8
# --------------------------------------------------------------------
# Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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

# person_in_charge: albert.alarcon at edf.fr


def assemblage_ops(
    self, MODELE, CHAM_MATER, CARA_ELEM, CHARGE, MATR_ASSE, VECT_ASSE,
          NUME_DDL, CHAR_CINE, INST, INFO, **args):
#  """
#     Ecriture de la macro MACRO_ASSE
#  """

    ier = 0
    from Utilitai.Utmess import UTMESS

    # On met le mot cle NUME_DDL dans une variable locale pour le proteger
    numeddl = NUME_DDL
    info = INFO
    # On importe la definition de la commande
    # Le nom de la variable doit etre obligatoirement le nom de la commande
    NUME_DDL = self.get_cmd('NUME_DDL')

    # La macro compte pour 1 dans la numerotation des commandes
    self.set_icmd(1)

    if numeddl in self.sdprods:
        # Si le concept numeddl est dans self.sdprods
        # il doit etre  produit par la macro
        # il faudra donc appeler la commande NUME_DDL
        if (MATR_ASSE is None):
            UTMESS('F', 'MATRICE0_5')

        lnume = 1
    else:
        lnume = 0
        # dans le cas ou on assemble des vecteurs, le mot cle charge utilise prealablement pour
        # la construction des conditions de Dirichlet est indispensable...sauf si initialement
        # les matrices etaient construites sans aucune charge (peut etre le cas
        # en dynamique)
        if ((VECT_ASSE is not None) and (CHARGE is None)):
            UTMESS('A', 'MATRICE0_6')

    lrigel = 0
    lmasel = 0

# ASSEMBLAGE DES MATRICES
    if MATR_ASSE is not None:
        # import des commandes a utiliser dans la macro pour l'assemblage des
        # matrices
        CALC_MATR_ELEM = self.get_cmd('CALC_MATR_ELEM')
        ASSE_MATRICE = self.get_cmd('ASSE_MATRICE')
        # decalage eventuel en premiere position dans la liste de l occurence de MATR_ASSE contenant
        # l option de rigidite
        try:
            for m in MATR_ASSE:
                option = m['OPTION']
                if option in ('RIGI_MECA', 'RIGI_THER', 'RIGI_ACOU', 'RIGI_FLUI_STRU'):
                    decal = m
                    MATR_ASSE.remove(decal)
                    MATR_ASSE.insert(0, decal)
                    break
        except:
            pass

        iocc = 0
        for m in MATR_ASSE:
            iocc = iocc + 1
            option = m['OPTION']

            motscles = {'OPTION': option}
            if option == 'RIGI_MECA_HYST':
                if (not lrigel):
                    UTMESS('F', 'MATRICE0_10')
                motscles['RIGI_MECA'] = rigel
            if option == 'AMOR_MECA':
                if (not lrigel):
                    UTMESS('F', 'MATRICE0_11')
                if CHAM_MATER is not None:
                    motscles['RIGI_MECA'] = rigel
                    if (lmasel):
                        motscles['MASS_MECA'] = masel
            if CHARGE is not None:
                if option[0:9] != 'RIGI_GEOM':
                    motscles['CHARGE'] = CHARGE
            if CHAM_MATER:
                motscles['CHAM_MATER'] = CHAM_MATER
            if CARA_ELEM is not None:
                motscles['CARA_ELEM'] = CARA_ELEM
            if INST is not None:
                motscles['INST'] = INST

            try:
                motscles['SIEF_ELGA'] = m['SIEF_ELGA']
            except IndexError:
                pass

            try:
                motscles['MODE_FOURIER'] = m['MODE_FOURIER']
            except IndexError:
                pass

            try:
                motscles['GROUP_MA'] = m['GROUP_MA']
            except IndexError:
                pass

            _a = CALC_MATR_ELEM(MODELE=MODELE, **motscles)

            if option == 'RIGI_MECA':
                rigel = _a
                lrigel = 1
            if option == 'MASS_MECA':
                masel = _a
                lmasel = 1

            if lnume == 0:
                num = numeddl

            # ici iocc est obligatoirement 1 vu le traitement précédent
            # et la non compatibilité des 4 options
            elif option in ('RIGI_MECA', 'RIGI_THER', 'RIGI_ACOU', 'RIGI_FLUI_STRU'):
                self.DeclareOut('num', numeddl)
                num = NUME_DDL(MATR_RIGI=_a, INFO=info)

            elif iocc == 1 and option not in (
                'RIGI_MECA', 'RIGI_THER', 'RIGI_ACOU','RIGI_FLUI_STRU'):

                self.DeclareOut('num', numeddl)
                if CHARGE is not None:
                    num = NUME_DDL(MODELE=MODELE, CHARGE=CHARGE, INFO=info)
                else:
                    num = NUME_DDL(MODELE=MODELE, INFO=info)

            self.DeclareOut('mm', m['MATRICE'])
            motscles = {'OPTION': option}
            if CHAR_CINE is not None:
                mm = ASSE_MATRICE(
                    MATR_ELEM=_a, NUME_DDL=num, CHAR_CINE=CHAR_CINE)
            else:
                mm = ASSE_MATRICE(MATR_ELEM=_a, NUME_DDL=num)

# ASSEMBLAGE DES VECTEURS
    if VECT_ASSE is not None:
        # import des commandes a utiliser dans la macro pour l'assemblage des
        # vecteurs
        CALC_VECT_ELEM = self.get_cmd('CALC_VECT_ELEM')
        ASSE_VECTEUR = self.get_cmd('ASSE_VECTEUR')

        for v in VECT_ASSE:
            option = v['OPTION']
            motscles = {'OPTION': option}

            if CHARGE is not None:
                liste_toutes_charges = list(
                    CHARGE)  # on prend en compte les charges globales et on additionne les autres apres pour
                                                  # chaque vecteur
            else:
                liste_toutes_charges = []

            try:
                    # on ajoute a la liste de charges de Dirichlet les charges
                    # de Newmann
                for char_vv in v['CHARGE']:
                    if char_vv not in liste_toutes_charges:
                        liste_toutes_charges.append(char_vv)

                    else:
                        UTMESS('F', 'MATRICE0_12')
                               # on ineterdit les doublons avec les charges
                               # globales

            except:
                if (CHARGE is None):  # on ne peut pas construire de vecteur si on a aucune charge
                    UTMESS('F', 'MATRICE0_8')
                pass

            motscles['CHARGE'] = tuple(liste_toutes_charges)
                                       # remplissage du mot-cle CHARGE pour
                                       # toutes les options

            if (option == 'CHAR_MECA'):

                if CARA_ELEM is not None:
                    motscles['CARA_ELEM'] = CARA_ELEM
                if CHAM_MATER is not None:
                    motscles['CHAM_MATER'] = CHAM_MATER
                if INST is not None:
                    motscles['INST'] = INST
                try:
                    motscles['MODE_FOURIER'] = v['MODE_FOURIER']
                except IndexError:
                    pass

            elif (option == 'CHAR_THER'):

                if CARA_ELEM is not None:
                    motscles['CARA_ELEM'] = CARA_ELEM
                if INST is not None:
                    motscles['INST'] = INST

            else:  # option == 'CHAR_ACOU':
                if (CHAM_MATER is None):
                    UTMESS('F', 'MATRICE0_7')
                else:
                    motscles['CHAM_MATER'] = CHAM_MATER

            _b = CALC_VECT_ELEM(**motscles)

            # les vecteurs assembles sont des concepts sortants.
            self.DeclareOut('vv', v['VECTEUR'])
            # assemblage des vecteurs
            vv = ASSE_VECTEUR(VECT_ELEM=_b, NUME_DDL=numeddl)

    return ier
