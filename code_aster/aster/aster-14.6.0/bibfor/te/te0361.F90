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

subroutine te0361(option, nomte)
!
! person_in_charge: jerome.laverne at edf.fr
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/eiangl.h"
#include "asterfort/eifono.h"
#include "asterfort/eifore.h"
#include "asterfort/eiinit.h"
#include "asterfort/elref2.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/terefe.h"
#include "asterfort/utmess.h"
    character(len=16) :: option, nomte
! ......................................................................
!    - FONCTION REALISEE:  FORC_NODA ET REFE_FORC_NODA
!                          POUR ELEMENTS D'INTERFACE
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! ......................................................................
!
    character(len=8) :: lielrf(10)
    aster_logical :: axi
    integer :: nno1, nno2, npg, ivf2, idf2, nnos, jgn
    integer :: iw, ivf1, idf1, igeom, icontm, ivectu, ndim, ntrou, icamas
    integer :: iu(3, 18), im(3, 9), it(18)
    real(kind=8) :: ang(24), sigref, depref
!
!
    call elref2(nomte, 2, lielrf, ntrou)
    call elrefe_info(elrefe=lielrf(1), fami='RIGI', ndim=ndim, nno=nno1, nnos=nnos,&
                     npg=npg, jpoids=iw, jvf=ivf1, jdfde=idf1, jgano=jgn)
    call elrefe_info(elrefe=lielrf(2), fami='RIGI', ndim=ndim, nno=nno2, nnos=nnos,&
                     npg=npg, jpoids=iw, jvf=ivf2, jdfde=idf2, jgano=jgn)
    ndim = ndim + 1
    axi = lteatt('AXIS','OUI')
!
! - DECALAGE D'INDICE POUR LES ELEMENTS D'INTERFACE
    call eiinit(nomte, iu, im, it)
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PVECTUR', 'E', ivectu)
!
! --- ORIENTATION DE L'ELEMENT D'INTERFACE : REPERE LOCAL
!     RECUPERATION DES ANGLES NAUTIQUES DEFINIS PAR AFFE_CARA_ELEM
!
    call jevech('PCAMASS', 'L', icamas)
    if (zr(icamas) .eq. -1.d0) then
        call utmess('F', 'ELEMENTS5_47')
    endif
!
!     DEFINITION DES ANGLES NAUTIQUES AUX NOEUDS SOMMETS : ANG
!
    call eiangl(ndim, nno2, zr(icamas+1), ang)
!
!      OPTIONS FORC_NODA ET REFE_FORC_NODA
!
    if (option .eq. 'FORC_NODA') then
!
        call jevech('PCONTMR', 'L', icontm)
        call eifono(ndim, axi, nno1, nno2, npg,&
                    zr(iw), zr(ivf1), zr(ivf2), zr(idf2), zr(igeom),&
                    ang, iu, im, zr(icontm), zr(ivectu))
!
    else
!
!
        call terefe('SIGM_REFE', 'MECA_INTERFACE', sigref)
        call terefe('DEPL_REFE', 'MECA_INTERFACE', depref)
!
        call eifore(ndim, axi, nno1, nno2, npg,&
                    zr(iw), zr(ivf1), zr(ivf2), zr(idf2), zr(igeom),&
                    ang, iu, im, sigref, depref,&
                    zr(ivectu))
!
    endif
!
end subroutine
