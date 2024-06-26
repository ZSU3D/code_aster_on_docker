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
subroutine comp_meca_pvar(model_, compor_cart_, compor_list_, compor_info)
!
use Behaviour_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/as_allocate.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/comp_meca_name.h"
#include "asterfort/comp_ntvari.h"
#include "asterfort/dismoi.h"
#include "asterfort/etenca.h"
#include "asterfort/jecrec.h"
#include "asterfort/jecroc.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeecra.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/jexatr.h"
#include "asterfort/wkvect.h"
#include "asterfort/comp_meca_exc2.h"
#include "asterfort/comp_meca_l.h"
#include "asterfort/lteatt.h"
#include "asterfort/Behaviour_type.h"
!
character(len=8), optional, intent(in) :: model_
character(len=19), optional, intent(in) :: compor_cart_
character(len=16), optional, intent(in) :: compor_list_(20)
character(len=19), intent(in) :: compor_info
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Prepare informations about internal variables
!
! --------------------------------------------------------------------------------------------------
!
! In  model            : name of model
! In  compor_info      : name of object for information about internal variables and comportement
! In  compor_cart      : name of <CARTE> COMPOR
! In  compor_list      : name of list of COMPOR (for SIMU_POINT_MAT)
!
!    Objects:
!       INFO.INFO = global parameters
!         v_info(1) = nb_elem_mesh
!          => total number of elements in mesh
!         v_info(2) = nb_zone
!          => total number of zone in CARTE
!         v_info(3) = nb_vari_maxi
!          => maximum number of internal variables
!         v_info(4) = nt_vari    
!          => total number of internal variables
!       INFO.VARI = Collection of nb_zone (from CARTE) x Vecteur_Info
!       For each zone   : Vector_Info is list of nb_vari name of internal variables (K16)
!       INFO.ZONE = list on nb_zone (from CARTE)
!       For each zone   : number of elements with this comportement
!       INFO.RELA = list on nb_zone (from CARTE) * 8
!       For each zone   : some information from comprotement (name of RELATION, DEFORMATION, ...)
!
! --------------------------------------------------------------------------------------------------
!
    aster_logical :: l_excl, l_kit_meta, l_cristal, l_pmf, l_kit_thm
    aster_logical :: l_umat, l_mfront_proto, l_mfront_offi, l_prot_comp
    aster_logical :: l_zone_read
    character(len=8) :: mesh
    character(len=19) :: ligrmo
    integer, pointer :: v_info(:) => null()
    integer, pointer :: v_zone(:) => null()
    integer, pointer :: v_zone_read(:) => null()
    integer, pointer :: v_model_elem(:) => null()
    character(len=16), pointer :: v_vari(:) => null()
    character(len=16), pointer :: v_rela(:) => null()
    character(len=16), pointer :: v_compor_vale(:) => null()
    integer, pointer :: v_compor_desc(:) => null()
    integer, pointer :: v_compor_lima(:) => null()
    integer, pointer :: v_compor_lima_lc(:) => null()
    integer, pointer :: v_compor_ptma(:) => null()
    integer :: nb_vale, nb_cmp_max, nb_zone, nb_vari, nt_vari, nb_vari_maxi, nb_zone_acti, nb_zone2
    integer :: i_zone, i_elem, nb_elem_mesh, iret, nutyel, nb_vari_meca
    character(len=16) :: post_iter, vari_excl
    character(len=16) :: rela_comp, defo_comp, kit_comp(4), type_cpla, type_comp
    character(len=255) :: libr_name, subr_name
    character(len=16) :: model_mfront, notype
    integer :: model_dim
    type(Behaviour_External), pointer :: v_exte(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
! - Initializations
!
    nb_zone_acti = 0
!
! - Access to COMPOR
!
    if (present(compor_cart_)) then
        call jeveuo(compor_cart_//'.DESC', 'L', vi   = v_compor_desc)
        call jeveuo(compor_cart_//'.VALE', 'L', vk16 = v_compor_vale)
        call jelira(compor_cart_//'.VALE', 'LONMAX', nb_vale)
        call jeveuo(jexnum(compor_cart_//'.LIMA', 1), 'L', vi = v_compor_lima)
        call jeveuo(jexatr(compor_cart_//'.LIMA', 'LONCUM'), 'L', vi = v_compor_lima_lc)
        nb_zone    = v_compor_desc(3)
        nb_cmp_max = nb_vale/v_compor_desc(2)
        call dismoi('NOM_MAILLA'  , compor_cart_, 'CARTE', repk=mesh)
        call dismoi('NB_MA_MAILLA', mesh        , 'MAILLAGE', repi=nb_elem_mesh)
        ligrmo = model_(1:8)//'.MODELE'
        call jeveuo(model_//'.MAILLE', 'L', vi = v_model_elem)
        call etenca(compor_cart_, ligrmo, iret)
        call jeveuo(compor_cart_//'.PTMA', 'L', vi = v_compor_ptma)
    else if (present(compor_list_)) then
        nb_zone      = 1
        nb_cmp_max   = 0
        nb_elem_mesh = 1
    else
        ASSERT(.false.)
    endif
!
! - Create list of zones: for each zone (in CARTE), how many elements 
!
    call wkvect(compor_info(1:19)//'.ZONE', 'V V I', nb_zone, vi = v_zone)
!
! - Count number of elements by zone (in CARTE)
!
    if (present(compor_cart_)) then
        do i_elem = 1, nb_elem_mesh
            i_zone = v_compor_ptma(i_elem)
            if (i_zone .ne. 0 .and. v_model_elem(i_elem) .ne. 0) then
                v_zone(i_zone) = v_zone(i_zone)+1
            endif
        end do
    else
        v_zone(1) = 1
    endif
!
! - Count total of internal variables
!
    if (present(compor_cart_)) then
        call comp_ntvari(model_ = model_, compor_cart_ = compor_cart_, compor_info = compor_info,&
                         nt_vari = nt_vari, nb_vari_maxi = nb_vari_maxi,&
                         nb_zone = nb_zone2, v_exte = v_exte)
    elseif (present(compor_list_)) then
        call comp_ntvari(compor_list_ = compor_list_, compor_info = compor_info,&
                         nt_vari = nt_vari, nb_vari_maxi = nb_vari_maxi,&
                         nb_zone = nb_zone2, v_exte = v_exte)
    else
        ASSERT(.false.)
    endif
    ASSERT(nb_zone2 .eq. nb_zone)
    AS_ALLOCATE(vi = v_zone_read, size = nb_zone)
!
! - No internal variables names
!
    if (nt_vari .eq. 0) then
        goto 99
    endif
!
! - Create list of comportment information (RELATION, DEFORMATION, etc.)
!
    call wkvect(compor_info(1:19)//'.RELA', 'V V K16', 3*nb_zone, vk16 = v_rela)
!
! - Create list of internal variables names
!
    call jecrec(compor_info(1:19)//'.VARI', 'V V K16', 'NU', 'DISPERSE', 'VARIABLE', nb_zone)
    do i_zone = 1, nb_zone
        call jecroc(jexnum(compor_info(1:19)//'.VARI', i_zone))
    end do
! 
    do i_elem = 1, nb_elem_mesh
!
! ----- Get current zone
!
        if (present(compor_cart_)) then
            i_zone = v_compor_ptma(i_elem)
            if (i_zone .eq. 0) then
                l_zone_read = .true.
            else
                ASSERT(i_zone .ne. 0)
                l_zone_read = v_zone_read(i_zone) .eq. 1
            endif
        else
            i_zone      = 1
            l_zone_read = .false._1
        endif
        if (.not. l_zone_read) then
!
! --------- Get parameters
!
            if (present(compor_cart_)) then
                rela_comp    = v_compor_vale(nb_cmp_max*(i_zone-1)+RELA_NAME)
                defo_comp    = v_compor_vale(nb_cmp_max*(i_zone-1)+DEFO)
                type_comp    = v_compor_vale(nb_cmp_max*(i_zone-1)+INCRELAS)
                type_cpla    = v_compor_vale(nb_cmp_max*(i_zone-1)+PLANESTRESS)
                kit_comp(1)  = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT1_NAME)
                kit_comp(2)  = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT2_NAME)
                kit_comp(3)  = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT3_NAME)
                kit_comp(4)  = v_compor_vale(nb_cmp_max*(i_zone-1)+KIT4_NAME)
                post_iter    = v_compor_vale(nb_cmp_max*(i_zone-1)+POSTITER)
                read (v_compor_vale(nb_cmp_max*(i_zone-1)+NVAR),'(I16)') nb_vari
                nb_vari_meca = 0
                if (v_compor_vale(nb_cmp_max*(i_zone-1)+MECA_NVAR) .ne. 'VIDE') then
                    read (v_compor_vale(nb_cmp_max*(i_zone-1)+MECA_NVAR),'(I16)') nb_vari_meca
                endif
            else
                rela_comp    = compor_list_(RELA_NAME)
                defo_comp    = compor_list_(DEFO)
                type_cpla    = compor_list_(PLANESTRESS)
                type_comp    = compor_list_(INCRELAS)
                kit_comp(1)  = compor_list_(KIT1_NAME)
                kit_comp(2)  = compor_list_(KIT2_NAME)
                kit_comp(3)  = compor_list_(KIT3_NAME)
                kit_comp(4)  = compor_list_(KIT4_NAME)
                post_iter    = compor_list_(POSTITER)
                read (compor_list_(NVAR),'(I16)') nb_vari
                nb_vari_meca = 0
                if (compor_list_(MECA_NVAR) .ne. 'VIDE') then
                    read (compor_list_(MECA_NVAR),'(I16)') nb_vari_meca
                endif
            endif
!
! --------- Detection of specific cases
!
            call comp_meca_l(rela_comp, 'KIT_THM' , l_kit_thm)
            call comp_meca_l(rela_comp, 'KIT_META', l_kit_meta)
            call comp_meca_l(rela_comp, 'CRISTAL' , l_cristal)
            if (present(compor_list_)) then
                l_pmf = .false._1
            else
                nutyel = v_model_elem(i_elem)
                if (nutyel .eq. 0) then
                    l_pmf = .false._1
                else
                    call jenuno(jexnum('&CATA.TE.NOMTE', nutyel), notype)
                    l_pmf = lteatt('TYPMOD2','PMF', typel = notype)
                endif
            endif
!
! --------- Parameters for external constitutive laws
!
            l_umat         = v_exte(i_zone)%l_umat
            l_mfront_proto = v_exte(i_zone)%l_mfront_proto
            l_mfront_offi  = v_exte(i_zone)%l_mfront_offi
            subr_name      = v_exte(i_zone)%subr_name
            libr_name      = v_exte(i_zone)%libr_name
            model_mfront   = v_exte(i_zone)%model_mfront
            model_dim      = v_exte(i_zone)%model_dim
            l_prot_comp    = l_mfront_proto .or. l_umat
!
! --------- Exception for name of internal variables
!
            call comp_meca_exc2(l_cristal, l_prot_comp, l_pmf, &
                                l_excl   , vari_excl)
!
! --------- Save names of relation
!
            v_rela(3*(i_zone-1) + 1) = rela_comp
            v_rela(3*(i_zone-1) + 2) = defo_comp
            v_rela(3*(i_zone-1) + 3) = type_cpla
!
! --------- Save name of internal variables
!
            call jeecra(jexnum(compor_info(1:19)//'.VARI', i_zone), 'LONMAX', nb_vari)
            call jeveuo(jexnum(compor_info(1:19)//'.VARI', i_zone), 'E', vk16 = v_vari)
            call comp_meca_name(nb_vari   , nb_vari_meca,&
                                l_excl    , vari_excl   ,&
                                l_kit_meta, l_kit_thm   , l_mfront_offi, &
                                rela_comp , defo_comp   , kit_comp     , type_cpla, post_iter,&
                                libr_name , subr_name   , model_mfront , model_dim,&
                                v_vari)
!
! --------- Save current zone
!
            v_zone_read(i_zone) = 1
            nb_zone_acti        = nb_zone_acti + 1
        endif
    end do
!
 99 continue
!
! - Save general information
!
    call wkvect(compor_info(1:19)//'.INFO', 'V V I', 5, vi = v_info)
    v_info(1) = nb_elem_mesh
    v_info(2) = nb_zone
    v_info(3) = nb_vari_maxi
    v_info(4) = nt_vari
    v_info(5) = nb_zone_acti
!
    deallocate(v_exte)
    AS_DEALLOCATE(vi = v_zone_read)
!
    call jedema()
!
end subroutine
