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

subroutine te0319(option, nomte)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/r8dgrd.h"
#include "asterfort/dfdm3d.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/matrot.h"
#include "asterfort/rccoma.h"
#include "asterfort/rcvalb.h"
#include "asterfort/utmess.h"
#include "asterfort/utpvgl.h"
#include "asterfort/utpvlg.h"
#include "asterfort/utrcyl.h"
!
    character(len=16) :: option, nomte
! ----------------------------------------------------------------------
! CALCUL DES FLUX AU CARRE AUX POINTS DE GAUSS
! ELEMENTS ISOPARAMETRIQUES 3D  OPTION : 'SOUR_ELGA'
!
! IN  OPTION : OPTION DE CALCUL
! IN  NOMTE  : NOM DU TYPE ELEMENT
!
!
!
    integer :: icodre(3), kpg, spt
    character(len=8) :: fami, poum
    character(len=16) :: nomres(3)
    character(len=32) :: phenom
    real(kind=8) :: valres(3), lambda, fluxx, fluxy, fluxz, tpg
    real(kind=8) :: dfdx(27), dfdy(27), dfdz(27), poids
    real(kind=8) :: lambor(3), fluglo(3), fluloc(3), p(3, 3)
    real(kind=8) :: dire(3), orig(3), point(3), a, b, c, angl(3)
    integer :: ipoids, ivf, idfde, igeom, imate
    integer :: jgano, nno, kp, npg1, i, iflux, itemps, itempe
    aster_logical :: aniso, global
! FIN ------------------------------------------------------------------
!-----------------------------------------------------------------------
    integer :: icamas, l, ndim, nnos, nuno
    real(kind=8) :: alpha, beta
!-----------------------------------------------------------------------
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nno, nnos=nnos, npg=npg1,&
                     jpoids=ipoids, jvf=ivf, jdfde=idfde, jgano=jgano)
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
    call jevech('PTEMPSR', 'L', itemps)
    call jevech('PTEMPER', 'L', itempe)
    call jevech('PSOUR_R', 'E', iflux)
!
    call rccoma(zi(imate), 'THER', 1, phenom, icodre(1))
!
    if (phenom .eq. 'THER') then
        nomres(1) = 'LAMBDA'
        call rcvalb(fami, kpg, spt, poum, zi(imate),&
                    ' ', phenom, 1, 'INST', [zr(itemps)],&
                    1, nomres, valres, icodre, 1)
        lambda = valres(1)
        aniso = .false.
    else if (phenom.eq.'THER_ORTH') then
        nomres(1) = 'LAMBDA_L'
        nomres(2) = 'LAMBDA_T'
        nomres(3) = 'LAMBDA_N'
        call rcvalb(fami, kpg, spt, poum, zi(imate),&
                    ' ', phenom, 1, 'INST', [zr(itemps)],&
                    3, nomres, valres, icodre, 1)
        lambor(1) = valres(1)
        lambor(2) = valres(2)
        lambor(3) = valres(3)
        aniso = .true.
    else if (phenom.eq.'THER_NL') then
        aniso = .false.
    else
        call utmess('F', 'ELEMENTS2_63')
    endif
!
    global = .false.
    if (aniso) then
        call jevech('PCAMASS', 'L', icamas)
        if (zr(icamas) .gt. 0.d0) then
            global = .true.
            angl(1) = zr(icamas+1)*r8dgrd()
            angl(2) = zr(icamas+2)*r8dgrd()
            angl(3) = zr(icamas+3)*r8dgrd()
            call matrot(angl, p)
        else
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
    a = 0.d0
    b = 0.d0
    c = 0.d0
    do 30 kp = 1, npg1
        l = (kp-1)*nno
        call dfdm3d(nno, kp, ipoids, idfde, zr(igeom),&
                    poids, dfdx, dfdy, dfdz)
!
!     CALCUL DU GRADIENT DE TEMPERATURE AUX POINTS DE GAUSS
!
        tpg = 0.0d0
        fluxx = 0.0d0
        fluxy = 0.0d0
        fluxz = 0.0d0
        if (.not.global .and. aniso) then
            point(1) = 0.d0
            point(2) = 0.d0
            point(3) = 0.d0
            do 10 nuno = 1, nno
                point(1) = point(1) + zr(ivf+l+nuno-1)*zr(igeom+3* nuno-3)
                point(2) = point(2) + zr(ivf+l+nuno-1)*zr(igeom+3* nuno-2)
                point(3) = point(3) + zr(ivf+l+nuno-1)*zr(igeom+3* nuno-1)
 10         continue
            call utrcyl(point, dire, orig, p)
        endif
!
        do 20 i = 1, nno
            tpg = tpg + zr(itempe-1+i)*zr(ivf+l+i-1)
            fluxx = fluxx + zr(itempe-1+i)*dfdx(i)
            fluxy = fluxy + zr(itempe-1+i)*dfdy(i)
            fluxz = fluxz + zr(itempe-1+i)*dfdz(i)
 20     continue
!
        if (phenom .eq. 'THER_NL') then
            call rcvalb(fami, kpg, spt, poum, zi(imate),&
                        ' ', phenom, 1, 'TEMP', [tpg],&
                        1, 'LAMBDA', valres, icodre, 1)
            lambda = valres(1)
        endif
!
        if (.not.aniso) then
            fluglo(1) = lambda*fluxx
            fluglo(2) = lambda*fluxy
            fluglo(3) = lambda*fluxz
        else
            fluglo(1) = fluxx
            fluglo(2) = fluxy
            fluglo(3) = fluxz
            call utpvgl(1, 1, p, fluglo, fluloc)
            fluloc(1) = lambor(1)*fluloc(1)
            fluloc(2) = lambor(2)*fluloc(2)
            fluloc(3) = lambor(3)*fluloc(3)
            call utpvlg(1, 1, p, fluloc, fluglo)
        endif
!
        a = a - fluglo(1)/npg1
        b = b - fluglo(2)/npg1
        c = c - fluglo(3)/npg1
 30 end do
    do 40 kp = 1, npg1
        zr(iflux+ (kp-1)) = (a**2+b**2+c**2)/lambda
 40 end do
! FIN ------------------------------------------------------------------
end subroutine
