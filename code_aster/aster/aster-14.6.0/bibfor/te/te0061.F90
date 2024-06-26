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

subroutine te0061(option, nomte)
!
!     BUT: CALCUL DU SECOND MEMBRE ELEMENTAIRE EN THERMIQUE CORRESPON-
!          DANT A UN PROBLEME TRANSITOIRE
!          ELEMENTS ISOPARAMETRIQUES 3D
!
!          OPTION : 'CHAR_THER_EVOL'
!
!     ENTREES  ---> OPTION : OPTION DE CALCUL
!              ---> NOMTE  : NOM DU TYPE ELEMENT
!----------------------------------------------------------------------
! CORPS DU PROGRAMME
    implicit none
!
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/r8dgrd.h"
#include "asterfort/dfdm3d.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/matrot.h"
#include "asterfort/rccoma.h"
#include "asterfort/rcvalb.h"
#include "asterfort/utmess.h"
#include "asterfort/utpvgl.h"
#include "asterfort/utpvlg.h"
#include "asterfort/utrcyl.h"
#include "asterfort/uttgel.h"
!
    integer :: nbres
    parameter (nbres=4)
    integer :: icodre(nbres)
    character(len=16) :: nomres(nbres), nomte, option
    character(len=32) :: phenom
    character(len=2) :: typgeo
    real(kind=8) :: valres(nbres), valpar(1), theta, lambor(3), point(3)
    real(kind=8) :: dfdx(27), dfdy(27), dfdz(27), tem, poids, dire(3), orig(3)
    real(kind=8) :: lambda, fluglo(3), fluloc(3), p(3, 3), angl(3), zero, deltat
    real(kind=8) :: cp, alpha, beta, dtemdx, dtemdy, dtemdz
    integer :: jgano, ipoids, ivf, idfde, igeom, imate, nno, kp, npg1, i, itemp
    integer :: itps, n1, n2, ndim, ivectt, icamas, l, nuno, nnos, npg2, ipoid2
    integer :: ivf2, idfde2
    aster_logical :: aniso, global
!
!====
! 1.1 PREALABLES: RECUPERATION ADRESSES FONCTIONS DE FORMES...
!====
    zero = 0.0d0
!
    call uttgel(nomte, typgeo)
    if ((lteatt('LUMPE','OUI')) .and. (typgeo.ne.'PY')) then
        call elrefe_info(fami='NOEU', ndim=ndim, nno=nno, nnos=nnos, npg=npg2,&
                         jpoids=ipoid2, jvf=ivf2, jdfde=idfde2, jgano=jgano)
    else
        call elrefe_info(fami='MASS', ndim=ndim, nno=nno, nnos=nnos, npg=npg2,&
                         jpoids=ipoid2, jvf=ivf2, jdfde=idfde2, jgano=jgano)
    endif
!
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nno, nnos=nnos, npg=npg1,&
                     jpoids=ipoids, jvf=ivf, jdfde=idfde, jgano=jgano)
!
!====
! 1.2 PREALABLES LIES AUX RECHERCHES DE DONNEES GENERALES
!====
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
    call jevech('PVECTTR', 'E', ivectt)
    call jevech('PTEMPER', 'L', itemp)
    call jevech('PTEMPSR', 'L', itps)
    valpar(1) = zr(itps)
    deltat = zr(itps+1)
    theta = zr(itps+2)
    call rccoma(zi(imate), 'THER', 1, phenom, icodre(1))
!
!====
! 1.3 PREALABLES LIES A LA RECUPERATION DES DONNEES MATERIAUX
!====
    if (phenom .eq. 'THER') then
        nomres(1) = 'LAMBDA'
        nomres(2) = 'RHO_CP'
        aniso = .false.
        call rcvalb('FPG1', 1, 1, '+', zi(imate),&
                    ' ', phenom, 1, 'INST', [valpar],&
                    2, nomres, valres, icodre, 1)
        lambda = valres(1)
        cp = valres(2)
    else if (phenom.eq.'THER_ORTH') then
        nomres(1) = 'LAMBDA_L'
        nomres(2) = 'LAMBDA_T'
        nomres(3) = 'LAMBDA_N'
        nomres(4) = 'RHO_CP'
        aniso = .true.
        call rcvalb('FPG1', 1, 1, '+', zi(imate),&
                    ' ', phenom, 1, 'INST', [valpar],&
                    4, nomres, valres, icodre, 1)
        lambor(1) = valres(1)
        lambor(2) = valres(2)
        lambor(3) = valres(3)
        cp = valres(4)
    else
        call utmess('F', 'ELEMENTS2_63')
    endif
!
!====
! 1.4 PREALABLES LIES A L'ANISOTROPIE
!====
    if (aniso) then
        call jevech('PCAMASS', 'L', icamas)
        if (zr(icamas) .gt. zero) then
            global = .true.
            angl(1) = zr(icamas+1)*r8dgrd()
            angl(2) = zr(icamas+2)*r8dgrd()
            angl(3) = zr(icamas+3)*r8dgrd()
            call matrot(angl, p)
        else
            global = .false.
            alpha = zr(icamas+1)*r8dgrd()
            beta = zr(icamas+2)*r8dgrd()
            dire(1) = cos(alpha)*cos(beta)
            dire(2) = sin(alpha)*cos(beta)
            dire(3) = -sin(beta)
            orig(1) = zr(icamas+4)
            orig(2) = zr(icamas+5)
            orig(3) = zr(icamas+6)
        endif
    endif
!
!====
! 3.1 CALCULS TERMES DE RIGIDITE
!    POUR LES ELEMENTS LUMPES ET NON LUMPES
!====
!
! ---   BOUCLE SUR LES POINTS DE GAUSS :
!       ------------------------------
    do 160 kp = 1, npg1
!
        l = (kp-1)*nno
        call dfdm3d(nno, kp, ipoids, idfde, zr(igeom),&
                    poids, dfdx, dfdy, dfdz)
!
        dtemdx = zero
        dtemdy = zero
        dtemdz = zero
        do 110 i = 1, nno
! CALCUL DE GRAD(T-)
            dtemdx = dtemdx + zr(itemp+i-1)*dfdx(i)
            dtemdy = dtemdy + zr(itemp+i-1)*dfdy(i)
            dtemdz = dtemdz + zr(itemp+i-1)*dfdz(i)
110     continue
!
        if (.not.aniso) then
            fluglo(1) = lambda*dtemdx
            fluglo(2) = lambda*dtemdy
            fluglo(3) = lambda*dtemdz
        else
            if (.not.global) then
                point(1) = zero
                point(2) = zero
                point(3) = zero
                do 130 nuno = 1, nno
                    point(1) = point(1) + zr(ivf+l+nuno-1)* zr(igeom+ 3*nuno-3)
                    point(2) = point(2) + zr(ivf+l+nuno-1)* zr(igeom+ 3*nuno-2)
                    point(3) = point(3) + zr(ivf+l+nuno-1)* zr(igeom+ 3*nuno-1)
130             continue
                call utrcyl(point, dire, orig, p)
            endif
            fluglo(1) = dtemdx
            fluglo(2) = dtemdy
            fluglo(3) = dtemdz
            n1 = 1
            n2 = 3
            call utpvgl(n1, n2, p, fluglo, fluloc)
            fluloc(1) = lambor(1)*fluloc(1)
            fluloc(2) = lambor(2)*fluloc(2)
            fluloc(3) = lambor(3)*fluloc(3)
            n1 = 1
            n2 = 3
            call utpvlg(n1, n2, p, fluloc, fluglo)
        endif
!
! --- AFFECTATION DES TERMES DE RIGIDITE :
!     ----------------------------------
        do 140 i = 1, nno
            zr(ivectt+i-1) = zr(ivectt+i-1) - poids* ((1.0d0-theta)* (dfdx(i)*fluglo(1)+dfdy(i)*f&
                             &luglo(2)+ dfdz(i)*fluglo(3)))
140     continue
160 continue
!
!====
! 3.2 CALCULS TERMES DE MASSE
!    POUR LES ELEMENTS LUMPES
!====
!
! ---   BOUCLE SUR LES POINTS DE GAUSS :
!       ------------------------------
    do 210 kp = 1, npg2
!
        l = (kp-1)*nno
        call dfdm3d(nno, kp, ipoid2, idfde2, zr(igeom),&
                    poids, dfdx, dfdy, dfdz)
        tem = zero
        do 170 i = 1, nno
! CALCUL DE T-
            tem = tem + zr(itemp+i-1)*zr(ivf2+l+i-1)
170     continue
!
! --- AFFECTATION DU TERME DE MASSE :
!     -----------------------------
        do 190 i = 1, nno
            zr(ivectt+i-1) = zr(ivectt+i-1) + poids*cp/deltat*zr(ivf2+ l+i-1)*tem
190     continue
210 continue
!
!
end subroutine
