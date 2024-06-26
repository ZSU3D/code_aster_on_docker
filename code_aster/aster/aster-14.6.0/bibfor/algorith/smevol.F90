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

subroutine smevol(temper, modelz, mate, compor, option,&
                  phasin, numpha)
    implicit none
#include "jeveux.h"
#include "asterc/r8prem.h"
#include "asterc/r8vide.h"
#include "asterfort/calc_meta_init.h"
#include "asterfort/calcul.h"
#include "asterfort/cesvar.h"
#include "asterfort/copisd.h"
#include "asterfort/detrsd.h"
#include "asterfort/exlima.h"
#include "asterfort/inical.h"
#include "asterfort/iunifi.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenonu.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/mecact.h"
#include "asterfort/rcadme.h"
#include "asterfort/rsadpa.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsnoch.h"
#include "asterfort/rsorac.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
!
    integer :: numpha
    character(len=8) :: temper
    character(len=16) :: option
    character(len=19) :: compor
    character(len=24) :: mate, phasin
    character(len=*) :: modelz
! ......................................................................
!     OPTION: META_ELGA_TEMP    DES COMMANDES:   THER_LINEAIRE
!             META_ELNO                  ET THER_NON_LINE
!                          ET APPEL A CALCUL
! ......................................................................
!
!
!
    integer :: nbhist, iadtrc(2), long, jordr, nbordr(1), i, iret, vali(2), iad
    integer :: ifm,  ibid, num0, num1, num2, num3, iord, iainst, numphi
    real(kind=8) :: r8b, time(6), inst0, inst1, inst2, dt3
    real(kind=8) :: valr(2)
    integer :: valii
    complex(kind=8) :: cbid
    integer :: icodre, test
    character(len=8) :: k8b, modele, nomcm2(2), mater, timcmp(6), lpain(8)
    character(len=8) :: lpaout(2)
    character(len=19) :: sdtemp, lchin(8), lchout(2)
    character(len=24) :: ch24, ligrmo, tempe, tempa, nomch, chtime, kordre
    character(len=24) :: chmate, tempi, chftrc
    character(len=8), pointer :: vale(:) => null()
!
    data timcmp/ 'INST    ', 'DELTAT  ', 'THETA   ', 'KHI     ',&
     &             'R       ', 'RHO     '/
    data time   / 6*0.d0 /
    data nomcm2 / 'I1  ', 'I2  ' /
!     ------------------------------------------------------------------
!
    call jemarq()
    modele = modelz
    ifm = iunifi('MESSAGE')
!
    call inical(8, lpain, lchin, 2, lpaout,&
                lchout)
!
!
! --- RECUPERATION DE LA STRUCTURE DE DONNEES MATERIAU
!
    ch24 = mate(1:8)//'.CHAMP_MAT'
    chmate = mate(1:8)//'.MATE_CODE'
    call jeveuo(ch24(1:19)//'.VALE', 'E', vk8=vale)
    call jelira(ch24(1:19)//'.VALE', 'LONMAX', long)
    call exlima(' ', 0, 'V', modele, ligrmo)
!
    nbhist = 0
    test =1
    iadtrc(1) = 0
    iadtrc(2) = 0
!
    do i = 1, long
        mater = vale(i)
        if (mater .ne. '        ') then
            call rcadme(mater, 'META_ACIER', 'TRC', iadtrc, icodre,&
                        0)
            if (icodre .eq. 0) test = 0
            nbhist = max(nbhist,iadtrc(1))
        endif
    end do
!
    if (test .eq. 0) then
        call wkvect('&&SMEVOL_FTRC', 'V V R', 9*nbhist, vali(1))
        call wkvect('&&SMEVOL_TRC', 'V V R', 15*nbhist, vali(2))
        chftrc = '&&SMEVOL.ADRESSES'
        call mecact('V', chftrc, 'LIGREL', ligrmo, 'ADRSJEVN',&
                    ncmp=2, lnomcmp=nomcm2, vi=vali)
    else
        chftrc = ' '
    endif
!
! --- RECUPERATION DES PAS DE TEMPS DE LA STRUCTURE DE DONNEES EVOL_THER
!
    sdtemp = temper
    kordre = '&&SMEVOL.NUMEORDR'
    call rsorac(sdtemp, 'LONUTI', 0, r8b, k8b,&
                cbid, r8b, k8b, nbordr, 1,&
                ibid)
    call wkvect(kordre, 'V V I', nbordr(1), jordr)
    call rsorac(sdtemp, 'TOUT_ORDRE', 0, r8b, k8b,&
                cbid, r8b, k8b, zi(jordr), nbordr(1),&
                ibid)
!
! CREATION CHAM_ELEM COMPOR DONNANT NOMBRE DE VARIABLE INTERNE ET
! CONSIDERE VIA LCHOUT COMME UNE DONNEE ENTREE DE CALCUL
!
    call detrsd('CHAM_ELEM_S', compor)
    call cesvar(' ', compor, ligrmo, compor)
!
! --- SI NUMPHA = 0
! --- RECUPERATION DU CHAMP INITIAL (PAS 0 ET 1) DE METALLURGIE
! --- TRANSFORMATION DE LA CARTE EN CHAM_ELEM
! --- ET STOCKAGE DU CHAMP INITIAL DANS LA S D EVOL_THER (PAS 0 ET 1)
!
    if (numpha .eq. 0) then
!
        numphi=1
        num0 = zi(jordr)
        call calc_meta_init(temper, num0, ligrmo, compor, phasin,&
                            chmate)
        num1 = zi(jordr+1)
        call calc_meta_init(temper, num1, ligrmo, compor, phasin,&
                            chmate)
!
    else
        numphi=0
        do iord = 2, nbordr(1)
            if (zi(jordr+iord-1) .eq. numpha) numphi=iord-1
        enddo
    endif
!
! --- BOUCLE SUR LES PAS DE TEMPS DU CHAMP DE TEMPERATURE
!
    do iord = 1, nbordr(1) - 2
!
        if (zi(jordr+iord-1) .lt. zi(jordr+numphi-1)) goto 19
!
        num1 = zi(jordr+iord-1)
        num2 = zi(jordr+iord )
        num3 = zi(jordr+iord+1)
!
        call rsexch('F', temper, 'TEMP', num1, tempa,&
                    iret)
        call rsexch('F', temper, 'TEMP', num2, tempe,&
                    iret)
        call rsexch('F', temper, 'META_ELNO', num2, phasin,&
                    iret)
        call rsexch('F', temper, 'TEMP', num3, tempi,&
                    iret)
!
! --- RECUPERATION DE L'INSTANT DE CALCUL ET DES DELTAT -> CHAMP(INST_R)
!
        call rsadpa(sdtemp, 'L', 1, 'INST', num1,&
                    0, sjv=iainst, styp=k8b)
        inst0 = zr(iainst)
!
        call rsadpa(sdtemp, 'L', 1, 'INST', num2,&
                    0, sjv=iainst, styp=k8b)
        inst1 = zr(iainst)
!
        call rsadpa(sdtemp, 'L', 1, 'INST', num3,&
                    0, sjv=iainst, styp=k8b)
        inst2 = zr(iainst)
!
        time(1) = inst1
        time(2) = inst1 - inst0
        time(3) = inst2 - inst1
!
        call jenonu(jexnom(sdtemp//'.NOVA', 'DELTAT'), iad)
        if (iad .ne. 0) then
            call rsadpa(sdtemp, 'L', 1, 'DELTAT', num3,&
                        0, sjv=iad, styp=k8b, istop=0)
            dt3 = zr(iad)
            if (dt3 .ne. r8vide()) then
                if (abs(dt3-time(3)) .gt. r8prem()) then
                    valii = num3
                    valr (1) = dt3
                    valr (2) = time(3)
                    call utmess('A', 'ALGORITH14_61', si=valii, nr=2, valr=valr)
                endif
            endif
        endif
!
        chtime = '&&SMEVOL.CH_INST_R'
        call mecact('V', chtime, 'MODELE', ligrmo, 'INST_R  ',&
                    ncmp=6, lnomcmp=timcmp, vr=time)
!
! CALCUL DE META_ELNO
! ------------------------
!
        lpaout(1) = 'PPHASNOU'
        lchout(1) = '&&SMEVOL.PHAS_META3'
!
        lpain(1) = 'PMATERC'
        lchin(1) = chmate(1:19)
        lpain(2) = 'PCOMPOR'
        lchin(2) = compor(1:19)
        lpain(3) = 'PTEMPAR'
        lchin(3) = tempa(1:19)
        lpain(4) = 'PTEMPER'
        lchin(4) = tempe(1:19)
        lpain(5) = 'PTEMPIR'
        lchin(5) = tempi(1:19)
        lpain(6) = 'PTEMPSR'
        lchin(6) = chtime(1:19)
        lpain(7) = 'PPHASIN'
        lchin(7) = phasin(1:19)
        lpain(8) = 'PFTRC'
        lchin(8) = chftrc(1:19)
!
        call copisd('CHAM_ELEM_S', 'V', compor, lchout(1))
        call calcul('S', option, ligrmo, 8, lchin,&
                    lpain, 1, lchout, lpaout, 'V',&
                    'OUI')
!
! ----- STOCKAGE DU CHAMP DANS LA S D EVOL_THER
!
        call rsexch(' ', temper, 'META_ELNO', num3, nomch,&
                    iret)
        call copisd('CHAMP_GD', 'G', '&&SMEVOL.PHAS_META3', nomch(1:19))
        call rsnoch(temper, 'META_ELNO', num3)
!        write(ifm,1010) 'META_ELNO', num3, inst2
        call utmess('I', 'ARCHIVAGE_6', sk='META_ELNO', si=num3, sr=inst2)

        call rsexch(' ', temper, 'COMPORMETA', num3, nomch,&
                    iret)
        call copisd('CHAMP_GD', 'G', compor, nomch(1:19))
        call rsnoch(temper, 'COMPORMETA', num3)
!        write(ifm,1010) 'META_ELNO', num3, inst2
        call utmess('I', 'ARCHIVAGE_6', sk='COMPORMETA', si=num3, sr=inst2)

!
19      continue
    end do
!
! --- MENAGE
    call jedetr('&&SMEVOL_FTRC')
    call jedetr('&&SMEVOL_TRC')
    call jedetr('&&SMEVOL.NUMEORDR')
    call detrsd('CARTE', '&&SMEVOL.ADRESSES')
    call detrsd('CARTE', '&&SMEVOL.CH_INST_R')
    call detrsd('CHAMP_GD', '&&SMEVOL.PHAS_META1')
    call detrsd('CHAMP_GD', '&&SMEVOL.PHAS_META3')
!
!    1010 format (1p,3x,'CHAMP    STOCKE   :',1x,a14,' NUME_ORDRE:',i8,&
!     &       ' INSTANT:',d12.5)
!
    call jedema()
end subroutine
