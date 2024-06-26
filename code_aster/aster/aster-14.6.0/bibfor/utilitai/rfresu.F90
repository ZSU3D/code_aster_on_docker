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

subroutine rfresu()
    implicit none
!     OPERATEUR "RECU_FONCTION"
!     ------------------------------------------------------------------
#include "jeveux.h"
#include "asterc/getres.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/foattr.h"
#include "asterfort/focrr2.h"
#include "asterfort/focrr3.h"
#include "asterfort/focrrs.h"
#include "asterfort/foimpr.h"
#include "asterfort/getvid.h"
#include "asterfort/getvis.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/infmaj.h"
#include "asterfort/infniv.h"
#include "asterfort/jenonu.h"
#include "asterfort/jexnom.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/lxliis.h"
#include "asterfort/ordonn.h"
#include "asterfort/rsutnc.h"
#include "asterfort/titre.h"
#include "asterfort/utcmp1.h"
#include "asterfort/utmess.h"
#include "asterfort/utnono.h"
#include "asterfort/varinonu.h"
#include "asterfort/rsadpa.h"
    integer :: nbtrou, numer1(1), l, n1, iret, ivari
    integer :: nm, ngm, npoint, np, nn, npr, ngn
    integer :: nres, ifm, niv, nusp, numa, jlue
    real(kind=8) :: epsi
    character(len=8) :: k8b, crit, maille, noma, intres, nomo
    character(len=8) :: noeud, cmp, nomgd
    character(len=16) :: nomcmd, typcon, nomcha, npresu, nomvari
    character(len=19) :: nomfon, cham19, resu
    character(len=24) :: valk(3), nogma, nogno
!
!     ------------------------------------------------------------------
    call jemarq()
!
    call getres(nomfon, typcon, nomcmd)
!
! --- RECUPERATION DU NIVEAU D'IMPRESSION
    call infmaj()
    call infniv(ifm, niv)
!
    call getvtx(' ', 'CRITERE', scal=crit, nbret=n1)
    call getvr8(' ', 'PRECISION', scal=epsi, nbret=n1)
    intres = 'NON     '
    call getvtx(' ', 'INTERP_NUME', scal=intres, nbret=n1)
!
    npoint = 0
    cmp = ' '
    noeud = ' '
    maille = ' '
    nogma = ' '
    nogno = ' '
    call getvtx(' ', 'MAILLE', scal=maille, nbret=nm)
    call getvtx(' ', 'GROUP_MA', scal=nogma, nbret=ngm)
    call getvis(' ', 'SOUS_POINT', scal=nusp, nbret=np)
    if (np .eq. 0) nusp = 0
    call getvis(' ', 'POINT', scal=npoint, nbret=np)
    call getvtx(' ', 'NOEUD', scal=noeud, nbret=nn)
    call getvtx(' ', 'GROUP_NO', scal=nogno, nbret=ngn)
!
!     -----------------------------------------------------------------
!                       --- CAS D'UN RESULTAT ---
!     -----------------------------------------------------------------
!
!
!
    call getvid(' ', 'RESULTAT ', scal=resu, nbret=nres)
!
    if (nres .ne. 0) then
        call getvtx(' ', 'NOM_PARA_RESU', scal=npresu, nbret=npr)
        if (npr .ne. 0) then
            if (intres(1:3) .ne. 'NON') then
                call utmess('F', 'UTILITAI4_21')
            endif
            call focrr3(nomfon, resu, npresu, 'G', iret)
            goto 10
        endif
!
        call getvtx(' ', 'NOM_CHAM', scal=nomcha, nbret=l)
        call rsutnc(resu, nomcha, 1, cham19, numer1,&
                    nbtrou)
        if (nbtrou .eq. 0) then
            call utmess('F', 'UTILITAI4_22', sk=nomcha)
        endif
        call dismoi('NOM_MAILLA', cham19, 'CHAMP', repk=noma)
        call dismoi('NOM_GD', cham19, 'CHAMP', repk=nomgd)
        if (ngn .ne. 0) then
            call utnono(' ', noma, 'NOEUD', nogno, noeud,&
                        iret)
            if (iret .eq. 10) then
                call utmess('F', 'ELEMENTS_67', sk=nogno)
            else if (iret.eq.1) then
                valk(1) = nogno
                valk(2) = noeud
                call utmess('A', 'SOUSTRUC_87', nk=2, valk=valk)
            endif
        endif
        if (ngm .ne. 0) then
            call utnono(' ', noma, 'MAILLE', nogma, maille,&
                        iret)
            if (iret .eq. 10) then
                call utmess('F', 'ELEMENTS_73', sk=nogma)
            else if (iret.eq.1) then
                valk(1) = maille
                call utmess('A', 'UTILITAI6_72', sk=valk(1))
            endif
        endif
        call utcmp1(nomgd, ' ', 1, cmp, ivari, nomvari)
        if (ivari.eq.-1) then
            ASSERT(nomcha(1:7).eq.'VARI_EL')
            call rsadpa(resu, 'L', 1, 'MODELE', 1, 0, sjv=jlue)
            nomo = zk8(jlue)
            call jenonu(jexnom(noma//'.NOMMAI', maille), numa)
            call varinonu(nomo, ' ', resu, 1, [numa], 1, nomvari, cmp)
            call lxliis(cmp(2:8), ivari, iret)
            ASSERT(iret.eq.0)
            ASSERT(cmp(1:1).eq.'V')
        else
            nomvari=' '
        endif

        if (intres(1:3) .eq. 'NON') then
            call focrrs(nomfon, resu, 'G', nomcha, maille,&
                        noeud, cmp, npoint, nusp, ivari, nomvari,&
                        iret)
        else
            call focrr2(nomfon, resu, 'G', nomcha, maille,&
                        noeud, cmp, npoint, nusp, ivari, nomvari,&
                        iret)
        endif
        goto 10
    endif
 10 continue
    call foattr(' ', 1, nomfon)
!     --- VERIFICATION QU'ON A BIEN CREER UNE FONCTION ---
!         ET REMISE DES ABSCISSES EN ORDRE CROISSANT
    call ordonn(nomfon, 0)
!
    call titre()
    if (niv .gt. 1) call foimpr(nomfon, niv, ifm, 0, k8b)
!
    call jedema()
end subroutine
