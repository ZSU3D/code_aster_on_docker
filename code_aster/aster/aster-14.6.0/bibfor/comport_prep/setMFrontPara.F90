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
! person_in_charge: mickael.abbas at edf.fr
!
subroutine setMFrontPara(v_para, i_comp)
!
use Behaviour_type
!
implicit none
!
#include "asterf_types.h"
#include "asterc/mfront_set_double_parameter.h"
#include "asterc/mfront_set_integer_parameter.h"
#include "asterc/mfront_set_outofbounds_policy.h"
#include "asterfort/assert.h"
!
type(Behaviour_Criteria), pointer :: v_para(:)
integer, intent(in) :: i_comp
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Set parameters for MFront
!
! --------------------------------------------------------------------------------------------------
!
! In  v_para           : list of informations to save
! In  i_comp           : index in previous list
!
! --------------------------------------------------------------------------------------------------
!
    type(Behaviour_External) :: comp_exte
    real(kind=8) :: iter_inte_maxi, resi_inte_rela
    integer:: iveriborne
    aster_logical :: l_mfront_proto, l_mfront_offi
    character(len=255) :: libr_name, subr_name
    character(len=16) :: model_mfront
!
! --------------------------------------------------------------------------------------------------
!
    iveriborne      = v_para(i_comp)%iveriborne
    resi_inte_rela  = v_para(i_comp)%resi_inte_rela
    iter_inte_maxi  = v_para(i_comp)%iter_inte_maxi
    comp_exte       = v_para(i_comp)%comp_exte
    l_mfront_offi   = comp_exte%l_mfront_offi
    l_mfront_proto  = comp_exte%l_mfront_proto
    libr_name       = comp_exte%libr_name 
    subr_name       = comp_exte%subr_name
    model_mfront    = comp_exte%model_mfront
!
! - Set values
!
    if (l_mfront_offi .or. l_mfront_proto) then
        call mfront_set_double_parameter(libr_name, subr_name, model_mfront,&
                                         "epsilon", resi_inte_rela)
        call mfront_set_integer_parameter(libr_name, subr_name, model_mfront,&
                                          "iterMax", int(iter_inte_maxi))
        call mfront_set_outofbounds_policy(libr_name, subr_name, model_mfront,&
                                           iveriborne)
    endif
!
end subroutine
