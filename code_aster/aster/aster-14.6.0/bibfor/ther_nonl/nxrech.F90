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
! person_in_charge: mickael.abbas at edf.fr
! aslint: disable=W1504
!
subroutine nxrech(model    , mate    , cara_elem, list_load  , nume_dof   ,&
                  tpsthe   , time    , lonch    , compor     , varc_curr  ,&
                  temp_iter, vtempp  , vtempr   , temp_prev  , hydr_prev  ,&
                  hydr_curr, dry_prev, dry_curr , vec2nd     , cnvabt     ,&
                  cnresi   , rho     , iterho   , ds_algopara)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "jeveux.h"
#include "asterc/r8prem.h"
#include "asterfort/asasve.h"
#include "asterfort/ascova.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/verstp.h"
#include "asterfort/vethbt.h"
!
character(len=24), intent(in) :: model
character(len=24), intent(in) :: mate
character(len=24), intent(in) :: cara_elem
character(len=19), intent(in) :: list_load
character(len=24), intent(in) :: nume_dof
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
real(kind=8) :: tpsthe(6)
character(len=24), intent(in) :: time
character(len=19), intent(in) :: varc_curr
integer :: lonch
real(kind=8) :: rho
character(len=24) :: temp_prev, vtempr, vtempp, temp_iter, cnvabt, cnresi, vec2nd
character(len=24) :: hydr_prev, hydr_curr, compor, dry_prev, dry_curr
!
! --------------------------------------------------------------------------------------------------
!
! COMMANDE THER_NON_LINE : RECHERCHE LINEAIRE
! DANS LA DIRECTION DONNEE PAR NEWTON (ON CHERCHE RHO).
!
! --------------------------------------------------------------------------------------------------
!
! In  ds_algopara      : datastructure for algorithm parameters
!
! --------------------------------------------------------------------------------------------------
!
    integer :: i
    integer ::    j2nd, jvare, jbtla
    real(kind=8) :: rho0, rhot, f0, f1, rhomin, rhomax
    real(kind=8) :: rhof, ffinal
    real(kind=8) :: testm, r8bid
    character(len=24) :: vebtla, veresi, varesi, bidon, vabtla
    character(len=1) :: typres
    integer :: itrmax, k, iterho
    real(kind=8) :: time_curr
    real(kind=8), pointer :: tempm(:) => null()
    real(kind=8), pointer :: tempp(:) => null()
    real(kind=8), pointer :: tempr(:) => null()
    character(len=24) :: lload_name, lload_info
    parameter (rhomin = -2.d0, rhomax = 2.d0)
    data typres        /'R'/
    data bidon         /'&&FOMULT.BIDON'/
    data vebtla        /'&&VETBTL           .RELR'/
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    varesi = '&&VARESI'
    veresi = '&&VERESI'
    time_curr = tpsthe(1)
    lload_name = list_load(1:19)//'.LCHA'
    lload_info = list_load(1:19)//'.INFC'
!
! --- RECUPERATION D'ADRESSES JEVEUX
!
    call jeveuo(temp_iter(1:19)//'.VALE', 'E', vr=tempm)
    call jeveuo(vtempp(1:19)//'.VALE', 'E', vr=tempp)
    call jeveuo(vtempr(1:19)//'.VALE', 'E', vr=tempr)
    call jeveuo(vec2nd(1:19)//'.VALE', 'L', j2nd)
    call jeveuo(cnresi(1:19)//'.VALE', 'L', jvare)
    call jeveuo(cnvabt(1:19)//'.VALE', 'L', jbtla)
!
! --- RECHERCHE LINEAIRE (CALCUL DE RHO) SUR L'INCREMENT VTEMPP
!
    f0 = 0.d0
    do i = 1, lonch
        f0 = f0 + tempp(i)*( zr(j2nd+i-1) - zr(jvare+i-1) - zr( jbtla+i-1) )
    end do
!
    rho0 = 0.d0
    rho = 1.d0
    itrmax = ds_algopara%line_search%iter_maxi + 1
    do iterho = 1, itrmax
        do i = 1, lonch
            tempr(i) = tempm(i) + rho * tempp(i)
        end do
!
! ----- Neumann loads elementary vectors (residuals)
!
        call verstp(model    , lload_name, lload_info, mate    , time_curr,&
                    time     , compor    , temp_prev , vtempr  , varc_curr,&
                    veresi   , 'V'       ,&
                    hydr_prev, hydr_curr , dry_prev  , dry_curr)
!
! ----- Neumann loads vector (residuals)
!
        call asasve(veresi, nume_dof, typres, varesi)
        call ascova('D', varesi, bidon, 'INST', r8bid,&
                    typres, cnresi)
        call jeveuo(cnresi(1:19)//'.VALE', 'L', jvare)
!
! --- BT LAMBDA - CALCUL ET ASSEMBLAGE
!
        call vethbt(model, lload_name, lload_info, cara_elem, mate,&
                    vtempr, vebtla, 'V')
        call asasve(vebtla, nume_dof, typres, vabtla)
        call ascova('D', vabtla, bidon, 'INST', r8bid,&
                    typres, cnvabt)
        call jeveuo(cnvabt(1:19)//'.VALE', 'L', jbtla)
!
        f1 = 0.d0
        do i = 1, lonch
            f1 = f1 + tempp(i) * ( zr(j2nd+i-1) - zr(jvare+i-1) - zr(jbtla+i-1) )
        end do
        testm = 0.d0
        do k = 1, lonch
            testm = max( testm, abs(zr(j2nd+k-1)-zr(jvare+k-1)-zr( jbtla+k-1)))
        end do
        if (testm .lt. ds_algopara%line_search%resi_rela) then
            goto 999
        endif
!
        if (iterho .eq. 1) then
            ffinal = f1
            rhof = 1.d0
        endif
        if (abs(f1) .lt. abs(ffinal)) then
            ffinal=f1
            rhof=rho
        endif
        rhot=rho
        if (abs(f1-f0) .gt. r8prem()) then
            rho = -(f0*rhot-f1*rho0)/(f1-f0)
            if (rho .lt. rhomin) rho = rhomin
            if (rho .gt. rhomax) rho = rhomax
            if (abs(rho-rhot) .lt. 1.d-08) then
                goto 40
            endif
        else
            goto 40
        endif
        rho0= rhot
        f0 = f1
    end do
40  continue
    rho=rhof
    f1=ffinal
!
999 continue
    iterho = iterho - 1
    call jedema()
end subroutine
