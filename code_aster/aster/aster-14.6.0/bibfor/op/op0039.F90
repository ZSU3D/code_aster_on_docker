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

subroutine op0039()
    implicit none
! ----------------------------------------------------------------------
! person_in_charge: nicolas.sellenet at edf.fr
!
!     BUT:
!       IMPRIMER DES RESULTATS ET DES MAILLAGE
!       PROCEDURE IMPR_RESU
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvid.h"
#include "asterfort/getvis.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/infmaj.h"
#include "asterfort/irmfac.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/ulaffe.h"
#include "asterfort/ulexis.h"
#include "asterfort/ultype.h"
#include "asterfort/ulopen.h"
#include "asterfort/utmess.h"
#include "asterfort/asmpi_info.h"
    mpi_int :: mrank, msize
    integer :: nocc, iocc, ifc, ifi, versio, nbrank
    integer :: nmail, nresu, ncham, nres, n11
    integer :: nmo, nn, nmod, nforma, ngibi, nproc
!
    real(kind=8) :: versi2, eps
!
    character(len=1) :: typf
    character(len=8) :: modele, noma, form, nomsq, proc
    character(len=8) :: resu
    character(len=16) :: fich
    character(len=24) :: valk(6)
!
    aster_logical :: lresu
    aster_logical :: lmail, lgmsh
!
! ----------------------------------------------------------------------
!
    call asmpi_info(rank=mrank, size=msize)
    nbrank = to_aster_int(mrank)
    call jemarq()
    call infmaj()
!
!   --- PROC0 = 'OUI' pour effectuer les impressions uniquement sur le processeur de rang 0 ---
    call getvtx(' ', 'PROC0', scal=proc, nbret=nproc)
    if ( proc .eq. 'NON' ) then
      nbrank = 0
    endif
!
    if ( nbrank .eq. 0 ) then
!     --- RECUPERATION DU NOMBRE DE MISES EN FACTEUR DU MOT-CLE RESU ---
       call getfac('RESU', nocc)
!
       do iocc = 1, nocc
           call getvtx('RESU', 'NOEUD_CMP', iocc=iocc, nbval=0, nbret=nmo)
           if (nmo .ne. 0) then
               nn = nmo / 2
               if (2*nn .ne. nmo) then
                   call utmess('F', 'PREPOST3_65')
               endif
           endif
       end do
!
!     -----------------
!     --- LE MODELE ---
!     -----------------
       modele = ' '
       call getvid(' ', 'MODELE', scal=modele, nbret=nmod)
!
!     ---------------------------------------------
!     --- FORMAT, FICHIER ET UNITE D'IMPRESSION ---
!     ---------------------------------------------
!
!     --- FORMAT ---
      call getvtx(' ', 'FORMAT', scal=form, nbret=nforma)
!
!     --- VERIFICATION DE LA COHERENCE ENTRE LE MAILLAGE ---
!     --- PORTANT LE RESULTAT ET LE MAILLAGE DONNE PAR   ---
!     --- L'UTILISATEUR DANS IMPR_RESU(FORMAT='IDEAS')   ---
!
       if (form(1:5) .eq. 'IDEAS') then
           call getvid('RESU', 'RESULTAT', iocc=1, scal=resu, nbret=nres)
           call getvid('RESU', 'MAILLAGE', iocc=1, scal=noma, nbret=nmail)
           if (nres*nmail .gt. 0) then
               call dismoi('NOM_MAILLA', resu, 'RESULTAT', repk=nomsq)
               if (nomsq .ne. noma) then
                   valk(1)=noma
                   valk(2)=nomsq
                   valk(3)=resu
                   call utmess('A', 'PREPOST3_74', nk=3, valk=valk)
               endif
           endif
       endif
!
!
!     --- VERSION D'ECRITURE  ----
       versio = 0
       if (form(1:5) .eq. 'IDEAS') then
           versio = 5
           call getvis(' ', 'VERSION', scal=versio, nbret=ngibi)
       else if (form(1:4) .eq. 'GMSH') then
           versio = 1
           versi2 = 1.0d0
           eps = 1.0d-6
           call getvr8(' ', 'VERSION', scal=versi2, nbret=ngibi)
           if (versi2 .gt. 1.0d0-eps .and. versi2 .lt. 1.0d0+eps) then
               versio = 1
           else if (versi2.gt.1.2d0-eps.and.versi2.lt.1.2d0+eps) then
               versio = 2
           endif
       endif
!
!     --- FICHIER ---
       ifi = 0
       fich = 'F_'//form
       call getvis(' ', 'UNITE', scal=ifi, nbret=n11)
       ifc = ifi
       if (.not. ulexis( ifi )) then
           if (form .eq.'MED')then
               call ulaffe(ifi, ' ', fich, 'NEW', 'O')
           else
               call ulopen(ifi, ' ', fich, 'NEW', 'O')
           endif
       elseif (form .eq.'MED') then
           call ultype(ifi, typf)
           if (typf .ne. 'B' .and. typf .ne. 'L') then
            call utmess('A','PREPOST3_7')
           endif
       endif
!
!     -- VERIFICATIONS POUR GMSH :
      if (form(1:4) .eq. 'GMSH') then
        lmail=.false.
        lresu=.false.
        do iocc = 1, nocc
            call getvid('RESU', 'MAILLAGE', iocc=iocc, scal=noma, nbret=nmail)
            call getvid('RESU', 'RESULTAT', iocc=iocc, scal=resu, nbret=nresu)
            call getvid('RESU', 'CHAM_GD', iocc=iocc, scal=resu, nbret=ncham)
            if (nresu .ne. 0 .or. ncham .ne. 0) then
                lresu=.true.
                goto 220
            endif
            if (nmail .ne. 0) lmail=.true.
220         continue
        end do
        if (lmail .and. lresu) then
            call utmess('A', 'PREPOST3_68')
            goto 999
        endif
      endif
      lgmsh = ASTER_FALSE
!
!     --- BOUCLE SUR LE NOMBRE DE MISES EN FACTEUR ---
!     -----------------------------------------------------------------
      do iocc = 1, nocc
!
        call irmfac(iocc, form, ifi, versio, modele, noma, lgmsh)
!
      end do
!
999   continue
    endif
    call jedema()
end subroutine
