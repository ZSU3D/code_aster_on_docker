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

subroutine te0088(option, nomte)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
!
#include "asterfort/elrefe_info.h"
#include "asterfort/jevecd.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/vff2dn.h"
    character(len=16) :: option, nomte
! ......................................................................
!
!     BUT: CALCUL DES VECTEURS ELEMENTAIRES EN MECANIQUE
!          CORRESPONDANT A UN CHARGEMENT EN PRESSION REPARTIE
!          SUR DES FACES D'ELEMENTS ISOPARAMETRIQUES 2D
!
!          OPTION : 'CHAR_MECA_PRES_R'
!
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! ......................................................................
!
    real(kind=8) :: poids, r, tx, ty, nx, ny, pr(9), ci(9)
    integer :: nno, kp, npg, ipoids, ivf, idfde, igeom
    integer :: ipres, ivectu, k, i
    aster_logical :: laxi
!
!
!-----------------------------------------------------------------------
    integer :: jgano, ndim, nnos
    real(kind=8) :: s, t
!-----------------------------------------------------------------------
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nno, nnos=nnos, npg=npg,&
                     jpoids=ipoids, jvf=ivf, jdfde=idfde, jgano=jgano)
!
    laxi = .false.
    if (lteatt('AXIS','OUI')) laxi = .true.
!
    call jevech('PGEOMER', 'L', igeom)
    call jevecd('PPRESSR', ipres, 0.d0)
    call jevech('PVECTUR', 'E', ivectu)
!
!    BOUCLE SUR LES POINTS DE GAUSS
!
    do 40 kp = 1, npg
        k = (kp-1)*nno
!
! CALCUL DE P AU POINT DE GAUSS KP A PARTIR DE P AUX NOEUDS
        s = 0.d0
        t = 0.d0
        do 10 i = 1, nno
            s = s + zr(ipres+2*(i-1) )*zr(ivf+k+i-1)
            t = t + zr(ipres+2*(i-1)+1)*zr(ivf+k+i-1)
 10     continue
        pr(kp) = s
        ci(kp) = t
!
        call vff2dn(ndim, nno, kp, ipoids, idfde,&
                    zr(igeom), nx, ny, poids)
!
        if (laxi) then
            r = 0.d0
            do 20 i = 1, nno
                r = r + zr(igeom+2*(i-1))*zr(ivf+k+i-1)
 20         continue
            poids = poids*r
        endif
!
        tx = -nx*pr(kp) - ny*ci(kp)
        ty = -ny*pr(kp) + nx*ci(kp)
        do 30 i = 1, nno
            zr(ivectu+2*i-2) = zr(ivectu+2*i-2) + tx*zr(ivf+k+i-1)* poids
            zr(ivectu+2*i-1) = zr(ivectu+2*i-1) + ty*zr(ivf+k+i-1)* poids
 30     continue
 40 end do
end subroutine
