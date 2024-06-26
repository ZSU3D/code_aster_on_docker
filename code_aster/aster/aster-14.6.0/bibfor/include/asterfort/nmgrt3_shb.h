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
!
#include "asterf_types.h"
!
interface
    subroutine nmgrt3_shb(nno, poids, def, pff, option,&
                      dsidep, sign, sigma, matsym, matuu)
        integer :: nno
        real(kind=8) :: poids
        real(kind=8) :: def(6, nno, 3)
        real(kind=8) :: pff(6, nno, nno)
        character(len=16) :: option
        real(kind=8) :: dsidep(6, 6)
        real(kind=8) :: sign(6)
        real(kind=8) :: sigma(6)
        aster_logical :: matsym
        real(kind=8) :: matuu(*)
    end subroutine nmgrt3_shb
end interface
