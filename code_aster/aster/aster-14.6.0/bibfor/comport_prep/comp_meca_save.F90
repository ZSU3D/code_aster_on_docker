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
subroutine comp_meca_save(model         , mesh, chmate, compor, nb_cmp,&
                          ds_compor_prep)
!
use Behaviour_type
!
implicit none
!
#include "asterf_types.h"
#include "asterc/getexm.h"
#include "asterfort/getvtx.h"
#include "asterfort/assert.h"
#include "asterfort/comp_meca_l.h"
#include "asterfort/comp_read_mesh.h"
#include "asterfort/dismoi.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
#include "asterfort/jedetr.h"
#include "asterfort/jelira.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/nmdpmf.h"
#include "asterfort/nocart.h"
#include "asterfort/reliem.h"
#include "asterfort/utmess.h"
#include "asterfort/setBehaviourTypeValue.h"
!
character(len=8), intent(in) :: model, mesh, chmate
character(len=19), intent(in) :: compor
integer, intent(in) :: nb_cmp
type(Behaviour_PrepPara), intent(in) :: ds_compor_prep
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Save informations in COMPOR <CARTE>
!
! --------------------------------------------------------------------------------------------------
!
! In  model            : name of model
! In  mesh             : name of mesh
! In  chmate           : name of material field
! In  compor           : name of <CARTE> COMPOR
! In  nb_cmp           : number of components in <CARTE> COMPOR
! In  ds_compor_prep   : datastructure to prepare comportement
!
! --------------------------------------------------------------------------------------------------
!
    character(len=24) :: list_elem_affe
    aster_logical :: l_affe_all
    integer :: nb_elem_affe, nb_model_affe
    integer, pointer :: v_elem_affe(:) => null()
    integer, pointer :: v_model_elem(:) => null()
    integer :: i_elem_affe
    character(len=19) :: ligrmo
    character(len=16) :: keywordfact
    integer :: i_comp, nb_comp
    character(len=16), pointer :: v_compor_valv(:) => null()
    aster_logical :: l_cristal, l_pmf, l_is_pmf
    integer :: elem_nume
!
! --------------------------------------------------------------------------------------------------
!
    keywordfact    = 'COMPORTEMENT'
    list_elem_affe = '&&COMPMECASAVE.LIST'
    nb_comp        = ds_compor_prep%nb_comp
    l_is_pmf       = ASTER_FALSE
    ligrmo         =  model//'.MODELE'
!
! - Access to MODEL
!
    call jeveuo(model//'.MAILLE', 'L', vi=v_model_elem)
!
! - Access to COMPOR <CARTE>
!
    call jeveuo(compor//'.VALV', 'E', vk16 = v_compor_valv)
!
! - Loop on occurrences of COMPORTEMENT
!
    do i_comp = 1, nb_comp
!
! ----- Detection of specific cases
!
        call comp_meca_l(ds_compor_prep%v_comp(i_comp)%rela_comp, 'CRISTAL', l_cristal)
        call comp_meca_l(ds_compor_prep%v_comp(i_comp)%rela_comp, 'PMF'    , l_pmf)
!
! ----- Multifiber beams
!
        if (l_pmf) then
            l_is_pmf = .true.
        endif
!
! ----- Get elements
!
        call comp_read_mesh(mesh          , keywordfact, i_comp      ,&
                            list_elem_affe, l_affe_all , nb_elem_affe)
!
! ----- Check if elements belong to model
!
        nb_model_affe = 0
        if (nb_elem_affe .ne. 0) then
            call jeveuo(list_elem_affe, 'L', vi = v_elem_affe)
            do i_elem_affe = 1, nb_elem_affe
                elem_nume = v_elem_affe(i_elem_affe)
                if (v_model_elem(elem_nume) .ne. 0) then
                    nb_model_affe = nb_model_affe + 1
                endif
            end do
        endif
        if (.not.l_affe_all) then
            if (nb_model_affe.eq.0) then
                call utmess('A', 'COMPOR4_72', si = i_comp)
            endif
        endif
!
! ----- Save informations in the field <COMPOR>
!
        call setBehaviourTypeValue(ds_compor_prep%v_comp, i_comp, v_compor_ = v_compor_valv)
!
! ----- Affect in <CARTE>
!
        if (l_affe_all) then
            call nocart(compor, 1, nb_cmp)
        else
            call jeveuo(list_elem_affe, 'L', vi = v_elem_affe)
            call nocart(compor, 3, nb_cmp, mode = 'NUM', nma = nb_elem_affe,&
                        limanu = v_elem_affe)
            call jedetr(list_elem_affe)
        endif
    enddo
!
! - Compor <CARTE> fusing for multifiber beams
!
    if (l_is_pmf) then
        call nmdpmf(compor, chmate)
    endif
!
    call jedetr(compor//'.NCMP')
    call jedetr(compor//'.VALV')
!
end subroutine
