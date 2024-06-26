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

import os

# NOM_PARA requis dans EXEC_LOGICIEL: INPUTFILE1, CHOIX

# STUDY = nom de l'étude

# Pour isovaleurs
# INPUTFILE1 : Fichier de resultat MED
# CHOIX = 'DEPL', 'ISO', 'GAUSS', 'ON_DEFORMED'

# Pour courbes
# INPUTFILE1 : Fichier de resultat TXT
# CHOIX = 'COURBE'


if 'CHOIX' not in ['DEPL', 'ISO', 'GAUSS', 'COURBE', 'ON_DEFORMED']:
    raise Exception("Erreur de type de visualisation!")
if not os.path.isfile('INPUTFILE1'):
    raise Exception("Fichier %s non present!" % 'INPUTFILE1')


#%====================Initialisation Salome================================%
import sys
import salome
import SALOMEDS
import salome_kernel
orb, lcc, naming_service, cm = salome_kernel.salome_kernel_init()
obj = naming_service.Resolve('myStudyManager')
myStudyManager = obj._narrow(SALOMEDS.StudyManager)

root = os.path.normpath(
    os.path.dirname(os.path.abspath(os.path.realpath(sys.argv[0]))))
file1 = os.path.join(root, 'INPUTFILE1')
if not os.path.isfile(file1):
    raise Exception("Fichier %s non present!" % 'INPUTFILE1')

#%====================Initialisation etude================================%
if 'STUDY':
    # Si on a le nom de l'etude
    study = myStudyManager.GetStudyByName('STUDY')
    salome.salome_init(study._get_StudyId())
    import visu_gui
    import VISU
    import visu
    myVisu = visu_gui.myVisu
    myVisu.SetCurrentStudy(study)

else:
    # Sinon on choisit etude courante
    salome.salome_init()
    import visu_gui
    import VISU
    import visu
    myVisu = visu_gui.myVisu
    myVisu.SetCurrentStudy(salome.myStudy)
    # ou la premiere detectee ?
    # Liste_Study = salome.myStudyManager.GetOpenStudies()
    # NOM = Liste_Study[0]
    # myVisu.SetCurrentStudy(salome.myStudyManager.GetStudyByName(NOM))


myViewManager = myVisu.GetViewManager()
if myViewManager is None:
    raise Exception("Erreur de creation de study")


#%===================Construction courbe======================%

if 'CHOIX' == 'COURBE':
    table_txt = myVisu.ImportTables(file1, 0)
    if table_txt:
        IsFound, aSObject = table_txt.FindSubObject(1)
        if IsFound:
            anID = aSObject.GetID()
            table = myVisu.CreateTable(anID)
            NRow = table.GetNbRows()
            myContainer = myVisu.CreateContainer()
            for i in range(2, NRow + 1):
                resu = myVisu.CreateCurve(table, 1, i)
                myContainer.AddCurve(resu)

#%====================Construction isovaleurs====================%

else:
    myResult = myVisu.ImportFile(file1)
    if myResult is None:
        raise Exception("Erreur de fichier MED")

    MAILLAGE = myResult.GetMeshNames()[0]
    LISTE_CHAMP_CELL = myResult.GetFields(MAILLAGE, VISU.CELL)
    LISTE_CHAMP_NODE = myResult.GetFields(MAILLAGE, VISU.NODE)

    resu = []
    resuanim = []

    # Si on n'est pas en DEPL, on a une visualisation par composante
    # Si on est en DEPL, on a une visualisation de la deformee
    # Si on a plusieurs instants, on a visualisation de type Presentation
    # animee

    if 'CHOIX' == 'ON_DEFORMED':
        if LISTE_CHAMP_NODE == []:
            raise Exception("Erreur de champ")
        TYPE_ENTITE = VISU.NODE
        NOM_CHAMP = LISTE_CHAMP_NODE[0]
        NUM_INST = myResult.GetTimeStampNumbers(
            MAILLAGE, TYPE_ENTITE, NOM_CHAMP)[0]
        L_INST = myResult.GetTimeStampNumbers(MAILLAGE, TYPE_ENTITE, NOM_CHAMP)
        nINST = len(L_INST)

        if LISTE_CHAMP_CELL == []:
            TYPE_SCAL = VISU.NODE
            NOM_CHAMP_SCAL = LISTE_CHAMP_NODE[1]
        else:
            TYPE_SCAL = VISU.CELL
            NOM_CHAMP_SCAL = LISTE_CHAMP_CELL[0]

        nCMP = myResult.GetNumberOfComponents(
            MAILLAGE, TYPE_SCAL, NOM_CHAMP_SCAL)
        name0 = NOM_CHAMP_SCAL.rstrip('_') + '_'
        name = MAILLAGE + '_' + NOM_CHAMP.rstrip('_') + '_'

        for i in range(1, nCMP + 1):
            if nINST == 1:
                res = myVisu.DeformedShapeAndScalarMapOnField(
                    myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
                res.SetScalarField(TYPE_SCAL, NOM_CHAMP_SCAL, NUM_INST)
                res.SetTitle(name0 + str(i))
                res.SetScalarMode(i)
                resu.append(res)
            else:
                res = VISU.ColoredPrs3dHolder.BasicInput(
                    myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
                MyPres = myVisu.GetColoredPrs3dCache(myVisu.GetCurrentStudy())
                resanim = MyPres.CreateHolder(
                    VISU.TDEFORMEDSHAPEANDSCALARMAP, res)
                visu.SetName(resanim, name + str(i))
                resanim.GetDevice().SetScalarField(
                    TYPE_SCAL, NOM_CHAMP_SCAL, NUM_INST)
                resanim.GetDevice().SetTitle(name0 + str(i))
                resanim.GetDevice().SetScalarMode(i)
                resu.append(res)
                resuanim.append(resanim)

    if 'CHOIX' == 'DEPL':
        TYPE_ENTITE = VISU.NODE
        if LISTE_CHAMP_NODE == []:
            raise Exception("Erreur de champ")
        NOM_CHAMP = LISTE_CHAMP_NODE[0]
        NUM_INST = myResult.GetTimeStampNumbers(
            MAILLAGE, TYPE_ENTITE, NOM_CHAMP)[0]
        L_INST = myResult.GetTimeStampNumbers(MAILLAGE, TYPE_ENTITE, NOM_CHAMP)
        nINST = len(L_INST)
        nCMP = 1
        name0 = NOM_CHAMP.rstrip('_')
        name = MAILLAGE + '_' + name0

        if nINST == 1:
            res = myVisu.DeformedShapeOnField(
                myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
            res.ShowColored(True)
            res.SetTitle(name0)
            resu.append(res)
        else:
            res = VISU.ColoredPrs3dHolder.BasicInput(
                myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
            MyPres = myVisu.GetColoredPrs3dCache(myVisu.GetCurrentStudy())
            resanim = MyPres.CreateHolder(VISU.TDEFORMEDSHAPE, res)
            visu.SetName(resanim, name)
            resanim.GetDevice().ShowColored(True)
            resanim.GetDevice().SetTitle(name0)
            resu.append(res)
            resuanim.append(resanim)

    if 'CHOIX' == 'GAUSS':
        TYPE_ENTITE = VISU.CELL
        if LISTE_CHAMP_CELL == []:
            raise Exception("Erreur de champ")
        NOM_CHAMP = LISTE_CHAMP_CELL[0]
        NUM_INST = myResult.GetTimeStampNumbers(
            MAILLAGE, TYPE_ENTITE, NOM_CHAMP)[0]
        L_INST = myResult.GetTimeStampNumbers(MAILLAGE, TYPE_ENTITE, NOM_CHAMP)
        nINST = len(L_INST)
        nCMP = myResult.GetNumberOfComponents(MAILLAGE, TYPE_ENTITE, NOM_CHAMP)
        name0 = NOM_CHAMP.rstrip('_') + '_'
        name = MAILLAGE + '_' + name0

        for i in range(1, nCMP + 1):
            if nINST == 1:
                res = myVisu.GaussPointsOnField(
                    myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
                res.SetIsDispGlobalScalarBar(False)
                res.SetScalarMode(i)
                res.SetTitle(name0 + str(i))
                resu.append(res)
            else:
                res = VISU.ColoredPrs3dHolder.BasicInput(
                    myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
                MyPres = myVisu.GetColoredPrs3dCache(myVisu.GetCurrentStudy())
                resanim = MyPres.CreateHolder(VISU.TGAUSSPOINTS, res)
                visu.SetName(resanim, name + str(i))
                resanim.GetDevice().SetIsDispGlobalScalarBar(False)
                resanim.GetDevice().SetScalarMode(i)
                resanim.GetDevice().SetTitle(name0 + str(i))
                resu.append(res)
                resuanim.append(resanim)

    if 'CHOIX' == 'ISO':
        if LISTE_CHAMP_CELL == []:
            TYPE_ENTITE = VISU.NODE
            if LISTE_CHAMP_NODE == []:
                raise Exception("Erreur de champ")
            NOM_CHAMP = LISTE_CHAMP_NODE[0]
        else:
            TYPE_ENTITE = VISU.CELL
            NOM_CHAMP = LISTE_CHAMP_CELL[0]

        NUM_INST = myResult.GetTimeStampNumbers(
            MAILLAGE, TYPE_ENTITE, NOM_CHAMP)[0]
        L_INST = myResult.GetTimeStampNumbers(MAILLAGE, TYPE_ENTITE, NOM_CHAMP)
        nINST = len(L_INST)
        nCMP = myResult.GetNumberOfComponents(MAILLAGE, TYPE_ENTITE, NOM_CHAMP)
        name0 = NOM_CHAMP.rstrip('_') + '_'
        name = MAILLAGE + '_' + name0

        for i in range(1, nCMP + 1):
            if nINST == 1:
                res = myVisu.ScalarMapOnField(
                    myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
                res.SetScalarMode(i)
                res.SetTitle(name0 + str(i))
                resu.append(res)
            else:
                res = VISU.ColoredPrs3dHolder.BasicInput(
                    myResult, MAILLAGE, TYPE_ENTITE, NOM_CHAMP, NUM_INST)
                MyPres = myVisu.GetColoredPrs3dCache(myVisu.GetCurrentStudy())
                resanim = MyPres.CreateHolder(VISU.TSCALARMAP, res)
                visu.SetName(resanim, name + str(i))
                resanim.GetDevice().SetScalarMode(i)
                resanim.GetDevice().SetTitle(name0 + str(i))
                resu.append(res)
                resuanim.append(resanim)


#%=============== Affichage ============================%
myView1 = myViewManager.GetCurrentView()
if 'CHOIX' == 'COURBE':
    myView1 = myViewManager.CreateXYPlot()
    myView1.Display(myContainer)
    session = naming_service.Resolve('/Kernel/Session')
    session.emitMessageOneWay("updateObjBrowser")
else:
    if myView1 is None:
        myView1 = myViewManager.Create3DView()
    else:
        if myView1.GetType() != VISU.TVIEW3D:
            myView1 = myViewManager.Create3DView()
            if myView1 is None:
                raise Exception("Erreur de vue VTK")

    if nINST == 1:
        myView1.DisplayOnly(resu[nCMP - 1])
        myView1.FitAll()
    else:
        myView1.EraseAll()
        # for anInfo in range(1,nINST+1) :
        #   resu[nCMP-1].myTimeStampNumber = anInfo
        # resuanim[nCMP-1].Apply(resuanim[nCMP-1].GetDevice(),resu[nCMP-1],
        # myView1)
        resu[nCMP - 1].myTimeStampNumber = nINST
        resuanim[nCMP - 1].Apply(
            resuanim[nCMP - 1].GetDevice(), resu[nCMP - 1], myView1)
        myView1.FitAll()

#%==================FIN ================================%
