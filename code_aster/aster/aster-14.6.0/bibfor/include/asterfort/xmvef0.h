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

!
#include "asterf_types.h"
!
interface
    subroutine xmvef0(ndim, jnne, nnc,&
                      hpg, ffc, jacobi, lpenac,&
                      dlagrf, tau1, tau2,&
                      jddle, nfhe, lmulti, heavno,&
                      vtmp)
        integer :: ndim
        integer :: jnne(3)
        integer :: nnc
        real(kind=8) :: hpg
        real(kind=8) :: ffc(9)
        real(kind=8) :: jacobi
        aster_logical :: lpenac
        real(kind=8) :: dlagrf(2)
        real(kind=8) :: tau1(3)
        real(kind=8) :: tau2(3)
        integer :: jddle(2)
        integer :: nfhe
        aster_logical :: lmulti
        integer :: heavno(8)
        real(kind=8) :: vtmp(336)
    end subroutine xmvef0
end interface
