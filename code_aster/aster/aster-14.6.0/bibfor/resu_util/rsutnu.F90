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

subroutine rsutnu(resu, motcle, iocc, knum, nbordr,&
                  prec, crit, ier)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getexm.h"
#include "asterc/getres.h"
#include "asterfort/getvid.h"
#include "asterfort/getvis.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/i2trgi.h"
#include "asterfort/indiis.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jedupo.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/lxlgut.h"
#include "asterfort/ordis.h"
#include "asterfort/rsadpa.h"
#include "asterfort/rsnopa.h"
#include "asterfort/rsorac.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
    integer :: iocc, nbordr, ier
    real(kind=8) :: prec
    character(len=*) :: resu, motcle, knum, crit
! person_in_charge: nicolas.sellenet at edf.fr
!        RECUPERATION DES NUMEROS D'ORDRE DANS UNE STRUCTURE DE DONNEES
!     DE TYPE "RESULTAT" A PARTIR DES VARIABLES D'ACCES UTILISATEUR
!     LES ACCES : NUME_ORDRE
!                 FREQ, INST, NOEUD_CMP, ...
!                 TOUT_ORDRE (PAR DEFAUT)
!     ------------------------------------------------------------------
! IN  : RESU   : NOM DE LA STRUCTURE DE DONNEES
! IN  : MOTCLE : NOM DU MOT CLE FACTEUR
! IN  : IOCC   : NUMERO D'OCCURENCE
! IN  : KNUM   : NOM JEVEUX DU VECTEUR ZI POUR ECRIRE LA LISTE DES NUME
! OUT : NBORDR : NOMBRE DE NUMERO D'ORDRE
! IN  : PREC   : PRECISION DEMANDEE
! IN  : CRIT   : CRITERE DEMANDE
! OUT : IER    : CODE RETOUR, = 0 : OK
!     ------------------------------------------------------------------
    integer :: ibid, n1, n2, nbacc, iret, jpara, iacc, iad, iut, nbval
    integer :: vali(4)
    integer :: jval, nbva2, jnch, ii, ival, nbtrou, lg, laccr
    integer :: iord, jordr, jord1, jord2, nbordt, nbinst, nbfreq
    integer :: nbtrop, indi, jordr3, long1, jordr1, jordr2, itrou, i
    real(kind=8) :: r8b
    real(kind=8) :: valr
    character(len=4) :: ctyp
    character(len=80) :: valk(2)
    character(len=8) :: k8b
    character(len=16) :: concep, nomcmd, nomacc
    character(len=19) :: knacc, kvacc, knmod, listr, resuin, knum2
    complex(kind=8) :: c16b
    integer :: ltout, linst, lfreq, lordr, tord(1)
    aster_logical :: verifi
!     ------------------------------------------------------------------
    call jemarq()
    call getres(k8b, concep, nomcmd)
    knacc = '&&RSUTNU.NOM_ACCES '
    kvacc = '&&RSUTNU.VALE_ACCES'
    knmod = '&&RSUTNU.NOEUD_CMP '
    nbordr = 0
    ier = 0
!
    resuin = resu
    call jelira(resuin//'.ORDR', 'LONUTI', iret)
    if (iret .eq. 0) then
        ier = 10
        goto 100
    endif
!
!     --- CAS "NUME_ORDRE" ---
    call getvis(motcle, 'NUME_ORDRE', iocc=iocc, nbval=0, nbret=n1)
    if (n1 .ne. 0) then
        nbordr = -n1
        call wkvect(knum, 'V V I', nbordr, jordr)
        call getvis(motcle, 'NUME_ORDRE', iocc=iocc, nbval=nbordr, vect=zi(jordr),&
                    nbret=n1)
        goto 100
    endif
!
!     --- CAS "NUME_MODE","INST","FREQ", ... ---
    n2 = 0
    call rsnopa(resu, 0, knacc, nbacc, ibid)
    call jeexin(knacc, iret)
    if (iret .gt. 0) call jeveuo(knacc, 'L', jpara)
    if (nbacc .ne. 0) then
        call rsorac(resu, 'TOUT_ORDRE', 0, r8b, k8b,&
                    c16b, r8b, k8b, tord, 1,&
                    ibid)
        iord=tord(1)            
        do 40 iacc = 1, nbacc
            if (getexm(motcle,zk16(jpara-1+iacc)) .eq. 0) goto 40
!
            ctyp = '    '
            call rsadpa(resu, 'L', 1, zk16(jpara-1+iacc), iord,&
                        1, sjv=iad, styp=ctyp, istop=0)
            if (ctyp(1:1) .eq. 'I') then
                call getvis(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=0, nbret=n2)
            else if (ctyp(1:1).eq.'R') then
                call getvr8(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=0, nbret=n2)
            else if (ctyp(1:1).eq.'K') then
                call getvtx(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=0, nbret=n2)
                if (zk16(jpara-1+iacc) (1:9) .eq. 'NOEUD_CMP') n2 = n2/ 2
            endif
!
            if (n2 .ne. 0) then
                call rsorac(resu, 'LONUTI', 0, r8b, k8b,&
                            c16b, r8b, k8b, tord, 1,&
                            ibid)
                nbordt=tord(1)            
                call wkvect('&&RSUTNU.N1', 'V V I', nbordt, jord1)
                call wkvect('&&RSUTNU.N2', 'V V I', nbordt, jord2)
                nbval = -n2
                iut = lxlgut(ctyp)
                call wkvect(kvacc, 'V V '//ctyp(1:iut), nbval, jval)
                if (ctyp(1:1) .eq. 'I') then
                    call getvis(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbval,&
                                vect=zi(jval), nbret=n2)
                else if (ctyp(1:1).eq.'R') then
                    call getvr8(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbval,&
                                vect=zr(jval), nbret=n2)
                else if (ctyp(1:2).eq.'K8') then
                    call getvtx(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbval,&
                                vect=zk8(jval), nbret=n2)
                else if (ctyp(1:3).eq.'K16') then
                    if (zk16(jpara-1+iacc) (1:9) .eq. 'NOEUD_CMP') then
                        nbva2 = 2*nbval
                        call wkvect(knmod, 'V V K8', nbva2, jnch)
                        call getvtx(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbva2,&
                                    vect=zk8(jnch), nbret=n2)
                        do 10 ii = 1, nbval
                            zk16(jval+ii-1) = zk8( jnch+ (2*ii-1)-1)// zk8(jnch+ (2*ii)-1 )
 10                     continue
                        call jedetr(knmod)
                    else
                        call getvtx(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbval,&
                                    vect=zk16(jval), nbret=n2)
                    endif
                else if (ctyp(1:3).eq.'K24') then
                    call getvtx(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbval,&
                                vect=zk24(jval), nbret=n2)
                else if (ctyp(1:3).eq.'K32') then
                    call getvtx(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbval,&
                                vect=zk32(jval), nbret=n2)
                else if (ctyp(1:3).eq.'K80') then
                    call getvtx(motcle, zk16(jpara-1+iacc), iocc=iocc, nbval=nbval,&
                                vect=zk80(jval), nbret=n2)
                endif
                nbordr = 1
                do 20 ival = 1, nbval
                    if (ctyp(1:1) .eq. 'I') then
                        call rsorac(resu, zk16(jpara-1+iacc), zi(jval-1+ ival), r8b, k8b,&
                                    c16b, prec, crit, zi(jord2), nbordt,&
                                    nbtrou)
                    else if (ctyp(1:1).eq.'R') then
                        call rsorac(resu, zk16(jpara-1+iacc), ibid, zr(jval-1+ival), k8b,&
                                    c16b, prec, crit, zi(jord2), nbordt,&
                                    nbtrou)
                    else if (ctyp(1:2).eq.'K8') then
                        call rsorac(resu, zk16(jpara-1+iacc), ibid, r8b, zk8(jval-1+ival),&
                                    c16b, prec, crit, zi(jord2), nbordt,&
                                    nbtrou)
                    else if (ctyp(1:3).eq.'K16') then
                        call rsorac(resu, zk16(jpara-1+iacc), ibid, r8b, zk16(jval-1+ival),&
                                    c16b, prec, crit, zi(jord2), nbordt,&
                                    nbtrou)
                    else if (ctyp(1:3).eq.'K24') then
                        call rsorac(resu, zk16(jpara-1+iacc), ibid, r8b, zk24(jval-1+ival),&
                                    c16b, prec, crit, zi(jord2), nbordt,&
                                    nbtrou)
                    else if (ctyp(1:3).eq.'K32') then
                        call rsorac(resu, zk16(jpara-1+iacc), ibid, r8b, zk32(jval-1+ival),&
                                    c16b, prec, crit, zi(jord2), nbordt,&
                                    nbtrou)
                    else if (ctyp(1:3).eq.'K80') then
                        call rsorac(resu, zk16(jpara-1+iacc), ibid, r8b, zk80(jval-1+ival),&
                                    c16b, prec, crit, zi(jord2), nbordt,&
                                    nbtrou)
                    endif
                    if (nbtrou .eq. 1) then
                        call i2trgi(zi(jord1), zi(jord2), nbtrou, nbordr)
                    else if (nbtrou.gt.1) then
                        valk (1) = resu
                        call utmess('A+', 'UTILITAI8_38', sk=valk(1))
                        lg = max(1,lxlgut(zk16(jpara-1+iacc)))
                        if (ctyp(1:1) .eq. 'I') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            vali (1) = zi(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_39', sk=valk(1), si=vali(1))
                        else if (ctyp(1:1).eq.'R') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valr = zr(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_40', sk=valk(1), sr=valr)
                        else if (ctyp(1:2).eq.'K8') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk8(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', nk=2, valk=valk)
                        else if (ctyp(1:3).eq.'K16') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk16(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', nk=2, valk=valk)
                        else if (ctyp(1:3).eq.'K24') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk24(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', nk=2, valk=valk)
                        else if (ctyp(1:3).eq.'K32') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk32(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', nk=2, valk=valk)
                        else if (ctyp(1:3).eq.'K80') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk80(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', nk=2, valk=valk)
                        endif
                        vali (1) = nbtrou
                        vali (2) = zi(jord2)
                        vali (3) = zi(jord2+1)
                        vali (4) = zi(jord2+2)
                        if (nbtrou .eq. 2) then
                            call utmess('A', 'UTILITAI8_46', ni=3, vali=vali)
                        else
                            call utmess('A', 'UTILITAI8_48', ni=4, vali=vali)
                        endif
!
                        call i2trgi(zi(jord1), zi(jord2), nbtrou, nbordr)
                    else if (nbtrou.eq.0) then
                        valk (1) = resu
                        call utmess('A+', 'UTILITAI8_47', sk=valk(1))
                        lg = max(1,lxlgut(zk16(jpara-1+iacc)))
                        if (ctyp(1:1) .eq. 'I') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            vali (1) = zi(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_39', si=vali(1))
                        else if (ctyp(1:1).eq.'R') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valr = zr(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_40', sr=valr)
                        else if (ctyp(1:2).eq.'K8') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk8(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', sk=valk(1))
                        else if (ctyp(1:3).eq.'K16') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk16(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', sk=valk(1))
                        else if (ctyp(1:3).eq.'K24') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk24(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', sk=valk(1))
                        else if (ctyp(1:3).eq.'K32') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk32(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', sk=valk(1))
                        else if (ctyp(1:1).eq.'K80') then
                            valk (1) = zk16(jpara-1+iacc) (1:lg)
                            valk (2) = zk80(jval-1+ival)
                            call utmess('A+', 'UTILITAI8_41', sk=valk(1))
                        endif
                        call utmess('A', 'VIDE_1')
                        ier = ier + 10
                    else if (nbtrou.lt.0) then
                        call utmess('F', 'DVP_1')
                    endif
 20             continue
                nbordr = nbordr - 1
                if (nbordr .ne. 0) then
                    call wkvect(knum, 'V V I', nbordr, jordr)
                    do 30 iord = 0, nbordr - 1
                        zi(jordr+iord) = zi(jord1+iord)
 30                 continue
                endif
                call jedetr('&&RSUTNU.N1')
                call jedetr('&&RSUTNU.N2')
                goto 100
            endif
 40     continue
    endif
!
    linst = getexm(motcle,'LIST_INST')
    if (linst .eq. 1) then
        call getvid(motcle, 'LIST_INST', iocc=iocc, scal=listr, nbret=n1)
        if (n1 .ne. 0) then
            call rsorac(resu, 'LONUTI', 0, r8b, k8b,&
                        c16b, r8b, k8b, tord, 1,&
                        ibid)
            nbordt=tord(1)            
            nomacc = 'INST'
            call jeveuo(listr//'.VALE', 'L', laccr)
            call jelira(listr//'.VALE', 'LONMAX', nbinst)
            call wkvect('&&RSUTNU.N1', 'V V I', nbordt, jord1)
            call wkvect('&&RSUTNU.N2', 'V V I', nbordt, jord2)
            nbordr = 1
            do 50 iord = 0, nbinst - 1
                call rsorac(resu, nomacc, ibid, zr(laccr+iord), k8b,&
                            c16b, prec, crit, zi(jord2), nbordt,&
                            nbtrou)
                if (nbtrou .eq. 0) then
                    ier = ier + 1
                    valk (1)= nomacc
                    valr = zr(laccr+iord)
                    call utmess('A', 'UTILITAI8_56', sk=valk(1), sr=valr)
                else if (nbtrou.lt.0) then
                    call utmess('F', 'DVP_1')
                else
                    if (nbtrou .gt. 1) then
                        valk (1) = resu
                        valr = zr(laccr+iord)
                        vali (1) = nbtrou
                        call utmess('A', 'UTILITAI8_57', sk=valk(1), si=vali(1), sr=valr)
                    endif
                    call i2trgi(zi(jord1), zi(jord2), nbtrou, nbordr)
                endif
 50         continue
            nbordr = nbordr - 1
            if (nbordr .ne. 0) then
                call wkvect(knum, 'V V I', nbordr, jordr)
                do 60 iord = 0, nbordr - 1
                    zi(jordr+iord) = zi(jord1+iord)
 60             continue
            endif
            call jedetr('&&RSUTNU.N1')
            call jedetr('&&RSUTNU.N2')
            goto 100
        endif
    endif
!
    lfreq = getexm(motcle,'LIST_FREQ')
    if (lfreq .eq. 1) then
        call getvid(motcle, 'LIST_FREQ', iocc=iocc, scal=listr, nbret=n1)
        if (n1 .ne. 0) then
            call rsorac(resu, 'LONUTI', 0, r8b, k8b,&
                        c16b, r8b, k8b, tord, 1,&
                        ibid)
            nbordt=tord(1)            
            nomacc = 'FREQ'
            call jeveuo(listr//'.VALE', 'L', laccr)
            call jelira(listr//'.VALE', 'LONMAX', nbfreq)
            call wkvect('&&RSUTNU.N1', 'V V I', nbordt, jord1)
            call wkvect('&&RSUTNU.N2', 'V V I', nbordt, jord2)
            nbordr = 1
            do 70 iord = 0, nbfreq - 1
                call rsorac(resu, nomacc, ibid, zr(laccr+iord), k8b,&
                            c16b, prec, crit, zi(jord2), nbordt,&
                            nbtrou)
                if (nbtrou .eq. 0) then
                    ier = ier + 1
                    valk (1) = nomacc
                    valr = zr(laccr+iord)
                    call utmess('A', 'UTILITAI8_58', sk=valk(1), sr=valr)
                else if (nbtrou.lt.0) then
                    call utmess('F', 'DVP_1')
                else
                    if (nbtrou .gt. 1) then
                        valk (1) = resu
                        valr = zr(laccr+iord)
                        vali (1) = nbtrou
                        call utmess('A', 'UTILITAI8_59', sk=valk(1), si=vali(1), sr=valr)
                    endif
                    call i2trgi(zi(jord1), zi(jord2), nbtrou, nbordr)
                endif
 70         continue
            nbordr = nbordr - 1
            if (nbordr .ne. 0) then
                call wkvect(knum, 'V V I', nbordr, jordr)
                do 80 iord = 0, nbordr - 1
                    zi(jordr+iord) = zi(jord1+iord)
 80             continue
            endif
            call jedetr('&&RSUTNU.N1')
            call jedetr('&&RSUTNU.N2')
            goto 100
        endif
    endif
!
    lordr = getexm(motcle,'LIST_ORDRE')
    if (lordr .eq. 1) then
        call getvid(motcle, 'LIST_ORDRE', iocc=iocc, scal=listr, nbret=n1)
        if (n1 .ne. 0) then
            call jeveuo(listr//'.VALE', 'L', laccr)
            call jelira(listr//'.VALE', 'LONMAX', nbordr)
            call wkvect(knum, 'V V I', nbordr, jordr)
            do 90 iord = 0, nbordr - 1
                zi(jordr+iord) = zi(laccr+iord)
 90         continue
            goto 100
        endif
    endif
!
!     --- LE DERNIER: 'TOUT_ORDRE' VALEUR PAR DEFAUT ---
!
    ltout = getexm(motcle,'TOUT_ORDRE')
    if (ltout .eq. 1) then
        call rsorac(resu, 'LONUTI', 0, r8b, k8b,&
                    c16b, r8b, k8b, tord, 1,&
                    ibid)
        nbordr=tord(1)            
        call wkvect(knum, 'V V I', nbordr, jordr)
        call rsorac(resu, 'TOUT_ORDRE', 0, r8b, k8b,&
                    c16b, r8b, k8b, zi(jordr), nbordr,&
                    ibid)
    endif
!
100 continue
!
!
!     9- ON VERIFIE QUE LES NUMEROS D'ORDRE TROUVES APPARTIENNENT
!        BIEN A RESU ; SINON ON LES RETIRE DE LA LISTE :
!     ------------------------------------------------------------
    if (nbordr .gt. 0) then
        call jelira(resuin//'.ORDR', 'LONUTI', long1)
        call jeveuo(resuin//'.ORDR', 'L', jordr1)
        call jeveuo(knum, 'L', jordr2)
        nbtrop=0
        do 777 i = 1, nbordr
            itrou= indiis(zi(jordr1),zi(jordr2-1+i),1,long1)
            if (itrou .eq. 0) nbtrop=nbtrop+1
777     continue
!
        if (nbtrop .gt. 0) then
            knum2='&&RSUTNU.KNUM2'
            if ((nbordr-nbtrop) .eq. 0) then
                call utmess('F', 'UTILITAI4_53')
            endif
            call wkvect(knum2, 'V V I', nbordr-nbtrop, jordr3)
            indi=0
            do 778 i = 1, nbordr
                itrou= indiis(zi(jordr1),zi(jordr2-1+i),1,long1)
                if (itrou .gt. 0) then
                    indi=indi+1
                    zi(jordr3-1+indi)= zi(jordr2-1+i)
                endif
778         continue
            call jedetr(knum)
            call jedupo(knum2, 'V', knum, .false._1)
            call jedetr(knum2)
            nbordr=indi
        endif
!
        verifi=.false.
        call jeveuo(knum, 'L', jordr2)
        do 779 i = 1, nbordr-1
            if (zi(jordr2-1+i) .gt. zi(jordr2+i)) then
                verifi=.true.
            endif
779     continue
        if (verifi) then
            call ordis(zi(jordr2), nbordr)
        endif
    endif
!
!
!
!
    call jedetr('&&RSUTNU.NOM_ACCES')
    call jedetr('&&RSUTNU.VALE_ACCES')
    call jedetr('&&RSUTNU.NOEUD_CMP')
    call jedetr('&&RSUTNU.DOUBLE')
!
    call jedema()
end subroutine
