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

subroutine nmiclb(fami,kpg,ksp, option, compor,&
                  imate, xlong0, aire, tmoins, tplus,&
                  dlong0, effnom, vim, effnop, vip,&
                  klv, fono, epsm, crildc, codret)
!
    implicit none
#include "asterf_types.h"
#include "asterfort/lcimpl.h"
#include "asterfort/nm1dci.h"
#include "asterfort/nm1dco.h"
#include "asterfort/nm1dis.h"
#include "asterfort/r8inir.h"
#include "asterfort/relax_acier_cable.h"
#include "asterfort/rcvalb.h"
#include "asterfort/utmess.h"
#include "asterfort/verift.h"
!
! --------------------------------------------------------------------------------------------------
!
    integer :: imate, neq, nbt,kpg,ksp, codret
    parameter (neq=6,nbt=21)
!
    real(kind=8) :: xlong0, aire, tmoins, tplus, dlong0, crildc(3), epsm
    real(kind=8) :: effnom, vim(*), effnop, vip(*), fono(neq), klv(nbt)
!
    character(len=16) :: compor(*), option
    character(len=*) :: fami
!
! --------------------------------------------------------------------------------------------------
!
!
!    TRAITEMENT DE LA RELATION DE COMPORTEMENT -ELASTOPLASTICITE-
!    ECROUISSAGE ISOTROPE ET CINEMATIQUE- LINEAIRE - VON MISES-
!    POUR UN MODELE BARRE ELEMENT MECA_BARRE
!
!
! --------------------------------------------------------------------------------------------------
!
! IN  : IMATE : POINTEUR MATERIAU CODE
!       COMPOR : LOI DE COMPORTEMENT
!       XLONG0 : LONGUEUR DE L'ELEMENT DE BARRE AU REPOS
!       aire   : SECTION DE LA BARRE
!       TMOINS : INSTANT PRECEDENT
!       TPLUS  : INSTANT COURANT
!       DLONG0 : INCREMENT D'ALLONGEMENT DE L'ELEMENT
!       EFFNOM : EFFORT NORMAL PRECEDENT
!       TREF   : TEMPERATURE DE REFERENCE
!       TEMPM  : TEMPERATURE IMPOSEE A L'INSTANT PRECEDENT
!       TEMPP  : TEMPERATURE IMPOSEE A L'INSTANT COURANT
!       OPTION : OPTION DEMANDEE (R_M_T,FULL OU RAPH_MECA)
! OUT : EFFNOP : CONTRAINTE A L'INSTANT ACTUEL
!       VIP    : VARIABLE INTERNE A L'INSTANT ACTUEL
!       FONO   : FORCES NODALES COURANTES
!       KLV    : MATRICE TANGENTE
!
! --------------------------------------------------------------------------------------------------
!
    integer       :: codres(1)
    real(kind=8)  :: sigm, deps, depsth, depsm, em, ep
    real(kind=8)  :: sigp, xrig, val(1), dsde
    aster_logical :: isot, cine, elas, corr, impl, isotli, relax
!
! --------------------------------------------------------------------------------------------------
!
    elas   = .false.
    isot   = .false.
    cine   = .false.
    corr   = .false.
    impl   = .false.
    isotli = .false.
    relax  = .false.
    if       (compor(1).eq. 'ELAS') then
        elas = .true.
    else if ((compor(1) .eq. 'VMIS_ISOT_LINE') .or. &
             (compor(1) .eq. 'VMIS_ISOT_TRAC')) then
        isot = .true.
        if (compor(1) .eq. 'VMIS_ISOT_LINE') then
            isotli = .true.
        endif
        if (crildc(2) .eq. 9) then
            impl = .true.
        endif
        if (impl .and. (.not.isotli)) then
            call utmess('F', 'ELEMENTS5_50')
        endif
    else if (compor(1) .eq. 'VMIS_CINE_LINE') then
        cine = .true.
    else if (compor(1) .eq. 'CORR_ACIER') then
        corr = .true.
    else if (compor(1) .eq. 'RELAX_ACIER') then
        relax = .true.
    endif
!
    call r8inir(nbt, 0.d0, klv, 1)
    call r8inir(neq, 0.d0, fono, 1)
!
!   Récupération des caractéristiques
    deps = dlong0/xlong0
    sigm = effnom/aire
!
    if (isot .and. (.not.impl)) then
!       Caractéristiques élastiques a t-
        call rcvalb(fami,kpg,ksp,'-',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        em=val(1)
!       Caractéristiques élastiques a t+
        call rcvalb(fami,kpg,ksp,'+',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        ep=val(1)
!
        call verift(fami,kpg,ksp, 'T', imate, epsth_=depsth)
        depsm=deps-depsth
        call nm1dis(fami,kpg,ksp, imate, em, ep, sigm, depsm, vim, option,&
                    compor, ' ', sigp, vip, dsde)
    else if (cine) then
!       Caractéristiques élastiques a t-
        call rcvalb(fami,kpg,ksp,'-',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        em=val(1)
!       Caractéristiques élastiques a t+
        call rcvalb(fami,kpg,ksp,'+',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        ep=val(1)
!
        call verift(fami,kpg,ksp, 'T', imate, epsth_=depsth)
        depsm = deps-depsth
        call nm1dci(fami,kpg,ksp, imate, em, ep, sigm, depsm, vim, option,&
                    ' ', sigp, vip, dsde)
    else if (relax) then
        call verift(fami,kpg,ksp, 'T', imate, epsth_=depsth)
        depsm = deps-depsth
        call relax_acier_cable(fami,kpg,ksp, imate, sigm, epsm, depsm, vim, option,&
                               ' ', sigp, vip, dsde)
    else if (elas) then
!       Caractéristiques élastiques a t-
        call rcvalb(fami,kpg,ksp,'-',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        em=val(1)
!       Caractéristiques élastiques a t+
        call rcvalb(fami,kpg,ksp,'+',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        ep=val(1)
!
        dsde = ep
        vip(1) = 0.d0
        call verift(fami,kpg,ksp, 'T', imate, epsth_=depsth)
        sigp = ep* (sigm/em+deps-depsth)
    else if (corr) then
!       Caractéristiques élastiques a t-
        call rcvalb(fami,kpg,ksp,'-',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        em=val(1)
!       Caractéristiques élastiques a t+
        call rcvalb(fami,kpg,ksp,'+',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        ep=val(1)
!
        call nm1dco(fami,kpg,ksp, option, imate, ' ', ep, sigm, epsm, deps,&
                    vim, sigp, vip, dsde, crildc, codret)
    else if (impl) then
!       Caractéristiques élastiques a t-
        call rcvalb(fami,kpg,ksp,'-',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        em=val(1)
!       Caractéristiques élastiques a t+
        call rcvalb(fami,kpg,ksp,'+',imate,' ','ELAS', &
                    0, ' ', [0.d0], 1, 'E', val, codres, 1)
        ep=val(1)
!
        call lcimpl(fami,kpg,ksp, imate, em, ep, sigm, tmoins, tplus, deps,&
                    vim, option, sigp, vip, dsde)
    else
        call utmess('F', 'ALGORITH6_87')
    endif
!
!   Calcul du coefficient non nul de la matrice tangente
    if (option(1:10) .eq. 'RIGI_MECA_' .or. option(1:9) .eq. 'FULL_MECA') then
        xrig    =  dsde*aire/xlong0
        klv(1)  =  xrig
        klv(7)  = -xrig
        klv(10) =  xrig
    endif
!
!   Calcul des forces nodales
    if (option(1:14) .eq. 'RAPH_MECA' .or. option(1:9) .eq. 'FULL_MECA') then
        effnop  =  sigp*aire
        fono(1) = -effnop
        fono(4) =  effnop
    endif
!
    if (option(1:16) .eq. 'RIGI_MECA_IMPLEX') then
        if ((.not.impl) .and. (.not.elas)) then
            call utmess('F', 'ELEMENTS5_49')
        endif
        effnop  =  sigp*aire
        fono(1) = -effnop
        fono(4) =  effnop
    endif
!
end subroutine
