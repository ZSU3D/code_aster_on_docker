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

subroutine te0165(option, nomte)
!
    implicit none
#include "jeveux.h"
#include "asterfort/fpouli.h"
#include "asterfort/jevech.h"
#include "asterfort/kpouli.h"
#include "asterfort/rcvalb.h"
#include "asterfort/utmess.h"
#include "asterfort/verift.h"
#include "blas/ddot.h"
#include "asterfort/Behaviour_type.h"
!
    character(len=16) :: option, nomte
! ......................................................................
! INTRODUCTION DE LA TEMPERATURE
!
!    - FONCTION REALISEE:  CALCUL MATRICE DE RIGIDITE MEPOULI
!                          OPTION : 'FULL_MECA        '
!                          OPTION : 'RAPH_MECA        '
!                          OPTION : 'RIGI_MECA_TANG   '
!
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! ......................................................................
!
    character(len=16) :: nomres(2)
    integer :: icodre(2)
    real(kind=8) :: a, w(9), nx, l1(3), l2(3), l10(3), l20(3)
    real(kind=8) :: valres(2), e
    real(kind=8) :: norml1, norml2, norl10, norl20, l0, allong
    real(kind=8) :: preten, r8bid, epsthe
    integer :: imatuu, jefint, lsigma
    integer :: icompo, lsect, igeom, imate, idepla, ideplp
    integer :: i, jcret, kc
!
!
!
!***  ESSAI DE PRETENSION
!     PRETEN = 1000.D0
!***  FIN DE L'ESSAI DE PRETENSION
!
!
    call jevech('PCOMPOR', 'L', icompo)
    if (zk16(icompo-1+RELA_NAME)(1:4) .ne. 'ELAS') then
        call utmess('F', 'CALCULEL4_92', sk=zk16(icompo-1+RELA_NAME))
    endif
    if (zk16(icompo-1+DEFO) .ne. 'GROT_GDEP') then
        call utmess('F', 'CALCULEL4_93', sk=zk16(icompo-1+DEFO))
    endif
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
    nomres(1) = 'E'
    r8bid = 0.0d0
    call rcvalb('RIGI', 1, 1, '+', zi(imate),&
                ' ', 'ELAS', 0, '  ', [r8bid],&
                1, nomres, valres, icodre, 1)
    call verift('RIGI', 1, 1, '+', zi(imate),&
                epsth_=epsthe)
    e = valres(1)
    call jevech('PCACABL', 'L', lsect)
    a = zr(lsect)
    preten = zr(lsect+1)
!
    call jevech('PDEPLMR', 'L', idepla)
    call jevech('PDEPLPR', 'L', ideplp)
!
    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:14) .eq. 'RIGI_MECA_TANG') then
        call jevech('PMATUUR', 'E', imatuu)
    endif
    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
        call jevech('PVECTUR', 'E', jefint)
        call jevech('PCONTPR', 'E', lsigma)
    endif
!
!
    do i = 1, 9
        w(i)=zr(idepla-1+i)+zr(ideplp-1+i)
    end do
!
    do kc = 1, 3
        l1(kc) = w(kc ) + zr(igeom-1+kc) - w(6+kc) - zr(igeom+5+kc)
        l10(kc) = zr(igeom-1+kc) - zr(igeom+5+kc)
    end do
    do kc = 1, 3
        l2(kc) = w(3+kc) + zr(igeom+2+kc) - w(6+kc) - zr(igeom+5+kc)
        l20(kc) = zr(igeom+2+kc) - zr(igeom+5+kc)
    end do
    norml1=ddot(3,l1,1,l1,1)
    norml2=ddot(3,l2,1,l2,1)
    norl10=ddot(3,l10,1,l10,1)
    norl20=ddot(3,l20,1,l20,1)
    norml1 = sqrt (norml1)
    norml2 = sqrt (norml2)
    norl10 = sqrt (norl10)
    norl20 = sqrt (norl20)
    l0 = norl10 + norl20
    allong = (norml1 + norml2 - l0) / l0
    nx = e * a * allong
!
    if (abs(nx) .le. 1.d-6) then
        nx = preten
    else
        nx = nx - e * a * epsthe
    endif
!
    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:14) .eq. 'RIGI_MECA_TANG') then
        call kpouli(e, a, nx, l0, l1,&
                    l2, norml1, norml2, zr(imatuu))
    endif
    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
        call fpouli(nx, l1, l2, norml1, norml2,&
                    zr(jefint))
        zr(lsigma) = nx
    endif
!
    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
        call jevech('PCODRET', 'E', jcret)
        zi(jcret) = 0
    endif
!
end subroutine
