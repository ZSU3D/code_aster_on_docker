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

subroutine te0573(option, nomte)
!
! person_in_charge: mickael.abbas at edf.fr
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
!
#include "asterfort/assert.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/nmpr2d.h"
#include "blas/dcopy.h"
    character(len=16) :: nomte, option
!
! ----------------------------------------------------------------------
!
! ROUTINE CALCUL ELEMENTAIRE
!
! CALCUL DES OPTIONS ELEMENTAIRES EN MECANIQUE CORRESPONDANT A UN
! CHARGEMENT EN PRESSION SUIVEUSE SUR DES ARETES D'ELEMENTS
! ISOPARAMETRIQUES 2D
!
! LA PRESSION EST UNE CONSTANTE RELLE
!
! ----------------------------------------------------------------------
!
!
! IN  OPTION : OPTION DE CALCUL
!               CHAR_MECA_PRSU_R
!               RIGI_MECA_PRSU_R
! IN  NOMTE  : NOM DU TYPE ELEMENT
!
!
!
!
!
    integer :: mxnoeu, mxnpg, mxvect, mxmatr
    parameter     (mxnoeu=3,mxnpg=4,mxvect=2*3,mxmatr=2*3*2*3)
!
    aster_logical :: laxi
    integer :: ndim, nno, npg, nnos, nddl
    integer :: iddl, ino, ipg
    integer :: jpoids, jvf, jdf, jgano
    integer :: jvect, jmatr
    integer :: jgeom, jdepm, jdepp, jpres
    integer :: kdec, i, j, k
!
    real(kind=8) :: p(2, mxnpg)
    real(kind=8) :: vect(mxvect), matr(mxmatr)
!
! ----------------------------------------------------------------------
!
!
! --- CARACTERISTIQUES ELEMENT
!
    laxi = lteatt('AXIS','OUI')
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nno, nnos=nnos, npg=npg,&
                     jpoids=jpoids, jvf=jvf, jdfde=jdf, jgano=jgano)
    nddl = 2*nno
    ASSERT(nno .le.mxnoeu)
    ASSERT(npg .le.mxnpg)
!
! --- ACCES CHAMPS
!
    call jevech('PGEOMER', 'L', jgeom)
    call jevech('PDEPLMR', 'L', jdepm)
    call jevech('PDEPLPR', 'L', jdepp)
    call jevech('PPRESSR', 'L', jpres)
!
! --- REACTUALISATION DE LA GEOMETRIE PAR LE DEPLACEMENT
!
    do 10 iddl = 1, nddl
        zr(jgeom+iddl-1) = zr(jgeom+iddl-1) + zr(jdepm+iddl-1) + zr(jdepp+iddl-1)
 10 end do
!
! --- CALCUL DE LA PRESSION AUX POINTS DE GAUSS (A PARTIR DES NOEUDS)
!
    do 100 ipg = 1, npg
        kdec = (ipg-1) * nno
        p(1,ipg) = 0.d0
        p(2,ipg) = 0.d0
        do 105 ino = 1, nno
            p(1,ipg) = p(1,ipg) + zr(jpres+2*(ino-1)+1-1) * zr(jvf+ kdec+ino-1)
            p(2,ipg) = p(2,ipg) + zr(jpres+2*(ino-1)+2-1) * zr(jvf+ kdec+ino-1)
105     continue
100 end do
!
! --- CALCUL EFFECTIF DE LA RIGIDITE
!
    if (option .eq. 'CHAR_MECA_PRSU_R') then
        call nmpr2d(1, laxi, nno, npg, zr(jpoids),&
                    zr(jvf), zr(jdf), zr( jgeom), p, vect,&
                    matr)
!
! --- RECOPIE DU VECTEUR ELEMENTAIRE
!
        call jevech('PVECTUR', 'E', jvect)
        call dcopy(nddl, vect, 1, zr(jvect), 1)
!
    else if (option.eq.'RIGI_MECA_PRSU_R') then
        call nmpr2d(2, laxi, nno, npg, zr(jpoids),&
                    zr(jvf), zr(jdf), zr( jgeom), p, vect,&
                    matr)
!
! --- RECOPIE DE LA MATRICE ELEMENTAIRE (NON-SYMETRIQUE)
! --- LES MATRICES NON SYMETRIQUES SONT ENTREES EN LIGNE
!
        call jevech('PMATUNS', 'E', jmatr)
        k = 0
        do 110 i = 1, nddl
            do 120 j = 1, nddl
                k = k + 1
                zr(jmatr-1+k) = matr((j-1)*nddl+i)
120         continue
110     end do
        ASSERT(k.eq.nddl*nddl)
!
    else
        ASSERT(.false.)
    endif
!
end subroutine
