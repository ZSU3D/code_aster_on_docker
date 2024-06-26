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

subroutine te0519(option, nomte)
!
!
    implicit none
#include "jeveux.h"
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/elref1.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/elrfvf.h"
#include "asterfort/indent.h"
#include "asterfort/iselli.h"
#include "asterfort/jevech.h"
#include "asterfort/tecach.h"
#include "asterfort/vecini.h"
#include "asterfort/xteini.h"
#include "asterfort/xcalc_code.h"
#include "asterfort/xcalc_heav.h"
#include "asterfort/xcalfev_wrap.h"
#include "asterfort/lteatt.h"
#include "asterfort/xkamat.h"
!
    character(len=16) :: option, nomte
! ----------------------------------------------------------------------
!  XFEM GRANDS GLISSEMENTS
!  REACTUALISATION DES GEOMETRIES DES FACETTES DE CONTACT
!  (MAITRE ET ESCLAVE)
!
!  OPTION : 'GEOM_FAC' (X-FEM GEOMETRIE DES FACETTES DE CONTACT)
!
!  ENTREES  ---> OPTION : OPTION DE CALCUL
!           ---> NOMTE  : NOM DU TYPE ELEMENT
!
!
!
!
    character(len=8) :: elref
    integer :: jdepl, jpint, jlon, jgeo, jlst, nfiss
    integer :: jges, jgma, ifiss, ifh, ncompp, jtab(7), iret, ncomph
    integer :: ibid, ndim, nno, nfh, singu, ddls, ninter
    integer :: i, j, ipt, nfe, ddlc, nnom, nddl, ddlm, nnos, in
    integer :: jheafa, jeu(2), jheavn, ncompn
    integer :: jstno, jlsn, igeom, jbaslo, alp, imate
    real(kind=8) :: ptref(3), deple(3), deplm(3), ff(20)
    real(kind=8) :: fk_mait(27,3,3), fk_escl(27,3,3), ka, mu
    aster_logical :: axi
!
! ---------------------------------------------------------------------
!
    ASSERT(option.eq.'GEOM_FAC')
!
!
! --- RECUPERATION DU TYPE DE MAILLE, DE SA DIMENSION
! --- ET DE SON NOMBRE DE NOEUDS
!
    call elref1(elref)
    call elrefe_info(fami='RIGI',ndim=ndim,nno=nno,nnos=nnos)
!
! --- INITIALISATION DES DIMENSIONS DES DDLS X-FEM
    call xteini(nomte, nfh, nfe, singu, ddlc,&
                nnom, ddls, nddl, ddlm, nfiss,&
                ibid)
!
! --- RECUPERATION DES ENTRÉES / SORTIE
!
    call jevech('PDEPLA', 'L', jdepl)
    call jevech('PPINTER', 'L', jpint)
    call jevech('PLONGCO', 'L', jlon)
    call jevech('PLST', 'L', jlst)
    if (nfh.gt.0) then
        call jevech('PHEA_NO', 'L', jheavn)
        call tecach('OOO', 'PHEA_NO', 'L', iret, nval=7,&
                itab=jtab)
        ncompn = jtab(2)/jtab(3)
    endif
    if (nfe .gt. 0) then
        call jevech('PBASLOR', 'L', jbaslo)
        call jevech('PLSN', 'L', jlsn)
        call jevech('PSTANO', 'L', jstno)
        call jevech('PGEOMER', 'L', igeom)
        call jevech('PMATERC', 'L', imate)
        axi=lteatt('AXIS','OUI')
    endif
! --- LES GEOMETRIES MAITRES ET ESCLAVES INITIALES SONT
! --- ET RESTENT LES MEMES
    call jevech('PGESCLO', 'L', jgeo)
! --- CAS MULTI-HEAVISIDE
    if (nfiss .gt. 1) then
        call jevech('PHEA_FA', 'L', jheafa)
        call tecach('OOO', 'PHEA_FA', 'L', iret, nval=2,&
                itab=jtab)
        ncomph = jtab(2)
    endif
    call tecach('OOO', 'PPINTER', 'L', iret, nval=2,&
                itab=jtab)
    ncompp = jtab(2)
    jeu(1) = xcalc_code(1,[-1])
    jeu(2) = xcalc_code(1,[+1])
!
    call jevech('PNEWGES', 'E', jges)
    call jevech('PNEWGEM', 'E', jgma)
!
! --- BOUCLE SUR LES FISSURES
!
    do 10 ifiss = 1, nfiss
!
! --- RECUPERATION DU NOMBRE DES POINTS D'INTERSECTION
!
        ninter=zi(jlon-1+3*(ifiss-1)+1)
        if (ndim .eq. 2 .and. .not.iselli(elref)) then
            if (ninter .eq. 2) ninter=3
        endif
!
! --- BOUCLE SUR LES POINTS D'INTERSECTION
!
        do 100 ipt = 1, ninter
            call vecini(ndim, 0.d0, deple)
            call vecini(ndim, 0.d0, deplm)
            do 110 i = 1, ndim
!
! --- RECUPERATION DES COORDONNEES DE REFERENCE DU POINT D'INTERSECTION
!
                ptref(i)=zr(jpint-1+ncompp*(ifiss-1)+ndim*(ipt-1)+i)
110          continue
!
! --- CALCUL DES FONCTIONS DE FORMES DU POINT D'INTERSECTION
!
            call elrfvf(elref, ptref, nno, ff, nno)
!
            if (nfe .gt. 0) then
              call xkamat(zi(imate), ndim, axi, ka, mu)
              call xcalfev_wrap(ndim, nno, zr(jbaslo), zi(jstno), +1.d0,&
                           zr(jlsn), zr(jlst), zr(igeom), ka, mu, ff,&
                           fk_mait, face='MAIT')
              call xcalfev_wrap(ndim, nno, zr(jbaslo), zi(jstno), -1.d0,&
                           zr(jlsn), zr(jlst), zr(igeom), ka, mu, ff,&
                           fk_escl, face='ESCL')
            endif
!
! --- CALCUL DES DEPLACEMENTS MAITRES ET ESCLAVES
! --- DU POINT D'INTERSECTION
!
            do 210 i = 1, nno
                call indent(i, ddls, ddlm, nnos, in)
                do 220 j = 1, ndim
                    deplm(j)=deplm(j)+ff(i)*zr(jdepl-1+in+j)
                    deple(j)=deple(j)+ff(i)*zr(jdepl-1+in+j)
220              continue
                do 230 ifh = 1, nfh
                    if (nfiss .gt. 1) then
                        jeu(1) = zi(jheafa-1+ncomph*(ifiss-1)+1)
                        jeu(2) = zi(jheafa-1+ncomph*(ifiss-1)+2)
                    endif
                    do 250 j = 1, ndim
                        deplm(j)=deplm(j)+xcalc_heav(zi(jheavn-1+ncompn*(i-1)+ifh),jeu(2),&
                                                     zi(jheavn-1+ncompn*(i-1)+ncompn))&
                                         *ff(i)*zr(jdepl-1+in+ndim*ifh+j)
                        deple(j)=deple(j)+xcalc_heav(zi(jheavn-1+ncompn*(i-1)+ifh),jeu(1),&
                                                     zi(jheavn-1+ncompn*(i-1)+ncompn))&
                                         *ff(i)*zr(jdepl-1+in+ndim*ifh+j)
250                  continue
230              continue
                do 240 alp = 1, nfe*ndim
                  do j = 1, ndim
                    deplm(j)=deplm(j)+fk_mait(i,alp,j)*zr(jdepl-1+in+ndim*(1+&
                    nfh)+alp)
                    deple(j)=deple(j)+fk_escl(i,alp,j)*zr(jdepl-1+in+ndim*(1+&
                    nfh)+alp)
                  enddo   
240              continue
210          continue
!
! --- CALCUL DES NOUVELLES COORDONNEES DES POINTS D'INTERSECTIONS
! --- MAITRES ET ESCLAVES, ON FAIT :
! --- NOUVELLES COORDONNEES = ANCIENNES COORDONEES + DEPLACEMENT
!
            do 300 i = 1, ndim
                zr(jges-1+ncompp*(ifiss-1)+ndim*(ipt-1)+i) = zr(&
                                                             jgeo- 1+ncompp*(ifiss-1)+ndim*(ipt-1&
                                                             &)+i) + deple(i&
                                                             )
                zr(jgma-1+ncompp*(ifiss-1)+ndim*(ipt-1)+i) = zr(&
                                                             jgeo- 1+ncompp*(ifiss-1)+ndim*(ipt-1&
                                                             &)+i) + deplm(i&
                                                             )
300          continue
100      continue
!
10  end do
!
end subroutine
