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

subroutine te0047(optioz, nomtez)
    implicit none
#include "jeveux.h"
#include "asterfort/diarm0.h"
#include "asterfort/dibili.h"
#include "asterfort/dicho0.h"
#include "asterfort/dicora.h"
#include "asterfort/diecci.h"
#include "asterfort/dielas.h"
#include "asterfort/digou2.h"
#include "asterfort/digric.h"
#include "asterfort/diisotrope.h"
#include "asterfort/dizeng.h"
#include "asterfort/infdis.h"
#include "asterfort/infted.h"
#include "asterfort/jevech.h"
#include "asterfort/matrot.h"
#include "asterfort/tecach.h"
#include "asterfort/tecael.h"
#include "asterfort/ut2vgl.h"
#include "asterfort/utmess.h"
#include "asterfort/utpvgl.h"
#include "blas/dcopy.h"
!
    character(len=16) :: option, nomte
    character(len=*) :: optioz, nomtez
!
! person_in_charge: jean-luc.flejou at edf.fr
! --------------------------------------------------------------------------------------------------
!
!         COMPORTEMENT LINEAIRE ET NON-LINEAIRE POUR LES DISCRETS
!
! --------------------------------------------------------------------------------------------------
!
! elements concernes
!     MECA_DIS_TR_L     : sur une maille a 2 noeuds
!     MECA_DIS_T_L      : sur une maille a 2 noeuds
!     MECA_DIS_TR_N     : sur une maille a 1 noeud
!     MECA_DIS_T_N      : sur une maille a 1 noeud
!     MECA_2D_DIS_TR_L  : sur une maille a 2 noeuds
!     MECA_2D_DIS_T_L   : sur une maille a 2 noeuds
!     MECA_2D_DIS_TR_N  : sur une maille a 1 noeud
!     MECA_2D_DIS_T_N   : sur une maille a 1 noeud
!
! CALCUL DES OPTIONS
!           FULL_MECA   RAPH_MECA   RIGI_MECA_TANG  RIGI_MECA_ELAS  FULL_MECA_ELAS
!   MATR       OUI                     OUI             OUI               OUI
!   FORC       OUI         OUI
!   VINT       OUI         OUI
!   DUL                                0.0
!
! --------------------------------------------------------------------------------------------------
!
!   IN
!       optioz : nom de l'option a calculer
!       nomtez : nom du type_element
!
! --------------------------------------------------------------------------------------------------
!
    real(kind=8) :: ang(3), pgl(3, 3)
    real(kind=8) :: ugm(12), dug(12), ulm(12), dul(12)
    real(kind=8) :: r8bid
!
    integer :: nbt, nno, nc, neq, igeom, ideplm, ideplp, icompo
    integer :: ii, ndim, jcret, itype, lorien
    integer :: iadzi, iazk24, ibid, infodi, iret
!
    character(len=8) :: k8bid
    character(len=24) :: messak(5)
!
! --------------------------------------------------------------------------------------------------
!
    option = optioz
    nomte = nomtez
!   on vérifie que les caractéristiques ont été affectées
!   le code du discret
    call infdis('CODE', ibid, r8bid, nomte)
!   le code stocké dans la carte
    call infdis('TYDI', infodi, r8bid, k8bid)
    if (infodi .ne. ibid) then
        call utmess('F+', 'DISCRETS_25', sk=nomte)
        call infdis('DUMP', ibid, r8bid, 'F+')
    endif
!   discret de type raideur
    call infdis('DISK', infodi, r8bid, k8bid)
    if (infodi .eq. 0) then
        call utmess('A+', 'DISCRETS_27', sk=nomte)
        call infdis('DUMP', ibid, r8bid, 'A+')
    endif
!   les discrets sont obligatoirement symétriques
    call infdis('SYMK', infodi, r8bid, k8bid)
    if (infodi .ne. 1) then
        call utmess('F', 'DISCRETS_40')
    endif
!   informations sur les discrets :
!       nbt   = nombre de coefficients dans k
!       nno   = nombre de noeuds
!       nc    = nombre de composante par noeud
!       ndim  = dimension de l'élément
!       itype = type de l'élément
    call infted(nomte, infodi, nbt, nno, nc,&
                ndim, itype)
    neq = nno*nc
!   récupération des adresses jeveux
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PDEPLMR', 'L', ideplm)
    call jevech('PDEPLPR', 'L', ideplp)
!   récupération des infos concernant les comportements :
!       zk16(icompo)      NOM_DU_COMPORTEMENT
!       zk16(icompo+1)    nbvar = read (zk16(icompo+1),'(i16)')
!       zk16(icompo+2)    petit   PETIT_REAC  GROT_GDEP
!       zk16(icompo+3)    COMP_ELAS   COMP_INCR
    call jevech('PCOMPOR', 'L', icompo)
    if (zk16(icompo+2) .ne. 'PETIT') then
        call utmess('A', 'DISCRETS_18')
    endif
!   si COMP_ELAS alors comportement elas
    if ((zk16(icompo+3).eq.'COMP_ELAS') .and. (zk16(icompo).ne.'ELAS')) then
        messak(1) = nomte
        messak(2) = option
        messak(3) = zk16(icompo+3)
        messak(4) = zk16(icompo)
        call tecael(iadzi, iazk24)
        messak(5) = zk24(iazk24-1+3)
        call utmess('F', 'DISCRETS_8', nk=5, valk=messak)
    endif
!   dans les cas *_ELAS, les comportements qui ont une matrice de
!   décharge sont : elas DIS_GRICRA. pour tous les autres cas : <f>
    if ((option(10:14).eq.'_ELAS') .and. (zk16(icompo).ne.'ELAS') .and.&
        (zk16(icompo).ne.'DIS_GRICRA')) then
        messak(1) = nomte
        messak(2) = option
        messak(3) = zk16(icompo+3)
        messak(4) = zk16(icompo)
        call tecael(iadzi, iazk24)
        messak(5) = zk24(iazk24-1+3)
        call utmess('F', 'DISCRETS_10', nk=5, valk=messak)
    endif
!
!   récupération des orientations (angles nautiques -> vecteur ang)
!   orientation de l'élément et déplacements dans les repères g et l
    call tecach('ONO', 'PCAORIE', 'L', iret, iad=lorien)
    if (iret .ne. 0) then
        messak(1) = nomte
        messak(2) = option
        messak(3) = zk16(icompo+3)
        messak(4) = zk16(icompo)
        call tecael(iadzi, iazk24)
        messak(5) = zk24(iazk24-1+3)
        call utmess('F', 'DISCRETS_6', nk=5, valk=messak)
    endif
    call dcopy(3, zr(lorien), 1, ang, 1)
!   déplacements dans le repère global :
!       ugm = déplacement précédent
!       dug = incrément de déplacement
    do ii = 1, neq
        ugm(ii) = zr(ideplm+ii-1)
        dug(ii) = zr(ideplp+ii-1)
    enddo
!
!   matrice mgl de passage repère global -> repère local
    call matrot(ang, pgl)
!   déplacements dans le repère local :
!       ulm = déplacement précédent    = pgl * ugm
!       dul = incrément de déplacement = pgl * dug
    if (ndim .eq. 3) then
        call utpvgl(nno, nc, pgl, ugm, ulm)
        call utpvgl(nno, nc, pgl, dug, dul)
    else if (ndim.eq.2) then
        call ut2vgl(nno, nc, pgl, ugm, ulm)
        call ut2vgl(nno, nc, pgl, dug, dul)
    endif
!
    iret = 0
    if (zk16(icompo) .eq. 'ELAS') then
!       comportement élastique
        call dielas(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'DIS_VISC') then
!       comportement DIS_ZENER
        call dizeng(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'DIS_ECRO_TRAC') then
!       comportement ISOTROPE
        call diisotrope(option, nomte, ndim, nbt, nno,&
                        nc, ulm, dul, pgl, iret)
    else if (zk16(icompo)(1:10).eq.'DIS_GOUJ2E') then
!       comportement DIS_GOUJON : application : gouj2ech
        call digou2(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'ARME') then
!       comportement armement
        call diarm0(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'ASSE_CORN') then
!       comportement CORNIÈRE
        call dicora(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'DIS_GRICRA') then
!       comportement DIS_GRICRA : liaison grille-crayon combu
        call digric(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'DIS_CHOC') then
!       comportement choc
        call dicho0(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'DIS_ECRO_CINE') then
!       comportement DIS_ECRO_CINE : DISCRET_NON_LINE
        call diecci(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else if (zk16(icompo).eq.'DIS_BILI_ELAS') then
!       comportement DIS_BILI_ELAS : DISCRET_NON_LINE
        call dibili(option, nomte, ndim, nbt, nno,&
                    nc, ulm, dul, pgl, iret)
    else
!       si on passe par ici c'est qu'aucun comportement n'est valide
        messak(1) = nomte
        messak(2) = option
        messak(3) = zk16(icompo+3)
        messak(4) = zk16(icompo)
        call tecael(iadzi, iazk24)
        messak(5) = zk24(iazk24-1+3)
        call utmess('F', 'DISCRETS_7', nk=5, valk=messak)
    endif
!
!   les comportements valident passe par ici
    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
        call jevech('PCODRET', 'E', jcret)
        zi(jcret) = iret
    endif
!
end subroutine
