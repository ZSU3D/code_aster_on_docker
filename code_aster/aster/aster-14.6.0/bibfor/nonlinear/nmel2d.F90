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

subroutine nmel2d(fami, poum, nno, npg, ipoids,&
                  ivf, idfde, geom, typmod, option,&
                  imate, compor, lgpg, crit, idepl,&
                  angmas, dfdi, pff, def, sig,&
                  vi, matuu, ivectu, codret)
! aslint: disable=W1504
    implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/nmcpel.h"
#include "asterfort/nmgeom.h"
    integer :: nno, npg, imate, lgpg, codret, ipoids, ivf, idfde
    integer :: ivectu, idepl
    character(len=8) :: typmod(*)
    character(len=16) :: option, compor(*)
    character(len=*) :: fami, poum
    real(kind=8) :: geom(2, nno), crit(3)
    real(kind=8) :: angmas(3)
    real(kind=8) :: dfdi(nno, 2)
    real(kind=8) :: pff(4, nno, nno), def(4, nno, 2)
    real(kind=8) :: sig(4, npg), vi(lgpg, npg)
    real(kind=8) :: matuu(*)
!.......................................................................
!
!     BUT:  CALCUL  DES OPTIONS RIGI_MECA_TANG, RAPH_MECA ET FULL_MECA
!           EN HYPER-ELASTICITE
!.......................................................................
! IN  NNO     : NOMBRE DE NOEUDS DE L'ELEMENT
! IN  NPG     : NOMBRE DE POINTS DE GAUSS
! IN  POIDSG  : POIDS DES POINTS DE GAUSS
! IN  VFF     : VALEUR  DES FONCTIONS DE FORME
! IN  DFDE    : DERIVEE DES FONCTIONS DE FORME ELEMENT DE REFERENCE
! IN  DFDK    : DERIVEE DES FONCTIONS DE FORME ELEMENT DE REFERENCE
! IN  GEOM    : COORDONEES DES NOEUDS
! IN  TYPMOD  : TYPE DE MODELISATION
! IN  OPTION  : OPTION DE CALCUL
! IN  IMATE   : MATERIAU CODE
! IN  COMPOR  : COMPORTEMENT
! IN  LGPG  : "LONGUEUR" DES VARIABLES INTERNES POUR 1 POINT DE GAUSS
!              CETTE LONGUEUR EST UN MAJORANT DU NBRE REEL DE VAR. INT.
! IN  CRIT    : CRITERES DE CONVERGENCE LOCAUX
! IN  DEPL    : DEPLACEMENT A PARTIR DE LA CONF DE REF
! OUT DFDI    : DERIVEE DES FONCTIONS DE FORME  AU DERNIER PT DE GAUSS
! OUT PFF     : PRODUIT DES FCT. DE FORME       AU DERNIER PT DE GAUSS
! OUT DEF     : PRODUIT DER. FCT. FORME PAR F   AU DERNIER PT DE GAUSS
! OUT SIG     : CONTRAINTES DE CAUCHY (RAPH_MECA ET FULL_MECA)
! OUT VI      : VARIABLES INTERNES    (RAPH_MECA ET FULL_MECA)
! OUT MATUU   : MATRICE DE RIGIDITE PROFIL (RIGI_MECA_TANG ET FULL_MECA)
! OUT VECTU   : FORCES NODALES (RAPH_MECA ET FULL_MECA)
!......................................................................
!
!
    integer :: kpg, kk, n, i, m, j, j1, kl, pq, kkd
    aster_logical :: grdepl, axi, cplan
    real(kind=8) :: dsidep(6, 6), f(3, 3), eps(6), r, sigma(6), ftf, detf
    real(kind=8) :: poids, tmp1, tmp2, sigp(6)
!
    integer :: indi(4), indj(4)
    real(kind=8) :: rind(4), rac2
    data    indi / 1 , 2 , 3 , 1 /
    data    indj / 1 , 2 , 3 , 2 /
    data    rind / 0.5d0 , 0.5d0 , 0.5d0 , 0.70710678118655d0 /
    data    rac2 / 1.4142135623731d0 /
!
!
!
!
! - INITIALISATION
!
    grdepl = compor(3).eq. 'GROT_GDEP'
    axi = typmod(1) .eq. 'AXIS'
    cplan = typmod(1) .eq. 'C_PLAN'
!
! - CALCUL POUR CHAQUE POINT DE GAUSS
!
    do 10 kpg = 1, npg
!
! - CALCUL DE LA TEMPERATURE AU POINT DE GAUSS
! -
!
! - CALCUL DES ELEMENTS GEOMETRIQUES
!
!      CALCUL DE DFDI, F, EPS, R (EN AXI) ET POIDS
        call nmgeom(2, nno, axi, grdepl, geom,&
                    kpg, ipoids, ivf, idfde, zr(idepl),&
                    .true._1, poids, dfdi, f, eps,&
                    r)
!
!      CALCUL DES PRODUITS SYMETR. DE F PAR N,
        do 120 n = 1, nno
            do 122 i = 1, 2
                def(1,n,i) = f(i,1)*dfdi(n,1)
                def(2,n,i) = f(i,2)*dfdi(n,2)
                def(3,n,i) = 0.d0
                def(4,n,i) = (f(i,1)*dfdi(n,2) + f(i,2)*dfdi(n,1))/ rac2
122         continue
120     continue
!
!      TERME DE CORRECTION (3,3) AXI QUI PORTE EN FAIT SUR LE DDL 1
        if (axi) then
            do 124 n = 1, nno
                def(3,n,1) = f(3,3)*zr(ivf+n+(kpg-1)*nno-1)/r
124         continue
        endif
!
!      CALCUL DES PRODUITS DE FONCTIONS DE FORMES (ET DERIVEES)
        if (( option(1:10) .eq. 'RIGI_MECA_' .or. option(1: 9) .eq. 'FULL_MECA' ) .and.&
            grdepl) then
            do 125 n = 1, nno
                do 126 m = 1, n
                    pff(1,n,m) = dfdi(n,1)*dfdi(m,1)
                    pff(2,n,m) = dfdi(n,2)*dfdi(m,2)
                    pff(3,n,m) = 0.d0
                    pff(4,n,m) =(dfdi(n,1)*dfdi(m,2)+dfdi(n,2)*dfdi(m,&
                    1))/rac2
126             continue
125         continue
        endif
!
!
! - LOI DE COMPORTEMENT : S(E) ET DS/DE
!
        call nmcpel(fami, kpg, 1, poum, 2,&
                    typmod, angmas, imate, compor, crit,&
                    option, eps, sigma, vi(1, kpg), dsidep,&
                    codret)
!
!
! - CALCUL DE LA MATRICE DE RIGIDITE
!
        if (option(1:10) .eq. 'RIGI_MECA_' .or. option(1: 9) .eq. 'FULL_MECA') then
!
            do 130 n = 1, nno
                do 131 i = 1, 2
                    kkd = (2*(n-1)+i-1) * (2*(n-1)+i) /2
                    do 151 kl = 1, 4
                        sigp(kl)=0.d0
                        sigp(kl)=sigp(kl)+def(1,n,i)*dsidep(1,kl)
                        sigp(kl)=sigp(kl)+def(2,n,i)*dsidep(2,kl)
                        sigp(kl)=sigp(kl)+def(3,n,i)*dsidep(3,kl)
                        sigp(kl)=sigp(kl)+def(4,n,i)*dsidep(4,kl)
151                 continue
                    do 140 j = 1, 2
                        do 141 m = 1, n
                            if (m .eq. n) then
                                j1 = i
                            else
                                j1 = 2
                            endif
!
!                 RIGIDITE GEOMETRIQUE
                            tmp1 = 0.d0
                            if (grdepl .and. i .eq. j) then
                                tmp1 = pff(1,n,m)*sigma(1) + pff(2,n, m)*sigma(2) + pff(3,n,m)*si&
                                       &gma(3) + pff(4,n,m)*sigma(4)
!
!                  TERME DE CORRECTION AXISYMETRIQUE
                                if (axi .and. i .eq. 1) then
                                    tmp1=tmp1+zr(ivf+n+(kpg-1)*nno-1)*&
                                    zr(ivf+m+(kpg-1)*nno-1)/(r*r)*&
                                    sigma(3)
                                endif
                            endif
!
!                RIGIDITE ELASTIQUE
                            tmp2 = sigp(1)*def(1,m,j) + sigp(2)*def(2, m,j) + sigp(3)*def(3,m,j) &
                                   &+ sigp(4)*def(4, m,j)
!
!                STOCKAGE EN TENANT COMPTE DE LA SYMETRIE
                            if (j .le. j1) then
                                kk = kkd + 2*(m-1)+j
                                matuu(kk) = matuu(kk) + (tmp1+tmp2)* poids
                            endif
!
141                     continue
140                 continue
131             continue
130         continue
        endif
!
! - CALCUL DE LA FORCE INTERIEURE ET DES CONTRAINTES DE CAUCHY
!
        if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
!
            do 185 n = 1, nno
                do 186 i = 1, 2
                    do 187 kl = 1, 4
                        zr(ivectu-1+2*(n-1)+i)= zr(ivectu-1+2*(n-1)+i)&
                        +def(kl,n,i)*sigma(kl)*poids
187                 continue
186             continue
185         continue
!
!
            if (grdepl) then
!          CONVERSION LAGRANGE -> CAUCHY
                if (cplan) f(3,3) = sqrt(abs(2.d0*eps(3)+1.d0))
                detf = f(3,3)*(f(1,1)*f(2,2)-f(1,2)*f(2,1))
                do 190 pq = 1, 4
                    sig(pq,kpg) = 0.d0
                    do 200 kl = 1, 4
                        ftf = (&
                              f(&
                              indi(pq), indi(kl))*f(indj(pq), indj( kl)) + f(indi(pq),&
                              indj(kl))*f(indj(pq), indi( kl))&
                              )*rind(kl&
                              )
                        sig(pq,kpg) = sig(pq,kpg)+ ftf*sigma(kl)
200                 continue
                    sig(pq,kpg) = sig(pq,kpg)/detf
190             continue
            else
                do 210 kl = 1, 3
                    sig(kl,kpg) = sigma(kl)
210             continue
                sig(4,kpg) = sigma(4)/rac2
            endif
        endif
 10 end do
end subroutine
