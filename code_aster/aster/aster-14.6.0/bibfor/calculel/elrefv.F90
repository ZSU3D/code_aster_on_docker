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

subroutine elrefv(nomte, famil, ndim, nno, nno2,&
                  nnos, npg, ipoids, ivf, ivf2,&
                  idfde, idfde2, jgano, jgano2)
    implicit none
#include "asterfort/elref1.h"
#include "asterfort/elrefe_info.h"
    character(len=16) :: nomte
    character(len=4) :: famil
    integer :: ndim, nno, nnos, npg, ipoids, ivf, idfde, jgano
    integer :: nno2, ivf2, idfde2, jgano2
!
!
! ---------------------------------------------------------------------
! BUT: RECUPERER DANS UNE ROUTINE TE00IJ LES ADRESSES DANS ZR
!      - DES POIDS DES POINTS DE GAUSS  : IPOIDS
!      - DES VALEURS DES FONCTIONS DE FORME : IVF
!      - DES VALEURS DES DERIVEES 1ERES DES FONCTIONS DE FORME : IDFDE
!      - DE LA MATRICE DE PASSAGE GAUSS -> NOEUDS : JGANO
! ---------------------------------------------------------------------
!   IN   NOMTE        -->  NOM DU TYPE ELEMENT
!        FAMIL  : NOM (LOCAL) DE LA FAMILLE DE POINTS DE GAUSS :
!                 'STD','RICH',...
!   OUT  NDIM   : DIMENSION DE L'ESPACE (=NB COORDONNEES)
!        NNO    : NOMBRE DE NOEUDS DU TYPE_MAILLE 1
!                 (DEPLACEMENT QUADRATIQUE)
!        NNO2   : NOMBRE DE NOEUDS DU TYPE_MAILLE 2
!                 (VARIABLE INETERNE + LAGRANGE LINEAIRE)
!        NNOS   : NOMBRE DE NOEUDS SOMMETS DU TYPE_MAILLE
!        NPG    : NOMBRE DE POINTS DE GAUSS
!        IPOIDS : ADRESSE DANS ZR DU TABLEAU POIDS(IPG)
!        IVF    : ADRESSE DANS ZR DU TABLEAU FF(INO,IPG) TYPE_MAILLE 1
!        IVF2   : ADRESSE DANS ZR DU TABLEAU FF(INO2,IPG) TYPE_MAILLE 2
!        IDFDE  : ADRESSE DANS ZR DU TABLEAU DFF(IDIM,INO,IPG)
!        IDFDE2 : ADRESSE DANS ZR DU TABLEAU DFF(IDIM,INO2,IPG)
!        JGANO  : ADRESSE DANS ZR DE LA MATRICE DE PASSAGE
!                      GAUSS -> NOEUDS (DIM= 2+NNO*NPG)
!                 ATTENTION : LES 2 1ERS TERMES SONT LES
!                             DIMMENSIONS DE LA MATRICE: NNO ET NPG
!        JGANO2  : ADRESSE DANS ZR DE LA MATRICE DE PASSAGE
!                      GAUSS -> NOEUDS (DIM= 2+NNO2*NPG)
!                 ATTENTION : LES 2 1ERS TERMES SONT LES
!                             DIMMENSIONS DE LA MATRICE: NNO2 ET NPG
!   -------------------------------------------------------------------
    character(len=8) :: elrefe, elref2
!
!
    call elref1(elrefe)
!
    call elrefe_info(elrefe=elrefe,fami=famil,ndim=ndim,nno=nno,nnos=nnos,&
  npg=npg,jpoids=ipoids,jvf=ivf,jdfde=idfde,jgano=jgano)
!
    if (elrefe .eq. 'TR3' .or. elrefe .eq. 'QU4') then
!
! --- CAS LINEAIRE
!
        call elrefe_info(elrefe=elrefe,fami=famil,ndim=ndim,nno=nno2,nnos=nnos,&
  npg=npg,jpoids=ipoids,jvf=ivf2,jdfde=idfde2,jgano=jgano2)
    else
!
! --- CAS QUADRATIQUE
!
        if (elrefe .eq. 'TR6') then
            elref2 = 'TR3'
        else if (elrefe .eq. 'QU8') then
            elref2 = 'QU4'
        else if (elrefe .eq. 'H20') then
            elref2 = 'HE8'
        else if (elrefe .eq. 'T10') then
            elref2 = 'TE4'
        else if (elrefe .eq. 'P15') then
            elref2 = 'PE6'
        else if (elrefe .eq. 'S15') then
            elref2 = 'SH6'
        else if (elrefe .eq. 'P13') then
            elref2 = 'PY5'
        endif
        call elrefe_info(elrefe=elref2,fami=famil,ndim=ndim,nno=nno2,nnos=nnos,&
  npg=npg,jpoids=ipoids,jvf=ivf2,jdfde=idfde2,jgano=jgano2)
    endif
!
!
end subroutine
