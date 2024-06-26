# coding=utf-8
# --------------------------------------------------------------------
# Copyright (C) 1991 - 2017 - EDF R&D - www.code-aster.org
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

# Ce module est une surcharge de pylotage 2.0.2
# Il faudra reporter les methodes modifiees dans la prochaine version
# puis supprimer ce fichier.

from pylotage.TOOLS.Visu import *
from pylotage.TOOLS.Study import *

# Attention: pylotage appelle readMED pour importer le fichier med et en meme temps definir le maillage contenant les champs
# => si on veut afficher les champs de deux maillages differents, sans avoir a reimporter le fichier med,
# il faut decoupler dans readMED l'import du fichier et l'affectation du maillage dans l'attribut meshName.
# Evolution de XYplot2: on ajoute les parametres x_title et y_title pour definir les noms des axes
# => TODO mettre a jour pylotage
# => On surcharge la classe Visu de pylotage, en attendant d'y integrer les modifs ci-dessous


class Visu(Visu):

    def readMED(self, medFilePathName, meshName=None, entity=None):
        """
        Chargement des données du maillage à afficher à partir d'un fichier MED

        EXCEPTION-> Non

        @type     medFilePathName:     string
        @param  medFilePathName:     chemin absolu du fichier MED
        @type     meshName:     string
        @param  meshName:     nom d'un des maillages présents dans le fichier MED
        @type     entity:     type defini ds ce module
        @param  entity:     entité à visualiser sur le maillage de nom meshName

        @rtype:   None en cas d'ERREUR( mauvais paramètres ?)
        @return:  None en cas d'ERREUR( mauvais paramètres ?)
        """
        ok = None
        # try:
        if True:
            ok = self.importMED(medFilePathName)
            if meshName and entity:
                ok = self.setEntity(entity, meshName)
        # except:
            # pass
        return ok

    def importMED(self, medFilePathName):
        ok = None
        # try:
        if True:
            self.medFilePathName = medFilePathName
            self.dataPresentation = self.visuEngine.ImportFile(
                self.medFilePathName)
            ok = True
        # except:
            # pass
        return ok

    def XYPlot2(self, l_courbes, title="Title of table", x_title=None, y_title=None):
        """
        """
        import random
        ok = None
        try:
            ok = None
            size_lines = 2

            # >>> Create table
            myTObject = self.__createTableObject(l_courbes, title)
            myVisuTable = self.visuEngine.CreateTable(myTObject.GetID())

            # >>> Create container and insert curves
            myContainer = self.visuEngine.CreateContainer()
            nbRows = myVisuTable.GetNbRows()
            for i in range(2, nbRows + 1):
                curve = self.visuEngine.CreateCurve(myVisuTable, 1, i)
                curve.SetMarker(VISU.Curve.CROSS)
                curve.SetLine(VISU.Curve.SOLIDLINE, size_lines)
                curve.SetColor(
                    SALOMEDS.Color(random.random(), random.random(), random.random()))
                myContainer.AddCurve(curve)

            # Create View
            myViewManager = self.visuEngine.GetViewManager()
            myView = myViewManager.CreateXYPlot()
            myView.SetTitle(title)
            myView.EraseAll()
            # BUG avec Salome 4.1.3: Display n'affiche que la derniere courbe
            # cf REX Code_Aster 12604
            myView.Display(myContainer)
            myView.EnableYGrid(1, 20, 0, 2)
            myView.SetMarkerSize(size_lines * 10)
            if x_title is not None:
                myView.SetXTitle(x_title)
            if y_title is not None:
                myView.SetYTitle(y_title)
            ok = True
        except:
            pass
        return ok
