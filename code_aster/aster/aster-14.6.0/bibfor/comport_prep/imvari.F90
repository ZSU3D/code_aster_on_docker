! --------------------------------------------------------------------
! Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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
subroutine imvari(compor_info)
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/comp_meca_l.h"
#include "asterfort/cesexi.h"
#include "asterfort/carces.h"
#include "asterfort/detrsd.h"
#include "asterfort/jeexin.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/utmess.h"
!
character(len=19), intent(in) :: compor_info
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Print informations about internal variables
!
! --------------------------------------------------------------------------------------------------
!
! In  compor_info      : name of object for information about internal variables and comportement
!
! --------------------------------------------------------------------------------------------------
!
    integer :: i_vari, i_zone, c_pmf
    integer :: nb_vari, nb_zone, nb_elem_zone, nt_vari
    character(len=16) :: vari_excl
    character(len=16) :: rela_comp, defo_comp, type_cpla
    aster_logical :: l_excl
    integer, pointer :: v_info(:) => null()
    integer, pointer :: v_zone(:) => null()
    character(len=16), pointer :: v_vari(:) => null()
    character(len=16), pointer :: v_rela(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
! - Access to informations
!
    call jeveuo(compor_info(1:19)//'.INFO', 'L', vi = v_info)
    nt_vari = v_info(4)
    if (nt_vari .eq. 0) then
        goto 99
    endif
    call utmess('I', 'COMPOR4_1')
    nb_zone = v_info(2)
    call jeveuo(compor_info(1:19)//'.RELA', 'L', vk16 = v_rela)
    call jeveuo(compor_info(1:19)//'.ZONE', 'L', vi = v_zone)

    c_pmf = 0
    do i_zone = 1, nb_zone
        
        nb_elem_zone = v_zone(i_zone)
!
        if (nb_elem_zone .ne. 0) then
!
! --------- Acces to list of name of internal variables
!
            call jeveuo(jexnum(compor_info(1:19)//'.VARI', i_zone), 'L', vk16 = v_vari)
            call jelira(jexnum(compor_info(1:19)//'.VARI', i_zone), 'LONMAX', nb_vari)
!
! --------- Exceptions ?
!
            l_excl = .false.
            vari_excl = v_vari(1)
            if (vari_excl(1:2) .eq. '&&') then
                l_excl = .true.
            endif
!
! --------- Get names of relation
!
            rela_comp   = v_rela(3*(i_zone-1) + 1)
            defo_comp   = v_rela(3*(i_zone-1) + 2)
            type_cpla   = v_rela(3*(i_zone-1) + 3)
!
! --------- Print name of internal variables
!
            if (l_excl) then
               if (vari_excl.eq.'&&MULT_COMP') then
                  call utmess('I', 'COMPOR4_4', si = nb_elem_zone)
                  call utmess('I', 'COMPOR4_11')
                  call utmess('I', 'COMPOR4_9' , si = nb_vari)
                  call utmess('I', 'COMPOR4_15')
               else if (vari_excl.eq.'&&PROT_COMP') then
                  call utmess('I', 'COMPOR4_4', si = nb_elem_zone)
                  call utmess('I', 'COMPOR4_10')
                  call utmess('I', 'COMPOR4_6', sk = defo_comp)
                  call utmess('I', 'COMPOR4_9', si = nb_vari)
                  call utmess('I', 'COMPOR4_16')
               else if (vari_excl.eq.'&&MULT_PMF') then
                  c_pmf = c_pmf + 1 
               else
                  ASSERT(ASTER_FALSE)
               endif
            else
                call utmess('I', 'COMPOR4_4', si = nb_elem_zone)
                call utmess('I', 'COMPOR4_5', sk = rela_comp)
                call utmess('I', 'COMPOR4_6', sk = defo_comp)
                if (type_cpla .eq. 'DEBORST') then
                    call utmess('I', 'COMPOR4_8')
                endif
                call utmess('I', 'COMPOR4_9', si = nb_vari)
                do i_vari = 1, nb_vari
                    call utmess('I', 'COMPOR4_20', sk = v_vari(i_vari), si = i_vari)
                enddo
            endif
        endif
     end do
     if (c_pmf .ne. 0) then
        call utmess('I', 'COMPOR4_12', si = c_pmf)
     endif
!
99  continue
!
    call jedema()
!
end subroutine
