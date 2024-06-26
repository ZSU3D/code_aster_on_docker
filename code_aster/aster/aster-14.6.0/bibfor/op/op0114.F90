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

subroutine op0114()
! person_in_charge: nicolas.greffet at edf.fr
! aslint: disable=W1304,W1305
    implicit none
!  ----- OPERATEUR RECU_PARA_YACS             --------------------------
!  RECUPERATION DE VALEURS D'INITIALISATION POUR COUPLAGE IFS VIA YACS
!     ------------------------------------------------------------------
#include "jeveux.h"
#include "asterc/cpedb.h"
#include "asterc/cpldb.h"
#include "asterc/cplen.h"
#include "asterc/getres.h"
#include "asterfort/getvis.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/infmaj.h"
#include "asterfort/infniv.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/liimpr.h"
#include "asterfort/titre.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
    integer :: ifm, niv, nbvale, ndim, jpas, jnbp, jbor, jval, i
    character(len=19) :: resu
    character(len=16) :: nomcmd, concep
!     ------------------------------------------------------------------
!     COUPLAGE =>
    integer(kind=4) :: lenvar, cpiter, numpa4, taille, eyacs(1), ibid4
    integer :: icompo, ibid, numpas, iadr
    parameter (lenvar = 144)
    parameter (cpiter= 41)
    real(kind=4) :: ti4, tf4
    real(kind=8) :: dt, ryacs(1), ti, tf
    character(len=16) :: option, valk(3)
    character(len=24) :: ayacs
    character(len=lenvar) :: nomvar
!     COUPLAGE <=
!
    call jemarq()
    call infmaj()
    call infniv(ifm, niv)
!
!     ASSIGNATION DES NOMS POUR LES ADRESSES DANS LES COMMON ASTER
!     ------------------------------------------------------------
    ayacs='&ADR_YACS'
!
!     RECUPERATION DE L'ADRESSE YACS
!     ------------------------------
    call jeveuo(ayacs, 'L', iadr)
    icompo=zi(iadr)
!
    call getres(resu, concep, nomcmd)
!
    call getvtx(' ', 'DONNEES', scal=option, nbret=ibid)
    if (niv .eq. 2) then
        valk(1) = 'OP0114'
        valk(2) = 'DONNEES'
        valk(3) = option
        call utmess('I+', 'COUPLAGEIFS_11', nk=3, valk=valk)
    endif
!
    nbvale = 7
    if (( option(1:3) .eq. 'FIN' ) .or. ( option(1:4) .eq. 'CONV' ) .or.&
        ( option(1:3) .eq. 'PAS' )) nbvale = 1
!
    ndim = max(1,nbvale-1)
    call wkvect(resu//'.LPAS', 'G V R', ndim, jpas)
    call wkvect(resu//'.NBPA', 'G V I', ndim, jnbp)
    call wkvect(resu//'.BINT', 'G V R', nbvale, jbor)
    call wkvect(resu//'.VALE', 'G V R', nbvale, jval)
!
    if (option(1:4) .eq. 'INIT') then
        call getvr8(' ', 'PAS', scal=dt, nbret=ibid)
! reception des parametres utilisateurs a l iteration 0
        numpa4 = 0
        numpas = 0
        ti = 0.d0
        tf = 0.d0
        ti4 = 0.d0
        tf4 = 0.d0
!
        do 10 i = 1, nbvale-1
            zr(jpas+i-1) = 0.1d0
            zi(jnbp+i-1) = 1
10      continue
        zr(jpas) = 0.1d0
        zi(jnbp) = 1
!  RECEPTION NOMBRE DE PAS DE TEMPS
        nomvar = 'NBPDTM'
        call cplen(icompo, cpiter, ti4, tf4, numpa4,&
                   nomvar, int(1, 4), taille, eyacs, ibid4)
        zr(jbor) = eyacs(1)
        zr(jval) = eyacs(1)
!  RECEPTION NOMBRE DE SOUS-ITERATIONS
        nomvar = 'NBSSIT'
        call cplen(icompo, cpiter, ti4, tf4, numpa4,&
                   nomvar, int(1, 4), taille, eyacs, ibid4)
        zr(jbor+1) = eyacs(1)
        zr(jval+1) = eyacs(1)
!  RECEPTION EPSILON
        nomvar = 'EPSILO'
        call cpldb(icompo, cpiter, ti, tf, numpa4,&
                   nomvar, int(1, 4), taille, ryacs, ibid4)
        zr(jbor+2) = ryacs(1)
        zr(jval+2) = ryacs(1)
        nomvar = 'ISYNCP'
        call cplen(icompo, cpiter, ti4, tf4, numpa4,&
                   nomvar, int(1, 4), taille, eyacs, ibid4)
        zr(jbor+3) = eyacs(1)
        zr(jval+3) = eyacs(1)
        nomvar = 'NTCHRO'
        call cplen(icompo, cpiter, ti4, tf4, numpa4,&
                   nomvar, int(1, 4), taille, eyacs, ibid4)
        zr(jbor+4) = eyacs(1)
        zr(jval+4) = eyacs(1)
        nomvar = 'TTINIT'
        call cpldb(icompo, cpiter, ti, tf, numpa4,&
                   nomvar, int(1, 4), taille, ryacs, ibid4)
        zr(jbor+5) = ryacs(1)
        zr(jval+5) = ryacs(1)
!  RECEPTION PAS DE TEMPS DE REFERENCE
        nomvar = 'PDTREF'
        call cpldb(icompo, cpiter, ti, tf, numpa4,&
                   nomvar, int(1, 4), taille, ryacs, ibid4)
        zr(jbor+6) = ryacs(1)
        zr(jval+6) = ryacs(1)
    else
        call getvr8(' ', 'INST', scal=tf, nbret=ibid)
        call getvis(' ', 'NUME_ORDRE_YACS', scal=numpas, nbret=ibid)
        numpa4 = int(numpas, 4)
        call getvr8(' ', 'PAS', scal=dt, nbret=ibid)
        ti = tf
        if (option(1:3) .eq. 'FIN') then
            nomvar = 'END'
            ryacs(1) = 0.d0
        else
            if (option(1:4) .eq. 'CONV') then
                nomvar = 'ICVAST'
                call cplen(icompo, cpiter, ti4, tf4, numpa4,&
                           nomvar, int(1, 4), taille, eyacs, ibid4)
                ryacs(1) = eyacs(1)
            else
                nomvar = 'DTAST'
                call cpedb(icompo, cpiter, ti, numpa4, nomvar,&
                           int(1, 4), [dt], ibid4)
                nomvar = 'DTCALC'
                call cpldb(icompo, cpiter, ti, tf, numpa4,&
                           nomvar, int(1, 4), taille, ryacs, ibid4)
            endif
        endif
        zr(jbor) = ryacs(1)
        zr(jval) = ryacs(1)
        zr(jpas) = 0.1d0
        zi(jnbp) = 1
!
    endif
!     --- TITRE ---
    call titre()
!     --- IMPRESSION ---
    if (niv .gt. 1) call liimpr(resu, niv, 'MESSAGE')
!
    call jedema()
end subroutine
