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

subroutine te0350(option, nomte)
!
implicit none
!
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/nmas2d.h"
#include "asterfort/rcangm.h"
#include "asterfort/tecach.h"
#include "asterfort/utmess.h"
#include "blas/dcopy.h"
!
! aslint: disable=W0104
!
    character(len=16) :: option, nomte

! ======================================================================
!    CALCUL DES OPTIONS MECANIQUES POUR LES ELEMENTS QUAS4
!    => 1 POINT DE GAUSS + STABILISATION ASSUMED STRAIN
! ======================================================================
!
!
    character(len=16) :: mult_comp
    character(len=8) :: typmod(2)
    character(len=4) :: fami
    integer :: nno, npg1, i, imatuu, lgpg, lgpg1
    integer :: ipoids, ivf, idfde, igeom, imate
    integer :: icontm, ivarim, jv_mult_comp
    integer :: iinstm, iinstp, ideplm, ideplp, icompo, icarcr
    integer :: ivectu, icontp, ivarip
    integer :: ivarix, iret, idim
    integer :: jtab(7), jcret, codret, ndim
    real(kind=8) :: vect1(54), vect3(4*27*2), xyz(3)
    real(kind=8) :: angmas(7)
!
!
!
!
!
    fami = 'RIGI'
    call elrefe_info(fami=fami,ndim=ndim,nno=nno,&
                      npg=npg1,jpoids=ipoids,jvf=ivf,jdfde=idfde)
!
!     MATNS MAL DIMENSIONNEE
    ASSERT(nno.le.9)
! - TYPE DE MODELISATION
!
    if (lteatt('AXIS','OUI')) then
        typmod(1) = 'AXIS    '
    else if (lteatt('C_PLAN','OUI')) then
        typmod(1) = 'C_PLAN  '
    else if (lteatt('D_PLAN','OUI')) then
        typmod(1) = 'D_PLAN  '
    else
!       NOM D'ELEMENT ILLICITE
        ASSERT(lteatt('C_PLAN', 'OUI'))
    endif
!
    typmod(2) = 'ASSU    '
!
    codret = 0
!
!
! - PARAMETRES EN ENTREE
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
    call jevech('PCONTMR', 'L', icontm)
    call jevech('PVARIMR', 'L', ivarim)
    call jevech('PDEPLMR', 'L', ideplm)
    call jevech('PDEPLPR', 'L', ideplp)
    call jevech('PCOMPOR', 'L', icompo)
    call jevech('PCARCRI', 'L', icarcr)
    call jevech('PCOMPOR', 'L', icompo)
    call jevech('PMULCOM', 'L', jv_mult_comp)
    mult_comp = zk16(jv_mult_comp-1+1)
!
    call tecach('OOO', 'PVARIMR', 'L', iret, nval=7,&
                itab=jtab)
    lgpg1 = max(jtab(6),1)*jtab(7)
    lgpg = lgpg1
!
!     ORIENTATION DU MASSIF
!     COORDONNEES DU BARYCENTRE ( POUR LE REPRE CYLINDRIQUE )
!
    xyz(1) = 0.d0
    xyz(2) = 0.d0
    xyz(3) = 0.d0
    do i = 1, nno
        do idim = 1, ndim
            xyz(idim) = xyz(idim)+zr(igeom+idim+ndim*(i-1)-1)/nno
        end do
    end do
    call rcangm(ndim, xyz, angmas)
!
! - VARIABLES DE COMMANDE
!
    call jevech('PINSTMR', 'L', iinstm)
    call jevech('PINSTPR', 'L', iinstp)
!
! PARAMETRES EN SORTIE
!
    imatuu=1
    if (option(1:10) .eq. 'RIGI_MECA_' .or. option(1:9) .eq. 'FULL_MECA') then
        call jevech('PMATUUR', 'E', imatuu)
    endif
!
    if (option(1:9) .eq. 'RAPH_MECA' .or. option(1:9) .eq. 'FULL_MECA') then
        call jevech('PVECTUR', 'E', ivectu)
        call jevech('PCONTPR', 'E', icontp)
        call jevech('PVARIPR', 'E', ivarip)
!
!      ESTIMATION VARIABLES INTERNES A L'ITERATION PRECEDENTE
        call jevech('PVARIMP', 'L', ivarix)
        call dcopy(npg1*lgpg, zr(ivarix), 1, zr(ivarip), 1)
    else
        ivectu=1
        icontp=1
        ivarip=1
    endif
!
!
!
! - HYPER-ELASTICITE
!
    if (zk16(icompo+3) (1:9) .eq. 'COMP_ELAS') then
        if (zk16(icompo).ne.'ELAS') then
            call utmess('F', 'ALGORITH10_88')
        endif
    endif
!
!
! - HYPO-ELASTICITE
!
        if (zk16(icompo+2) (6:10) .eq. '_REAC') then
            do i = 1, 2*nno
                zr(igeom+i-1) = zr(igeom+i-1) + zr(ideplm+i-1) + zr(ideplp+i-1)
            end do
        endif
!
        if (zk16(icompo+2) (1:5) .eq. 'PETIT') then
!
            call nmas2d(fami, nno, npg1, ipoids, ivf,&
                        idfde, zr(igeom), typmod, option, zi(imate),&
                        zk16(icompo), mult_comp, lgpg, zr(icarcr), zr(iinstm), zr(iinstp),&
                        zr(ideplm), zr(ideplp), angmas, zr(icontm), zr(ivarim),&
                        vect1, vect3, zr(icontp), zr(ivarip), zr(imatuu),&
                        zr(ivectu), codret)
!
        else
            call utmess('F', 'ELEMENTS3_16', sk=zk16(icompo+2))
        endif
!

    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
        call jevech('PCODRET', 'E', jcret)
        zi(jcret) = codret
    endif
end subroutine
