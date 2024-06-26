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

subroutine op0176()
    implicit none
!
!     BUT:
!       OPERATEUR D'EXTRACTION
!
!
!     ARGUMENTS:
!     ----------
!
!      ENTREE :
!-------------
!
!      SORTIE :
!-------------
!
! ......................................................................
!
!
!
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterc/getres.h"
#include "asterfort/dyarc0.h"
#include "asterfort/extrs1.h"
#include "asterfort/extrs2.h"
#include "asterfort/getvid.h"
#include "asterfort/infmaj.h"
#include "asterfort/infniv.h"
#include "asterfort/irecri.h"
#include "asterfort/iunifi.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/refdcp.h"
#include "asterfort/rscrsd.h"
#include "asterfort/rsinfo.h"
#include "asterfort/rsnopa.h"
#include "asterfort/rsorac.h"
#include "asterfort/titre.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
    character(len=6) :: nompro
    parameter ( nompro = 'OP0176' )
!
    integer :: ibid, nbordr, jordr, nbexcl, jexcl, nbarch, jarch
    integer :: nbac, nbpa, jpa, iret, nbnosy, nbpara, nbrest
    integer :: izero, versio, iul, tord(1), ifm, niv
!
    real(kind=8) :: r8b
!
    character(len=1) :: cecr
    character(len=8) :: k8b, form, formar, tabid(1)
    character(len=8) :: noma, nomo, nocara, nochmat
    character(len=16) :: typcon, nomcmd
    character(len=19) :: resuou, resuin
    character(len=24) :: lisarc, lichex, nompar
!
    aster_logical :: fals, true, lbid, lrest
!
    complex(kind=8) :: c16b
    integer :: nmail, nmode, ncara, nchmat
!
! ----------------------------------------------------------------------
!
    call jemarq()
    call infmaj()
    call infniv(ifm, niv)
    true = .true.
    fals = .false.
    noma=' '
    nomo=' '
    nocara=' '
    nochmat=' '
!
    lisarc = '&&'//nompro//'.LISTE.ARCH'
    lichex = '&&'//nompro//'.LISTE.CHAM'
    nompar = '&&'//nompro//'.NOMS_PARA '
    formar = '1PE12.5'
    versio = 0
!
    call getres(resuou, typcon, nomcmd)
!
    call getvid(' ', 'RESULTAT', scal=resuin, nbret=ibid)
!
!     --- CHAMPS ---
!
    call jelira(resuin//'.DESC', 'NOMMAX', nbnosy)
    if (nbnosy .eq. 0) goto 9997
!
!     --- NOMBRE DE NUMERO D'ORDRE ---
!
    call rsorac(resuin, 'LONUTI', 0, r8b, k8b,&
                c16b, r8b, k8b, tord, 1,&
                ibid)
    nbordr=tord(1)
    call wkvect('&&'//nompro//'.NUME_ORDRE', 'V V I', nbordr, jordr)
    call rsorac(resuin, 'TOUT_ORDRE', 0, r8b, k8b,&
                c16b, r8b, k8b, zi(jordr), nbordr,&
                ibid)
!
!     --- ACCES ET PARAMETRES ---
!
    call rsnopa(resuin, 2, nompar, nbac, nbpa)
    nbpara = nbac + nbpa
    call jeveuo(nompar, 'L', jpa)
!
!     --- CHAMPS EXCLUS ET PAS D'ARCHIVAGE ---
!
    call dyarc0(resuin, nbnosy, nbarch, lisarc, nbexcl,&
                lichex)
!
!     --- MOT-CLE RESTREINT
    call getfac('RESTREINT', nbrest)
    lrest = .false.
    if (nbrest .gt. 0) then
        lrest = .true.
        call getvid('RESTREINT', 'MAILLAGE', iocc=1, scal=noma, nbret=nmail)
        call getvid('RESTREINT', 'MODELE', iocc=1, scal=nomo, nbret=nmode)
        call getvid('RESTREINT', 'CARA_ELEM', iocc=1, scal=nocara, nbret=ncara)
        call getvid('RESTREINT', 'CHAM_MATER', iocc=1, scal=nochmat, nbret=nchmat)
    endif
    if ((nbarch.eq.0) .and. (nbrest.eq.0)) then
        goto 9997
    else if ((nbarch.eq.0)) then
        jarch = jordr
        nbarch = nbordr
    else
        call jeveuo(lisarc, 'L', jarch)
    endif
    call jeveuo(lichex, 'L', jexcl)
!
!     --- ALLOCATION DE LA STRUCTURE SORTIE SI ELLE N'EXISTE PAS ---
!
    call jeexin(resuou//'.DESC', iret)
    if (iret .eq. 0) then
        call rscrsd('G', resuou, typcon, nbarch)
    endif
!
!
    if (resuin .eq. resuou) then
        if (lrest)  call utmess('F', 'PREPOST2_5')
        call extrs1(resuin, nbordr, zi(jordr), nbpara, zk16(jpa),&
                    nbarch, zi(jarch), nbexcl, zk16(jexcl), nbnosy)
    else
        call extrs2(resuin, resuou, typcon, lrest, noma,&
                    nomo, nocara, nochmat, nbordr, zi(jordr), nbpara, zk16(jpa),&
                    nbarch, zi(jarch), nbexcl, zk16(jexcl), nbnosy)
    endif
!
    call titre()
!
!     --- IMPRESSION ---
!
    form = 'RESULTAT'
    iul = iunifi( 'MESSAGE' )
    call rsinfo(resuou, iul)
!
    call rsorac(resuou, 'LONUTI', 0, r8b, k8b,&
                c16b, r8b, k8b, tord, 1,&
                ibid)
    nbordr=tord(1)
    call rsorac(resuou, 'TOUT_ORDRE', 0, r8b, k8b,&
                c16b, r8b, k8b, zi(jordr), nbordr,&
                ibid)
    k8b = '        '
    cecr = 'T'
    izero = 0
    tabid(1) = ' '
    call irecri(resuou, form, iul, k8b, lbid,&
                izero, tabid, ' ', nbpara, zk16(jpa),&
                nbordr, zi(jordr), true, 'RESU', 1,&
                cecr, k8b, fals, 0, [0],&
                0, [0], izero, k8b, fals,&
                r8b, fals, r8b, fals, fals,&
                formar, versio, niv)
!
9997 continue
!
!
!
!     -- CREATION DE L'OBJET .REFD SI NECESSAIRE:
!     -------------------------------------------
    call refdcp(resuin, resuou)
!
!
    call jedema()
!
end subroutine
