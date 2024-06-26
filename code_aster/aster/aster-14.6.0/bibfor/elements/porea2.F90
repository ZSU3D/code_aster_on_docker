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

subroutine porea2(nno, nc, geom, gamma, pgl,&
                  xl)
    implicit none
#include "jeveux.h"
#include "asterfort/angvx.h"
#include "asterfort/assert.h"
#include "asterfort/matrot.h"
#include "asterfort/tecach.h"
#include "asterfort/vdiff.h"
#include "blas/ddot.h"
!
    integer :: nno, nc
    real(kind=8) :: geom(3, nno), gamma
!
    real(kind=8) :: pgl(3, 3), xl
!
!
!     ------------------------------------------------------------------
!     CALCUL DE LA MATRICE DE PASSAGE GLOBALE/LOCALE EN TENANT COMPTE
!     DE LA GEOMETRIE REACTUALISEE AINSI QUE LA LONGUEUR DE LA POUTRE
!     POUR L'OPTION FORC_NODA
!     ------------------------------------------------------------------
! IN  NNO    : NOMBRE DE NOEUDS
! IN  NC     : NOMBRE DE COMPOSANTE DU CHAMP DE DEPLACEMENTS
! IN  GEOM   : COORDONNEES DES NOEUDS
! IN  GAMMA  : ANGLE DE VRILLE AU TEMPS -
! OUT PGL    : MATRICE DE PASSAGE GLOBAL/LOCAL
!     ------------------------------------------------------------------
!
!     VARIABLES LOCALES
    integer :: i, ideplm, ideplp, iret
    real(kind=8) :: utg(14), xug(6), xd(3), xl2, alfa1, beta1
    real(kind=8) :: tet1, tet2, gamma1, ang1(3)
!
    ASSERT(nno.eq.2)
!
    call tecach('ONO', 'PDEPLMR', 'L', iret, iad=ideplm)
    if (iret .ne. 0) then
        do 100 i = 1, 2*nc
            utg(i) = 0.d0
100      continue
    else
        do 102 i = 1, 2*nc
            utg(i) = zr(ideplm-1+i)
102      continue
    endif
!
    call tecach('ONO', 'PDEPLPR', 'L', iret, iad=ideplp)
    if (iret .eq. 0) then
        do 104 i = 1, 2*nc
            utg(i) = utg(i) + zr(ideplp-1+i)
104      continue
    endif
!
    do 110 i = 1, 3
        xug(i) = utg(i) + geom(i,1)
        xug(i+3) = utg(i+nc) + geom(i,2)
110  end do
!
    call vdiff(3, xug(4), xug(1), xd)
    xl2=ddot(3,xd,1,xd,1)
    xl = sqrt(xl2)
    tet1=ddot(3,utg(4),1,xd,1)
    tet2=ddot(3,utg(nc+4),1,xd,1)
    tet1 = tet1/xl
    tet2 = tet2/xl
    call angvx(xd, alfa1, beta1)
!
    gamma1 = gamma + (tet1+tet2)/2.d0
    ang1(1) = alfa1
    ang1(2) = beta1
    ang1(3) = gamma1
!
    call matrot(ang1, pgl)
end subroutine
