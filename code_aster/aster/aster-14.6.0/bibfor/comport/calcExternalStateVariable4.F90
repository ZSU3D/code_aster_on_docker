! --------------------------------------------------------------------
! Copyright (C) 1991 - 2018 - EDF R&D - www.code-aster.org
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
!
subroutine calcExternalStateVariable4(nno     , npg   , ndim,&
                                      jv_dfunc,&
                                      geom    , typmod)
!
use calcul_module, only : ca_vext_eltsize2_
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/r8vide.h"
#include "asterfort/assert.h"
#include "asterfort/utmess.h"
#include "asterfort/mgauss.h"
#include "asterfort/r8inir.h"
!
integer, intent(in) :: nno, npg, ndim
integer, intent(in) :: jv_dfunc
character(len=8), intent(in) :: typmod(2)
real(kind=8), intent(in) :: geom(ndim, nno)
!
! --------------------------------------------------------------------------------------------------
!
! Behaviour - Compute intrinsic external state variables
!
! Case: size of element (ELTSIZE2)
!
! --------------------------------------------------------------------------------------------------
!
! In  nno              : number of nodes 
! In  npg              : number of Gauss points
! In  ndim             : dimension of problem (2 or 3)
! In  jv_dfunc         : JEVEUX adress for derivative of shape functions
! In  typmod2          : type of modelization (TYPMOD2)
! In  geom             : initial coordinates of nodes
!
! --------------------------------------------------------------------------------------------------
!
    integer :: kpg, i, j, k, jj, iret
    real(kind=8) :: l(3, 3)
    real(kind=8) :: inv(3, 3), det, de, dn, dk
!
! --------------------------------------------------------------------------------------------------
!
    if (typmod(1)(1:2) .eq. '3D') then
        do kpg = 1, npg
            do i = 1, 3
                l(1,i) = 0.d0
                l(2,i) = 0.d0
                l(3,i) = 0.d0
                do  j = 1, nno
                    k = 3*nno*(kpg-1)
                    jj = 3*(j-1)
                    de = zr(jv_dfunc-1+k+jj+1)
                    dn = zr(jv_dfunc-1+k+jj+2)
                    dk = zr(jv_dfunc-1+k+jj+3)
                    l(1,i) = l(1,i) + de*geom(i,j)
                    l(2,i) = l(2,i) + dn*geom(i,j)
                    l(3,i) = l(3,i) + dk*geom(i,j)
                end do
            end do
!
! --------- inversion de la matrice l
            iret = 0
            det  = 0.d0
            call r8inir(9, 0.d0, inv, 1)
            do i = 1, 3
                inv(i,i) = 1.d0
            end do
!
            call mgauss('NCVP', l, inv, 3, 3,&
                        3, det, iret)
!
            do i = 1, 3
                do j = 1, 3
                    ca_vext_eltsize2_(3*(i-1)+j)=inv(i,j)
                end do
            end do
        end do
!
    else
        ca_vext_eltsize2_(:) = r8vide()
    endif
!
end subroutine
