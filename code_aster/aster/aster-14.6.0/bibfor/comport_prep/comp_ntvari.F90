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
! aslint: disable=W1003
! person_in_charge: mickael.abbas at edf.fr
!
subroutine comp_ntvari(model_ , compor_cart_, compor_list_, compor_info,&
                       nt_vari, nb_vari_maxi, nb_zone     , v_exte)
!
use Behaviour_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jelira.h"
#include "asterfort/jenuno.h"
#include "asterfort/jexnum.h"
#include "asterfort/jexatr.h"
#include "asterfort/getExternalBehaviourPara.h"
#include "asterfort/teattr.h"
#include "asterfort/Behaviour_type.h"
!
character(len=8), optional, intent(in) :: model_
character(len=19), optional, intent(in) :: compor_cart_
character(len=16), optional, intent(in) :: compor_list_(20)
character(len=19), intent(in) :: compor_info
integer, intent(out) :: nt_vari
integer, intent(out) :: nb_vari_maxi
integer, intent(out) :: nb_zone
type(Behaviour_External), pointer :: v_exte(:)
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Count total of internal variables
!
! --------------------------------------------------------------------------------------------------
!
! In  model            : name of model
! In  compor_cart      : name of <CARTE> COMPOR
! In  compor_list      : name of list of COMPOR (for SIMU_POINT_MAT)
! Out nt_vari          : total number of internal variables (on all <CARTE> COMPOR)
! Out nb_vari_maxi     : maximum number of internal variables on all comportments"
! Out nb_zone          : number of affected zones
! Out v_exte           : pointer to external constitutive laws parameters
!
! --------------------------------------------------------------------------------------------------
!
    aster_logical :: l_comp_external
    integer, pointer :: v_model_elem(:) => null()
    character(len=16), pointer :: v_compor_vale(:) => null()
    integer, pointer :: v_zone(:) => null()
    integer, pointer :: v_compor_desc(:) => null()
    integer, pointer :: v_compor_lima(:) => null()
    integer, pointer :: v_compor_lima_lc(:) => null()
    integer :: nb_vale, nb_cmp_max, nb_vari, nb_elem, nb_elem_mesh
    integer :: i_zone, iret, i_elem, posit
    integer :: type_affe, indx_affe, elem_type_nume, elem_nume, model_dim
    character(len=16) :: elem_type_name
    character(len=16) :: post_iter
    character(len=16) :: rela_comp, defo_comp, mult_comp, kit_comp(4), type_cpla
    character(len=16) :: model_mfront
    character(len=255) :: libr_name, subr_name
    character(len=16) :: principal
    character(len=8) :: mesh
!
! --------------------------------------------------------------------------------------------------
!
    nt_vari      = 0
    nb_vari_maxi = 0
    nb_zone      = 0
    v_exte       => null()
    if (present(model_)) then
        call jeveuo(model_//'.MAILLE', 'L', vi = v_model_elem)
    endif
!
! - Access to <CARTE> COMPOR
!
    if (present(compor_cart_)) then
        call jeveuo(compor_cart_//'.DESC', 'L', vi   = v_compor_desc)
        call jeveuo(compor_cart_//'.VALE', 'L', vk16 = v_compor_vale)
        call jelira(compor_cart_//'.VALE', 'LONMAX', nb_vale)
        call jeveuo(jexnum(compor_cart_//'.LIMA', 1), 'L', vi = v_compor_lima)
        call jeveuo(jexatr(compor_cart_//'.LIMA', 'LONCUM'), 'L', vi = v_compor_lima_lc)
        nb_zone    = v_compor_desc(3)
        nb_cmp_max = nb_vale/v_compor_desc(2)
        call dismoi('NOM_MAILLA'  , compor_cart_, 'CARTE'   , repk=mesh)
        call dismoi('NB_MA_MAILLA', mesh        , 'MAILLAGE', repi=nb_elem_mesh)
    else if (present(compor_list_)) then
        nb_zone      = 1
        nb_cmp_max   = 0
        nb_elem_mesh = 1
    endif
!
! - Create list of zones: for each zone (in CARTE), how many elements 
!
    call jeveuo(compor_info(1:19)//'.ZONE', 'L', vi = v_zone)
!
! - Prepare objects for external constitutive laws
!
    allocate(v_exte(nb_zone))
!
! - Count internal variables by comportment
!
    do i_zone = 1, nb_zone
!
        subr_name    = ' '
        libr_name    = ' '
        model_mfront = ' '
        model_dim    = 0
!
! ----- Get parameters
!
        if (present(compor_cart_)) then
            rela_comp   = v_compor_vale(nb_cmp_max*(i_zone-1)+RELA_NAME)
            defo_comp   = v_compor_vale(nb_cmp_max*(i_zone-1)+DEFO)
            type_cpla   = v_compor_vale(nb_cmp_max*(i_zone-1)+PLANESTRESS)
            mult_comp   = v_compor_vale(nb_cmp_max*(i_zone-1)+MULTCOMP)
            kit_comp(1) = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT1_NAME)
            kit_comp(2) = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT2_NAME)
            kit_comp(3) = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT3_NAME)
            kit_comp(4) = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT4_NAME)
            post_iter   = v_compor_vale(nb_cmp_max*(i_zone-1)+POSTITER)
        else
            rela_comp   = compor_list_(RELA_NAME)
            defo_comp   = compor_list_(DEFO)
            type_cpla   = compor_list_(PLANESTRESS)
            mult_comp   = compor_list_(MULTCOMP)
            kit_comp(1) = compor_list_(KIT1_NAME)
            kit_comp(2) = compor_list_(KIT2_NAME)
            kit_comp(3) = compor_list_(KIT3_NAME)
            kit_comp(4) = compor_list_(KIT4_NAME)
            post_iter   = compor_list_(POSTITER)
        endif
!
! ----- Find right TYPELEM
!
        if (present(compor_cart_)) then
            type_affe = v_compor_desc(1+3+(i_zone-1)*2)
            indx_affe = v_compor_desc(1+4+(i_zone-1)*2)
            if (type_affe .eq. 3) then
                nb_elem   = v_compor_lima_lc(1+indx_affe)-v_compor_lima_lc(indx_affe)
                posit     = v_compor_lima_lc(indx_affe)
            elseif (type_affe .eq. 1) then
                nb_elem   = nb_elem_mesh
                posit     = 0
            else
                ASSERT(.false.)
            endif
        else
            type_affe = 0
            nb_elem   = 1
            ASSERT(i_zone .eq. 1)
        endif 
        do i_elem = 1, nb_elem
            if (type_affe .eq. 3) then
                elem_nume = v_compor_lima(posit+i_elem-1)
            elseif (type_affe .eq. 1) then
                elem_nume = i_elem
            elseif (type_affe .eq. 0) then
                elem_nume = 1
            else
                ASSERT(.false.)
            endif
            if (elem_nume .ne. 0 .and. type_affe .gt. 0) then
                elem_type_nume = v_model_elem(elem_nume)
                if (elem_type_nume .ne. 0) then
                    call jenuno(jexnum('&CATA.TE.NOMTE', elem_type_nume), elem_type_name)
                    call teattr('C', 'PRINCIPAL'      , principal  , iret, typel = elem_type_name)
                    if (principal .eq. 'OUI') then
                        goto 20
                    endif
                endif
            endif
        end do
!
    20  continue
!
! ----- Get parameters for external programs (MFRONT/UMAT)
!
        call getExternalBehaviourPara(mesh           , v_model_elem  ,&
                                      rela_comp      , kit_comp      ,&
                                      l_comp_external, v_exte(i_zone), elem_type_ = elem_type_nume,&
                                      type_cpla_in_   = type_cpla)
!
! ----- Get number of internal variables
!
        if (present(compor_cart_)) then
            read (v_compor_vale(nb_cmp_max*(i_zone-1)+2),'(I16)') nb_vari
        else
            read (compor_list_(2),'(I16)') nb_vari
        endif
        nt_vari      = nt_vari+nb_vari
        nb_vari_maxi = max(nb_vari_maxi,nb_vari)
    end do
!
end subroutine
