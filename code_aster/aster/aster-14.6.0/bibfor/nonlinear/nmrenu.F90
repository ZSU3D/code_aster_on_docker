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
subroutine nmrenu(modelz  , list_func_acti, list_load, ds_contact, nume_dof,&
                  l_renumber)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/cfdisl.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/numer3.h"
#include "asterfort/utmess.h"
!
character(len=*), intent(in) :: modelz
character(len=24), intent(inout) :: nume_dof
character(len=19), intent(in) :: list_load
type(NL_DS_Contact), intent(inout) :: ds_contact
integer, intent(in) :: list_func_acti(*)
aster_logical, intent(out) :: l_renumber
!
! --------------------------------------------------------------------------------------------------
!
! Non-linear algorithm
!
! Renumbering equations ?
!
! --------------------------------------------------------------------------------------------------
!
! IO  nume_dof         : name of numbering object (NUME_DDL)
! In  model            : name of model datastructure
! In  list_load        : list of loads
! IO  ds_contact       : datastructure for contact management
! In  list_func_acti   : list of active functionnalities
! Out l_renumber       : .true. if renumber
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ifm, niv
    aster_logical :: l_cont, l_cont_cont, l_cont_xfem, l_cont_elem, l_cont_xfem_gg
    character(len=24) :: sd_iden_rela
!
! --------------------------------------------------------------------------------------------------
!
    call infdbg('MECANONLINE', ifm, niv)
!
! - Initializations
!
    l_renumber   = .false.
    l_cont       = isfonc(list_func_acti,'CONTACT')
    if (.not.l_cont) then
        goto 999
    endif
!
! - Get identity relation datastructure
!
    sd_iden_rela = ds_contact%iden_rela
!
! - Contact method
!
    l_cont_elem = isfonc(list_func_acti,'ELT_CONTACT')
    l_cont_xfem = isfonc(list_func_acti,'CONT_XFEM')
    l_cont_cont = isfonc(list_func_acti,'CONT_CONTINU')
!
! - Numbering to change ?
!
    if (l_cont_elem) then
        if (l_cont_xfem) then
            l_cont_xfem_gg = cfdisl(ds_contact%sdcont_defi,'CONT_XFEM_GG')
            if (l_cont_xfem_gg) then
               l_renumber = .true.
            else
               l_renumber = .false.
            endif
        else
            l_renumber = ds_contact%l_renumber
            ds_contact%l_renumber = .false.
        endif
    endif
!
! - Re-numbering
!
    if (l_renumber) then
        if (niv .ge. 2) then
            call utmess('I', 'MECANONLINE13_36')
        endif
        call numer3(modelz, list_load, nume_dof, sd_iden_rela)
    endif
!
999 continue
!
end subroutine
