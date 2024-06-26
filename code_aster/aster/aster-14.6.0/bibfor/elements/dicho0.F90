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

subroutine dicho0(option, nomte, ndim, nbt, nno,&
                  nc, ulm, dul, pgl, iret)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/r8prem.h"
#include "asterfort/dichoc.h"
#include "asterfort/dis_contact.h"
#include "asterfort/infdis.h"
#include "asterfort/jevech.h"
#include "asterfort/pmavec.h"
#include "asterfort/tecach.h"
#include "asterfort/ut2mgl.h"
#include "asterfort/ut2mlg.h"
#include "asterfort/ut2vgl.h"
#include "asterfort/ut2vlg.h"
#include "asterfort/utpsgl.h"
#include "asterfort/utpslg.h"
#include "asterfort/utpnlg.h"
#include "asterfort/utpvgl.h"
#include "asterfort/utpvlg.h"
#include "asterfort/vecma.h"
#include "asterfort/rcvala.h"
#include "asterfort/r8inir.h"
#include "asterfort/utmess.h"
#include "blas/dcopy.h"
!
    character(len=*) :: option, nomte
    integer :: ndim, nbt, nno, nc, iret
    real(kind=8) :: ulm(12), dul(12), pgl(3, 3)
!
! person_in_charge: jean-luc.flejou at edf.fr
! --------------------------------------------------------------------------------------------------
!
!  IN
!     option   : option de calcul
!     nomte    : nom terme élémentaire
!     ndim     : dimension du problème
!     nbt      : nombre de terme dans la matrice de raideur
!     nno      : nombre de noeuds de l'élément
!     nc       : nombre de composante par noeud
!     ulm      : déplacement moins
!     dul      : incrément de déplacement
!     pgl      : matrice de passage de global a local
!
! --------------------------------------------------------------------------------------------------
!
    integer :: jdc, irep, imat, ivarim, ii, jinst, ivitp, idepen, iviten, neq, igeom, ivarip
    integer :: iretlc, ifono
    integer :: icontm, icontp, nbre1, nbpar
    parameter     (nbre1=1)
    real(kind=8) :: r8bid, klv(78), varmo(8), varpl(8), dvl(12), dpe(12), dve(12), ulp(12), duly
    real(kind=8) :: force(3)
    real(kind=8) :: klc(144), fl(12)
    aster_logical :: statique
    character(len=8) :: k8bid
    real(kind=8) :: valre1(nbre1), valpar, coulom
    integer :: codre1(nbre1)
    character(len=8) :: nompar, nomre1(nbre1)
!
    data nomre1 /'COULOMB'/
!
!   paramètres en entrée
    call jevech('PCADISK', 'L', jdc)
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PCONTMR', 'L', icontm)
!
    call infdis('REPK', irep, r8bid, k8bid)
!   absolu vers local ? ---
!   irep = 1 = matrice en repère global ==> passer en local ---
    if (irep .eq. 1) then
        if (ndim .eq. 3) then
            call utpsgl(nno, nc, pgl, zr(jdc), klv)
        else if (ndim.eq.2) then
            call ut2mgl(nno, nc, pgl, zr(jdc), klv)
        endif
    else
        call dcopy(nbt, zr(jdc), 1, klv, 1)
    endif
    call jevech('PMATERC', 'L', imat)
    call jevech('PVARIMR', 'L', ivarim)
!
    do ii = 1, 8
        varmo(ii) = zr(ivarim+ii-1)
    enddo
!
    call jevech('PINSTPR', 'L', jinst)
!
    statique = .false.
    call tecach('ONO', 'PVITPLU', 'L', iretlc, iad=ivitp)
    if (iretlc .eq. 0) then
        if (ndim .eq. 3) then
            call utpvgl(nno, nc, pgl, zr(ivitp), dvl)
        else if (ndim.eq.2) then
            call ut2vgl(nno, nc, pgl, zr(ivitp), dvl)
        endif
    else
        dvl(:) = 0
        nbpar = 0
        nompar = ' '
        valpar = 0.d0
        call r8inir(nbre1, 0.d0, valre1, 1)
! ---    CARACTERISTIQUES DU MATERIAU
        call rcvala(zi(imat), ' ', 'DIS_CONTACT', nbpar, nompar,&
                    [valpar], nbre1, nomre1, valre1, codre1,&
                    0)
        coulom = valre1(1)
        if (coulom .ne. 0.d0) statique = .true.
    endif
    if (statique) then
        if ((nomte.ne.'MECA_DIS_T_N') .and. (nomte.ne.'MECA_DIS_T_L')) then
            call utmess('F', 'DISCRETS_50', nk=1, valk=nomte)
        endif
    endif
!
    call tecach('ONO', 'PDEPENT', 'L', iretlc, iad=idepen)
    if (iretlc .eq. 0) then
        if (ndim .eq. 3) then
            call utpvgl(nno, nc, pgl, zr(idepen), dpe)
        else if (ndim.eq.2) then
            call ut2vgl(nno, nc, pgl, zr(idepen), dpe)
        endif
    else
        dpe(:) = 0.0d0
    endif
!
    call tecach('ONO', 'PVITENT', 'L', iretlc, iad=iviten)
    if (iretlc .eq. 0) then
        if (ndim .eq. 3) then
            call utpvgl(nno, nc, pgl, zr(iviten), dve)
        else if (ndim.eq.2) then
            call ut2vgl(nno, nc, pgl, zr(iviten), dve)
        endif
    else
        dve(:) = 0.d0
    endif
!
    neq = nno*nc
    ulp(:) = ulm(:) + dul(:)
!   relation de comportement de choc
    if (statique) then
        call dis_contact(ndim, nno, nc, zi(imat), ulp,&
                         zr(igeom), pgl, force, klv, option,&
                         varmo, varpl)
    else
        call dichoc(nbt, neq, nno, nc, zi(imat),&
                    dul, ulp, zr(igeom), pgl, klv,&
                    duly, dvl, dpe, dve, force,&
                    varmo, varpl, ndim)
    endif
!   actualisation de la matrice tangente
    if (option .eq. 'FULL_MECA' .or. option .eq. 'RIGI_MECA_TANG') then
        if (statique) then
            call jevech('PMATUNS', 'E', imat)
            call utpnlg(nno, ndim, pgl, klv, zr(imat))
        else
            call jevech('PMATUUR', 'E', imat)
            if (ndim .eq. 3) then
                call utpslg(nno, nc, pgl, klv, zr(imat))
            else if (ndim.eq.2) then
                call ut2mlg(nno, nc, pgl, klv, zr(imat))
            endif
        endif
    endif
!
!   calcul des efforts généralisés, des forces nodales et des variables internes
    if (option .eq. 'FULL_MECA' .or. option .eq. 'RAPH_MECA') then
        call jevech('PVECTUR', 'E', ifono)
        call jevech('PCONTPR', 'E', icontp)
!       demi-matrice klv transformée en matrice pleine klc
        call vecma(klv, nbt, klc, neq)
!       calcul de fl = klc.dul (incrément d'effort)
        call pmavec('ZERO', neq, klc, dul, fl)
!       efforts généralisés aux noeuds 1 et 2 (repère local)
!       on change le signe des efforts sur le premier noeud pour les MECA_DIS_TR_L et MECA_DIS_T_L
        if (nno .eq. 1) then
            do ii = 1, neq
                zr(icontp-1+ii) = fl(ii) + zr(icontm-1+ii)
                fl(ii) = fl(ii) + zr(icontm-1+ii)
            enddo
        else if (nno.eq.2) then
            do ii = 1, nc
                zr(icontp-1+ii) = -fl(ii) + zr(icontm-1+ii)
                zr(icontp-1+ii+nc) = fl(ii+nc) + zr(icontm-1+ii+nc)
                fl(ii) = fl(ii) - zr(icontm-1+ii)
                fl(ii+nc) = fl(ii+nc) + zr(icontm-1+ii+nc)
            enddo
        endif
        if (nno .eq. 1) then
            zr(icontp-1+1) = force(1)
            zr(icontp-1+2) = force(2)
            fl(1) = force(1)
            fl(2) = force(2)
            if (ndim .eq. 3) then
                fl(3) = force(3)
                zr(icontp-1+3) = force(3)
            endif
        else if (nno.eq.2) then
            zr(icontp-1+1) = force(1)
            zr(icontp-1+1+nc) = force(1)
            zr(icontp-1+2) = force(2)
            zr(icontp-1+2+nc) = force(2)
            fl(1) = -force(1)
            fl(1+nc) = force(1)
            fl(2) = -force(2)
            fl(2+nc) = force(2)
            if (ndim .eq. 3) then
                zr(icontp-1+3) = force(3)
                zr(icontp-1+3+nc) = force(3)
                fl(3) = -force(3)
                fl(3+nc) = force(3)
            endif
        endif
        if (abs(force(1)) .lt. r8prem()) then
            do ii = 1, neq
                fl(ii) = 0.0d0
                zr(icontp-1+ii) = 0.0d0
            enddo
        endif
!       forces nodales aux noeuds 1 et 2 (repère global)
        if (nc .ne. 2) then
            call utpvlg(nno, nc, pgl, fl, zr(ifono))
        else
            call ut2vlg(nno, nc, pgl, fl, zr(ifono))
        endif
!       mise a jour des variables internes
        call jevech('PVARIPR', 'E', ivarip)
        do ii = 1, 8
            zr(ivarip+ii-1) = varpl(ii)
            if (nno .eq. 2) zr(ivarip+ii+7) = varpl(ii)
        enddo
    endif
end subroutine
