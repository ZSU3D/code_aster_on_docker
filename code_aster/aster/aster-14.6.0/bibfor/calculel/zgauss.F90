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

subroutine zgauss(v_matr, v_2mbr, dim, nb, v_solu)
!
implicit none
!
#include "asterf_types.h"
#include "asterc/matfpe.h"
#include "asterfort/assert.h"
#include "blas/zgesvx.h"
!
! aslint: disable=W1304,W1306
!
    integer, intent(in) :: dim
    integer, intent(in) :: nb
    complex(kind=8), pointer :: v_matr(:)
    complex(kind=8), pointer :: v_2mbr(:)
    complex(kind=8), pointer :: v_solu(:)
!
! --------------------------------------------------------------------------------------------------
!
    complex(kind=8) :: af(dim, dim)
    complex(kind=8) :: work(2*dim)
    integer(kind=4) :: ipiv(dim*dim)
    real(kind=8) :: r(dim)
    real(kind=8) :: c(dim)
    real(kind=8) :: ferr(nb)
    real(kind=8) :: berr(nb)
    real(kind=8) :: rwork(2*dim)
    character(len=1) :: equed
    integer(kind=4) :: info
    real(kind=8) :: rcond
!
! --------------------------------------------------------------------------------------------------
!
    call matfpe(-1)
!
    equed = 'N'
    call zgesvx('N', 'T', dim, nb, v_matr,&
                dim, af, dim, ipiv, equed,&
                r, c, v_2mbr, dim, v_solu,&
                dim, rcond, ferr, berr, work,&
                rwork, info)
!
    call matfpe(1)
!
end subroutine
