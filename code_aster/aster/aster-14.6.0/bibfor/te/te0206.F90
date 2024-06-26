! --------------------------------------------------------------------
! Copyright (C) 2007 NECS - BRUNO ZUBER   WWW.NECS.FR
! Copyright (C) 2007 - 2017 - EDF R&D - www.code-aster.org
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

subroutine te0206(option, nomte)
!
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/gedisc.h"
#include "asterfort/jevech.h"
#include "asterfort/nmfi3d.h"
#include "asterfort/tecach.h"
#include "asterfort/utmess.h"
!
    character(len=16) :: nomte, option
!
! ----------------------------------------------------------------------
!       OPTIONS NON LINEAIRES DES ELEMENTS DE FISSURE JOINT 3D
!       OPTIONS : FULL_MECA, FULL_MECA_ELAS, RAPH_MECA,
!                 RIGI_MECA_ELAS, RIGI_MECA_TANG
! ----------------------------------------------------------------------
!
!
    integer :: ndim, nno, nnos, npg, nddl
    integer :: ipoids, ivf, idfde, jgano
    integer :: igeom, imater, icarcr, icomp, idepm, iddep, icoret
    integer :: icontm, icontp, ivect, imatr
    integer :: ivarim, ivarip, jtab(7), iret, lgpg, iinstm, iinstp
!     COORDONNEES POINT DE GAUSS + POIDS : X,Y,Z,W => 1ER INDICE
    real(kind=8) :: coopg(4, 4)
    aster_logical :: resi, rigi, matsym
! ----------------------------------------------------------------------
!
    resi = option.eq.'RAPH_MECA' .or. option(1:9).eq.'FULL_MECA'
    rigi = option(1:9).eq.'FULL_MECA' .or. option(1:9).eq.'RIGI_MECA'
!
! -  FONCTIONS DE FORMES ET POINTS DE GAUSS : ATTENTION CELA CORRESPOND
!    ICI AUX FONCTIONS DE FORMES 2D DES FACES DES MAILLES JOINT 3D
!    PAR EXEMPLE FONCTION DE FORME DU QUAD4 POUR LES HEXA8.
!
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nno, nnos=nnos, npg=npg,&
                     jpoids=ipoids, jvf=ivf, jdfde=idfde, jgano=jgano)
!
    nddl = 6*nno
!
    if (nno .gt. 4) then
        call utmess('F', 'ELEMENTS5_22')
    endif
    if (npg .gt. 4) then
        call utmess('F', 'ELEMENTS5_23')
    endif
!
! - LECTURE DES PARAMETRES
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imater)
    call jevech('PCARCRI', 'L', icarcr)
    call jevech('PCOMPOR', 'L', icomp)
    call jevech('PDEPLMR', 'L', idepm)
    call jevech('PVARIMR', 'L', ivarim)
    call jevech('PCONTMR', 'L', icontm)
!
! - INSTANTS
    call jevech('PINSTMR', 'L', iinstm)
    call jevech('PINSTPR', 'L', iinstp)
!
!     CALCUL DES COORDONNEES DES POINTS DE GAUSS, POIDS=0
    call gedisc(3, nno, npg, zr(ivf), zr(igeom),&
                coopg)
!
!     RECUPERATION DU NOMBRE DE VARIABLES INTERNES PAR POINTS DE GAUSS
    call tecach('OOO', 'PVARIMR', 'L', iret, nval=7,&
                itab=jtab)
    lgpg = max(jtab(6),1)*jtab(7)
!
    if (resi) then
        call jevech('PDEPLPR', 'L', iddep)
        call jevech('PVARIPR', 'E', ivarip)
        call jevech('PCONTPR', 'E', icontp)
        call jevech('PVECTUR', 'E', ivect)
        call jevech('PCODRET', 'E', icoret)
    else
        iddep=1
        ivarip=1
        icontp=1
        ivect=1
        icoret=1
    endif
!
    if (rigi) then
!
        if (zk16(icomp)(1:15) .eq. 'JOINT_MECA_RUPT' .or. zk16(icomp)(1: 15) .eq.&
            'JOINT_MECA_FROT') then
            matsym = .false.
            call jevech('PMATUNS', 'E', imatr)
        else
            matsym = .true.
            call jevech('PMATUUR', 'E', imatr)
        endif
    else
        imatr=1
    endif
!
    call nmfi3d(nno, nddl, npg, lgpg, zr(ipoids),&
                zr(ivf), zr(idfde), zi(imater), option, zr(igeom),&
                zr(idepm), zr(iddep), zr(icontm), zr(icontp), zr(ivect),&
                zr(imatr), zr(ivarim), zr(ivarip), zr(icarcr), zk16(icomp),&
                matsym, coopg, zr(iinstm), zr(iinstp), zi(icoret))
!
end subroutine
