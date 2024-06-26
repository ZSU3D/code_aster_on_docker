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

subroutine merifs(modele, nchar, lchar, mate, cara,&
                  time, matel, nh)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
!
#include "asterfort/calcul.h"
#include "asterfort/codent.h"
#include "asterfort/detrsd.h"
#include "asterfort/exisd.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mecham.h"
#include "asterfort/memare.h"
#include "asterfort/reajre.h"
#include "asterfort/vrcins.h"
    integer :: nchar, nh
    real(kind=8) :: time
    character(len=8) :: modele, cara
    character(len=19) :: matel
    character(len=*) :: lchar(*), mate
!     CALCUL DES MATRICES ELEMENTAIRES DE RIGIDITE MECA
!      OPTION 'RIGI_FLUI_STRU'.
! ----------------------------------------------------------------------
! IN  : MODELE : NOM DU MODELE  (PAS OBLIGATOIRE)
! IN  : NCHAR  : NOMBRE DE CHARGES
! IN  : LCHAR  : LISTE DES CHARGES
! IN  : MATE   : CARTE DE MATERIAU
! IN  : CARA   : CHAMP DE CARAC_ELEM
! IN  : MATEL  : NOM DU MATR_ELEM RESULTAT
! IN  : TIME   : INSTANT DE CALCUL
! IN  : NH     : NUMERO D'HARMONIQUE DE FOURIER
! ----------------------------------------------------------------------
!     ------------------------------------------------------------------
    character(len=2) :: codret
    character(len=8) :: lpain(15), lpaout(1)
    character(len=16) :: option
    character(len=19) :: chvarc
    character(len=24) :: ligrmo, ligrch, lchin(15), lchout(10)
    character(len=24) :: chgeom, chcara(18), chharm
!-----------------------------------------------------------------------
    integer :: icha, icode, ilires, iret, iret1
    character(len=24), pointer :: rerr(:) => null()
!-----------------------------------------------------------------------
    data chvarc /'&&MERIFS.CHVARC'/
!
    call jemarq()
    option = 'RIGI_FLUI_STRU'
    call mecham(option, modele, cara, nh, chgeom,&
                chcara, chharm, icode)
!
    call vrcins(modele, mate, cara, time, chvarc,&
                codret)
!
    call memare('G', matel, modele, mate, cara,&
                option)
!     SI LA RIGIDITE EST CALCULEE SUR LE MODELE, ON ACTIVE LES S_STRUC:
    call jeveuo(matel//'.RERR', 'E', vk24=rerr)
    rerr(3) (1:3) = 'OUI'
!
    call jeexin(matel//'.RELR', iret1)
    if (iret1 .gt. 0) call jedetr(matel//'.RELR')
    ilires = 0
!
    lpaout(1) = 'PMATUUR'
    lchout(1) = matel(1:8)//'.ME001'
!
    if (icode .eq. 0) then
        ligrmo = modele//'.MODELE'
        lpain(1) = 'PGEOMER'
        lchin(1) = chgeom
        lpain(2) = 'PMATERC'
        lchin(2) = mate
        lpain(3) = 'PCAORIE'
        lchin(3) = chcara(1)
        lpain(4) = 'PCADISK'
        lchin(4) = chcara(2)
        lpain(5) = 'PCAGNPO'
        lchin(5) = chcara(6)
        lpain(6) = 'PCACOQU'
        lchin(6) = chcara(7)
        lpain(7) = 'PCASECT'
        lchin(7) = chcara(8)
        lpain(8) = 'PVARCPR'
        lchin(8) = chvarc
        lpain(9) = 'PCAARPO'
        lchin(9) = chcara(9)
        lpain(10) = 'PHARMON'
        lchin(10) = chharm
        lpain(11) = 'PABSCUR'
        lchin(11) = chgeom(1:8)//'.ABSC_CURV'
        lpain(12) = 'PNBSP_I'
        lchin(12) = chcara(16)
        lpain(13) = 'PFIBRES'
        lchin(13) = chcara(17)
        lpain(14) = 'PCOMPOR'
        lchin(14) = mate(1:8)//'.COMPOR'
        lpain(15) = 'PCINFDI'
        lchin(15) = chcara(15)
        call calcul('S', option, ligrmo, 15, lchin,&
                    lpain, 1, lchout, lpaout, 'G',&
                    'OUI')
        call reajre(matel, lchout(1), 'G')
        ilires=ilires+1
    endif
!
    do icha = 1, nchar
        ligrch = lchar(icha) (1:8)//'.CHME.LIGRE'
        call jeexin(lchar(icha) (1:8)//'.CHME.LIGRE.LIEL', iret)
        if (iret .le. 0) cycle
        lchin(1) = lchar(icha) (1:8)//'.CHME.CMULT'
        call exisd('CHAMP_GD', lchar(icha) (1:8)//'.CHME.CMULT', iret)
        if (iret .le. 0) cycle
!
        lpain(1) = 'PDDLMUR'
        ilires=ilires+1
        call codent(ilires, 'D0', lchout(1) (12:14))
        option = 'MECA_DDLM_R'
        call calcul('S', option, ligrch, 1, lchin,&
                    lpain, 1, lchout, lpaout, 'G',&
                    'OUI')
        call reajre(matel, lchout(1), 'G')
    end do
! --- MENAGE
    call detrsd('CHAM_ELEM', chvarc)
!
    call jedema()
end subroutine
