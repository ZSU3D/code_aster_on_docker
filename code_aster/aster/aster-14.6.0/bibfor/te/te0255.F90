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

subroutine te0255(option, nomte)
!.......................................................................
    implicit none
!
!     BUT: CALCUL DES VECTEURS ELEMENTAIRES EN MECANIQUE
!          ELEMENTS ISOPARAMETRIQUES 1D
!
!          OPTION : 'CHAR_MECA_VNOR '
!
!     ENTREES  ---> OPTION : OPTION DE CALCUL
!          ---> NOMTE  : NOM DU TYPE ELEMENT
!.......................................................................
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/rcvalb.h"
#include "asterfort/vff2dn.h"
!
    integer :: icodre(1)
    character(len=16) :: nomte, option
    real(kind=8) :: poids, nx, ny
    integer :: ipoids, ivf, idfde, igeom, ivnor
    integer :: nno, kp, npg, ivectu, imate, ldec, kpg, spt
    aster_logical :: laxi
    character(len=8) :: fami, poum
!
!
!-----------------------------------------------------------------------
    integer :: i, ii, jgano, ndim, nnos
    real(kind=8) :: r, rho(1)
!-----------------------------------------------------------------------
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nno, nnos=nnos, npg=npg,&
                     jpoids=ipoids, jvf=ivf, jdfde=idfde, jgano=jgano)
!
    laxi = .false.
    if (lteatt('AXIS','OUI')) laxi = .true.
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PVECTUR', 'E', ivectu)
    call jevech('PMATERC', 'L', imate)
    call jevech('PSOURCR', 'L', ivnor)
    fami='FPG1'
    kpg=1
    spt=1
    poum='+'
    call rcvalb(fami, kpg, spt, poum, zi(imate),&
                ' ', 'FLUIDE', 0, ' ', [0.d0],&
                1, 'RHO', rho, icodre, 1)
!
    do 10 i = 1, 2*nno
        zr(ivectu+i-1) = 0.0d0
 10 end do
!
!     BOUCLE SUR LES POINTS DE GAUSS
!
    do 40 kp = 1, npg
        ldec = (kp-1)*nno
!
        nx = 0.0d0
        ny = 0.0d0
!
        call vff2dn(ndim, nno, kp, ipoids, idfde,&
                    zr(igeom), nx, ny, poids)
        if (laxi) then
            r = 0.d0
            do 20 i = 1, nno
                r = r + zr(igeom+2* (i-1))*zr(ivf+ldec+i-1)
 20         continue
            poids = poids*r
        endif
!
        do 30 i = 1, nno
            ii = 2*i
            zr(ivectu+ii-1) = zr(ivectu+ii-1) - poids*zr(ivnor+kp-1)* rho(1)*zr(ivf+ldec+i-1)
 30     continue
!
 40 end do
!
end subroutine
