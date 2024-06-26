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

subroutine meonme(modele, nchar, lchar, mate, matel)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/calcul.h"
#include "asterfort/codent.h"
#include "asterfort/dismoi.h"
#include "asterfort/exisd.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jemarq.h"
#include "asterfort/mecham.h"
#include "asterfort/memare.h"
#include "asterfort/reajre.h"
#include "asterfort/utmess.h"
    integer :: nchar
    character(len=8) :: modele, lchar(*)
    character(len=19) :: matel
    character(len=*) :: mate
!     CALCUL DES MATRICES ELEMENTAIRES D 'IMPEDANCE PAR ONDE INCIDENTE
!     ACOUSTIQUE DANS LE PHENOMENE MECANIQUE
!
!
! ----------------------------------------------------------------------
! IN  : MODELE : NOM DU MODELE
! IN  : NCHAR  : NOMBRE DE CHARGES
! IN  : LCHAR  : LISTE DES CHARGES
! IN  : MATE   : CARTE DE MATERIAU
! VAR : MATEL  : NOM  DU  MATELE (N RESUELEM) PRODUIT
! ----------------------------------------------------------------------
!     ------------------------------------------------------------------
    integer :: nh
    character(len=8) :: k8b, cara, lpain(3), lpaout(1)
    character(len=16) :: option
    character(len=24) :: ligrmo, lchin(3), lchout(1)
    character(len=24) :: chgeom, chcara(18), chharm
    aster_logical :: lfonc
!
!-----------------------------------------------------------------------
    integer :: icha, icode, ilires, iret
!-----------------------------------------------------------------------
    call jemarq()
    if (modele(1:1) .eq. ' ') then
        call utmess('F', 'CALCULEL2_82')
    endif
!
    cara = ' '
    nh = 0
    option = 'CHAR_MECA'
    call mecham(option, modele, cara, nh, chgeom,&
                chcara, chharm, icode)
!
    call jeexin(matel//'.RERR', iret)
    if (iret .gt. 0) then
        call jedetr(matel//'.RERR')
        call jedetr(matel//'.RELR')
    endif
    call memare('G', matel, modele, mate, ' ',&
                option)
!
    lpaout(1) = 'PMATUUR'
    lchout(1) = matel(1:8)//'.ME001'
    ilires = 0
    if (lchar(1) .ne. '        ') then
!
        ligrmo = modele//'.MODELE'
        lpain(1) = 'PGEOMER'
        lchin(1) = chgeom
!
        lpain(3) = 'PMATERC'
        lchin(3) = mate
!
        do icha = 1, nchar
            call dismoi('TYPE_CHARGE', lchar(icha), 'CHARGE', repk=k8b)
            if (k8b(5:7) .eq. '_FO') then
                lfonc = .true.
            else
                lfonc = .false.
            endif
!           LIGRCH = LCHAR(ICHA)//'.CHME.LIGRE'
!
            call exisd('CHAMP_GD', lchar(icha)//'.CHME.ONDE ', iret)
            if (iret .ne. 0) then
                if (lfonc) then
                    option = 'ONDE_FLUI_F'
                    lpain(2) = 'PONDECF'
                else
                    option = 'ONDE_FLUI'
                    lpain(2) = 'PONDECR'
                endif
                lchin(2) = lchar(icha)//'.CHME.ONDE .DESC'
                ilires = ilires + 1
                call codent(ilires, 'D0', lchout(1) (12:14))
                call calcul('S', option, ligrmo, 3, lchin,&
                            lpain, 1, lchout, lpaout, 'G',&
                            'OUI')
                call reajre(matel, lchout(1), 'G')
            endif
        end do
    endif

    if (ilires.eq.0) then
        call utmess('F', 'CALCULEL2_84')
    endif
    call jedema()
end subroutine
