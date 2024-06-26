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

# person_in_charge: samuel.geniaut at edf.fr

"""
Ce module définit des fonctions permettant de manipuler un résultat issu de THYC
"""

import re


class ThycResult(object):

    """Object to represent a result read from THYC"""
    # TODO: encapsulate the following functions as methods of ThycResult
    __slots__ = ('chtr_nodal', 'chtr_poutre', 'chax_nodal', 'chax_poutre')


def cherche_rubrique_nom(fobj, nom):
    """Chercher une rubrique definie par son nom"""
    while 1:
        line = fobj.readline()
        if not line:
            break
        # if line.strip() == nom:
        #     return 1
        #strtmp = line[0:len(line) - 1]
        #if len(line) >= len(nom):
            #if line[0:len(nom)] == nom:
                #return 1
        if re.search(nom,line) : return True
    return None

def compute_ep_from_Z(line) :
  Zstr=line[2:len(line)]
  size=len(Zstr)
  Z=size*[None]
  for i in range(size) :
    Z[i]=float(Zstr[i])

  ep=[None]*size
  ep[0]=2*float(Z[0])
  for i in range(size-1) :
    ep[i+1]=2*(Z[i+1]-Z[i])-ep[i]
  epstr=['ep(m)', '=']
  for i in range(size) :
    epstr.append(ep[i])
  return(epstr)

def definir_chargement_transverse(cote, epaisseur, pos_thyc, force, prod):
    """XXX pas documenté, propre à lire_resu_thyc"""
    from code_aster.Cata.Commands import DEFI_FONCTION
    # Determination du chargement transverse sur les crayons pour un
    # assemblage donne.
    kk = 2
    eps = 1.0e-6

    defi_fonc = []
    # Pour aller de l embout inferieur jusqu'a la premiere grille.
    som_l = 0.0
    som_f = 0.0
    for k in range(kk, pos_thyc[0]):
        som_l = som_l + float(epaisseur[k])
        som_f = som_f + prod * float(force[k])
    som_feq = som_f / \
        (som_l + 0.25 * float(epaisseur[pos_thyc[0]]))
    defi_fonc.append(
        float(cote[kk]) - 0.5 * float(epaisseur[kk]) - eps)
    defi_fonc.append(som_feq)
    defi_fonc.append(
        float(cote[pos_thyc[0]]) - 0.5 * float(epaisseur[pos_thyc[0]]) + eps)
    defi_fonc.append(som_feq)
    defi_fonc.append(float(cote[pos_thyc[0]]))
    defi_fonc.append(0.0)

    # Pour aller de la premiere a la derniere grille.
    for j in range(0, len(pos_thyc) - 1):
        som_l = 0.0
        som_f = 0.0
        for k in range(pos_thyc[j] + 1, pos_thyc[j + 1]):
            som_l = som_l + float(epaisseur[k])
            #print('epaisseur = %s'%epaisseur[k])
            som_f = som_f + prod * float(force[k])
        #print('som_l = %f ; som_f = %f'%(som_l,som_f))
        som_feq = som_f / \
            (som_l + 0.25 *
             (float(epaisseur[pos_thyc[j]]) + float(epaisseur[pos_thyc[j + 1]])))
        #print('epaisseur avant = %s ; epaisseur apres = %s'%(epaisseur[pos_thyc[j]],epaisseur[pos_thyc[j + 1]]))
        #print('cote grille avant = %s ; cote grille apres = %s'%(cote[pos_thyc[j]],cote[pos_thyc[j + 1]]))
        defi_fonc.append(
            float(cote[pos_thyc[j]]) + 0.5 * float(epaisseur[pos_thyc[j]]) - eps)
        defi_fonc.append(som_feq)
        defi_fonc.append(
            float(cote[pos_thyc[j + 1]]) - 0.5 * float(epaisseur[pos_thyc[j + 1]]) + eps)
        defi_fonc.append(som_feq)
        defi_fonc.append(float(cote[pos_thyc[j + 1]]))
        defi_fonc.append(0.0)

    # Pour aller de la derniere grille jusqu'a l embout superieur.
    som_l = 0.0
    som_f = 0.0
    for k in range(pos_thyc[len(pos_thyc) - 1] + 1, len(cote)):
        som_l = som_l + float(epaisseur[k])
        som_f = som_f + prod * float(force[k])
    som_feq = som_f / \
        (som_l + 0.25 * float(epaisseur[len(cote) - 1]))
    defi_fonc.append(float(cote[pos_thyc[len(pos_thyc) - 1]]) + 0.5 * float(
        epaisseur[pos_thyc[len(pos_thyc) - 1]]) - eps)
    defi_fonc.append(som_feq)
    defi_fonc.append(
        float(cote[len(cote) - 1]) + 0.5 * float(epaisseur[len(cote) - 1]) + eps)
    defi_fonc.append(som_feq)

    _resu = DEFI_FONCTION(NOM_PARA='X',
                          VALE=defi_fonc,
                          PROL_DROITE='CONSTANT',
                          PROL_GAUCHE='CONSTANT',)
    return _resu


def lire_resu_thyc(coeur, MODELE, nom_fic):
    """XXX
    À définir dans un autre module : fonction qui prend un Coeur en argument
    ou un objet ThycResult avec .read(), .hydr_load()... pour récupérer les
    différents résultats
    """
    from code_aster.Cata.Commands import (DEFI_FONCTION, AFFE_CHAR_MECA,
        AFFE_CHAR_MECA_F)
    from code_aster.Cata.Syntax import _F
    # Fonction multiplicative de la force hydrodynamique axiale.
    # On multiplie par 0.722 les forces hydrodynamiques a froid pour obtenir
    # celles a chaud.
    FOHYFR_1 = 1.0    # Valeur a froid
    FOHYCH_1 = 0.722  # Valeur a chaud
    res = ThycResult()

    f = open(nom_fic, 'r')
    f2 = open(nom_fic, 'r')
    cherche_rubrique_nom(f, 'EFFORTS TRANSVERSES selon X en N')
    cherche_rubrique_nom(f2, 'EFFORTS TRANSVERSES selon Y en N')
    line = f.readline().split()
    line2 = f2.readline().split()
    line2 = f2.readline().split()
    fline=f.readline().split()
    version=None
    if (fline[0] == "ep(m)"):
      version = "Old"
    elif (fline[0] == "Z(m)"):
      version = "New"
    else :
      raise KeyError("invalid thyc result file")
    # Recuperation de l'epaisseur des mailles dans Thyc
    #epaisseur = f.readline().split()
    #if (epaisseur[0] != "ep(m)"):
        #raise KeyError("invalid epaisseur")
    if version == "Old" :
      cote = f.readline().split()
    else :
      cote=fline
    #if (cote[0] != "Z(m)"):
        #raise KeyError("invalid cote axial")
    epaisseur = compute_ep_from_Z(cote)
    #print('epaisseur = %s'%epaisseur)
    j = 0
    pos_thyc = []
    for i in range(2, len(cote)):
        # Positionnement des grilles
        if ((coeur.altitude[j] > (float(cote[i]) - float(epaisseur[i]) / 2.)) & (coeur.altitude[j] < (float(cote[i]) + float(epaisseur[i]) / 2.))):
            pos_thyc.append(i)
            j = j + 1
            if (j == len(coeur.altitude)):
                break

    for i in range(2, len(cote)):
        # Positionnement des crayons pour application des efforts transverses
        if ((coeur.XINFC > (float(cote[i]) - float(epaisseur[i]) / 2.)) & (coeur.XINFC < (float(cote[i]) + float(epaisseur[i]) / 2.))):
            pos_gril_inf = i
        if ((coeur.XSUPC > (float(cote[i]) - float(epaisseur[i]) / 2.)) & (coeur.XSUPC < (float(cote[i]) + float(epaisseur[i]) / 2.))):
            pos_gril_sup = i

    # Recuperation des efforts transverses sur les grilles
    mcf = []
    mcft = []
    chThyc={}
    for i in range(0, coeur.NBAC):
        line = f.readline().split()
        line2 = f2.readline().split()
        #print('line = ',line)
        #print('line2 = ',line2)
        posi_aster1 = coeur.position_fromthyc(int(line[0]),int(line[1]))
        posi_aster2 = coeur.position_fromthyc(int(line2[0]),int(line2[1]))
        if (posi_aster1 != posi_aster2):
            raise KeyError("position d assemblage avec ordre different")

        for j in range(0, len(pos_thyc)):
            chThyc['X']=float(line[pos_thyc[j]])  / 4.0
            chThyc['Y']=float(line2[pos_thyc[j]]) / 4.0
            chAsterY=coeur.coefFromThyc('Y')*chThyc[coeur.axeFromThyc('Y')]
            chAsterZ=coeur.coefFromThyc('Z')*chThyc[coeur.axeFromThyc('Z')]
            #print 'chAsterY , type()',chAsterY,type(chAsterY)
            mtmp = (_F(GROUP_NO='G_' + posi_aster1 + '_' + str(j + 1), FY=chAsterY , FZ=chAsterZ),)
            mcf.extend(mtmp)

        chThyc['X']=definir_chargement_transverse(cote, epaisseur, pos_thyc, line, coeur.coefToThyc('X'))
        chThyc['Y']=definir_chargement_transverse(cote, epaisseur, pos_thyc, line2, coeur.coefToThyc('Y'))

        _resu_fy = chThyc[coeur.axeFromThyc('Y')]
        _resu_fz = chThyc[coeur.axeFromThyc('Z')]
        mtmp = (
            _F(GROUP_MA='CR_' + posi_aster1, FY=_resu_fy, FZ=_resu_fz),)
        mcft.extend(mtmp)

    _co = AFFE_CHAR_MECA(MODELE=MODELE, FORCE_NODALE=mcf)
    res.chtr_nodal = _co
    _co = AFFE_CHAR_MECA_F(MODELE=MODELE, FORCE_POUTRE=mcft)
    res.chtr_poutre = _co

    # Recuperation des efforts axiaux
    cherche_rubrique_nom(
        f, 'FORCE HYDRODYNAMIQUE AXIALE')
    line = f.readline().split()
    line = f.readline().split()
    line = f.readline().split()

    mcp = []
    mcpf = []
    for i in range(0, coeur.NBAC):
        line = f.readline().split()
        posi_aster=coeur.position_fromthyc(int(line[0]),int(line[1]))
        idAC = coeur.position_todamac(posi_aster)

        #print(list(coeur.collAC.keys()))

        ac = coeur.collAC[idAC]
        KTOT = ac.K_GRM * \
            (ac.NBGR - 2) + ac.K_GRE * 2 + ac.K_EBSU + ac.K_TUB + ac.K_EBIN

        # Force axiale pour une grille extremite (inf)
        mtmp = (_F(GROUP_NO='G_' + posi_aster + '_' + str(1),
                FX=float(line[2]) / FOHYCH_1 * ac.K_GRE / KTOT / 4.0),)
        mcp.extend(mtmp)

        # Force axiale pour chacune des grilles de mélange
        for j in range(1, ac.NBGR - 1):
            mtmp = (_F(GROUP_NO='G_' + posi_aster + '_' + str(j + 1),
                    FX=float(line[2]) / FOHYCH_1 * ac.K_GRM / KTOT / 4.0),)
            mcp.extend(mtmp)

        # Force axiale pour une grille extremite (sup)
        mtmp = (_F(GROUP_NO='G_' + posi_aster + '_' + str(ac.NBGR),
                FX=float(line[2]) / FOHYCH_1 * ac.K_GRE / KTOT / 4.0),)
        mcp.extend(mtmp)

        # Force axiale pour l'embout inferieur
        mtmp = (
            _F(GROUP_NO='PI_' + posi_aster, FX=float(line[2]) / FOHYCH_1 * ac.K_EBIN / KTOT),)
        mcp.extend(mtmp)

        # Force axiale pour l'embout superieur
        mtmp = (
            _F(GROUP_NO='PS_' + posi_aster, FX=float(line[2]) / FOHYCH_1 * ac.K_EBSU / KTOT),)
        mcp.extend(mtmp)

        # Force axiale pour les crayons (appel a DEFI_FONCTION)
        vale = float(line[2]) / FOHYCH_1 * \
            ac.K_TUB / KTOT * ac.NBCR / \
            (ac.NBCR + ac.NBTG) / ac.LONCR
        _FXC = DEFI_FONCTION(
            NOM_PARA='X', PROL_DROITE='CONSTANT', PROL_GAUCHE='CONSTANT',
            VALE=(ac.XINFC, vale, ac.XSUPC, vale))
        mtmp = (_F(GROUP_MA='CR_' + posi_aster, FX=_FXC),)
        mcpf.extend(mtmp)

        # Force axiale pour les tubes-guides (appel a DEFI_FONCTION)
        vale = float(line[2]) / FOHYCH_1 * ac.K_TUB / KTOT * ac.NBTG / (
            ac.NBCR + ac.NBTG) / ac.LONTU
        _FXT = DEFI_FONCTION(
            NOM_PARA='X', PROL_DROITE='CONSTANT', PROL_GAUCHE='CONSTANT',
            VALE=(ac.XINFT, vale, ac.XSUPT, vale))
        mtmp = (_F(GROUP_MA='TG_' + posi_aster, FX=_FXT),)
        mcpf.extend(mtmp)

    _co = AFFE_CHAR_MECA(MODELE=MODELE, FORCE_NODALE=mcp)
    res.chax_nodal = _co
    _co = AFFE_CHAR_MECA_F(MODELE=MODELE, FORCE_POUTRE=mcpf)
    res.chax_poutre = _co

    f.close()
    f2.close()
    
    return res
