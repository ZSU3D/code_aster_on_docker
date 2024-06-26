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

subroutine sschge(nomacr)
    implicit none
!
!     ARGUMENTS:
!     ----------
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterfort/assert.h"
#include "asterfort/assvec.h"
#include "asterfort/detrsd.h"
#include "asterfort/getvid.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/jecroc.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenonu.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/me2mme.h"
#include "asterfort/rcmfmc.h"
#include "asterfort/ss2mm2.h"
#include "asterfort/ssvau1.h"
#include "asterfort/utmess.h"
!
    character(len=8) :: nomacr
! ----------------------------------------------------------------------
!     BUT: TRAITER LE MOT CLEF "CAS_CHARGE"
!             DE L'OPERATEUR MACR_ELEM_STAT
!     LES CHARGEMENTS SERONT CONDENSES LORS DE L'ASSEMBLAGE.
!
!     IN: NOMACR : NOM DU MACR_ELEM_STAT
!
!     OUT: LES OBJETS SUIVANTS DU MACR_ELEM_STAT SONT CALCULES:
!             NOMACR.LICA(NOMCAS)
!             NOMACR.LICH(NOMCAS)
!
! ----------------------------------------------------------------------
!
!
    character(len=1) :: base
    character(len=8) :: kbid
    character(len=14) :: nu
    character(len=8) :: nomo, materi, cara
    character(len=24) :: mate
    character(len=8) :: vprof, nomcas
    character(len=19) :: vecas, vecel
!
!-----------------------------------------------------------------------
    integer :: ialica, ialich, icas, iocc
    integer :: kk, n1, n2, nch, nddle, nddli, nddlt
    integer :: nocc
    real(kind=8) :: time
    character(len=8), pointer :: refm(:) => null()
    integer, pointer :: desm(:) => null()
    real(kind=8), pointer :: vale(:) => null()
!-----------------------------------------------------------------------
    call jemarq()
!
    base = 'V'
    call jeveuo(nomacr//'.REFM', 'L', vk8=refm)
    nomo= refm(1)
    materi = refm(3)
    if (materi .ne. '        ') then
        call rcmfmc(materi, mate, l_ther_ = ASTER_FALSE)
    else
        mate = ' '
    endif
    cara = refm(4)
    nu= refm(5)
    if (nu(1:8) .ne. nomacr) then
        ASSERT(.false.)
    endif
!
    vecel = '&&VECEL            '
    vecas = nomacr//'.CHARMECA'
!
    call jeveuo(nomacr//'.DESM', 'E', vi=desm)
    call jelira(nomacr//'.LICH', 'LONMAX', nch)
    nch= nch-1
    vprof= ' '
    nddle= desm(4)
    nddli= desm(5)
    nddlt= nddle+nddli
!
!     -- ON VERIFIE LA PRESENCE PARFOIS NECESSAIRE DE CARA_ELEM
!        ET CHAM_MATER :
    call getfac('CAS_CHARGE', nocc)
!
    do iocc = 1, nocc
!
        call getvtx('CAS_CHARGE', 'NOM_CAS', iocc=iocc, scal=nomcas, nbret=n1)
        call jecroc(jexnom(nomacr//'.LICA', nomcas))
        call jecroc(jexnom(nomacr//'.LICH', nomcas))
        call jenonu(jexnom(nomacr//'.LICA', nomcas), icas)
        call jeveuo(jexnum(nomacr//'.LICA', icas), 'E', ialica)
        call jeveuo(jexnum(nomacr//'.LICH', icas), 'E', ialich)
!
!       -- MISE A JOUR DE .LICH:
!       ------------------------
        call getvtx('CAS_CHARGE', 'SUIV', iocc=iocc, scal=kbid, nbret=n1)
        if (kbid(1:3) .eq. 'OUI') then
            zk8(ialich-1+1)= 'OUI_SUIV'
        else
            zk8(ialich-1+1)= 'NON_SUIV'
        endif
        call getvid('CAS_CHARGE', 'CHARGE', iocc=iocc, nbval=0, nbret=n1)
        if (-n1 .gt. nch) then
            call utmess('F', 'SOUSTRUC_40')
        endif
        call getvid('CAS_CHARGE', 'CHARGE', iocc=iocc, nbval=-n1, vect=zk8(ialich+1),&
                    nbret=n2)
!
!       -- INSTANT:
!       -----------
        call getvr8('CAS_CHARGE', 'INST', iocc=iocc, scal=time, nbret=n2)
!
!       -- CALCULS VECTEURS ELEMENTAIRES DU CHARGEMENT :
!       ------------------------------------------------
        call me2mme(nomo, -n1, zk8(ialich+1), mate, cara,&
                    time, vecel, 0, base)
        call ss2mm2(nomo, vecel, nomcas)
!
!        -- ASSEMBLAGE:
        call assvec('V', vecas, 1, vecel, [1.d0],&
                    nu, vprof, 'ZERO', 1)
!
!       -- RECOPIE DE VECAS.VALE DANS .LICA(1:NDDLT) :
        call jeveuo(vecas//'.VALE', 'L', vr=vale)
        do kk = 1, nddlt
            zr(ialica-1+kk)=vale(kk)
        end do
!
!       -- CONDENSATION DE .LICA(1:NDDLT) DANS .LICA(NDDLT+1,2*NDDLT) :
        call ssvau1(nomacr, ialica, ialica+nddlt)
!
!       -- ON COMPTE LES CAS DE CHARGE EFFECTIVEMENT CALCULES:
        desm(7) = icas
!
        call detrsd('VECT_ELEM', vecel)
        call detrsd('CHAMP_GD', vecas)
    end do
!
!
    call jedema()
end subroutine
