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


from .cata_comportement import LoiComportement

loi = LoiComportement(
    nom            = 'GRILLE_PINTO_MEN',
    lc_type        = ('MECANIQUE',),
    doc            =   """Relation de comportement des grilles d'armatures de béton armé, à comportement cyclique phénoménologique de Pinto et Menegotto"""              ,
    num_lc         = 0,
    nb_vari        = 16,
    nom_vari       = ('EPSRN-1','EPSRN','SIGRN','EPSM+V5','DEPS-TH',
        'INDICYCL','INDIPLAS','INDIFLAM','VIDE','VIDE',
        'VIDE','VIDE','VIDE','VIDE','VIDE',
        'VIDE',),
    mc_mater       = None,
    modelisation   = ('GRILLE_MEMBRANE','GRILLE_EXCENTRE','1D',),
    deformation    = ('PETIT',),
    algo_inte      = ('ANALYTIQUE',),
    type_matr_tang = None,
    proprietes     = None,
    syme_matr_tang = ('Yes',),
    exte_vari      = None,
    deform_ldc     = ('OLD',),
)