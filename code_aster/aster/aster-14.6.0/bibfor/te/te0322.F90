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

subroutine te0322(option, nomte)
!
! person_in_charge: jerome.laverne at edf.fr
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/ejinit.h"
#include "asterfort/elref2.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/nmfihm.h"
#include "asterfort/tecach.h"
    character(len=16) :: nomte, option
!
!-----------------------------------------------------------------------
!     BUT : CALCUL DES OPTIONS NON LINEAIRES DES ELEMENTS DE JOINT ET
!           JOINT_HYME
!     OPTION : RAPH_MECA, FULL_MECA, RIGI_MECA_TANG, RIGI_MECA_ELAS
!-----------------------------------------------------------------------
!
    integer :: ndim, nno1, nno2, nnos, npg, nddl, ntrou
    integer :: iw, ivf1, ivf2, idf1, idf2, jgn
    integer :: igeom, imater, icarcr, icomp, iddlm, iddld
    integer :: icontm, icontp, ivect, imatr, iu(3, 16), ip(8)
    integer :: ivarim, ivarip, jtab(7), iret, iinstm, iinstp
    integer :: lgpg1, lgpg
    character(len=8) :: typmod(2), lielrf(10)
    aster_logical :: resi, rigi
!
    resi = option.eq.'RAPH_MECA' .or. option(1:9).eq.'FULL_MECA'
    rigi = option(1:9).eq.'FULL_MECA' .or. option(1:9).eq.'RIGI_MECA'
!
! FONCTIONS DE FORMES ET POINTS DE GAUSS
    call elref2(nomte, 2, lielrf, ntrou)
    call elrefe_info(elrefe=lielrf(1), fami='RIGI', ndim=ndim, nno=nno1, nnos=nnos,&
                     npg=npg, jpoids=iw, jvf=ivf1, jdfde=idf1, jgano=jgn)
    call elrefe_info(elrefe=lielrf(1), fami='RIGI', ndim=ndim, nno=nno2, nnos=nnos,&
                     npg=npg, jpoids=iw, jvf=ivf2, jdfde=idf2, jgano=jgn)
!
! LA DIMENSION DE L'ESPACE EST CELLE DE L'ELEM DE REF SURFACIQUE PLUS 1
    ndim = ndim + 1
!
! NB DE DDL = NDIM PAR NOEUD DE DEPL + UN PAR NOEUD DE PRES
    nddl = ndim*2*nno1 + nno2
!
! DECALAGE D'INDICE POUR LES ELEMENTS DE JOINT
    call ejinit(nomte, iu, ip)
!
! TYPE DE MODELISATION
!
    if (ndim .eq. 3) then
        typmod(1) = '3D'
    else
        typmod(1) = 'PLAN'
    endif
!
    if (lteatt('TYPMOD2','ELEMJOIN')) then
        typmod(2) = 'ELEMJOIN'
    else if (lteatt('TYPMOD2','EJ_HYME')) then
        typmod(2) = 'EJ_HYME'
    else
!       MODELISATION NON SUPORTEE
        ASSERT(typmod(2).eq.'ELEMJOIN'.or. typmod(2) .eq.'EJ_HYME')
    endif
!
! DONNEES EN ENTREE
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imater)
    call jevech('PCARCRI', 'L', icarcr)
    call jevech('PCOMPOR', 'L', icomp)
    call jevech('PDEPLMR', 'L', iddlm)
    call jevech('PDEPLPR', 'L', iddld)
    call jevech('PVARIMR', 'L', ivarim)
    call jevech('PINSTMR', 'L', iinstm)
    call jevech('PINSTPR', 'L', iinstp)
    call jevech('PCONTMR', 'L', icontm)
!
! RECUPERATION DU NOMBRE DE VARIABLES INTERNES PAR POINTS DE GAUSS
    call tecach('OOO', 'PVARIMR', 'L', iret, nval=7,&
                itab=jtab)
    lgpg1 = max(jtab(6),1)*jtab(7)
    lgpg = lgpg1
!
! DONNEES EN SORTIE
    if (rigi) then
        call jevech('PMATUNS', 'E', imatr)
    endif
!
    if (resi) then
        call jevech('PVARIPR', 'E', ivarip)
        call jevech('PCONTPR', 'E', icontp)
        call jevech('PVECTUR', 'E', ivect)
    else
        ivarip=1
        icontp=1
        ivect=1
    endif
!
! CALCUL DES CONTRAINTES, VIP, FORCES INTERNES ET MATR TANG ELEMENTAIRES
    call nmfihm(ndim, nddl, nno1, nno2, npg,&
                lgpg, iw, zr(iw), zr(ivf1), zr(ivf2),&
                idf2, zr(idf2), zi(imater), option, zr(igeom),&
                zr(iddlm), zr(iddld), iu, ip, zr(icontm),&
                zr(icontp), zr(ivect), zr(imatr), zr(ivarim), zr(ivarip),&
                zr(iinstm), zr(iinstp), zr(icarcr), zk16(icomp), typmod)
!
end subroutine
