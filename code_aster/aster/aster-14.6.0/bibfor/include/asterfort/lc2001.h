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
interface
    subroutine lc2001(fami, kpg, ksp, ndim, imate,&
                      neps, deps, nsig, sigm, option,&
                      angmas, sigp, vip, typmod, ndsde,&
                      dsidep, codret)
        character(len=*), intent(in) :: fami
        integer, intent(in) :: kpg
        integer, intent(in) :: ksp
        integer, intent(in) :: ndim
        integer, intent(in) :: imate
        integer, intent(in) :: neps
        real(kind=8), intent(in) :: deps(neps)
        integer, intent(in) :: nsig
        real(kind=8), intent(in) :: sigm(nsig)
        character(len=16), intent(in) :: option
        real(kind=8), intent(in) :: angmas(3)
        real(kind=8), intent(out) :: sigp(nsig)
        real(kind=8), intent(out) :: vip(1)
        character(len=8), intent(in) :: typmod(*)
        integer, intent(in) :: ndsde
        real(kind=8), intent(out) :: dsidep(ndsde)
        integer, intent(out) :: codret
    end subroutine lc2001
end interface
