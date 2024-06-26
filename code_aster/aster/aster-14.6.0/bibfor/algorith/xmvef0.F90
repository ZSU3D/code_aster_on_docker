! --------------------------------------------------------------------
! Copyright (C) 1991 - 2018 - EDF R&D - www.code-aster.org
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

subroutine xmvef0(ndim, jnne, nnc,&
                  hpg, ffc, jacobi, lpenac,&
                  dlagrf, tau1, tau2,&
                  jddle, nfhe, lmulti, heavno,&
                  vtmp)
!
!
! aslint: disable=W1504
    implicit none
#include "asterf_types.h"
#include "asterfort/xplma2.h"
    integer :: ndim, nnc, jnne(3), jddle(2)
    real(kind=8) :: hpg, ffc(9), jacobi
    real(kind=8) :: dlagrf(2)
    real(kind=8) :: tau1(3), tau2(3)
    real(kind=8) :: vtmp(336)
    integer :: nfhe, heavno(8)
    aster_logical :: lpenac, lmulti
!
! ----------------------------------------------------------------------
!
! ROUTINE CONTACT (METHODE XFEMGG - CALCUL ELEM.)
!
! CALCUL DU SECOND MEMBRE POUR LE FROTTEMENT
! CAS SANS CONTACT (XFEM)
!
! ----------------------------------------------------------------------
! ROUTINE SPECIFIQUE A L'APPROCHE <<GRANDS GLISSEMENTS AVEC XFEM>>,
! TRAVAIL EFFECTUE EN COLLABORATION AVEC I.F.P.
! ----------------------------------------------------------------------
!
! IN  NDIM   : DIMENSION DU PROBLEME
! IN  NNE    : NOMBRE DE NOEUDS DE LA MAILLE ESCLAVE
! IN  HPG    : POIDS DU POINT INTEGRATION DU POINT DE CONTACT
! IN  FFC    : FONCTIONS DE FORME DU POINT DE CONTACT
! IN  JACOBI : JACOBIEN DE LA MAILLE AU POINT DE CONTACT
! IN  LAMBD  : LAGRANGE DE CONTACT ET FROTTEMENT AU POINT D'INTÉGRATION
! IN  TAU1   : PREMIER VECTEUR TANGENT
! IN  TAU2   : DEUXIEME VECTEUR TANGENT
! IN  DDLES : NOMBRE DE DDLS D'UN NOEUD SOMMET ESCLAVE
! I/O VTMP   : VECTEUR SECOND MEMBRE ELEMENTAIRE DE CONTACT/FROTTEMENT
! ----------------------------------------------------------------------
!
    integer :: i, l, ii, pl, nne, nnes, ddles
    real(kind=8) :: tt(3), t
! ----------------------------------------------------------------------
!
! --- INITIALISATIONS
!
    nne=jnne(1)
    nnes=jnne(2)
    ddles=jddle(1)
!
    tt(:) = 0.d0
!
! --- CALCUL DE T.T
!
    do i = 1, ndim
        t = dlagrf(1)*tau1(i)+dlagrf(2)*tau2(i)
        tt(1) = t*tau1(i)+tt(1)
        if (ndim .eq. 3) tt(2) = t*tau2(i)+tt(2)
    end do
!
! --------------------- CALCUL DE {L3_FROT}----------------------------
!
    do i = 1, nnc
        call xplma2(ndim, nne, nnes, ddles, i,&
                    nfhe, pl)
        if (lmulti) pl = pl + (heavno(i)-1)*ndim
        do l = 1, ndim-1
            ii = pl+l
            if (lpenac) then
                vtmp(ii)= vtmp(ii)+jacobi*hpg*ffc(i)*tt(l)
            else
                vtmp(ii)= vtmp(ii)+jacobi*hpg*ffc(i)*tt(l)
            endif
        end do
    end do
!
end subroutine
