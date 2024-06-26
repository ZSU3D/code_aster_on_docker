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

subroutine apldlt(kptsc, action, prepost, rsolu, vcine, nbsol)
!
#include "asterf_types.h"
#include "asterf_petsc.h"
!
!
use aster_petsc_module
use petsc_data_module
    implicit none
!
! person_in_charge: natacha.bereux@edf.fr

#include "jeveux.h"
#include "asterc/asmpi_comm.h"
#include "asterfort/asmpi_info.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/utmess.h"
#include "asterfort/copisd.h"
#include "asterfort/detrsd.h"
#include "asterfort/jedetr.h"
#include "asterfort/ldlt_matr.h"
#include "asterfort/as_allocate.h"
#include "asterfort/as_deallocate.h"

    integer, intent(in) :: kptsc
    character(len=*), intent(in) :: action, prepost
    real(kind=8), intent(inout) :: rsolu(*)
    character(len=19), intent(inout) :: vcine
    integer, intent(in) :: nbsol

!----------------------------------------------------------------
!
!  Renumerotation de la matrice si PRE_COND=LDLT_INC
!  (pour etre plus efficace)
!  + renumerotation de rsolu
!  + renumerotation de vcine
!----------------------------------------------------------------
!
#ifdef _HAVE_PETSC
!----------------------------------------------------------------
    integer :: k,isol,neq
    character(len=24) :: precon,kperm
    character(len=19) :: matas2,nosolv,vcin2, vcine_avant
    character(len=24), dimension(:), pointer :: slvk => null()
    real(kind=8), dimension(:), pointer :: tempor => null()
    real(kind=8), dimension(:), pointer :: vciv1 => null()
    real(kind=8), dimension(:), pointer :: vciv2 => null()
    integer, dimension(:), pointer :: perm => null()
!
!----------------------------------------------------------------
    call jemarq()
    ASSERT(prepost.eq.'PRE' .or. prepost.eq.'POST')
    ASSERT(kptsc.ge.1 .and. kptsc.le.5)
    matas2='&&apldlt.matr'
    kperm='&&apldlt.perm'
    vcine_avant=' '

    nomat_courant=nomats(kptsc)
    nonu_courant=nonus(kptsc)


!   1. Il n'y a peut-etre rien a faire => goto 999 :
!   ------------------------------------------------
    if (action.ne.'PRERES' .and. action.ne.'RESOUD') goto 999

    nosolv = nosols(kptsc)
    call jeveuo(nosolv//'.SLVK', 'L', vk24=slvk)
    precon = slvk(2)
    if (precon.ne.'LDLT_INC') goto 999


!   2. Calcul de la nouvelle matrice, du nouveau nume_ddl et de kprem :
!   -------------------------------------------------------------------
    if (prepost.eq.'PRE') then
        call ldlt_matr(nomats(kptsc), matas2, kperm, 'V')
    endif
    nomat_courant=matas2
    call dismoi('NOM_NUME_DDL', matas2, 'MATR_ASSE', repk=nonu_courant)


!   3. Renumerotation de rsolu et vcine :
!   -------------------------------------
    if (action.eq.'RESOUD') then
        call jeveuo(kperm, 'L', vi=perm)
        neq=size(perm)

!       3.1 Renumerotation de rsolu :
!       -----------------------------
        AS_ALLOCATE(vr=tempor,size=neq)
        do isol=1,nbsol
            do k=1,neq
                tempor(k)=rsolu((isol-1)*neq +k)
            enddo
            if (prepost.eq.'PRE') then
                do k=1,neq
                    rsolu((isol-1)*neq +perm(k))=tempor(k)
                enddo
            elseif (prepost.eq.'POST') then
                do k=1,neq
                    rsolu((isol-1)*neq +k)=tempor(perm(k))
                enddo
            endif
        enddo
        AS_DEALLOCATE(vr=tempor)

!       3.2 Renumerotation de vcine :
!       -----------------------------
        if (prepost.eq.'PRE') then
            vcin2='&&apldlt.vcine'
            call copisd('CHAMP', 'V', vcine, vcin2)
            call jeveuo(vcine//'.VALE', 'L', vr=vciv1)
            call jeveuo(vcin2//'.VALE', 'E', vr=vciv2)
            ASSERT(size(vciv1).eq.neq)
            ASSERT(size(vciv2).eq.neq)
            do k=1,neq
                vciv2(perm(k))=vciv1(k)
            enddo
            vcine_avant=vcine
            vcine=vcin2
        elseif (prepost.eq.'POST') then
            vcine=vcine_avant
            call detrsd('CHAMP', '&&apldlt.vcine')
        endif

    endif


!   4. Menage :
!   -----------
    if (prepost.eq.'POST') then
        call detrsd('MATR_ASSE', nomat_courant)
        call detrsd('NUME_DDL', nonu_courant)
        call jedetr(kperm)
    endif


999 continue
    call jedema()

#else
    character(len=1) :: kdummy
    real(kind=8) :: rdummy
    integer :: idummy
    kdummy = action(1:1) // prepost(1:1) // vcine(1:1)
    rdummy = rsolu(1)
    idummy = kptsc + nbsol
#endif

end subroutine
