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

subroutine irmano(noma, nbma, numai, nbnos, numnos)
    implicit none
!
#include "jeveux.h"
#include "asterfort/dismoi.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexatr.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
!
    character(len=*) :: noma
    integer :: nbma, numai(*), nbnos, numnos(*)
! ----------------------------------------------------------------------
!     BUT :   TROUVER LA LISTE DES NUMEROS DE NOEUDS SOMMETS D'UNE LISTE
!             DE MAILLES
!     ENTREES:
!        NOMA   : NOM DU MAILLAGE
!        NBMA   : NOMBRE DE MAILLES DE LA LISTE
!        NUMAI  : NUMEROS DES MAILLES DE LA LISTE
!     SORTIES:
!        NBNOS  : NOMBRE DE NOEUDS SOMMETS
!        NUMNOS : NUMEROS DES NOEUDS SOMMETS (UN NOEUD APPARAIT UNE
!                               SEULE FOIS )
! ----------------------------------------------------------------------
!     ------------------------------------------------------------------
    integer :: nnoe
    character(len=8) :: nomma
!
!
!-----------------------------------------------------------------------
    integer :: ima, imai, ino, inoe, ipoin
    integer ::  jpoin, nbnoe, num
    integer, pointer :: vnumnos(:) => null()
    integer, pointer :: connex(:) => null()
!-----------------------------------------------------------------------
    call jemarq()
    nomma=noma
    nbnos= 0
!  --- RECHERCHE DU NOMBRE DE NOEUDS DU MAILLAGE ---
!-DEL CALL JELIRA(NOMMA//'.NOMNOE','NOMMAX',NBNOE,' ')
    call dismoi('NB_NO_MAILLA', nomma, 'MAILLAGE', repi=nbnoe)
    AS_ALLOCATE(vi=vnumnos, size=nbnoe)
!     --- INITIALISATION DU TABLEAU DE TRAVAIL &&IRMANO.NUMNOS ----
    do ino = 1, nbnoe
        vnumnos(ino) = 0
    end do
!     --- RECHERCHE DES NOEUDS SOMMETS ----
    call jeveuo(nomma//'.CONNEX', 'L', vi=connex)
    call jeveuo(jexatr(nomma//'.CONNEX', 'LONCUM'), 'L', jpoin)
    do ima = 1, nbma
        imai=numai(ima)
        ipoin= zi(jpoin-1+imai)
        nnoe = zi(jpoin-1+imai+1)-ipoin
        do inoe = 1, nnoe
            num=connex(ipoin-1+inoe)
            vnumnos(num) =1
        end do
    end do
!  --- STOCKAGE DES NOEUDS PRESENTS SUR LA LISTE DES MAILLES---
    do inoe = 1, nbnoe
        if (vnumnos(inoe) .eq. 1) then
            nbnos=nbnos+1
            numnos(nbnos)=inoe
        endif
    end do
!
    AS_DEALLOCATE(vi=vnumnos)
    call jedema()
end subroutine
