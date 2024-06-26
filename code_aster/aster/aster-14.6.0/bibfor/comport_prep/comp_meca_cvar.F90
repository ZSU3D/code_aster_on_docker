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
! person_in_charge: mickael.abbas at edf.fr
!
subroutine comp_meca_cvar(ds_compor_prep)
!
use Behaviour_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/comp_nbvari.h"
!
type(Behaviour_PrepPara), intent(inout) :: ds_compor_prep
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Count all internal variables
!
! --------------------------------------------------------------------------------------------------
!
! IO  ds_compor_prep   : datastructure to prepare comportement
!
! --------------------------------------------------------------------------------------------------
!
    integer :: i_comp, nb_comp
    character(len=16) :: keywordfact
    character(len=16) :: post_iter
    character(len=16) :: rela_comp, defo_comp, mult_comp, kit_comp(4), type_cpla
    integer :: nume_comp(4), nb_vari, nb_vari_comp(4), nb_vari_umat, model_dim
    character(len=255) :: libr_name, subr_name
    character(len=16) :: model_mfront
    aster_logical :: l_implex
!
! --------------------------------------------------------------------------------------------------
!
    keywordfact    = 'COMPORTEMENT'
    nb_comp        = ds_compor_prep%nb_comp
!
! - Loop on occurrences of COMPORTEMENT
!
    do i_comp = 1, nb_comp
!
! ----- Init
!
        nb_vari           = 0
        nume_comp(1:4)    = 0
        nb_vari_comp(1:4) = 0
!
! ----- Options
!
        rela_comp    = ds_compor_prep%v_comp(i_comp)%rela_comp
        defo_comp    = ds_compor_prep%v_comp(i_comp)%defo_comp
        type_cpla    = ds_compor_prep%v_comp(i_comp)%type_cpla
        kit_comp(:)  = ds_compor_prep%v_comp(i_comp)%kit_comp(:)
        mult_comp    = ds_compor_prep%v_comp(i_comp)%mult_comp
        post_iter    = ds_compor_prep%v_comp(i_comp)%post_iter
        libr_name    = ds_compor_prep%v_exte(i_comp)%libr_name
        subr_name    = ds_compor_prep%v_exte(i_comp)%subr_name
        nb_vari_umat = ds_compor_prep%v_exte(i_comp)%nb_vari_umat
        model_mfront = ds_compor_prep%v_exte(i_comp)%model_mfront
        model_dim    = ds_compor_prep%v_exte(i_comp)%model_dim
        l_implex     = ds_compor_prep%l_implex
!
! ----- Count internal variables
!
        call comp_nbvari(rela_comp   , defo_comp, type_cpla   , kit_comp ,&
                         post_iter   , mult_comp, libr_name,&
                         subr_name   , model_dim, model_mfront, nb_vari  ,&
                         nb_vari_umat, l_implex ,&
                         nb_vari_comp, nume_comp)
!
! ----- Save informations
!
        ds_compor_prep%v_comp(i_comp)%nb_vari         = nb_vari
        ds_compor_prep%v_comp(i_comp)%nb_vari_comp(:) = nb_vari_comp(:)
        ds_compor_prep%v_comp(i_comp)%nume_comp(:)    = nume_comp(:)
    end do
!
end subroutine
