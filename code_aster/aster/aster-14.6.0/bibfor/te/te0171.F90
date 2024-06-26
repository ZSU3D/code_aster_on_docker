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

subroutine te0171(option, nomte)
!
implicit none
!
#include "jeveux.h"
#include "asterfort/dfdm3d.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/rcvalb.h"
!
! aslint: disable=W0104
!
    character(len=16), intent(in) :: option
    character(len=16), intent(in) :: nomte
!
! --------------------------------------------------------------------------------------------------
!
! Elementary computation
!
! Elements: 3D_FLUIDE
! Option: MASS_MECA
!
! --------------------------------------------------------------------------------------------------
!
    integer, parameter :: nbres=2
    character(len=16), parameter :: nomres(nbres) = (/'RHO   ', 'CELE_R'/)
    real(kind=8) :: valres(nbres)
    integer :: icodre(nbres)
    integer :: k
    character(len=8) :: fami, poum
    integer :: kpg, spt
    real(kind=8) :: a(2, 2, 27, 27)
    real(kind=8) :: dfdx(27), dfdy(27), dfdz(27), poids, rho, celer
    integer :: ipoids, ivf, idfde, jv_geom, jv_mate
    integer :: nno, kp, npg, ik, ijkl, i, j, l, jv_matr
!
! --------------------------------------------------------------------------------------------------
!
    fami       = 'FPG1'
    kpg        = 1
    spt        = 1
    poum       = '+'
    a(:,:,:,:) = 0.d0
!
! - Get fields
!
    call jevech('PGEOMER', 'L', jv_geom)
    call jevech('PMATERC', 'L', jv_mate)
    call jevech('PMATUUR', 'E', jv_matr)
!
! - Get element parameters
!
    call elrefe_info(fami='RIGI', nno=nno, npg=npg, jpoids=ipoids, jvf=ivf, jdfde=idfde)
!
! - Get material properties
!
    call rcvalb(fami , kpg     , spt   , poum  , zi(jv_mate),&
                ' '  , 'FLUIDE', 0     , ' '   , [0.d0]     ,&
                nbres, nomres  , valres, icodre, 1)
    rho   = valres(1)
    celer = valres(2)
!
! - Loop on Gauss points
!
    do kp = 1, npg
        l = (kp-1)*nno
        call dfdm3d(nno, kp, ipoids, idfde, zr(jv_geom),&
                    poids, dfdx, dfdy, dfdz)
        do i = 1, nno
            do j = 1, i
!
! ----- Compute -RHO*(GRAD(PHI)**2)
!
                a(2,2,i,j) = a(2,2,i,j) -&
                             poids* (dfdx(i)*dfdx(j)+ dfdy(i)*dfdy(j)+ dfdz(i)*dfdz(j))*rho
!
! ----- Compute (P*PHI)/(CEL**2)
!
                if (celer .eq. 0.d0) then
                    a(1,2,i,j) = 0.d0
                else
                    a(1,2,i,j) = a(1,2,i,j) + poids*zr(ivf+l+i-1)*zr(ivf+ l+j-1)/ celer/celer
                endif
            end do
        end do
    end do
!
! - Matrix is symmetric
!
    do i = 1, nno
        do j = 1, i
            a(2,1,i,j) = a(1,2,i,j)
        end do
    end do
!
! - Save matrix
!
    do k = 1, 2
        do l = 1, 2
            do i = 1, nno
                ik = ((2*i+k-3)* (2*i+k-2))/2
                do j = 1, i
                    ijkl = ik + 2* (j-1) + l
                    zr(jv_matr+ijkl-1) = a(k,l,i,j)
                end do
            end do
        end do
    end do
!
end subroutine
