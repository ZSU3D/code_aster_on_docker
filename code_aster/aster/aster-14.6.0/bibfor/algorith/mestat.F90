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

subroutine mestat(modelz, fomulz, lischz, mate, caraz,&
                  ltpsz, solvez, compor, matasz)
!
! ---------------------------------------------------------------------
!     BUT:  FAIRE UN CALCUL DE MECANIQUE STATIQUE : K(T)*U = F(T)
!           POUR LES DIFFERENTS INSTANTS "T" DE LTPS.
!     IN: MODELZ : NOM D'1 MODELE
!         FOMULZ : LISTE DES FONCTIONS MULTIPLICATRICES
!         LISCHZ : INFORMATION SUR LES CHARGEMENTS
!         MATE   : NOM DU MATERIAU
!         CARAZ  : NOM D'1 CARAC_ELEM
!         LTPSZ  : LISTE DES INSTANTS DE CALCUL
!         SOLVEZ : METHODE DE RESOLUTION 'LDLT' OU 'GCPC'
!         COMPOR : COMPOR POUR LES MULTIFIBRE (POU_D_EM)
!         MATASZ : MATRICE ASSEMBLEE DU SYSTEME
!
!    OUT: L'EVOL_ELAS  EST REMPLI (POUR SA PARTIE 'DEPL')
! ---------------------------------------------------------------------
implicit none
!
! 0.1. ==> ARGUMENTS
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/etausr.h"
#include "asterc/getres.h"
#include "asterc/r8maem.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvid.h"
#include "asterfort/getvr8.h"
#include "asterfort/gnomsd.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jerecu.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mereso.h"
#include "asterfort/nmvcd2.h"
#include "asterfort/numero.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsnume.h"
#include "asterfort/sigusr.h"
#include "asterfort/utcrre.h"
#include "asterfort/utmess.h"
#include "asterfort/uttcpg.h"
#include "asterfort/uttcpr.h"
#include "asterfort/uttcpu.h"
#include "asterfort/vtcreb.h"
    character(len=*) :: modelz, fomulz, lischz, mate, caraz, ltpsz, solvez
    character(len=*) :: matasz
    character(len=8) :: ltps
    character(len=19) :: lischa, solveu
    character(len=24) :: compor
!
! 0.2. ==> COMMUNS
!
!
! 0.3. ==> VARIABLES LOCALES
!
    character(len=6) :: nompro
    parameter    (nompro = 'MESTAT')
    integer :: nbval, ibid, itps, itps0, iret, ninstc
    integer :: vali, nocc
    real(kind=8) :: time, instf, tps1(4), tps2(4), tps3(4), tcpu, partps(3)
    real(kind=8) :: valr(3)
    character(len=1) :: base
    character(len=8) :: repk, result, result_reuse
    character(len=14) :: nuposs
    character(len=16) :: k16bid
    character(len=19) :: maprec, vecass, chdepl, matass
    character(len=24) :: numedd, criter, modele, carele
    character(len=24) :: fomult, noojb
    aster_logical :: matcst, assmat
    aster_logical :: ltemp, lhydr, lsech, lptot
    real(kind=8), pointer :: vale(:) => null()
!
! DEB------------------------------------------------------------------
!====
! 1. PREALABLES
!====
!
    call jemarq()
!
! 1.1. ==> LES ARGUMENTS
!
    solveu = solvez
    modele = modelz
    carele = caraz
    matass = matasz
    fomult = fomulz
    lischa = lischz
    ltps = ltpsz
!
! 1.2. ==> LES CONSTANTES
!
!               12   345678   90123456789
    vecass = '&&'//nompro//'.2NDMBR_ASS'
    maprec = '&&'//nompro//'_MAT_PRECON'
!
    partps(2) = 0.d0
    partps(3) = 0.d0
    base = 'V'
    criter = '&&RESGRA_GCPC'
    call getres(result, k16bid, k16bid)
    call getvid(' ', 'RESULTAT', scal = result_reuse, nbret = nocc)
    if (nocc .ne. 0) then
        if (result .ne. result_reuse) then
            call utmess('F', 'SUPERVIS2_79', sk='RESULTAT')
        endif
    endif
!
!
! 1.3. ==> ALLOCATION DES RESULTATS
    call jelira(ltps//'           .VALE', 'LONMAX', nbval)
    call utcrre(result, nbval)
!
! 1.4. ==> ON REGARDE SI LE MATERIAU EST UNE FONCTION DU TEMPS
!     (DEPENDANCE AVEC LA TEMPERATURE, HYDRATATION, SECHAGE)
!
    call nmvcd2('HYDR', mate, lhydr)
    call nmvcd2('SECH', mate, lsech)
    call nmvcd2('PTOT', mate, lptot)
    call nmvcd2('TEMP', mate, ltemp)
!
!
!     -- LE MATERIAU (ELAS) PEUT-IL CHANGER AU COURS DU TEMPS ?
    call dismoi('ELAS_FO', mate, 'CHAM_MATER', repk=repk)
    matcst=(.not.(repk.eq.'OUI'))
!
! 2.2. ==> NUMEROTATION ET CREATION DU PROFIL DE LA MATRICE
!
    numedd=  '12345678.NUMED'
    noojb='12345678.00000.NUME.PRNO'
    call gnomsd(' ', noojb, 10, 14)
    numedd=noojb(1:14)
!
!
    call rsnume(result, 'DEPL', nuposs)
!
    call numero(numedd, 'VG',&
                old_nume_ddlz = nuposs,&
                modelz = modele , list_loadz = lischa)
!
    call vtcreb(vecass, 'V', 'R',&
                nume_ddlz = numedd)
!
!     ??? IL SERAIT PEUT ETRE BON DE VERIFIER QUE QUELQUE CHOSE BOUGE
!     AVEC LE TEMPS. POUR L'INSTANT ON RECALCULE LE 2EME MEMBRE A CHA
!     QUE FOIS.
!
    call uttcpu('CPU.OP0046.1', 'INIT', ' ')
    call uttcpu('CPU.OP0046.2', 'INIT', ' ')
    call uttcpu('CPU.OP0046.3', 'INIT', ' ')
!
    call jeveuo(ltps//'           .VALE', 'L', vr=vale)
    instf=r8maem()
    call getvr8(' ', 'INST_FIN', scal=instf, nbret=ibid)
!
!
!====
! 2. BOUCLE 2 SUR LES PAS DE TEMPS
!====
!
    ninstc=0
    do itps = 1, nbval
        call jerecu('V')
!
!       SI LE PAS DE TEMPS A DEJA ETE CALCULE, ON SAUTE L'ITERATION
        call rsexch(' ', result, 'DEPL', itps, chdepl,&
                    iret)
        if (iret .eq. 0) goto 2
!
! 2.1. ==> L'INSTANT
        itps0 = itps
        time = vale(itps)
!
!       -- SI ON A DEPASSE INSTF, ON SORT :
        if (time .gt. instf) goto 999
!
        ninstc=ninstc+1
        partps(1) = time
!
!
! 2.2.1. ==> Y-A-T'IL ASSEMBLAGE DES MATRICES ?
!
        if (.not.matcst .or. ninstc .eq. 1) then
            assmat = .true.
        else
            assmat = .false.
        endif
! 2.2.2. ==> RESOLUTION
!
        call mereso(result, modele, mate, carele, fomult,&
                    lischa, itps0, partps, numedd, vecass,&
                    assmat, solveu, matass, maprec, base,&
                    compor)
!
!       -- IMPRESSION EVENTUELLE DES MESURES DE TEMPS:
        call uttcpg('IMPR', 'INCR')
!
!       --- VERIFICATION SI INTERRUPTION DEMANDEE PAR SIGNAL USR1
!
        if (etausr() .eq. 1) call sigusr()
!
!
! 2.3. ==> CONTROLE DU TEMPS CPU
!
        call uttcpr('CPU.OP0046.1', 4, tps1)
        call uttcpr('CPU.OP0046.2', 4, tps2)
        call uttcpr('CPU.OP0046.3', 4, tps3)
        if (.not.matcst .or. ninstc .eq. 1) then
            tcpu = tps1(4) + tps2(4) + tps3(4)
        else
            tcpu = tps3(4)
        endif
        if (nbval .gt. 1 .and. itps .lt. nbval .and. tcpu .gt. .95d0* tps3(1)) then
            vali = itps
            valr (1) = time
            valr (2) = tcpu
            valr (3) = tcpu
            call utmess('Z', 'ALGORITH16_88', si=vali, nr=3, valr=valr,&
                        num_except=28)
            call utmess('F', 'ALGORITH11_83')
            goto 999
        endif
!
  2     continue
    end do
!
999 continue
    call detrsd('CHAMP_GD', vecass)
!
!
    call jeexin(criter(1:19)//'.CRTI', iret)
    if (iret .ne. 0) then
        call jedetr(criter(1:19)//'.CRTI')
        call jedetr(criter(1:19)//'.CRTR')
        call jedetr(criter(1:19)//'.CRDE')
    endif
    call jedema()
end subroutine
