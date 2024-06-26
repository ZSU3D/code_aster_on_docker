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

subroutine fluimp(itypfl, nivpar, nivdef, melflu, typflu,&
                  nuor, freq, freqi, nbm, vite,&
                  npv, carac, calcul, amoc)
    implicit none
! IMPRESSION DANS LE FICHIER RESULTAT DES PARAMETRES DE COUPLAGE
! FLUIDE-STRUCTURE (FREQ,AMOR) ET/OU DES DEFORMEES MODALES
! APPELANT : FLUST1, FLUST2, FLUST3, FLUST4
!-----------------------------------------------------------------------
!  IN : ITYPLF : INDICE CARACTERISANT LE TYPE DE LA CONFIGURATION
!                ETUDIEE
!  IN : NIVPAR : NIVEAU D'IMPRESSION DES PARAMETRES DU COUPLAGE
!                (FREQ,AMOR)
!  IN : NIVDEF : NIVEAU D'IMPRESSION DES DEFORMEES MODALES
!  IN : MELFLU : NOM UTILISATEUR DU CONCEPT MELASFLU
!  IN : NUOR   : LISTE DES NUMEROS D'ORDRE DES MODES SELECTIONNES POUR
!                LE COUPLAGE
!  IN : FREQ   : LISTE DES FREQUENCES ET AMORTISSEMENTS REDUITS MODAUX
!                PERTURBES PAR L'ECOULEMENT
!  IN : FREQI  : LISTE DES FREQUENCES MODALES INITIALES
!  IN : NBM    : NOMBRE DE MODES PRIS EN COMPTE POUR LE COUPLAGE
!  IN : VITE   : LISTE DES VITESSES D'ECOULEMENT ETUDIEES
!  IN : NPV    : NOMBRE DE VITESSES D'ECOULEMENT
!  IN : CARAC   : DIAMETRE HYDRAULIQUE ET EPAISSEUR
!-----------------------------------------------------------------------
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/codent.h"
#include "asterfort/codree.h"
#include "asterfort/irdepl.h"
#include "asterfort/iunifi.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
!
    integer :: itypfl, nivpar, nivdef, nbm, npv, nuor(nbm)
    integer :: nive, nbval, lfsvi, pas
    character(len=19) :: melflu
    character(len=8) :: typflu
    real(kind=8) :: carac(2), freq(2*nbm*npv), freqi(*), vite(npv), amoc(*)
    real(kind=8) :: vrmin, vrmax, vrmin1, vrmin2, vrmax1, vrmax2
    real(kind=8) :: vmoy, vmoyto, reduit, rappor, rappo2
!
    integer :: jvit1, jvit2
    integer :: jtr1, jtr2
    integer :: lprofv, lnoe, iret, modul, modul2
    character(len=3) :: i3
    character(len=8) :: k8bid, nomsym, nomcmp(6), formar, numzo, nbpzon
    character(len=8) :: xl1, xl2, xl3
    character(len=13) :: xcod, xvred, xfreq1, xamor, xbmin, xbmax
    character(len=13) :: xvmin, xvmax, xvmoy
    character(len=30) :: cham30
    character(len=19) :: cham19
    character(len=24) :: nom1, nom2, fsvi, ccste
    character(len=100) :: chav11, chav12, chav13, chav21, chav22, chav23
    character(len=100) :: chav31, chav32, chav33, chav34
    character(len=100) :: chazp1, chazv1, chazp2, chazv2, chazp3, chazv3
    character(len=100) :: chazp4, chazv4, chazp5, chazv5, chazp6, chazv6
    character(len=100) :: chazp7, chazv7, chav40, chaz40
    character(len=255) :: ctrav1, ctrav2, ctrav3
    aster_logical :: lcor, lsup, linf, lmin, lmax, lresu, calcul(2)
!
!-----------------------------------------------------------------------
    integer :: i, ibid, ifr, ik, im, imod, ind
    integer :: iv, j, k, l1
    integer :: l2, l3, n1, n2, npasv, nzone
!
    real(kind=8) :: amor1, bmax, bmin, dif1, freq1, rbid, vred
    real(kind=8), pointer :: cste(:) => null()
    character(len=80), pointer :: trav1(:) => null()
    character(len=80), pointer :: trav2(:) => null()
    character(len=80), pointer :: trav3(:) => null()
    character(len=80), pointer :: trav4(:) => null()
    character(len=80), pointer :: trav5(:) => null()
    real(kind=8), pointer :: rap(:) => null()
    real(kind=8), pointer :: profv(:) => null()
    integer, pointer :: tempo(:) => null()
    real(kind=8), pointer :: fsvr(:) => null()
    real(kind=8), pointer :: ven(:) => null()
    real(kind=8), pointer :: vcn(:) => null()
    real(kind=8), pointer :: vrzo(:) => null()
    real(kind=8), pointer :: mass(:) => null()
!
!-----------------------------------------------------------------------
    data           nomcmp /'DX      ','DY      ','DZ      ',&
     &                     'DRX     ','DRY     ','DRZ     '/
!
!-----------------------------------------------------------------------
!
    call jemarq()
    ifr = iunifi('RESULTAT')
!
    nom1 = '&&COEFAM.CDR2'
    nom2 = '&&COEFRA.CKR2'
    cham30='******************************'
!
!
    cham19(1:13) = melflu(1:8)//'.C01.'
    nomsym = 'DEPL_R  '
    formar = '1PE12.5'
    nive = 3
!
    npasv = npv
!
    lcor = .false.
    lsup = .false.
    linf = .false.
    lmin = .false.
    lmax = .false.
    lresu = .false.
!
!
!     VERIFICATION DE LA COHERENCE DES VITESSES REDUITES
!     ENTRE LES FICHIERS .70 ET .71 - OPTION FAISCEAU-TRANS
!
    if (itypfl .eq. 1) then
        call jeexin(nom1, iret)
        if (iret .ne. 0) then
            call jeveuo(nom1, 'L', jvit1)
            call jeveuo(nom2, 'L', jvit2)
            vrmin1 = zr(jvit1-1+1)
            vrmax1 = zr(jvit1-1+2)
            vrmin2 = zr(jvit2-1+1)
            vrmax2 = zr(jvit2-1+2)
            if ((abs(vrmin1-vrmin2)) .gt. 1.0d-04 .or. (abs(vrmax1- vrmax2)) .gt. 1.0d-04) then
                call utmess('F', 'ALGELINE_42')
            endif
        endif
!
    endif
!
    if (nivpar .eq. 1) then
        if (calcul(1)) then
            write (ifr,*)
            write (ifr,*) '==============================================='
            write (ifr,*)
            write (ifr,*) ' RESULTAT MODULE COUPLAGE FLUIDE-STRUCTURE'
            write (ifr,*)
            write (ifr,*) 'EVOLUTION DE LA FREQUENCE ET DE L AMORTISSEMENT'
            write (ifr,*) '   EN FONCTION DE LA VITESSE DE L ECOULEMENT'
            write (ifr,*)
            write (ifr,*) '==============================================='
            write (ifr,*)
!
            call jeexin('&&FLUST1.TEMP.PROFV', iret)
            if (iret .ne. 0) then
                call jelira('&&FLUST1.TEMP.PROFV', 'LONMAX', lprofv)
                lnoe = (lprofv-1)/2
                call jeveuo('&&FLUST1.TEMP.PROFV', 'L', vr=profv)
                vmoyto = profv(lprofv)
                write (ifr,101) vmoyto
                write (ifr,*)
            endif
        endif
        if (itypfl .eq. 1) then
            call jeveuo('&&MDCONF.TEMPO', 'L', vi=tempo)
            nzone = tempo(1)
            if (calcul(2)) then
                call jeveuo(melflu(1:8)//'.VEN', 'L', vr=ven)
                call jeveuo(melflu(1:8)//'.VCN', 'L', vr=vcn)
                call jeveuo(melflu(1:8)//'.MASS', 'L', vr=mass)
                call jeveuo(melflu(1:8)//'.RAP', 'L', vr=rap)
!
                call jeveuo(typflu//'           .FSVR', 'L', vr=fsvr)
                fsvi = typflu//'           .FSVI'
                call jeveuo(fsvi, 'L', lfsvi)
                nbval=1
                ctrav2=' *'
                do 50 i = 1, nzone
                    nbval=nbval*zi(lfsvi+1+nzone+i)
                    ctrav2((2+(30*(i-1))):(2+(30*i)))=cham30
 50             continue
!
                do 60 i = 1, 180
                    ctrav2((1+(30*nzone)+i):(1+(30*nzone)+i))='*'
 60             continue
                ctrav2((1+(30*nzone)+181):(1+(30*nzone)+181))='*'
                AS_ALLOCATE(vr=cste, size=nzone)
            endif
        endif
!
!
        do 10 im = 1, nbm
            imod = nuor(im)
            if (calcul(1)) then
                write (ifr,102) imod,freqi(imod)
                write (ifr,*) ' ------------------------------------------'
                write (ifr,*)
!
! ---     ECRITURE DE L'EN-TETE DU TABLEAU POUR CHAQUE MODE
                chav11 = '****************'
                chav12 = '                '
                chav13 = '               *'
                chav21 = '    VITESSE    *'
                chav22 = '   FREQUENCE   *'
                chav23 = ' AMORTISSEMENT *'
                chav31 = '    GAP(M/S)   *'
                chav32 = '    REDUITE    *'
                chav33 = '     (HZ)      *'
                chav34 = '       %       *'
            endif
            if (itypfl .eq. 1) then
                if (calcul(1)) then
!
                    chazp1 = '****************************'
                    chazp2 = '                            '
                    chazp3 = ' VITESSE MOY : '
                    chazp4 = '----------------------------'
                    chazp5 = ' NB POINTS DE LA ZONE :'
                    chazp6 = '     DONT HORS PLAGE :      '
                    chazp7 = ' <VREDMIN   TOT    >VREDMAX '
!
                    chazv1 = '*********************************'
                    chazv2 = '  ZONE  '
                    chazv3 = '|    PLAGE DE VITESSE REDUITE   *'
                    chazv4 = '|-------------------------------*'
                    chazv5 = '|    VREDMIN    |    VREDMAX    *'
                    chazv6 = '| '
                    chazv7 = '|               |               *'
!
                    AS_ALLOCATE(vk80=trav1, size=nzone)
                    AS_ALLOCATE(vk80=trav2, size=nzone)
                    AS_ALLOCATE(vk80=trav3, size=nzone)
                    AS_ALLOCATE(vk80=trav4, size=nzone)
!
                    call jeveuo('&&COEFMO.VRZO', 'L', vr=vrzo)
!
                    do 15 j = 1, nzone
                        n1 = tempo(1+2*(j-1)+1)
                        n2 = tempo(1+2*(j-1)+2)
!                CONVERSION EN CHAINES DE CARACTERES
                        call codent(j, 'G', numzo)
                        call codent(n2-n1+1, 'G', nbpzon)
!
                        vrmin = vrzo(1+2*(j-1)+0)
                        call codree(vrmin, 'E', xvmin)
                        if (vrmin .lt. 0.d0) then
                            xvmin = '-'//xvmin(1:12)
                        else
                            xvmin = ' '//xvmin(1:12)
                        endif
!
                        vrmax = vrzo(1+2*(j-1)+1)
                        call codree(vrmax, 'E', xvmax)
                        if (vrmax .lt. 0.d0) then
                            xvmax = '-'//xvmax(1:12)
                        else
                            xvmax = ' '//xvmax(1:12)
                        endif
!
                        if (iret .ne. 0) then
                            vmoy = profv(1+lnoe+n1)
                            call codree(vmoy, 'E', xvmoy)
                            if (vmoy .lt. 0.d0) then
                                xvmoy = '-'//xvmoy(1:12)
                            else
                                xvmoy = ' '//xvmoy(1:12)
                            endif
                        else
                            xvmoy = '      -      '
                        endif
!
                        trav1(j) = chazv2(1:8)//numzo(1:2)// '          *'
                        trav2(j) = chazp3(1:15)//xvmoy//'*'
                        trav3(j) = chazp5(1:23)//nbpzon(1:4)// ' *'
                        trav4(j) = chazv6(1:2 )//xvmin//' | ' //xvmax//' *'
 15                 continue
!
                    write(ifr,301) ' *',chav11,chav11,chav11,chav11,&
                    (chazp1,chazv1,j=1,nzone)
                    write(ifr,301) ' *',chav12,chav12,chav12,chav13,&
                    (chazp2,trav1(j),j=1,nzone)
                    write(ifr,301) ' *',chav11,chav11,chav11,chav11,&
                    (chazp1,chazv1,j=1,nzone)
                    write(ifr,301) ' *',chav13,chav13,chav13,chav13,&
                    (trav2(j),chazv3,j=1,nzone)
                    write(ifr,301) ' *',chav21,chav21,chav22,chav23,&
                    (chazp4,chazv4,j=1,nzone)
                    write(ifr,301) ' *',chav31,chav32,chav33,chav34,&
                    (trav3(j),chazv5,j=1,nzone)
                    write(ifr,301) ' *',chav13,chav13,chav13,chav13,&
                    (chazp6,trav4(j),j=1,nzone)
                    write(ifr,301) ' *',chav13,chav13,chav13,chav13,&
                    (chazp7,chazv7,j=1,nzone)
                    write(ifr,301) ' *',chav11,chav11,chav11,chav11,&
                    (chazp1,chazv1,j=1,nzone)
!
                    AS_DEALLOCATE(vk80=trav1)
                    AS_DEALLOCATE(vk80=trav2)
                    AS_DEALLOCATE(vk80=trav3)
                    AS_DEALLOCATE(vk80=trav4)
                endif
            else
                write(ifr,201) ' *',chav11,chav11,chav11,chav11
                write(ifr,201) ' *',chav12,chav12,chav12,chav13
                write(ifr,201) ' *',chav11,chav11,chav11,chav11
                write(ifr,201) ' *',chav13,chav13,chav13,chav13
                write(ifr,201) ' *',chav21,chav21,chav22,chav23
                write(ifr,201) ' *',chav31,chav32,chav33,chav34
                write(ifr,201) ' *',chav13,chav13,chav13,chav13
                write(ifr,201) ' *',chav13,chav13,chav13,chav13
                write(ifr,201) ' *',chav11,chav11,chav11,chav11
            endif
!
            if (calcul(1)) then
! ---     ECRITURE DES LIGNES POUR CHAQUE VITESSE GAP
                do 20 iv = 1, npv
                    ind = 2*nbm*(iv-1) + 2*(im-1) + 1
                    freq1 = freq(ind)
                    amor1 = freq(ind+1)
                    dif1 = 1.d0-dble(abs(amor1))
!
                    if (vite(iv) .ge. 0) then
                        call codree(vite(iv), 'E', xcod)
                        xcod=' '//xcod(1:12)
                    else
                        call codree(abs(vite(iv)), 'E', xcod)
                        xcod='-'//xcod(1:12)
                    endif
!
                    if (freq1 .lt. 0.d0) then
                        chav40 = ' * '//xcod//' *            '// 'PROBLEME DE CONVERGENCE *'
                        if (itypfl .eq. 1) then
                            chaz40 = '                            |'// '        | *'
                            write(ifr,302) chav40,(chaz40,j=1,nzone)
                        else
                            write(ifr,202) chav40
                        endif
!
                    else if (dif1.lt.1.d-8) then
                        chav40 = ' * '//xcod//' *              '// 'SYSTEME SUR-AMORTI *'
                        if (itypfl .eq. 1) then
                            chaz40 = '                            |'// '        | *'
                            write(ifr,302) chav40,(chaz40,j=1,nzone)
                        else
                            write(ifr,202) chav40
                        endif
!
                    else
                        vred = vite(iv)/(freq1*carac(1))
                        if (vred .ge. 0) then
                            call codree(vred, 'E', xvred)
                            xvred = ' '//xvred(1:12)
                        else
                            call codree(abs(vred), 'E', xvred)
                            xvred = '-'//xvred(1:12)
                        endif
!
                        if (freq1 .ge. 0) then
                            call codree(freq1, 'E', xfreq1)
                            xfreq1 = ' '//xfreq1(1:12)
                        else
                            call codree(abs(freq1), 'E', xfreq1)
                            xfreq1 = '-'//xfreq1(1:12)
                        endif
!
                        if (amor1 .ge. 0) then
                            call codree(amor1*1.d+02, 'E', xamor)
                            xamor = ' '//xamor(1:12)
                        else
                            call codree(abs(amor1*1.d+02), 'E', xamor)
                            xamor = '-'//xamor(1:12)
                        endif
!
                        chav40 =' * '//xcod//' * '//xvred//' * '//&
                        xfreq1//' * '//xamor//' *'
!
                        if (itypfl .eq. 1) then
                            AS_ALLOCATE(vk80=trav5, size=10)
                            call jeveuo('&&PACOUC.TRAV1', 'L', jtr1)
                            call jeveuo('&&PACOUC.TRAV2', 'L', jtr2)
!
                            do 25 ik = 1, nzone
                                l1 = zi( jtr2 + 3*nzone*npv*(im-1)+ 3*nzone*(iv-1) + 3*(ik-1) )
                                l2 = zi(jtr2 + 3*nzone*npv*(im-1)+ 3*nzone*(iv-1) + 3*(ik-1) + 1)
                                l3 = zi(jtr2 + 3*nzone*npv*(im-1)+ 3*nzone*(iv-1) + 3*(ik-1) + 2)
                                bmin = zr(jtr1 + 2*nzone*npv*(im-1) + 2*nzone*(iv-1) + 2*(ik-1))
                                bmax = zr(&
                                       jtr1 +2*nzone*npv*(im-1) + 2*nzone*(iv-1) + 2*(ik-1) + 1)
                                call codent(l1, 'D', xl1)
                                call codent(l2, 'D', xl2)
                                call codent(l3, 'D', xl3)
                                if (l1 .eq. 0) then
                                    xbmin = '     -       '
                                else
                                    if (bmin .lt. 0.d0) then
                                        call codree(bmin, 'E', xbmin)
                                        xbmin = '-'//xbmin(1:12)
                                    else
                                        call codree(bmin, 'E', xbmin)
                                        xbmin = ' '//xbmin(1:12)
                                    endif
                                endif
                                if (l3 .eq. 0) then
                                    xbmax = '     -       '
                                else
                                    if (bmax .lt. 0.d0) then
                                        call codree(bmax, 'E', xbmax)
                                        xbmax = '-'//xbmax(1:12)
                                    else
                                        call codree(bmax, 'E', xbmax)
                                        xbmax = ' '//xbmax(1:12)
                                    endif
                                endif
                                trav5(ik) =' '//xl1(1:8)//' '//xl2(1:8)&
                                    &//' '//xl3(1:8)//' | '//xbmin//' | '&
                                    &//xbmax//' *'
 25                         continue
                            write (ifr,302) chav40,(trav5(j),&
                            j=1,nzone)
                            AS_DEALLOCATE(vk80=trav5)
                        else
                            write (ifr,202) chav40
                        endif
                    endif
 20             continue
!
                if (itypfl .eq. 1) then
                    write(ifr,301) '*',chav13,chav13,chav13,chav13,&
                    (chazp2,chazv7,j=1,nzone)
                    write(ifr,301) '*',chav11,chav11,chav11,chav11,&
                    (chazp1,chazv1,j=1,nzone)
                else
                    write(ifr,201) '*',chav13,chav13,chav13,chav13
                    write(ifr,201) '*',chav11,chav11,chav11,chav11
                endif
            endif
            if (calcul(2)) then
!
                write (ifr,*) '==============================================='
                write (ifr,*)
                write (ifr,*) 'VALEURS DES VITESSES CRITIQUES ET DES RAPPORTS'
                write (ifr,*) '   D INSTABILITE PAR LA METHODE DE CONNORS'
                write (ifr,*)
                write (ifr,*) '==============================================='
                write (ifr,*)
                write (ifr,103) mass(1)
                write (ifr,104) mass(2)
!
                if (calcul(1)) then
!
                    write (ifr,507)('*',j=1,117)
                    write (ifr,'(A)')' *   MODE    *      FREQUENCE(Hz)      *'//&
     &'    AMORTISSEMENT (%)    *  VITESSE EFFICACE (m/s) *'//&
     &'  VITESSE EFFICACE (m/s) *'
                    write (ifr,'(A)')' *           *                         *'//&
     &'                         *       (GEVIBUS)         *'//&
     &'       TTES CMPS         *'
!
                    write (ifr,507)('*',j=1,117)
                    write (ifr,501) imod,freqi(imod),(amoc(im)*100),&
                    ven(im),ven(nbm+im)
                    write (ifr,507)('*',j=1,117)
                    write (ifr,*)
!
                endif
                write(ifr,*)
                write(ifr,*) '============================================'
                write(ifr,*)'PLAGE DE VARIATION DES CONSTANTES DE CONNORS'
                write(ifr,*) '============================================'
                write(ifr,*)
                write(ifr,505) (cham30,j=1,nzone)
                write(ifr,503) ('ZONE',i,i=1,nzone)
                write(ifr,505) (cham30,j=1,nzone)
                write(ifr,504) (fsvr(1+3+2*(j-1)), fsvr(1+3+2*(j-&
                1)+1),j=1,nzone)
                write(ifr,505) (cham30,j=1,nzone)
                write(ifr,*)
                ctrav1=' *'
                ctrav3=' * '
                do 90 i = 1, nzone
                    call codent(i, 'D', i3)
                    ctrav1((3+30*(i-1)):(3+(30*i)))='           ZONE '//i3&
     &           //'          *'
 90             continue
!             CTRAV1((3+(30*NZONE)+120):(3+(30*NZONE)+120))='*'
                ctrav3(((15*nzone)-9):((15*nzone)+12))=&
     &             ' CONSTANTES DE CONNORS'
                ctrav3((2+(30*nzone)):(2+(30*nzone)))='*'
                ctrav3((3+(30*nzone)):(3+(30*nzone)+120))=&
     & '    VITESSE CRITIQUE (m/s)   *   VITESSE REDUITE CRITIQUE  *'&
     &//'    RAPPORT D INSTABILITE    *     RAPPORT TTES CMPS       *'
                write(ifr,'(A)') ctrav2(1:(2+(30*nzone)))
                write(ifr,'(A)') ctrav1(1:(2+(30*nzone)+90))
                write(ifr,'(A)') ctrav2(1:(2+(30*nzone)+120))
                write(ifr,'(A)') ctrav3(1:(2+(30*nzone)+120))
                write(ifr,'(A)') ctrav2(1:(2+(30*nzone)+120))
!
                do i = 1, nbval
                    ctrav1='* '
                    do j = 1, nzone
                        modul=1
                        do k = (j+1), nzone
                            modul=modul*zi(lfsvi+1+nzone+k)
                        enddo
                        if (j .eq. 1) then
                            pas=(i-1)/modul
                        else
                            modul2=modul*zi(lfsvi+1+nzone+j)
                            pas=(mod((i-1),modul2))/modul
                        endif
                        cste(j)=fsvr(1+3+2*(j-1))+pas*&
                        (fsvr(1+3+2*(j-1)+1)-fsvr(1+3+2*(j-1)))&
                        /(zi(lfsvi+1+nzone+j)-1)
                        call codree(cste(j), 'E', ccste)
                        ctrav1((3+(30*(j-1))):(3+(30*j)))='  '//ccste//'  *'
!
                    enddo
                    reduit=vcn((im-1)*nbval+i)/(freqi(imod)*&
                    carac(1))
                    rappor=rap((im-1)*nbval+i)
                    rappo2=rap(nbm*nbval+(im-1)*nbval+i)
!
                    write(ifr,506) cste, vcn((im-1)*nbval+&
                    i), reduit,rappor,rappo2
!
                enddo
                write(ifr,'(A)') ctrav2(1:(2+(30*nzone)+120))
                write(ifr,*)
            endif
!
 10     continue
!
    endif
!
    if (nivdef .eq. 1) then
!
        write (ifr,*)
        write (ifr,*) '==============================================='
        write (ifr,*)
        write (ifr,*) ' RESULTAT MODULE COUPLAGE FLUIDE-STRUCTURE'
        write (ifr,*)
        write (ifr,*) '        EVOLUTION DES DEFORMEES MODALES'
        write (ifr,*) '   EN FONCTION DE LA VITESSE DE L ECOULEMENT'
        write (ifr,*)
        write (ifr,*) '==============================================='
        write (ifr,*)
!
        if (itypfl .ne. 3) then
            npasv = 1
            write(ifr,*) 'LES DEFORMEES SOUS ECOULEMENT SONT INCHANGEES'//&
     &                 ' PAR RAPPORT A CELLES EN FLUIDE AU REPOS.'
            write(ifr,*)
        endif
!
        do 30 im = 1, nbm
            write(ifr,401) nuor(im)
            write(ifr,*)
            write(cham19(14:16),'(I3.3)') nuor(im)
            do 40 iv = 1, npasv
                write(ifr,402) iv
                write(ifr,*)
                write(cham19(17:19),'(I3.3)') iv
                call irdepl(cham19, ifr, 'RESULTAT', k8bid,&
                            k8bid, nomsym, ibid, lcor, 0,&
                            [0], 6, nomcmp, lsup, rbid,&
                            linf, rbid, lmax, lmin, lresu,&
                            formar)
                write(ifr,*)
 40         continue
 30     continue
!
    endif
    AS_DEALLOCATE(vr=cste)
    call jedema()
! --- FORMATS
!
    101 format (1p,' VITESSE MOYENNE SUR L ENSEMBLE DES ZONES = ',d13.6)
    102 format (1p,' MODE : NUMERO D ORDRE:',i3,'/ FREQ:',d13.6)
    103 format (1p,' MASSE LINEIQUE DE REFERENCE DU TUBE (kg/m) : ',e13.6)
    104 format (1p,' MASSE VOLUMIQUE DE REFERENCE DU FLUIDE SECONDAIRE (kg/m3) : ',e13.6)
    201 format (a2,4a16)
    202 format (a66)
!
    301 format (a2,4a16,30(a28,a33))
    302 format (a66,30a61)
!
    401 format (1x,' MODE N ',i3)
    402 format (1x,' VITESSE N ',i3)
!
    501 format (1p,1x,'*',3x,i3,5x,'*',4(5x,e13.6,7x,'*'))
    503 format (1x,'*',100(10x,a4,1x,i3,11x,'*'))
    504 format (1p,1x,100('*',d13.6,1x,'-',d13.6,1x))
    505 format (1x,'*',100a30)
    506 format (1p,1x,'*',5(8x,e13.6,8x,'*'))
    507 format (1p,1x,118a1)
!
!
end subroutine
