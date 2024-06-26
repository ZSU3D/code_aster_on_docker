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

subroutine meamme(optioz, modele, nchar, lchar, mate,&
                  cara, time, base, merigi,&
                  memass, meamor, varplu)
!
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/calcul.h"
#include "asterfort/codent.h"
#include "asterfort/dbgcal.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/infdbg.h"
#include "asterfort/inical.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mecham.h"
#include "asterfort/memare.h"
#include "asterfort/reajre.h"
#include "asterfort/redetr.h"
#include "asterfort/vrcins.h"
!
    integer :: nchar
    real(kind=8) :: time
    character(len=*) :: modele, optioz, cara, mate
    character(len=*) :: merigi, memass, meamor, varplu
    character(len=8) :: lchar(*)
    character(len=1) :: base
!
! ----------------------------------------------------------------------
!
! CALCUL DES MATRICES ELEMENTAIRES D'AMOR_MECA
! OU DES MATRICES ELEMENTAIRES DE RIGI_MECA_HYST
!
! ----------------------------------------------------------------------
!
!
! IN  OPTION : 'AMOR_MECA' OU 'RIGI_MECA_HYST'
! IN  MODELE : NOM DU MODELE
! IN  NCHAR  : NOMBRE DE CHARGES
! IN  LCHAR  : LISTE DES CHARGES
! IN  MATE   : CHAM_MATER
! IN  CARA   : CARA_ELEM
! OUT MEAMOR : MATR_ELEM AMORTISSEMENT
! IN  TIME   : INSTANT DE CALCUL
! IN  MERIGI : MATR_ELEM_DEPL_R DE RIGI_MECA
! IN  MEMASS : MATR_ELEM_DEPL_R DE MASS_MECA
!
!
!
!
    integer :: nbout, nbin
    parameter    (nbout=3, nbin=14)
    character(len=8) :: lpaout(nbout), lpain(nbin)
    character(len=19) :: lchout(nbout), lchin(nbin)
!
    integer :: icode, iret, i, icha, ires1
    integer :: ialir1, ilires
    integer :: nh, nop
    integer :: nbres1
    character(len=2) :: codret
    character(len=8) :: nomgd
    character(len=19) :: ligre1, chvarc
    character(len=24) :: rigich, massch, ligrmo, ligrch
    character(len=24) :: chgeom, chcara(18), chharm, argu
    character(len=16) :: option
    aster_logical :: debug
    integer :: ifmdbg, nivdbg
    character(len=24), pointer :: rerr(:) => null()
!
! ----------------------------------------------------------------------
!
    call jemarq()
    call infdbg('PRE_CALCUL', ifmdbg, nivdbg)
!
! --- INITIALISATIONS
!
    if (modele(1:1) .eq. ' ') then
        ASSERT(.false.)
    endif
    option = optioz
    ligrmo = modele(1:8)//'.MODELE'
    if (nivdbg .ge. 2) then
        debug = .true.
    else
        debug = .false.
    endif
!
! --- INITIALISATION DES CHAMPS POUR CALCUL
!
    call inical(nbin, lpain, lchin, nbout, lpaout,&
                lchout)
!
! --- CREATION DES CHAMPS DE GEOMETRIE, CARA_ELEM ET FOURIER
!
    nh = 0
    call mecham(option, modele, cara, nh, chgeom,&
                chcara, chharm, icode)
!
! --- CREATION CHAMP DE VARIABLES DE COMMANDE CORRESPONDANT
!
    chvarc = '&&MEAMME.CHVARC'
    call vrcins(modele, mate, cara, time, chvarc,&
                codret)
!
! --- NOM DES RESUELEM DE RIGIDITE
!
    rigich = ' '
    if (merigi(1:1) .ne. ' ') then
        call jeexin(merigi(1:19)//'.RELR', iret)
        if (iret .gt. 0) then
            call jeveuo(merigi(1:19)//'.RELR', 'L', ialir1)
            call jelira(merigi(1:19)//'.RELR', 'LONUTI', nbres1)
            do i = 1, nbres1
                rigich = zk24(ialir1-1+i)
                ires1=i
                call dismoi('NOM_LIGREL', rigich(1:19), 'RESUELEM', repk=ligre1)
                if (ligre1(1:8) .eq. modele(1:8)) goto 20
            end do
            ASSERT(.false.)
 20         continue
!
!
!
        endif
    endif
!
! --- NOM DES RESUELEM DE MASSE
!
    massch = ' '
    if (memass(1:1) .ne. ' ') then
        call jeexin(memass(1:19)//'.RELR', iret)
        if (iret .gt. 0) then
            call jeveuo(memass(1:19)//'.RELR', 'L', ialir1)
            call jelira(memass(1:19)//'.RELR', 'LONUTI', nbres1)
            do i = 1, nbres1
                massch = zk24(ialir1-1+i)
                call dismoi('NOM_LIGREL', massch(1:19), 'RESUELEM', repk=ligre1)
                if (ligre1(1:8) .eq. modele(1:8)) goto 40
            end do
            ASSERT(.false.)
 40         continue
        endif
    endif
!
! --- CREATION DU .RERR DES MATR_ELEM D'AMORTISSEMENT
!
    call jeexin(meamor(1:19)//'.RERR', iret)
    if (iret .gt. 0) then
        call jedetr(meamor(1:19)//'.RERR')
        call jedetr(meamor(1:19)//'.RELR')
    endif
    call memare(base, meamor(1:19), modele(1:8), mate, cara(1:8),&
                'AMOR_MECA')
!     SI LA MATRICE EST CALCULEE SUR LE MODELE, ON ACTIVE LES S_STRUC:
    call jeveuo(meamor(1:19)//'.RERR', 'E', vk24=rerr)
    rerr(3) (1:3) = 'OUI'
!
! --- REMPLISSAGE DES CHAMPS D'ENTREE
!
    lpain(1) = 'PGEOMER'
    lchin(1) = chgeom(1:19)
    lpain(2) = 'PMATERC'
    lchin(2) = mate(1:19)
    lpain(3) = 'PCAORIE'
    lchin(3) = chcara(1)(1:19)
    lpain(4) = 'PCADISA'
    lchin(4) = chcara(4)(1:19)
    lpain(5) = 'PCAGNPO'
    lchin(5) = chcara(6)(1:19)
    lpain(6) = 'PCACOQU'
    lchin(6) = chcara(7)(1:19)
    lpain(7) = 'PVARCPR'
    lchin(7) = chvarc(1:19)
    lpain(8) = 'PRIGIEL'
    lchin(8) = rigich(1:19)
    nop=11
!
    if (rigich .ne. ' ') then
        call dismoi('NOM_GD', rigich, 'RESUELEM', repk=nomgd)
        if (nomgd .eq. 'MDNS_R') then
            lpain(8) = 'PRIGINS'
        else
            call jeveuo(merigi(1:19)//'.RELR', 'L', ialir1)
            call jelira(merigi(1:19)//'.RELR', 'LONUTI', nbres1)
            if (ires1 .lt. nbres1) then
                rigich = zk24(ialir1+ires1)
                call dismoi('NOM_GD', rigich, 'RESUELEM', repk=nomgd)
                if (nomgd .eq. 'MDNS_R') then
                    nop=12
                    lpain(12) = 'PRIGINS'
                    lchin(12) = rigich(1:19)
                endif
            endif
        endif
    endif
!
    lpain(9) = 'PMASSEL'
    lchin(9) = massch(1:19)
    lpain(10) = 'PCADISK'
    lchin(10) = chcara(2)(1:19)
    lpain(11) = 'PCINFDI'
    lchin(11) = chcara(15)(1:19)
!
!
! --- REMPLISSAGE DES CHAMPS DE SORTIE
!
    if (option(1:9) .eq. 'AMOR_MECA') then
        lpaout(1) = 'PMATUUR'
        lpaout(2) = 'PMATUNS'
    else if (option.eq.'RIGI_MECA_HYST') then
        lpaout(1) = 'PMATUUC'
    else
        ASSERT(.false.)
    endif
    lpaout(3) = 'PMATUUR'
    lchout(1) = meamor(1:8)//'.ME001'
    lchout(2) = meamor(1:8)//'.ME002'
    lchout(3) = meamor(1:8)//'.ME003'
!
! --- APPEL A CALCUL
!
!    nop = 12
    if (varplu .ne. ' ') then
        nop=nop+1
        lpain(nop) = 'PVARIPG'
        lchin(nop) = varplu(1:19)
    endif
!   -- pour les PMF :
    nop=nop+1
    lpain(nop) = 'PCOMPOR'
    lchin(nop) = mate(1:8)//'.COMPOR'
    
    
    call calcul('S', option, ligrmo, nop, lchin,&
                lpain, 2, lchout, lpaout, base,&
                'OUI')
!
    if (debug) then
        call dbgcal(option, ifmdbg, nop, lpain, lchin,&
                    2, lpaout, lchout)
    endif
!
    call reajre(meamor, lchout(1), base)
    call reajre(meamor, lchout(2), base)
!
! --- PRISE EN COMPTE DES MATRICES DE BLOCAGE DANS LE CAS D'UNE
! --- RIGIDITE HYSTERETIQUE :
!
    if (option .eq. 'RIGI_MECA_HYST') then
        do icha = 1, nchar
            ligrch = lchar(icha) (1:8)//'.CHME.LIGRE'
            argu = lchar(icha) (1:8)//'.CHME.LIGRE.LIEL'
            call jeexin(argu, iret)
            if (iret .le. 0) goto 50
            lchin(1) = lchar(icha) (1:8)//'.CHME.CMULT'
            argu = lchar(icha) (1:8)//'.CHME.CMULT.DESC'
            call jeexin(argu, iret)
            if (iret .le. 0) goto 50
!
            lpain(1) = 'PDDLMUR'
            call jelira(meamor(1:19)//'.RELR', 'LONUTI', ilires)
            call codent(ilires+1, 'D0', lchout(3) (12:14))
            option = 'MECA_DDLM_R'
            call calcul('S', option, ligrch, 1, lchin,&
                        lpain, 1, lchout(3), lpaout(3), base,&
                        'OUI')
            call reajre(meamor, lchout(3), base)
 50         continue
        end do
    endif
!
!
!     -- DESTRUCTION DES RESUELEM NULS :
    call redetr(meamor)
!
    call detrsd('CHAMP_GD', chvarc)
!
    call jedema()
end subroutine
