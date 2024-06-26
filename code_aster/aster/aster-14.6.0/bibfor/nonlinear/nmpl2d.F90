! --------------------------------------------------------------------
! Copyright (C) 1991 - 2019 - EDF R&D - www.code-aster.org
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
! aslint: disable=W1504
!
subroutine nmpl2d(fami, nno, npg, ipoids, ivf,&
                  idfde, geom, typmod, option, imate,&
                  compor, mult_comp, lgpg, carcri, instam, instap,&
                  ideplm, ideplp, angmas, sigm, vim,&
                  matsym, dfdi, def, sigp, vip,&
                  matuu, ivectu, codret)
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/codere.h"
#include "asterfort/crirup.h"
#include "asterfort/lcegeo.h"
#include "asterfort/nmcomp.h"
#include "asterfort/nmgeom.h"
#include "asterfort/Behaviour_type.h"
!
integer :: nno, npg, imate, lgpg, codret, cod(9), ipoids, ivf, idfde
integer :: ivectu, ideplm, ideplp, ndim
character(len=8) :: typmod(*)
character(len=*) :: fami
character(len=16) :: option
character(len=16), intent(in) :: compor(*)
character(len=16), intent(in) :: mult_comp
real(kind=8), intent(in) :: carcri(*)
real(kind=8) :: instam, instap
real(kind=8) :: angmas(3)
real(kind=8) :: geom(2, nno)
real(kind=8) :: dfdi(nno, 2)
real(kind=8) :: def(4, nno, 2)
real(kind=8) :: sigm(4, npg), sigp(4, npg)
real(kind=8) :: vim(lgpg, npg), vip(lgpg, npg)
real(kind=8) :: matuu(*)
aster_logical :: matsym
!
!.......................................................................
!
!     BUT:  CALCUL  DES OPTIONS RIGI_MECA_TANG, RAPH_MECA ET FULL_MECA
!           EN HYPO-ELASTICITE EN 2D
!.......................................................................
! IN  NNO     : NOMBRE DE NOEUDS DE L'ELEMENT
! IN  NPG     : NOMBRE DE POINTS DE GAUSS
! IN  POIDSG  : POIDS DES POINTS DE GAUSS
! IN  VFF     : VALEUR  DES FONCTIONS DE FORME
! IN  DFDE    : DERIVEE DES FONCTIONS DE FORME ELEMENT DE REFERENCE
! IN  DFDK    : DERIVEE DES FONCTIONS DE FORME ELEMENT DE REFERENCE
! IN  GEOM    : COORDONEES DES NOEUDS
! IN  TYPMOD  : TYPE DE MODEELISATION
! IN  OPTION  : OPTION DE CALCUL
! IN  IMATE   : MATERIAU CODE
! IN  COMPOR  : COMPORTEMENT
! IN  LGPG    : "LONGUEUR" DES VARIABLES INTERNES POUR 1 POINT DE GAUSS
!               CETTE LONGUEUR EST UN MAJORANT DU NBRE REEL DE VAR. INT.
! IN  CRIT    : CRITERES DE CONVERGENCE LOCAUX
! IN  INSTAM  : INSTANT PRECEDENT
! IN  INSTAP  : INSTANT DE CALCUL
! IN  TM      : TEMPERATURE AUX NOEUDS A L'INSTANT PRECEDENT
! IN  TP      : TEMPERATURE AUX NOEUDS A L'INSTANT DE CALCUL
! IN  TREF    : TEMPERATURE DE REFERENCE
! IN  DEPLM   : DEPLACEMENT A L'INSTANT PRECEDENT
! IN  DEPLP   : INCREMENT DE DEPLACEMENT
! IN  ANGMAS  : LES TROIS ANGLES DU MOT_CLEF MASSIF (AFFE_CARA_ELEM)
! IN  SIGM    : CONTRAINTES A L'INSTANT PRECEDENT
! IN  VIM     : VARIABLES INTERNES A L'INSTANT PRECEDENT
! OUT DFDI    : DERIVEE DES FONCTIONS DE FORME  AU DERNIER PT DE GAUSS
! OUT DEF     : PRODUIT DER. FCT. FORME PAR F   AU DERNIER PT DE GAUSS
! OUT SIGP    : CONTRAINTES DE CAUCHY (RAPH_MECA ET FULL_MECA)
! OUT VIP     : VARIABLES INTERNES    (RAPH_MECA ET FULL_MECA)
! OUT MATUU   : MATRICE DE RIGIDITE PROFIL (RIGI_MECA_TANG ET FULL_MECA)
! OUT VECTU   : FORCES NODALES (RAPH_MECA ET FULL_MECA)
!.......................................................................
!
    aster_logical :: grand, axi
!
    integer :: kpg, kk, kkd, n, i, m, j, j1, kl, jvariext1, jvariext2
!
    real(kind=8) :: dsidep(6, 6), f(3, 3), eps(6), deps(6), r, sigma(6), sign(6)
    real(kind=8) :: poids, tmp, sig(6), rbid(1)
    real(kind=8) :: elgeom(10, 9), rac2
!
! - INITIALISATION
!
    elgeom(:,:) = 0.d0
    rac2 = sqrt(2.d0)
    grand = .false.
    axi = typmod(1) .eq. 'AXIS'
!
! - Get coded integers for external state variables
!
    jvariext1 = nint(carcri(IVARIEXT1))
    jvariext2 = nint(carcri(IVARIEXT2))
!
! - Compute intrinsic external state variables
!
    call lcegeo(nno   , npg      , 2        ,&
                ipoids, ivf      , idfde    ,&
                typmod, jvariext1, jvariext2,&
                geom  ,&
                zr(ideplm), zr(ideplp))
!
! - INITIALISATION CODES RETOURS
    do kpg = 1, npg
        cod(kpg)=0
    end do
!
! - CALCUL POUR CHAQUE POINT DE GAUSS
!
    do kpg = 1, npg
!
! - CALCUL DES ELEMENTS GEOMETRIQUES
!
!     CALCUL DE DFDI,F,EPS,DEPS,R(EN AXI) ET POIDS
!
        do j = 1, 6
            eps (j)=0.d0
            deps(j)=0.d0
        end do
!
        call nmgeom(2, nno, axi, grand, geom,&
                    kpg, ipoids, ivf, idfde, zr(ideplm),&
                    .true._1, poids, dfdi, f, eps,&
                    r)
!
!     CALCUL DE DEPS
!
        call nmgeom(2, nno, axi, grand, geom,&
                    kpg, ipoids, ivf, idfde, zr(ideplp),&
                    .true._1, poids, dfdi, f, deps,&
                    r)
!
!      CALCUL DES PRODUITS SYMETR. DE F PAR N,
        do n = 1, nno
            do i = 1, 2
                def(1,n,i) = f(i,1)*dfdi(n,1)
                def(2,n,i) = f(i,2)*dfdi(n,2)
                def(3,n,i) = 0.d0
                def(4,n,i) = (f(i,1)*dfdi(n,2) + f(i,2)*dfdi(n,1))/ rac2
            end do
        end do
!
!      TERME DE CORRECTION (3,3) AXI QUI PORTE EN FAIT SUR LE DDL 1
        if (axi) then
            do n = 1, nno
                def(3,n,1) = f(3,3)*zr(ivf+n+(kpg-1)*nno-1)/r
            end do
        endif
!
        do i = 1, 3
            sign(i) = sigm(i,kpg)
        end do
        sign(4) = sigm(4,kpg)*rac2
!
!
! - LOI DE COMPORTEMENT
        call nmcomp(fami, kpg, 1, 2, typmod,&
                    imate, compor, carcri, instam, instap,&
                    6, eps, deps, 6, sign,&
                    vim(1, kpg), option, angmas, 10, elgeom(1, kpg),&
                    sigma, vip(1, kpg), 36, dsidep, 1,&
                    rbid, cod(kpg), mult_comp)
!
        if (cod(kpg) .eq. 1) then
            goto 999
        endif
!
!
! - CALCUL DE LA MATRICE DE RIGIDITE
!
        if (option(1:10) .eq. 'RIGI_MECA_' .or. option(1: 9) .eq. 'FULL_MECA') then
!
            if (matsym) then
                do n = 1, nno
                    do i = 1, 2
                        do kl = 1, 4
                            sig(kl)=0.d0
                            sig(kl)=sig(kl)+def(1,n,i)*dsidep(1,kl)
                            sig(kl)=sig(kl)+def(2,n,i)*dsidep(2,kl)
                            sig(kl)=sig(kl)+def(3,n,i)*dsidep(3,kl)
                            sig(kl)=sig(kl)+def(4,n,i)*dsidep(4,kl)
                        end do
                        do j = 1, 2
                            do m = 1, n
                                if (m .eq. n) then
                                    j1 = i
                                else
                                    j1 = 2
                                endif
!
!                   RIGIDITE ELASTIQUE
                                tmp=0.d0
                                tmp=tmp+sig(1)*def(1,m,j)
                                tmp=tmp+sig(2)*def(2,m,j)
                                tmp=tmp+sig(3)*def(3,m,j)
                                tmp=tmp+sig(4)*def(4,m,j)
!
!                   STOCKAGE EN TENANT COMPTE DE LA SYMETRIE
                                if (j .le. j1) then
                                    kkd = (2*(n-1)+i-1) * (2*(n-1)+i) /2
                                    kk = kkd + 2*(m-1)+j
                                    matuu(kk) = matuu(kk) + tmp*poids
                                endif
!
                            end do
                        end do
                    end do
                end do
            else
                do n = 1, nno
                    do i = 1, 2
                        do kl = 1, 4
                            sig(kl)=0.d0
                            sig(kl)=sig(kl)+def(1,n,i)*dsidep(1,kl)
                            sig(kl)=sig(kl)+def(2,n,i)*dsidep(2,kl)
                            sig(kl)=sig(kl)+def(3,n,i)*dsidep(3,kl)
                            sig(kl)=sig(kl)+def(4,n,i)*dsidep(4,kl)
                        end do
                        do j = 1, 2
                            do m = 1, nno
!
!                   RIGIDITE ELASTIQUE
                                tmp=0.d0
                                tmp=tmp+sig(1)*def(1,m,j)
                                tmp=tmp+sig(2)*def(2,m,j)
                                tmp=tmp+sig(3)*def(3,m,j)
                                tmp=tmp+sig(4)*def(4,m,j)
!
!                   STOCKAGE SANS SYMETRIE
                                kk = 2*nno*(2*(n-1)+i-1) + 2*(m-1)+j
                                matuu(kk) = matuu(kk) + tmp*poids
!
                            end do
                        end do
                    end do
                end do
            endif
        endif
!
!
! - CALCUL DE LA FORCE INTERIEURE ET DES CONTRAINTES DE CAUCHY
!
        if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
!
            do n = 1, nno
                do i = 1, 2
                    do kl = 1, 4
!               VECTU(I,N)=VECTU(I,N)+DEF(KL,N,I)*SIGMA(KL)*POIDS
                        zr(ivectu-1+2*(n-1)+i)= zr(ivectu-1+2*(n-1)+i)&
                        +def(kl,n,i)*sigma(kl)*poids
                    end do
                end do
            end do
!
            do kl = 1, 3
                sigp(kl,kpg) = sigma(kl)
            end do
            sigp(4,kpg) = sigma(4)/rac2
!
        endif
!
! - CALCUL DES CONTRAINTES DE CAUCHY POUR LA METHODE IMPLEX
!
        if (option(1:16) .eq. 'RIGI_MECA_IMPLEX') then
!
            do kl = 1, 3
                sigp(kl,kpg) = sigma(kl)
            end do
            sigp(4,kpg) = sigma(4)/rac2
!
        endif
!
    end do
!
!     POST_ITER='CRIT_RUPT'
    if (carcri(13) .gt. 0.d0) then
        ndim=2
        call crirup(fami, imate, ndim, npg, lgpg,&
                    option, compor, sigp, vip, vim,&
                    instam, instap)
    endif
!
999 continue
! - SYNTHESE DES CODES RETOURS
    call codere(cod, npg, codret)
end subroutine
