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

subroutine te0049(option, nomte)
    implicit none
#include "jeveux.h"
#include "asterfort/bsigmc.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/epsimc.h"
#include "asterfort/jevech.h"
#include "asterfort/nbsigm.h"
#include "asterfort/ortrep.h"
#include "asterfort/sigimc.h"
#include "asterfort/tecach.h"
    character(len=16) :: option, nomte
!.......................................................................
!
!     BUT: CALCUL DES VECTEURS ELEMENTAIRES EN MECANIQUE
!          ELEMENTS ISOPARAMETRIQUES 3D
!
!          OPTION : 'CHAR_MECA_EPSI_R  ' ET 'CHAR_MECA_EPSI_F  '
!
!     ENTREES  ---> OPTION : OPTION DE CALCUL
!              ---> NOMTE  : NOM DU TYPE ELEMENT
!.......................................................................
!
    real(kind=8) :: sigi(162), epsi(162), bsigma(81), repere(7)
    real(kind=8) :: instan, nharm, bary(3)
    integer :: idim
!
! ---- CARACTERISTIQUES DU TYPE D'ELEMENT :
! ---- GEOMETRIE ET INTEGRATION
!      ------------------------
!-----------------------------------------------------------------------
    integer :: i, idfde, igeom, imate, ipoids, iret, itemps
    integer :: ivectu, ivf, jgano, nbsig, ndim, nno, nnos
    integer :: npg1
    real(kind=8) :: zero
!-----------------------------------------------------------------------
    call elrefe_info(fami='RIGI',ndim=ndim,nno=nno,nnos=nnos,&
  npg=npg1,jpoids=ipoids,jvf=ivf,jdfde=idfde,jgano=jgano)
!
! --- INITIALISATIONS :
!     -----------------
    zero = 0.0d0
    instan = zero
    nharm = zero
!
! ---- NOMBRE DE CONTRAINTES ASSOCIE A L'ELEMENT
!      -----------------------------------------
    nbsig = nbsigm()
!
    do 10 i = 1, nbsig*npg1
        epsi(i) = zero
        sigi(i) = zero
10  end do
!
    do 20 i = 1, ndim*nno
        bsigma(i) = zero
20  end do
!
! ---- RECUPERATION DES COORDONNEES DES CONNECTIVITES
!      ----------------------------------------------
    call jevech('PGEOMER', 'L', igeom)
!
! ---- RECUPERATION DU MATERIAU
!      ------------------------
    call jevech('PMATERC', 'L', imate)
!
! ---- RECUPERATION  DES DONNEEES RELATIVES AU REPERE D'ORTHOTROPIE
!      ------------------------------------------------------------
!     COORDONNEES DU BARYCENTRE ( POUR LE REPRE CYLINDRIQUE )
!
    bary(1) = 0.d0
    bary(2) = 0.d0
    bary(3) = 0.d0
    do 150 i = 1, nno
        do 140 idim = 1, ndim
            bary(idim) = bary(idim)+zr(igeom+idim+ndim*(i-1)-1)/nno
140      continue
150  end do
    call ortrep(ndim, bary, repere)
!
! ---- RECUPERATION DE L'INSTANT
!      -------------------------
    call tecach('NNO', 'PTEMPSR', 'L', iret, iad=itemps)
    if (itemps .ne. 0) instan = zr(itemps)
!
! ---- CONSTRUCTION DU VECTEUR DES DEFORMATIONS INITIALES DEFINIES AUX
! ---- POINTS D'INTEGRATION A PARTIR DES DONNEES UTILISATEUR
!      -----------------------------------------------------
    call epsimc(option, zr(igeom), nno, npg1, ndim,&
                nbsig, zr(ivf), epsi)
!
! ---- CALCUL DU VECTEUR DES CONTRAINTES INITIALES AUX POINTS
! ---- D'INTEGRATION
!      -------------
    call sigimc('RIGI', nno, ndim, nbsig, npg1,&
                zr(ivf), zr(igeom), instan, zi(imate), repere,&
                epsi, sigi)
!
! ---- CALCUL DU VECTEUR DES FORCES DUES AUX CONTRAINTES INITIALES
! ---- (I.E. BT*SIG_INITIALES)
!      ----------------------
    call bsigmc(nno, ndim, nbsig, npg1, ipoids,&
                ivf, idfde, zr(igeom), nharm, sigi,&
                bsigma)
!
! ---- RECUPERATION ET AFFECTATION DU VECTEUR EN SORTIE AVEC LE
! ---- VECTEUR DES FORCES DUES AUX CONTRAINTES INITIALES
!      -------------------------------------------------
    call jevech('PVECTUR', 'E', ivectu)
!
    do 30 i = 1, ndim*nno
        zr(ivectu+i-1) = bsigma(i)
30  end do
!
! FIN ------------------------------------------------------------------
end subroutine
