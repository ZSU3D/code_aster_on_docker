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

subroutine te0569(option, nomte)
    implicit none
#include "jeveux.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/rcvalb.h"
!
    character(len=16) :: option, nomte
!
    integer :: ipoids, ivf, idfdx, idfdy, igeom, i, j
    integer :: ndim, nno, ipg, npg1, ino, jno, ij, kpg, spt
    integer :: idec, jdec, kdec, ldec, imate, imatuu
    integer :: mater, ll, k, l, nnos, jgano
    integer :: ideplm, ideplp, ivectu
    real(kind=8) :: jac, nx, ny, nz, sx(9, 9), sy(9, 9), sz(9, 9)
    real(kind=8) :: valres(5), e, nu, lambda, mu, rho, coef_amor
    real(kind=8) :: rhocp, rhocs, l0, usl0
    real(kind=8) :: taux, tauy, tauz
    real(kind=8) :: nux, nuy, nuz, scal, vnx, vny, vnz
    real(kind=8) :: vituni(3, 3), vect(9, 3, 27)
    real(kind=8) :: matr(27, 27), depla(27)
    real(kind=8) :: vtx, vty, vtz
    integer :: icodre(5), ndim2
    character(len=8) :: fami, poum
    character(len=16) :: nomres(5)
    character(len=8) :: nompar(3)
    real(kind=8) :: valpar(3)
!     ------------------------------------------------------------------
!
    call elrefe_info(fami='RIGI',ndim=ndim,nno=nno,nnos=nnos,&
  npg=npg1,jpoids=ipoids,jvf=ivf,jdfde=idfdx,jgano=jgano)
    idfdy = idfdx + 1
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
!
    mater=zi(imate)
    nomres(1)='E'
    nomres(2)='NU'
    nomres(3) = 'RHO'
    nomres(4) = 'COEF_AMOR'
    nomres(5) = 'LONG_CARA'
    fami='FPG1'
    kpg=1
    spt=1
    poum='+'
!
    nompar(1) = 'X'
    nompar(2) = 'Y'
    nompar(3) = 'Z'
    ndim2 = 3
!   coordonnées du barycentre de l'élément
    valpar(:) = 0.d0
    do i = 1, nnos
        do j = 1, ndim2
            valpar(j) = valpar(j) + zr(igeom-1+(i-1)*ndim2+j)/nnos
        enddo
    enddo
!
    call rcvalb(fami, kpg, spt, poum, mater,&
                ' ', 'ELAS', 3, nompar, valpar,&
                4, nomres, valres, icodre, 1)
!   appel LONG_CARA en iarret = 0
    call rcvalb(fami, kpg, spt, poum, mater,&
                ' ', 'ELAS', 3, nompar, valpar,&
                1, nomres(5), valres(5), icodre(5), 0)
!
    e = valres(1)
    nu = valres(2)
    rho = valres(3)
    coef_amor = valres(4)
!
    usl0 = 0.d0    
    if (icodre(5) .eq. 0) then
      l0 = valres(5)
      usl0=1.d0/l0
    endif
!
    lambda = e*nu/ (1.d0+nu)/ (1.d0-2.d0*nu)
    mu = e/2.d0/ (1.d0+nu)
!
    if (option .eq. 'AMOR_MECA') then
      rhocp = coef_amor*sqrt((lambda+2.d0*mu)*rho)
      rhocs = coef_amor*sqrt(mu*rho)
    else
      rhocp = (lambda+2.d0*mu)*usl0
      rhocs = mu*usl0
    endif
!
!
!     VITESSE UNITAIRE DANS LES 3 DIRECTIONS
!
    vituni(1,1) = 1.d0
    vituni(1,2) = 0.d0
    vituni(1,3) = 0.d0
!
    vituni(2,1) = 0.d0
    vituni(2,2) = 1.d0
    vituni(2,3) = 0.d0
!
    vituni(3,1) = 0.d0
    vituni(3,2) = 0.d0
    vituni(3,3) = 1.d0
!
    do 310 i = 1, nno
        do 311 j = 1, 3
            do 312 k = 1, 3*nno
                vect(i,j,k) = 0.d0
312         continue
311     continue
310 continue
!
!     --- CALCUL DES PRODUITS VECTORIELS OMI X OMJ ---
!
    do 30 ino = 1, nno
        i = igeom + 3*(ino-1) -1
        do 31 jno = 1, nno
            j = igeom + 3*(jno-1) -1
            sx(ino,jno) = zr(i+2)*zr(j+3) - zr(i+3)*zr(j+2)
            sy(ino,jno) = zr(i+3)*zr(j+1) - zr(i+1)*zr(j+3)
            sz(ino,jno) = zr(i+1)*zr(j+2) - zr(i+2)*zr(j+1)
31      continue
30  continue
!
!     --- BOUCLE SUR LES POINTS DE GAUSS ---
!
    do 100 ipg = 1, npg1
        kdec = (ipg-1)*nno*ndim
        ldec = (ipg-1)*nno
!
        nx = 0.0d0
        ny = 0.0d0
        nz = 0.0d0
!
!        --- CALCUL DE LA NORMALE AU POINT DE GAUSS IPG ---
!
        do 101 i = 1, nno
            idec = (i-1)*ndim
            do 102 j = 1, nno
                jdec = (j-1)*ndim
                nx = nx + zr(idfdx+kdec+idec) * zr(idfdy+kdec+jdec) * sx(i,j)
                ny = ny + zr(idfdx+kdec+idec) * zr(idfdy+kdec+jdec) * sy(i,j)
                nz = nz + zr(idfdx+kdec+idec) * zr(idfdy+kdec+jdec) * sz(i,j)
102         continue
101     continue
!
!        --- LE JACOBIEN EST EGAL A LA NORME DE LA NORMALE ---
!
        jac = sqrt(nx*nx + ny*ny + nz*nz)
!
!        --- CALCUL DE LA NORMALE UNITAIRE ---
!
        nux = nx / jac
        nuy = ny / jac
        nuz = nz / jac
!
!        --- CALCUL DE V.N ---
!
        do 103 i = 1, nno
            do 104 j = 1, 3
                scal = nux*zr(ivf+ldec+i-1)*vituni(j,1)
                scal = scal+nuy*zr(ivf+ldec+i-1)*vituni(j,2)
                scal = scal+nuz*zr(ivf+ldec+i-1)*vituni(j,3)
!
!        --- CALCUL DE LA VITESSE NORMALE ET DE LA VITESSE TANGENCIELLE
!
                vnx = nux*scal
                vny = nuy*scal
                vnz = nuz*scal
!
                vtx = zr(ivf+ldec+i-1)*vituni(j,1)
                vty = zr(ivf+ldec+i-1)*vituni(j,2)
                vtz = zr(ivf+ldec+i-1)*vituni(j,3)
!
                vtx = vtx - vnx
                vty = vty - vny
                vtz = vtz - vnz
!
!        --- CALCUL DU VECTEUR CONTRAINTE
!
                taux = rhocp*vnx + rhocs*vtx
                tauy = rhocp*vny + rhocs*vty
                tauz = rhocp*vnz + rhocs*vtz
!
!        --- CALCUL DU VECTEUR ELEMENTAIRE
!
                do 105 l = 1, nno
                    ll = 3*l-2
                    vect(i,j,ll) = vect(i,j,ll) + taux*zr(ivf+ldec+l- 1)*jac*zr(ipoids+ipg-1)
                    vect(i,j,ll+1) = vect(i,j,ll+1) + tauy*zr(ivf+ ldec+l-1)*jac*zr(ipoids+ipg-1)
                    vect(i,j,ll+2) = vect(i,j,ll+2) + tauz*zr(ivf+ ldec+l-1)*jac*zr(ipoids+ipg-1)
105             continue
104         continue
103     continue
100 continue
!
    do 400 i = 1, nno
        do 401 j = 1, 3
            do 402 k = 1, 3*nno
                matr(3*(i-1)+j,k) = vect(i,j,k)
402         continue
401     continue
400 continue
!
!       --- PASSAGE AU STOCKAGE TRIANGULAIRE
!

    if (option .ne. 'FORC_NODA' .and. option .ne. 'RAPH_MECA') then
      call jevech('PMATUUR', 'E', imatuu)
      do 210 i = 1, 3*nno
        do 211 j = 1, i
            ij = (i-1)*i/2+j
            zr(imatuu+ij-1) = matr(i,j)
211     continue
210   continue
    endif
    if (option(1:9) .ne. 'RIGI_MECA' .and. option .ne. 'AMOR_MECA') then
      call jevech('PVECTUR', 'E', ivectu)
      call jevech('PDEPLMR', 'L', ideplm)
      call jevech('PDEPLPR', 'L', ideplp)
      do 212 i = 1, 3*nno
         depla(i) = zr(ideplm+i-1) + zr(ideplp+i-1)
         zr(ivectu+i-1) = 0.d0
212   continue
      do 213 i = 1, 3*nno
        do 214 j = 1, 3*nno
            zr(ivectu+i-1) = zr(ivectu+i-1) + matr(i,j)*depla(j)
214     continue
213   continue
    endif
!
end subroutine
