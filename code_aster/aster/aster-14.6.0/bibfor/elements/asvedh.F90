! --------------------------------------------------------------------
! Copyright (C) 2017 EDF R&D                  WWW.CODE-ASTER.ORG
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

subroutine asvedh(tpelt, coopg, invja, dh)
    implicit none
!
! ASSUMED STRAIN VECTOR DH
! EVALUATION OF VECTOR H DERIVATIVES
! ==================================
! Derivatives of h vectors in physical coordinate system are evaluated in this
! routine.  These are required within the frame of the assumed strain method,
! implemented for under-integrated SHB6 elements.
!
! Vectors h are expressed with help of the element parametric coordinates.
! 2 vectors h are defined for SHB6 element and are shared with the 4 defined for
! HEXS8 element. They are recalled here below.
! $h_{1}=\eta\cdot\zeta$
! $h_{2}=\zeta\cdot\xi$
! $h_{3}=\xi\cdot\eta$
! $h_{4}=\xi\cdot\eta\cdot\zeta$
!
!
! IN :  tpelt    element type: 1 for SHB6 
! IN    coopg    gauss point coordinates where are evaluated derivatives
! IN    invja    inverse jacobian matrix
! OUT   dh       derivatives of vector h in physical coordinate system
!
#include "asterfort/r8inir.h"
!
    integer, intent(in) :: tpelt
    real(kind=8), intent(in) :: coopg(3)
    real(kind=8), intent(in) :: invja(3,3)
    real(kind=8), intent(out) :: dh(4,3)
!
! ......................................................................
!
    call r8inir(12, 0.d0, dh, 1)
!
!   Evaluate dh1 & dh2, applicable for hexa & prisme element
!
    dh(1,1) = coopg(2)*invja(3,1) + coopg(3)*invja(2,1)
    dh(1,2) = coopg(2)*invja(3,2) + coopg(3)*invja(2,2)
    dh(1,3) = coopg(2)*invja(3,3) + coopg(3)*invja(2,3)
!
    dh(2,1) = coopg(1)*invja(3,1) + coopg(3)*invja(1,1)
    dh(2,2) = coopg(1)*invja(3,2) + coopg(3)*invja(1,2)
    dh(2,3) = coopg(1)*invja(3,3) + coopg(3)*invja(1,3)
!
!   Evaluate dh3 & dh4, applicable for hexa element
!
    if(tpelt.eq.2) then
       dh(3,1) = coopg(1)*invja(2,1) + coopg(2)*invja(1,1)
       dh(3,2) = coopg(1)*invja(2,2) + coopg(2)*invja(1,2)
       dh(3,3) = coopg(1)*invja(2,3) + coopg(2)*invja(1,3)
!
       dh(4,1) = coopg(1)*coopg(2)*invja(3,1) +&
                &coopg(2)*coopg(3)*invja(1,1) +&
                &coopg(1)*coopg(3)*invja(2,1)
       dh(4,2) = coopg(1)*coopg(2)*invja(3,2) +&
                &coopg(2)*coopg(3)*invja(1,2) +&
                &coopg(1)*coopg(3)*invja(2,2)
       dh(4,3) = coopg(1)*coopg(2)*invja(3,3) +&
                &coopg(2)*coopg(3)*invja(1,3) +&
                &coopg(1)*coopg(3)*invja(2,3)
    endif
!
end subroutine
