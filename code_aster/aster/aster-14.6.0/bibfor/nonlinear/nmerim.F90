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

subroutine nmerim(sderro)
!
! person_in_charge: mickael.abbas at edf.fr
!
    implicit none
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/utmess.h"
    character(len=24) :: sderro
!
! ----------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (SD ERREUR)
!
! EMISSION MESSAGE ERRREUR
!
! ----------------------------------------------------------------------
!
!
! IN  SDERRO : SD ERREUR
!
! ----------------------------------------------------------------------
!
    integer :: ieven, zeven
    character(len=24) :: errinf
    integer :: jeinfo
    character(len=24) :: erraac, erreni, errmsg
    integer :: jeeact, jeeniv, jeemsg
    integer :: icode
    character(len=9) :: teven
    character(len=24) :: meven
!
! ----------------------------------------------------------------------
!
    call jemarq()
!
! --- ACCES SD
!
    errinf = sderro(1:19)//'.INFO'
    call jeveuo(errinf, 'L', jeinfo)
    zeven = zi(jeinfo-1+1)
!
    erraac = sderro(1:19)//'.EACT'
    erreni = sderro(1:19)//'.ENIV'
    errmsg = sderro(1:19)//'.EMSG'
    call jeveuo(erraac, 'L', jeeact)
    call jeveuo(erreni, 'L', jeeniv)
    call jeveuo(errmsg, 'L', jeemsg)
!
! --- EMISSION DES MESSAGES D'ERREUR
!
    do 10 ieven = 1, zeven
        icode = zi(jeeact-1+ieven)
        teven = zk16(jeeniv-1+ieven)(1:9)
        meven = zk24(jeemsg-1+ieven)
        if ((teven(1:3).eq.'ERR') .and. (icode.eq.1)) then
            if (meven .eq. ' ') then
                ASSERT(.false.)
            endif
            if (meven .eq. 'MECANONLINE10_1') then
                call utmess('I', 'MECANONLINE10_1')
            else if (meven.eq.'MECANONLINE10_2') then
                call utmess('I', 'MECANONLINE10_2')
            else if (meven.eq.'MECANONLINE10_3') then
                call utmess('I', 'MECANONLINE10_3')
            else if (meven.eq.'MECANONLINE10_4') then
                call utmess('I', 'MECANONLINE10_4')
            else if (meven.eq.'MECANONLINE10_5') then
                call utmess('I', 'MECANONLINE10_5')
            else if (meven.eq.'MECANONLINE10_6') then
                call utmess('I', 'MECANONLINE10_6')
            else if (meven.eq.'MECANONLINE10_7') then
                call utmess('I', 'MECANONLINE10_7')
            else if (meven.eq.'MECANONLINE10_8') then
                call utmess('I', 'MECANONLINE10_8')
            else if (meven.eq.'MECANONLINE10_9') then
                call utmess('I', 'MECANONLINE10_9')
            else if (meven.eq.'MECANONLINE10_10') then
                call utmess('I', 'MECANONLINE10_10')
            else if (meven.eq.'MECANONLINE10_11') then
                call utmess('I', 'MECANONLINE10_11')
            else if (meven.eq.'MECANONLINE10_12') then
                call utmess('I', 'MECANONLINE10_12')
            else if (meven.eq.'MECANONLINE10_13') then
                call utmess('I', 'MECANONLINE10_13')
            else if (meven.eq.'MECANONLINE10_20') then
                call utmess('I', 'MECANONLINE10_20')
            else if (meven.eq.'MECANONLINE10_24') then
                call utmess('I', 'MECANONLINE10_24')
            else
                ASSERT(.false.)
            endif
        endif
 10 end do
!
    call jedema()
end subroutine
