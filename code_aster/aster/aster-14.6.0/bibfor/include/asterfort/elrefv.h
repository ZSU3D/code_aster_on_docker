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
    subroutine elrefv(nomte, famil, ndim, nno, nno2,&
                      nnos, npg, ipoids, ivf, ivf2,&
                      idfde, idfde2, jgano, jgano2)
        character(len=16) :: nomte
        character(len=4) :: famil
        integer :: ndim
        integer :: nno
        integer :: nno2
        integer :: nnos
        integer :: npg
        integer :: ipoids
        integer :: ivf
        integer :: ivf2
        integer :: idfde
        integer :: idfde2
        integer :: jgano
        integer :: jgano2
    end subroutine elrefv
end interface
