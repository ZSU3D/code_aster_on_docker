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

from cataelem.Tools.base_objects import LocatedComponents, ArrayOfComponents, SetOfNodes, ElrefeLoc
from cataelem.Tools.base_objects import Calcul, Element
import cataelem.Commons.physical_quantities as PHY
import cataelem.Commons.located_components as LC
import cataelem.Commons.parameters as SP
import cataelem.Commons.mesh_types as MT
from cataelem.Options.options import OP
import cataelem.Commons.attributes as AT

#----------------
# Modes locaux :
#----------------


DDL_MECA = LocatedComponents(phys=PHY.DEPL_R, type='ELNO',
    components=('DX','DY','DZ',))


EDEPLPG  = LocatedComponents(phys=PHY.DEPL_R, type='ELGA', location='RIGI',
    components=('DX','DY','DZ',))


CEPSINF  = LocatedComponents(phys=PHY.EPSI_F, type='ELEM',
    components=('EPXX','EPYY','EPZZ','EPXY','EPXZ',
          'EPYZ',))


CEPSINR  = LocatedComponents(phys=PHY.EPSI_R, type='ELEM',
    components=('EPXX','EPYY','EPZZ','EPXY','EPXZ',
          'EPYZ',))


CFORCEF  = LocatedComponents(phys=PHY.FORC_F, type='ELEM',
    components=('FX','FY','FZ',))


CFORCER  = LocatedComponents(phys=PHY.FORC_R, type='ELEM',
    components=('FX','FY','FZ',))


NFORCER  = LocatedComponents(phys=PHY.FORC_R, type='ELNO',
    components=('FX','FY','FZ',))


EKTHETA  = LocatedComponents(phys=PHY.G, type='ELEM',
    components=('GTHETA','FIC[3]','K[3]','BETA',))




NGEOMER  = LocatedComponents(phys=PHY.GEOM_R, type='ELNO',
    components=('X','Y','Z',))


EGGEOP_R = LocatedComponents(phys=PHY.GEOM_R, type='ELGA', location='RIGI',
    components=('X','Y','Z','W',))


EGGEOM_R = LocatedComponents(phys=PHY.GEOM_R, type='ELGA', location='RIGI',
    components=('X','Y','Z',))


CTEMPSR  = LocatedComponents(phys=PHY.INST_R, type='ELEM',
    components=('INST',))


EGNEUT_F = LocatedComponents(phys=PHY.NEUT_F, type='ELGA', location='RIGI',
    components=('X[30]',))


ERAYONM  = LocatedComponents(phys=PHY.NEUT_R, type='ELEM',
    components=('X1',))


CEFOND   = LocatedComponents(phys=PHY.NEUT_R, type='ELEM',
    components=('X1',))


ECASECT  = LocatedComponents(phys=PHY.NEUT_R, type='ELEM',
    components=('X[10]',))


EMNEUT_R = LocatedComponents(phys=PHY.NEUT_R, type='ELEM',
    components=('X[30]',))


EGNEUT_R = LocatedComponents(phys=PHY.NEUT_R, type='ELGA', location='RIGI',
    components=('X[30]',))


CPRESSF  = LocatedComponents(phys=PHY.PRES_F, type='ELEM',
    components=('PRES',))


CPRES_R  = LocatedComponents(phys=PHY.PRES_R, type='ELEM',
    components=('PRES',))


EPRESNO  = LocatedComponents(phys=PHY.PRES_R, type='ELNO',
    components=('PRES',))


ECONTNO  = LocatedComponents(phys=PHY.SIEF_R, type='ELNO',
    components=('SIXX','SIYY','SIZZ','SIXY','SIXZ',
          'SIYZ',))


MVECTUR  = ArrayOfComponents(phys=PHY.VDEP_R, locatedComponents=DDL_MECA)

MMATUNS  = ArrayOfComponents(phys=PHY.MDNS_R, locatedComponents=DDL_MECA)


#------------------------------------------------------------
class MECA_FACE3(Element):
    """Please document this element"""
    meshType = MT.TRIA3
    nodes = (
            SetOfNodes('EN1', (1,2,3,)),
        )
    attrs = ((AT.BORD_ISO,'OUI'),)
    elrefe =(
            ElrefeLoc(MT.TR3, gauss = ('RIGI=FPG3',), mater=('RIGI',),),
        )
    calculs = (

        OP.CALC_G(te=280,
            para_in=((SP.PACCELE, DDL_MECA), (SP.PDEPLAR, DDL_MECA),
                     (SP.PFR2D3D, NFORCER), (SP.PGEOMER, NGEOMER),
                     (SP.PPRESSR, EPRESNO), (SP.PSIGINR, ECONTNO),
                     (SP.PTHETAR, DDL_MECA), (OP.CALC_G.PVARCPR, LC.ZVARCPG),
                     (SP.PVITESS, DDL_MECA), ),
            para_out=((SP.PGTHETA, LC.EGTHETA), ),
        ),

        OP.CALC_G_F(te=280,
            para_in=((SP.PACCELE, DDL_MECA), (SP.PDEPLAR, DDL_MECA),
                     (SP.PFF2D3D, CFORCEF), (SP.PGEOMER, NGEOMER),
                     (SP.PPRESSF, CPRESSF), (SP.PSIGINR, ECONTNO),
                     (SP.PTEMPSR, CTEMPSR), (SP.PTHETAR, DDL_MECA),
                     (OP.CALC_G_F.PVARCPR, LC.ZVARCPG), (SP.PVITESS, DDL_MECA),
                     ),
            para_out=((SP.PGTHETA, LC.EGTHETA), ),
        ),

        OP.CALC_K_G(te=311,
            para_in=((OP.CALC_K_G.PBASLOR, LC.N9NEUT_R), (OP.CALC_K_G.PCOMPOR, LC.CCOMPOR),
                     (SP.PCOURB, LC.G27NEUTR), (SP.PDEPLAR, DDL_MECA),
                     (SP.PEPSINR, CEPSINR), (SP.PFR2D3D, NFORCER),
                     (SP.PFRVOLU, NFORCER), (SP.PGEOMER, NGEOMER),
                     (OP.CALC_K_G.PLSN, LC.N1NEUT_R), (OP.CALC_K_G.PLST, LC.N1NEUT_R),
                     (SP.PMATERC, LC.CMATERC), (SP.PPESANR, LC.CPESANR),
                     (SP.PPRESSR, EPRESNO), (SP.PPULPRO, LC.CFREQR),
                     (SP.PROTATR, LC.CROTATR), (SP.PSIGINR, ECONTNO),
                     (SP.PTHETAR, DDL_MECA), (OP.CALC_K_G.PVARCPR, LC.ZVARCPG),
                     (SP.PVARCRR, LC.ZVARCPG), ),
            para_out=((SP.PGTHETA, EKTHETA), ),
        ),

        OP.CALC_K_G_F(te=311,
            para_in=((OP.CALC_K_G_F.PBASLOR, LC.N9NEUT_R), (OP.CALC_K_G_F.PCOMPOR, LC.CCOMPOR),
                     (SP.PCOURB, LC.G27NEUTR), (SP.PDEPLAR, DDL_MECA),
                     (SP.PEPSINF, CEPSINF), (SP.PFF2D3D, CFORCEF),
                     (SP.PFFVOLU, CFORCEF), (SP.PGEOMER, NGEOMER),
                     (OP.CALC_K_G_F.PLSN, LC.N1NEUT_R), (OP.CALC_K_G_F.PLST, LC.N1NEUT_R),
                     (SP.PMATERC, LC.CMATERC), (SP.PPESANR, LC.CPESANR),
                     (SP.PPRESSF, CPRESSF), (SP.PPULPRO, LC.CFREQR),
                     (SP.PROTATR, LC.CROTATR), (SP.PSIGINR, ECONTNO),
                     (SP.PTEMPSR, CTEMPSR), (SP.PTHETAR, DDL_MECA),
                     (OP.CALC_K_G_F.PVARCPR, LC.ZVARCPG), (SP.PVARCRR, LC.ZVARCPG),
                     ),
            para_out=((SP.PGTHETA, EKTHETA), ),
        ),

        OP.CARA_SECT_POU3R(te=337,
            para_in=((SP.PGEOMER, NGEOMER), (SP.PORIGIN, LC.CGEOM3D),
                     ),
            para_out=((SP.PRAYONM, ERAYONM), ),
        ),

        OP.CARA_SECT_POUT3(te=337,
            para_in=((SP.PGEOMER, NGEOMER), ),
            para_out=((SP.PCASECT, ECASECT), ),
        ),

        OP.CARA_SECT_POUT4(te=337,
            para_in=((SP.PGEOMER, NGEOMER), (SP.PORIGIN, LC.CGEOM3D),
                     ),
            para_out=((SP.PVECTU1, MVECTUR), (SP.PVECTU2, MVECTUR),
                     ),
        ),

        OP.CARA_SECT_POUT5(te=337,
            para_in=((OP.CARA_SECT_POUT5.PCAORIE, LC.CGEOM3D), (SP.PGEOMER, NGEOMER),
                     (SP.PNUMMOD, LC.CNUMMOD), (SP.PORIGFI, LC.CGEOM3D),
                     (SP.PORIGIN, LC.CGEOM3D), ),
            para_out=((SP.PVECTU1, MVECTUR), (SP.PVECTU2, MVECTUR),
                     (SP.PVECTU3, MVECTUR), (SP.PVECTU4, MVECTUR),
                     (SP.PVECTU5, MVECTUR), (SP.PVECTU6, MVECTUR),
                     ),
        ),

        OP.CHAR_MECA_EFON_F(te=19,
            para_in=((SP.PEFOND, CEFOND), (SP.PGEOMER, NGEOMER),
                     (SP.PPREFFF, CPRESSF), (SP.PTEMPSR, CTEMPSR),
                     ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_EFON_R(te=18,
            para_in=((SP.PEFOND, CEFOND), (SP.PGEOMER, NGEOMER),
                     (SP.PPREFFR, EPRESNO), ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_EFSU_F(te=425,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PEFOND, CEFOND), (SP.PGEOMER, NGEOMER),
                     (SP.PPREFFF, CPRESSF), (SP.PTEMPSR, CTEMPSR),
                     ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_EFSU_R(te=424,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PEFOND, CEFOND), (SP.PGEOMER, NGEOMER),
                     (SP.PPREFFR, EPRESNO), ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_FF2D3D(te=29,
            para_in=((SP.PFF2D3D, CFORCEF), (SP.PGEOMER, NGEOMER),
                     (SP.PTEMPSR, CTEMPSR), ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_FR2D3D(te=28,
            para_in=((SP.PFR2D3D, NFORCER), (SP.PGEOMER, NGEOMER),
                     ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_PRES_F(te=19,
            para_in=((SP.PGEOMER, NGEOMER), (SP.PPRESSF, CPRESSF),
                     (SP.PTEMPSR, CTEMPSR), ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_PRES_R(te=18,
            para_in=((SP.PGEOMER, NGEOMER), (SP.PPRESSR, EPRESNO),
                     ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_PRSU_F(te=425,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PGEOMER, NGEOMER), (SP.PPRESSF, CPRESSF),
                     (SP.PTEMPSR, CTEMPSR), ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.CHAR_MECA_PRSU_R(te=424,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PGEOMER, NGEOMER), (SP.PPRESSR, EPRESNO),
                     ),
            para_out=((SP.PVECTUR, MVECTUR), ),
        ),

        OP.COOR_ELGA(te=488,
            para_in=((SP.PGEOMER, NGEOMER), ),
            para_out=((OP.COOR_ELGA.PCOORPG, EGGEOP_R), ),
        ),

        OP.INIT_VARC(te=99,
            para_out=((OP.INIT_VARC.PVARCPR, LC.ZVARCPG), ),
        ),

        OP.NORME_L2(te=563,
            para_in=((SP.PCALCI, LC.EMNEUT_I), (SP.PCHAMPG, EGNEUT_R),
                     (SP.PCOEFR, EMNEUT_R), (OP.NORME_L2.PCOORPG, EGGEOP_R),
                     ),
            para_out=((SP.PNORME, LC.ENORME), ),
        ),

        OP.NSPG_NBVA(te=496,
            para_in=((OP.NSPG_NBVA.PCOMPOR, LC.CCOMPO2), ),
            para_out=((SP.PDCEL_I, LC.EDCEL_I), ),
        ),

        OP.RIGI_MECA_EFSU_F(te=425,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PEFOND, CEFOND), (SP.PGEOMER, NGEOMER),
                     (SP.PPREFFF, CPRESSF), (SP.PTEMPSR, CTEMPSR),
                     ),
            para_out=((SP.PMATUNS, MMATUNS), ),
        ),

        OP.RIGI_MECA_EFSU_R(te=424,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PEFOND, CEFOND), (SP.PGEOMER, NGEOMER),
                     (SP.PPREFFR, EPRESNO), ),
            para_out=((SP.PMATUNS, MMATUNS), ),
        ),

        OP.RIGI_MECA_PRSU_F(te=425,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PGEOMER, NGEOMER), (SP.PPRESSF, CPRESSF),
                     (SP.PTEMPSR, CTEMPSR), ),
            para_out=((SP.PMATUNS, MMATUNS), ),
        ),

        OP.RIGI_MECA_PRSU_R(te=424,
            para_in=((SP.PDEPLMR, DDL_MECA), (SP.PDEPLPR, DDL_MECA),
                     (SP.PGEOMER, NGEOMER), (SP.PPRESSR, EPRESNO),
                     ),
            para_out=((SP.PMATUNS, MMATUNS), ),
        ),

        OP.SIRO_ELEM(te=411,
            para_in=((SP.PGEOMER, NGEOMER), (SP.PSIG3D, ECONTNO),
                     ),
            para_out=((SP.PPJSIGM, LC.EPJSIGM), ),
        ),

        OP.TOU_INI_ELEM(te=99,
            para_out=((SP.PFORC_R, CFORCER), (OP.TOU_INI_ELEM.PPRES_R, CPRES_R),
                     ),
        ),

        OP.TOU_INI_ELGA(te=99,
            para_out=((OP.TOU_INI_ELGA.PDEPL_R, EDEPLPG), (OP.TOU_INI_ELGA.PGEOM_R, EGGEOM_R),
                     (OP.TOU_INI_ELGA.PNEUT_F, EGNEUT_F), (OP.TOU_INI_ELGA.PNEUT_R, EGNEUT_R),
                     (OP.TOU_INI_ELGA.PPRES_R, LC.EPRESGA), ),
        ),

        OP.TOU_INI_ELNO(te=99,
            para_out=((OP.TOU_INI_ELNO.PGEOM_R, NGEOMER), (OP.TOU_INI_ELNO.PNEUT_F, LC.ENNEUT_F),
                     (OP.TOU_INI_ELNO.PNEUT_R, LC.ENNEUT_R), (OP.TOU_INI_ELNO.PPRES_R, EPRESNO),
                     (OP.TOU_INI_ELNO.PSIEF_R, ECONTNO), ),
        ),

    )


#------------------------------------------------------------
class MECA_FACE4(MECA_FACE3):
    """Please document this element"""
    meshType = MT.QUAD4
    nodes = (
            SetOfNodes('EN1', (1,2,3,4,)),
        )
    attrs = ((AT.BORD_ISO,'OUI'),)
    elrefe =(
            ElrefeLoc(MT.QU4, gauss = ('RIGI=FPG4',), mater=('RIGI',),),
        )


#------------------------------------------------------------
class MECA_FACE6(MECA_FACE3):
    """Please document this element"""
    meshType = MT.TRIA6
    nodes = (
            SetOfNodes('EN1', (1,2,3,4,5,6,)),
        )
    attrs = ((AT.BORD_ISO,'OUI'),)
    elrefe =(
            ElrefeLoc(MT.TR6, gauss = ('RIGI=FPG6',), mater=('RIGI',),),
        )


#------------------------------------------------------------
class MECA_FACE8(MECA_FACE3):
    """Please document this element"""
    meshType = MT.QUAD8
    nodes = (
            SetOfNodes('EN1', (1,2,3,4,5,6,7,8,)),
        )
    attrs = ((AT.BORD_ISO,'OUI'),)
    elrefe =(
            ElrefeLoc(MT.QU8, gauss = ('RIGI=FPG9',), mater=('RIGI',),),
        )


#------------------------------------------------------------
class MECA_FACE9(MECA_FACE3):
    """Please document this element"""
    meshType = MT.QUAD9
    nodes = (
            SetOfNodes('EN1', (1,2,3,4,5,6,7,8,9,)),
        )
    attrs = ((AT.BORD_ISO,'OUI'),)
    elrefe =(
            ElrefeLoc(MT.QU9, gauss = ('RIGI=FPG9',), mater=('RIGI',),),
        )
