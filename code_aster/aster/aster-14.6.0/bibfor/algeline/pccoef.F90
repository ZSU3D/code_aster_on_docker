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

subroutine pccoef(n, in, ip, ac, icpl,&
                  icpc, acpc, cx)
!
!   ENTREE
!   N          : TAILLE DE A
!   IN,IP,AC   : MATRICE D'ENTREE FORMAT SYMETRIQUE
!   CX         : TRAVAIL
!   ICPL       : IDEM IN POUR LA MATRICE DE PRECOND.
!   ICPC       : IDEM IP POUR LA MATRICE DE PRECOND.
!
!   SORTIE
!   ACPC       : COEFS DE LA MATRICE DE PRECOND.
!--------------------------------------------------------
! aslint: disable=W1304
    implicit none
#include "jeveux.h"
#include "asterfort/jedetr.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
    real(kind=8) :: ac(*)
    integer :: n
    integer :: in(n)
    integer(kind=4) :: ip(*), icpc(*)
    real(kind=8) :: acpc(*), cx(n)
    integer :: icpl(0:n)
!----------------------------------------------------------------------
!
! AC ---> ACPC
! ==========================
!-----------------------------------------------------------------------
    integer :: i, j,  k, k1, k2
    integer :: kk, kk1, kk2
    integer, pointer :: ind(:) => null()
!-----------------------------------------------------------------------
    kk2 = icpl(n-1)
    do 10 kk = 1, kk2
        acpc(kk) = 0.d0
10  end do
    AS_ALLOCATE(vi=ind, size=n)
!
    acpc(1) = ac(1)
    do 40 i = 2, n
!  LIGNE CREUSE I DE AC --> LIGNE PLEINE IND-CX
!                          (ICPL(I-1)=FIN LIGNE I)
        k1 = in(i-1) + 1
        k2 = in(i)
        do 20 k = k1, k2 - 1
            j = ip(k)
            ind(j) = i
            cx(j) = ac(k)
20      continue
        kk1 = icpl(i-2) + 1
        kk2 = icpl(i-1)
        do 30 kk = kk1, kk2 - 1
            j = icpc(kk)
            if (ind(j) .eq. i) acpc(kk) = cx(j)
30      continue
        acpc(kk2) = ac(k2)
40  end do
!
    AS_DEALLOCATE(vi=ind)
!
end subroutine
