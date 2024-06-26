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

function typmat(nbmat, tlimat)
    implicit none
#include "asterfort/asmpi_comm_vect.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/jeexin.h"
#include "asterfort/redetr.h"
    character(len=*) :: tlimat(*)
    integer :: nbmat
    character(len=1) :: typmat
!-----------------------------------------------------------------------
!
!  BUT : CETTE FONCTION RETOURNE LE TYPE SYMETRIQUE : 'S'
!                                     OU PLEINE     : 'N'
!        DE LA MATRICE GLOBALE RESULTANTE DE L'ASSEMBLAGE
!        DES MATR_ELEM TLIMAT
!  ATTENTION :
!    SI ON EST EN PARALLELE MPI, LA REPONSE EST GLOBALE.
!    CETTE ROUTINE FAIT DU MPI_ALLREDUCE. IL FAUT DONC L'APPELER
!    DE LA MEME FACON SUR TOUS LES PROCS.
!
!-----------------------------------------------------------------------
! --- DESCRIPTION DES PARAMETRES
! IN  I  NBMAT  : NOMBRE DE MATR_ELEM DE LA LISTE TLIMAT
! IN  K* TLIMAT : LISTE DES MATR_ELEM
! ----------------------------------------------------------------------
!----------------------------------------------------------------------
    character(len=8) :: sym, zero
    character(len=19) :: matel
    integer :: i, itymat
    integer :: iexi, iexiav
!----------------------------------------------------------------------
!     ITYMAT =  0 -> SYMETRIQUE
!            =  1 -> NON-SYMETRIQUE
!
!     --  PAR DEFAUT LE TYPE DE MATRICE EST SYMETRIQUE
    itymat = 0
!
    do i = 1, nbmat
        matel = tlimat(i)
        call jeexin(matel//'.RELR', iexi)
        iexi=min(1,abs(iexi))
        iexiav=iexi
        call asmpi_comm_vect('MPI_MAX', 'I', sci=iexi)
        iexi=min(1,abs(iexi))
        ASSERT(iexi.eq.iexiav)
        if (iexi .eq. 0) goto 10
!
!       -- LA LOGIQUE CI-DESSOUS N'EST VALABLE QUE SI LE MATR_ELEM
!          A ETE EXPURGE DE SES RESUELEM NULS => CALL REDETR()
        call redetr(matel)
!
        call dismoi('TYPE_MATRICE', matel, 'MATR_ELEM', repk=sym)
        if (sym .eq. 'NON_SYM') then
            call dismoi('ZERO', matel, 'MATR_ELEM', repk=zero)
            if (zero .eq. 'NON') then
                itymat = 1
            endif
        endif
!
        call asmpi_comm_vect('MPI_MAX', 'I', sci=itymat)
        if (itymat .eq. 1) goto 11
!
 10     continue
    end do
 11 continue
!
    if (itymat .eq. 0) then
        typmat='S'
    else
        typmat='N'
    endif
end function
