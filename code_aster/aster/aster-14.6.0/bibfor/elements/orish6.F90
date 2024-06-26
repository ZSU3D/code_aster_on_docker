! --------------------------------------------------------------------
! Copyright (C) 1991 - 2017 - EDF R&D - www.code-aster.org
! This file is part of code_aster.
!
! code_aster is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! code_aster is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with code_aster.  If not, see <http://www.gnu.org/licenses/>.
! --------------------------------------------------------------------

subroutine orish6(coor, ps)
    implicit   none
#include "asterfort/provec.h"
#include "blas/ddot.h"
    integer :: j
    real(kind=8) :: coor(18), ps
    real(kind=8) :: vec1(3), vec2(3), vec3(3), vect(3)
! ======================================================================
!
!    ORISHB6  --  VERIFIE SI LA NORMALE A LA PREMIERE FACE : 12 VECT 13
!                 EST RENTRANTE POUR UNE MAILLE PENTA6
!   ARGUMENT       E/S  TYPE         ROLE
!    COOR         IN    R         COORDONNEES DES 6 NOEUDS
!    PS           OUT   R         PRODUIT SCALAIRE : SI >0, NORMALE
!                                 RENTRANTE.
!
!.======================================================================
!
! VECTEURS 12 13 et 14
    do 10 j = 1, 3
        vec1(j) = coor(3+j) - coor(j)
        vec2(j) = coor(6+j) - coor(j)
        vect(j) = coor(9+j) - coor(j)
10  end do
! CALCUL DU PRODUIT VECTORIEL 12 X 13
    call provec(vec1, vec2, vec3)
!
!  VEC3= PRODUIT VECTORIEL 12 X 13 EST IL DANS LA DIRECTION DE 14
    ps=ddot(3,vec3,1,vect,1)
!
end subroutine
