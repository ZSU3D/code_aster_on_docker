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
interface
    subroutine nmetca(modele, noma, ds_material, sddisc, sdcriq,&
                      numins, valinc)
        use NonLin_Datastructure_type
        character(len=24) :: modele
        character(len=8) :: noma
        type(NL_DS_Material), intent(in) :: ds_material
        character(len=19) :: sddisc
        character(len=24) :: sdcriq
        integer :: numins
        character(len=19) :: valinc(*)
    end subroutine nmetca
end interface
