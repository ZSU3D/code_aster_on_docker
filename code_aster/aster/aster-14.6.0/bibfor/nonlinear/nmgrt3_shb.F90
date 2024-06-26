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

subroutine nmgrt3_shb(nno, poids, def, pff, option,&
                  dsidep, sign, sigma, matsym,&
                  matuu)
    implicit none
#include "asterf_types.h"
!
    integer :: nno, kk, kkd, n, i, m, j, j1, kl, nmax
    character(len=16) :: option
    real(kind=8) :: pff(6, nno, nno), def(6, nno, 3), dsidep(6, 6), poids
    real(kind=8) :: sigma(6), sign(6), matuu(*)
    real(kind=8) :: tmp1, tmp2, sigg(6), sig(6)
    aster_logical :: matsym
!
!.......................................................................
!     BUT:  CALCUL DE LA MATRICE TANGENTE EN CONFIGURATION LAGRANGIENNE
!           OPTIONS RIGI_MECA_TANG ET FULL_MECA
!.......................................................................
! IN  NNO     : NOMBRE DE NOEUDS DE L'ELEMENT
! IN  POIDS   : POIDS DES POINTS DE GAUSS
! IN  KPG     : NUMERO DU POINT DE GAUSS
! IN  VFF     : VALEUR  DES FONCTIONS DE FORME
! IN  DEF     : PRODUIT DE F PAR LA DERIVEE DES FONCTIONS DE FORME
! IN  PFF     : PRODUIT DES FONCTIONS DE FORME
! IN  OPTION  : OPTION DE CALCUL
! IN  AXI     : .TRUE. SI AXIS
! IN  R       : RAYON DU POINT DE GAUSS COURANT (EN AXI)
! IN  DSIDEP  : OPERATEUR TANGENT ISSU DU COMPORTEMENT
! IN  SIGN    : CONTRAINTES PK2 A L'INSTANT PRECEDENT (AVEC RAC2)
! IN  SIGMA   : CONTRAINTES PK2 A L'INSTANT ACTUEL    (AVEC RAC2)
! IN  MATSYM  : VRAI SI LA MATRICE DE RIGIDITE EST SYMETRIQUE
! OUT MATUU   : MATRICE DE RIGIDITE PROFIL (RIGI_MECA_TANG ET FULL_MECA)
! OUT VECTU   : VECTEUR DES FORCES INTERIEURES (RAPH_MECA ET FULL_MECA)
!.......................................................................
!
!
        if (option(1:4) .eq. 'RIGI') then
            sigg(1)=sign(1)
            sigg(2)=sign(2)
            sigg(3)=sign(3)
            sigg(4)=sign(4)
            sigg(5)=sign(5)
            sigg(6)=sign(6)
        else
            sigg(1)=sigma(1)
            sigg(2)=sigma(2)
            sigg(3)=sigma(3)
            sigg(4)=sigma(4)
            sigg(5)=sigma(5)
            sigg(6)=sigma(6)
        endif
!
        do 160 n = 1, nno
!
            do 150 i = 1, 3
!
                do 151 kl = 1, 6
                    sig(kl)=0.d0
                    sig(kl)=sig(kl)+def(1,n,i)*dsidep(1,kl)
                    sig(kl)=sig(kl)+def(2,n,i)*dsidep(2,kl)
                    sig(kl)=sig(kl)+def(3,n,i)*dsidep(3,kl)
                    sig(kl)=sig(kl)+def(4,n,i)*dsidep(4,kl)
                    sig(kl)=sig(kl)+def(5,n,i)*dsidep(5,kl)
                    sig(kl)=sig(kl)+def(6,n,i)*dsidep(6,kl)
151             continue
!
                if (matsym) then
                    nmax = n
                else
                    nmax = nno
                endif
!
                do 140 j = 1, 3
!
                    do 130 m = 1, nmax
!
! 5.4.1 -            RIGIDITE GEOMETRIQUE
!
                        tmp1 = 0.d0
                        if (i .eq. j) then
                            tmp1 =  pff(1,n,m)*sigg(1)&
                                  + pff(2,n,m)*sigg(2)&
                                  + pff(3,n,m)*sigg(3)&
                                  + pff(4,n,m)*sigg(4)&
                                  + pff(5,n,m)*sigg(5)&
                                  + pff(6,n,m)*sigg(6)
                        endif
!
!                    RIGIDITE DE COMPORTEMENT
!
                        tmp2=0.d0
                        tmp2=tmp2+sig(1)*def(1,m,j)
                        tmp2=tmp2+sig(2)*def(2,m,j)
                        tmp2=tmp2+sig(3)*def(3,m,j)
                        tmp2=tmp2+sig(4)*def(4,m,j)
                        tmp2=tmp2+sig(5)*def(5,m,j)
                        tmp2=tmp2+sig(6)*def(6,m,j)
!
                        if (matsym) then
!
!                       STOCKAGE EN TENANT COMPTE DE LA SYMETRIE
!
                            if (m .eq. n) then
                                j1 = i
                            else
                                j1 = 3
                            endif
                            if (j .le. j1) then
                                kkd = (3*(n-1)+i-1) * (3*(n-1)+i)/2
                                kk = kkd + 3*(m-1)+j
                                matuu(kk) = matuu(kk) + (tmp1+tmp2)* poids
                            endif
                        else
!                       STOCKAGE SANS SYMETRIE
                            kk = 3*nno*(3*(n-1)+i-1) + 3*(m-1)+j
                            matuu(kk) = matuu(kk) + (tmp1+tmp2)*poids
                        endif
!
130                 continue
140             continue
150         continue
160     continue
!
end subroutine
