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
! aslint: disable=W1504
!
subroutine get_elas_para(fami     , j_mater, poum, ipg, ispg, &
                         elas_id  , elas_keyword,&
                         time     , temp,&
                         e   , nu  , g,&
                         e1  , e2  , e3,&
                         nu12, nu13, nu23,&
                         g1  , g2  , g3)
!
implicit none
!
#include "asterfort/assert.h"
#include "asterfort/hypmat.h"
#include "asterfort/rcvalb.h"
!

!
    character(len=*), intent(in) :: fami
    integer, intent(in) :: j_mater
    character(len=*), intent(in) :: poum
    integer, intent(in) :: ipg
    integer, intent(in) :: ispg
    integer, intent(in) :: elas_id
    character(len=16), intent(in) :: elas_keyword
    real(kind=8), optional, intent(in) :: time
    real(kind=8), optional, intent(in) :: temp
    real(kind=8), optional, intent(out) :: e
    real(kind=8), optional, intent(out) :: nu
    real(kind=8), optional, intent(out) :: g
    real(kind=8), optional, intent(out) :: e1
    real(kind=8), optional, intent(out) :: e2
    real(kind=8), optional, intent(out) :: e3
    real(kind=8), optional, intent(out) :: nu12
    real(kind=8), optional, intent(out) :: nu13
    real(kind=8), optional, intent(out) :: nu23
    real(kind=8), optional, intent(out) :: g1
    real(kind=8), optional, intent(out) :: g2
    real(kind=8), optional, intent(out) :: g3
!
! --------------------------------------------------------------------------------------------------
!
! Comportment utility
!
! Get elastic parameters
!
! --------------------------------------------------------------------------------------------------
!
! In  fami         : Gauss family for integration point rule
! In  j_mater      : coded material address
! In  time         : current time
! In  time         : current temperature
! In  poum         : '-' or '+' for parameters evaluation (previous or current temperature)
! In  ipg          : current point gauss
! In  ispg         : current "sous-point" gauss
! In  elas_id      : Type of elasticity
!                 1 - Isotropic
!                 2 - Orthotropic
!                 3 - Transverse isotropic
! In  elas_keyword : keyword factor linked to type of elasticity parameters
! Out e            : Young modulus (isotropic)
! Out nu           : Poisson ratio (isotropic)
! Out e1           : Young modulus - Direction 1 (Orthotropic/Transverse isotropic)
! Out e2           : Young modulus - Direction 2 (Orthotropic)
! Out e3           : Young modulus - Direction 3 (Orthotropic/Transverse isotropic)
! Out nu12         : Poisson ratio - Coupling 1/2 (Orthotropic/Transverse isotropic)
! Out nu13         : Poisson ratio - Coupling 1/3 (Orthotropic/Transverse isotropic)
! Out nu23         : Poisson ratio - Coupling 2/3 (Orthotropic)
! Out g1           : shear ratio (Orthotropic)
! Out g2           : shear ratio (Orthotropic)
! Out g3           : shear ratio (Orthotropic)
! Out g            : shear ratio (isotropic/Transverse isotropic)
!
! --------------------------------------------------------------------------------------------------
!
    integer, parameter :: nbresm = 9
    integer :: icodre(nbresm)
    character(len=16) :: nomres(nbresm)
    real(kind=8) :: valres(nbresm)
!
    character(len=8) :: para_name(2)
    real(kind=8) :: para_vale(2)
    integer :: nbres, nb_para
    real(kind=8) :: c10, c01, c20, k
    real(kind=8) :: un
!
! --------------------------------------------------------------------------------------------------
!
    un             = 1.d0
    nb_para        = 0
    para_name(1:2) = ' '
    para_vale(1:2) = 0.d0
    if (present(time)) then
        nb_para   = nb_para + 1
        para_name(nb_para) = 'INST'
        para_vale(nb_para) = time
    endif
    if (present(temp)) then
        nb_para   = nb_para + 1
        para_name(nb_para) = 'TEMP'
        para_vale(nb_para) = temp
    endif
!
! - Get elastic parameters
!
    if (elas_id.eq.1) then
        if (elas_keyword.eq.'ELAS_HYPER') then
            call hypmat(fami, ipg, ispg, poum, j_mater,&
                        c10, c01, c20, k)
            nu = (3.d0*k-4.0d0*(c10+c01))/(6.d0*k+4.0d0*(c10+c01))
            if (present(e)) then
                e  = 4.d0*(c10+c01)*(un+nu)
            endif
        else
            nomres(1) = 'E'
            nomres(2) = 'NU'
            nbres     = 2
            call rcvalb(fami, ipg, ispg, poum, j_mater,&
                        ' ', elas_keyword, nb_para, para_name, [para_vale],&
                        nbres, nomres, valres, icodre, 1)
            if (present(e)) then
                e  = valres(1)
            endif
            nu = valres(2)
        endif
        if (present(g)) then
            ASSERT(present(nu))
            g = 1.d0/((1.d0+nu)*(1.d0-2.d0*nu))
        endif
    elseif (elas_id.eq.2) then
        nomres(1) = 'E_L'
        nomres(2) = 'E_T'
        nomres(3) = 'E_N'
        nomres(4) = 'NU_LT'
        nomres(5) = 'NU_LN'
        nomres(6) = 'NU_TN'
        nomres(7) = 'G_LT'
        nomres(8) = 'G_LN'
        nomres(9) = 'G_TN'
        nbres     = 9
        call rcvalb(fami, ipg, ispg, poum, j_mater,&
                    ' ', elas_keyword, nb_para, para_name, [para_vale],&
                    nbres, nomres, valres, icodre, 1)
        e1 = valres(1)
        e2 = valres(2)
        e3 = valres(3)
        nu12 = valres(4)
        nu13 = valres(5)
        nu23 = valres(6)
        g1 = valres(7)
        g2 = valres(8)
        g3 = valres(9)
    elseif (elas_id.eq.3) then
        nomres(1) = 'E_L'
        nomres(2) = 'E_N'
        nomres(3) = 'NU_LT'
        nomres(4) = 'NU_LN'
        nomres(5) = 'G_LN'
        nbres     = 5
        call rcvalb(fami, ipg, ispg, poum, j_mater,&
                    ' ', elas_keyword, nb_para, para_name, [para_vale],&
                    nbres, nomres, valres, icodre, 1)
        e1   = valres(1)
        e3   = valres(2)
        nu12 = valres(3)
        nu13 = valres(4)
        g    = valres(5)
    else
        ASSERT(.false.)
    endif

end subroutine
