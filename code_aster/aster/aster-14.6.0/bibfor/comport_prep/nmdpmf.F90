! --------------------------------------------------------------------
! Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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

subroutine nmdpmf(compor, chmate)
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/getvid.h"
#include "asterfort/carces.h"
#include "asterfort/cescar.h"
#include "asterfort/cesfus.h"
#include "asterfort/cesred.h"
#include "asterfort/detrsd.h"
#include "asterfort/exisd.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/utmess.h"
#include "asterfort/tecart.h"
!
! person_in_charge: jean-luc.flejou at edf.fr
!
    character(len=19), intent(in) :: compor
    character(len=8), intent(in) :: chmate
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Save informations in COMPOR <CARTE>
!
! --------------------------------------------------------------------------------------------------
!
! In  compor      : name of <CARTE> COMPOR
! In  chmate      : name of material field
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ibid, iret
    aster_logical :: lcumu(2), lcoc(2)
    character(len=8) :: licmp
    character(len=19) :: chs(2), chs3, chsx
    real(kind=8) :: lcoer(2)
    complex(kind=8) :: lcoec(2)
    data lcumu/.false._1,.false./
    data lcoc/.false._1,.false./
    data lcoer/1.d0,1.d0/
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
!     EN PRESENCE DE MULTIFIBRE, ON FUSIONNE LES CARTES
!     S'IL EXISTE UNE POUTRE MULTIFIBRE LA CARTE A ETE CREEE LORS
!        DE AFFE_MATERIAU / AFFE_COMPOR AVEC RCCOMP
!
!     CHAM_ELEM_S DE TRAVAIL
    chs(1)='&&NMDPMF.CHS1'
    chs(2)='&&NMDPMF.CHS2'
    chs3  ='&&NMDPMF.CHS3'
    chsx  ='&&NMDPMF.CHSX'
!
!     ON RECUPERE LA CARTE COMPOR ==> CHAM_ELEM_S
    call carces(compor, 'ELEM', ' ', 'V', chs(1),&
                'A', ibid)
!
!     VERIFICATION QU'UN COMPORTEMENT MULTI-FIBRES A ETE AFFECTE
!
    call exisd('CARTE', chmate//'.COMPOR', iret)
    if (iret .eq. 0) then
        call utmess('F', 'COMPOR1_73')
    endif
!
    call carces(chmate//'.COMPOR', 'ELEM', ' ', 'V', chsx,&
                'A', ibid)
!     ON ENLEVE LA COMPOSANTE 'DEFORM' DE LA CARTE
    licmp = 'DEFORM'
    call cesred(chsx, 0, [ibid], -1, licmp,&
                'V', chs(2))
!
!     FUSION DES CHAM_ELEM_S + COPIE DANS "COMPOR"
    call detrsd('CARTE', compor)
    call cesfus(2, chs, lcumu, lcoer, lcoec,&
                lcoc(1), 'V', chs3)
    call cescar(chs3, compor, 'V')
!
! - Compress COMPOR <CARTE>   
    call tecart(compor)
!   
!     MENAGE
    call detrsd('CHAM_ELEM_S', chs(1))
    call detrsd('CHAM_ELEM_S', chs(2))
    call detrsd('CHAM_ELEM_S', chs3)
    call detrsd('CHAM_ELEM_S', chsx)
!
    call jedema()
end subroutine
