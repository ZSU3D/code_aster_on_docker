! --------------------------------------------------------------------
! Copyright (C) 1991 - 2019 - EDF R&D - www.code-aster.org
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
    subroutine merimo(base           , l_xfem   , l_macr_elem,&
                      model          , cara_elem, mate       , iter_newt,&
                      ds_constitutive, varc_refe,&
                      hval_incr      , hval_algo,&
                      optioz         , merigi   , vefint   ,&
                      ldccvg         , sddynz_)
        use NonLin_Datastructure_type
        character(len=1), intent(in) :: base
        aster_logical, intent(in) :: l_xfem, l_macr_elem
        character(len=24), intent(in) :: model
        character(len=24), intent(in) :: cara_elem
        character(len=*), intent(in) :: mate
        integer, intent(in) :: iter_newt
        type(NL_DS_Constitutive), intent(in) :: ds_constitutive
        character(len=24), intent(in) :: varc_refe
        character(len=19), intent(in) :: hval_incr(*), hval_algo(*)
        character(len=*), intent(in) :: optioz
        character(len=19), intent(in) :: merigi, vefint
        integer, intent(out) :: ldccvg
        character(len=*), optional, intent(in) :: sddynz_
    end subroutine merimo
end interface
