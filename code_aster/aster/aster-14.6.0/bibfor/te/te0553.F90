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

subroutine te0553(option, nomte)
    implicit none
#include "jeveux.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/rcvalb.h"
#include "asterfort/vff2dn.h"
!
    character(len=16) :: option, nomte
! ......................................................................
!
!     BUT: CALCUL DES MATRICES ELEMENTAIRES EN MECANIQUE
!          CORRESPONDANT A UN AMORTISSEMENT
!          SUR DES FACES D'ELEMENTS ISOPARAMETRIQUES 2D
!
!          OPTION : 'AMOR_MECA'
!
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! ......................................................................
!
    character(len=16) :: nomres(5)
    character(len=8) ::  fami, poum
    integer :: icodre(5), kpg, spt
    real(kind=8) :: poids, nx, ny, valres(5), e, nu, lambda, mu
    real(kind=8) :: rhocp, rhocs, l0, usl0, depla(6), coef_amor
    real(kind=8) :: rho, taux, tauy, nux, nuy, scal, vnx, vny, vtx, vty
    real(kind=8) :: vituni(2, 2), vect(3, 2, 6), matr(6, 6), jac
    integer :: nno, kp, npg, ipoids, ivf, idfde, igeom
    integer :: k, i, l, mater, ndim2
    character(len=8) :: nompar(2)
    real(kind=8) :: valpar(2)
!
!-----------------------------------------------------------------------
    integer :: ij, imate, imatuu, j, jgano, ll, ndim
    integer :: ideplm, ideplp, ivectu
    integer :: nnos
!-----------------------------------------------------------------------
    call elrefe_info(fami='RIGI',ndim=ndim,nno=nno,nnos=nnos,&
  npg=npg,jpoids=ipoids,jvf=ivf,jdfde=idfde,jgano=jgano)
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
!
!      WRITE(6,*) 'MARC KHAM ---> TE0553  OPTION=',OPTION
!
    mater = zi(imate)
    nomres(1) = 'E'
    nomres(2) = 'NU'
    nomres(3) = 'RHO'
    nomres(4) = 'COEF_AMOR'
    nomres(5) = 'LONG_CARA'
    fami='FPG1'
    kpg=1
    spt=1
    poum='+'
    ndim2 = 2
!
    nompar(1) = 'X'
    nompar(2) = 'Y'
!   coordonnées du barycentre de l'élément
    valpar(:) = 0.d0
    do i = 1, nnos
        do j = 1, ndim2
            valpar(j) = valpar(j) + zr(igeom-1+(i-1)*ndim2+j)/nnos
        enddo
    enddo
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
!     VITESSE UNITAIRE DANS LES 3 DIRECTIONS
!
    vituni(1,1) = 1.d0
    vituni(1,2) = 0.d0
    vituni(2,1) = 0.d0
    vituni(2,2) = 1.d0
    do 10 i = 1, nno
        do 11 j = 1, 2
            do 12 k = 1, 2*nno
                vect(i,j,k) = 0.d0
12          continue
11      continue
10  continue
!
!    BOUCLE SUR LES POINTS DE GAUSS
!
    do 40 kp = 1, npg
        k = (kp-1)*nno
        call vff2dn(ndim, nno, kp, ipoids, idfde,&
                    zr(igeom), nx, ny, poids)
        jac = sqrt(nx*nx+ny*ny)
!
!        --- CALCUL DE LA NORMALE UNITAIRE ---
!
        nux = nx/jac
        nuy = ny/jac
!
!        --- CALCUL DE V.N ---
!
        scal = 0.d0
        do 41 i = 1, nno
            do 42 j = 1, 2
                scal = nux*zr(ivf+k+i-1)*vituni(j,1)
                scal = scal + nuy*zr(ivf+k+i-1)*vituni(j,2)
!
!        --- CALCUL DE LA VITESSE NORMALE ET DE LA VITESSE TANGENCIELLE
!
                vnx = nux*scal
                vny = nuy*scal
                vtx = zr(ivf+k+i-1)*vituni(j,1)
                vty = zr(ivf+k+i-1)*vituni(j,2)
                vtx = vtx - vnx
                vty = vty - vny
!
!        --- CALCUL DU VECTEUR CONTRAINTE
!
                taux = rhocp*vnx + rhocs*vtx
                tauy = rhocp*vny + rhocs*vty
!
!        --- CALCUL DU VECTEUR ELEMENTAIRE
!
                do 43 l = 1, nno
                    ll = 2*l - 1
                    vect(i,j,ll) = vect(i,j,ll) + taux*zr(ivf+k+l-1)* poids
                    vect(i,j,ll+1)=vect(i,j,ll+1)+tauy*zr(ivf+k+l-1)*&
                    poids
43              continue
42          continue
41      continue
40  continue
!
    do 80 i = 1, nno
        do 81 j = 1, 2
            do 82 k = 1, 2*nno
                matr(2* (i-1)+j,k) = vect(i,j,k)
82          continue
81      continue
80  continue
!
!       --- PASSAGE AU STOCKAGE TRIANGULAIRE
!
    if (option .ne. 'FORC_NODA' .and. option .ne. 'RAPH_MECA') then
      call jevech('PMATUUR', 'E', imatuu)
      do 100 i = 1, 2*nno
        do 101 j = 1, i
            ij = (i-1)*i/2 + j
            zr(imatuu+ij-1) = matr(i,j)
101     continue
100   continue
    endif
    if (option(1:9) .ne. 'RIGI_MECA' .and. option .ne. 'AMOR_MECA') then
      call jevech('PVECTUR', 'E', ivectu)
      call jevech('PDEPLMR', 'L', ideplm)
      call jevech('PDEPLPR', 'L', ideplp)
      do 102 i = 1, 2*nno
         depla(i) = zr(ideplm+i-1) + zr(ideplp+i-1)
         zr(ivectu+i-1) = 0.d0
102   continue
      do 103 i = 1, 2*nno
        do 104 j = 1, 2*nno
            zr(ivectu+i-1) = zr(ivectu+i-1) + matr(i,j)*depla(j)
104     continue
103   continue
    endif
!
end subroutine
