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

subroutine te0174(option, nomte)
!.......................................................................
    implicit none
!
!     BUT: CALCUL DES VECTEURS ELEMENTAIRES EN MECANIQUE
!          ELEMENTS ISOPARAMETRIQUES 3D
!
!          OPTION : 'CHAR_MECA_VNOR_F'
!
!     ENTREES  ---> OPTION : OPTION DE CALCUL
!          ---> NOMTE  : NOM DU TYPE ELEMENT
!.......................................................................
!
#include "jeveux.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/fointe.h"
#include "asterfort/jevech.h"
#include "asterfort/rcvalb.h"
#include "asterfort/tecach.h"
!
    integer :: icodre(1), kpg, spt
    character(len=8) :: nompar(4), fami, poum
    character(len=16) :: nomte, option
    real(kind=8) :: jac, nx, ny, nz, sx(9, 9), sy(9, 9), sz(9, 9)
    real(kind=8) :: vnorf, valpar(4)
    integer :: ipoids, ivf, idfdx, idfdy, igeom
    integer :: ndim, nno, ipg, npg1, ivectu, imate
    integer :: idec, jdec, kdec, ldec, nnos, jgano
!
!-----------------------------------------------------------------------
    integer :: i, ier, ii, ino, iret, itemps, ivnor
    integer :: j, jno, mater, n, nbpar
    real(kind=8) :: r8b, rho(1), x, y, z
!-----------------------------------------------------------------------
    call elrefe_info(fami='RIGI',ndim=ndim,nno=nno,nnos=nnos,&
  npg=npg1,jpoids=ipoids,jvf=ivf,jdfde=idfdx,jgano=jgano)
    idfdy = idfdx + 1
    fami='FPG1'
    kpg=1
    spt=1
    poum='+'
    r8b=0.d0
!
    call jevech('PGEOMER', 'L', igeom)
!
    call jevech('PMATERC', 'L', imate)
    mater = zi(imate)
    call rcvalb(fami, kpg, spt, poum, mater,&
                ' ', 'FLUIDE', 0, ' ', [r8b],&
                1, 'RHO', rho, icodre, 1)
!
    call jevech('PVECTUR', 'E', ivectu)
    call jevech('PSOURCF', 'L', ivnor)
!
    do i = 1, 2*nno
        zr(ivectu+i-1) = 0.0d0
    end do
!
!    CALCUL DES PRODUITS VECTORIELS OMI X OMJ
!
    do ino = 1, nno
        i = igeom + 3*(ino-1) -1
        do jno = 1, nno
            j = igeom + 3*(jno-1) -1
            sx(ino,jno) = zr(i+2) * zr(j+3) - zr(i+3) * zr(j+2)
            sy(ino,jno) = zr(i+3) * zr(j+1) - zr(i+1) * zr(j+3)
            sz(ino,jno) = zr(i+1) * zr(j+2) - zr(i+2) * zr(j+1)
        end do
    end do
!
    nompar(1) = 'X'
    nompar(2) = 'Y'
    nompar(3) = 'Z'
    nompar(4) = 'INST'
!
    call tecach('NNO', 'PTEMPSR', 'L', iret, iad=itemps)
    if (itemps .ne. 0) then
        valpar(4) = zr(itemps)
        nbpar = 4
    else
        nbpar = 3
    endif
!
!    BOUCLE SUR LES POINTS DE GAUSS
!
    do ipg = 1, npg1
        kdec=(ipg-1)*nno*ndim
        ldec=(ipg-1)*nno
!
!        COORDONNEES DU POINT DE GAUSS
        x = 0.d0
        y = 0.d0
        z = 0.d0
        do n = 0, nno-1
            x = x + zr(igeom+3*n ) * zr(ivf+ldec+n)
            y = y + zr(igeom+3*n+1) * zr(ivf+ldec+n)
            z = z + zr(igeom+3*n+2) * zr(ivf+ldec+n)
        end do
!
!        VALEUR DE LA VITESSE
        valpar(1) = x
        valpar(2) = y
        valpar(3) = z
        call fointe('FM', zk8(ivnor), nbpar, nompar, valpar,&
                    vnorf, ier)
!
        nx = 0.0d0
        ny = 0.0d0
        nz = 0.0d0
!
!   CALCUL DE LA NORMALE AU POINT DE GAUSS IPG
!
        do i = 1, nno
            idec = (i-1)*ndim
            do j = 1, nno
                jdec = (j-1)*ndim
!
                nx = nx + zr(idfdx+kdec+idec) * zr(idfdy+kdec+jdec) * sx(i,j)
                ny = ny + zr(idfdx+kdec+idec) * zr(idfdy+kdec+jdec) * sy(i,j)
                nz = nz + zr(idfdx+kdec+idec) * zr(idfdy+kdec+jdec) * sz(i,j)
!
            enddo
        enddo
!
!   CALCUL DU JACOBIEN AU POINT DE GAUSS IPG
!
        jac = sqrt (nx*nx + ny*ny + nz*nz)
!
        do i = 1, nno
            ii = 2*i
            zr(ivectu+ii-1) = zr(ivectu+ii-1)-jac*zr(ipoids+ipg-1) * vnorf * rho(1) * zr(ivf+ldec&
                              &+i-1)
        end do
    end do
!
end subroutine
