! --------------------------------------------------------------------
! Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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

subroutine te0247(option, nomte)
!
!
! --------------------------------------------------------------------------------------------------
!
!     CALCUL DES OPTIONS FULL_MECA OU RAPH_MECA POUR
!     LES ELEMENTS DE POUTRE 'MECA_POU_D_E/D_T'
!
! --------------------------------------------------------------------------------------------------
!
! IN  OPTION : K16 : NOM DE L'OPTION A CALCULER
!
! IN  NOMTE  : K16 : NOM DU TYPE ELEMENT
!        'MECA_POU_D_E' : POUTRE DROITE D'EULER       (SECTION VARIABLE)
!        'MECA_POU_D_T' : POUTRE DROITE DE TIMOSHENKO (SECTION VARIABLE)
!
! --------------------------------------------------------------------------------------------------
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lcsovn.h"
#include "asterfort/lonele.h"
#include "asterfort/matela.h"
#include "asterfort/matrot.h"
#include "asterfort/moytem.h"
#include "asterfort/nmpoel.h"
#include "asterfort/porea1.h"
#include "asterfort/porigi.h"
#include "asterfort/poutre_modloc.h"
#include "asterfort/ptkg00.h"
#include "asterfort/r8inir.h"
#include "asterfort/tecach.h"
#include "asterfort/utmess.h"
#include "asterfort/utpslg.h"
#include "asterfort/utpvlg.h"
#include "asterfort/verifm.h"
!
    character(len=*) :: option, nomte
! --------------------------------------------------------------------------------------------------
!
    integer :: igeom, icompo, imate, iorien, nd, nk
    integer :: iinstm, iinstp, icarcr, icontm, ideplm, ideplp, imatuu
    integer :: ivectu, icontp, itype, nno, nc, ivarim, ivarip, itemp, i
    integer :: jcret, iret, iretm, iretp
    integer :: npg, ndimel, nnoel, nnosel, lrcou
    integer :: istrxm, istrxp, ldep
    parameter    (nno=2,nc=6,nd=nc*nno,nk=nd*(nd+1)/2)
    real(kind=8) :: e, nu, em, num
    real(kind=8) :: a, xiy, xiz, alfay, alfaz, xjx, ez, ey
    real(kind=8) :: a2, xiy2, xiz2, alfay2, alfaz2, xjx2, xl, xfly, xflz
!
    character(len=24) :: valk(2)
!
    real(kind=8) :: pgl(3, 3), fl(nd), klv(nk)
    real(kind=8) :: tempm, tempp
    real(kind=8) :: epsthe
    real(kind=8) :: sigma(nd), rgeom(nk), gamma, angp(3)
    aster_logical :: reactu, matric, vecteu
! --------------------------------------------------------------------------------------------------
    integer, parameter :: nb_cara = 17
    real(kind=8) :: vale_cara(nb_cara)
    character(len=8) :: noms_cara(nb_cara)
    data noms_cara /'A1','IY1','IZ1','AY1','AZ1','EY1','EZ1','JX1',&
                    'A2','IY2','IZ2','AY2','AZ2','EY2','EZ2','JX2','TVAR'/
! --------------------------------------------------------------------------------------------------
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PCOMPOR', 'L', icompo)
    call jevech('PMATERC', 'L', imate)
    call jevech('PCAORIE', 'L', iorien)
    call jevech('PINSTMR', 'L', iinstm)
    call jevech('PINSTPR', 'L', iinstp)
    call jevech('PCARCRI', 'L', icarcr)
    call jevech('PVARIMR', 'L', ivarim)
    call jevech('PCONTMR', 'L', icontm)
    call jevech('PDEPLMR', 'L', ideplm)
!
!   la presence du champ de deplacement a l instant t+ devrait etre conditionne par l'option
!   (avec rigi_meca_tang ca n a pas de sens).
!   cependant ce champ est initialise a 0 par la routine nmmatr.
    call jevech('PDEPLPR', 'L', ideplp)
!   POINT DE GAUSS DE L'ELEMENT
    call elrefe_info(fami='RIGI', ndim=ndimel, nno=nnoel, nnos=nnosel, npg=npg)
    ASSERT((npg.eq.2).or.(npg.eq.3))
!
!   booleens pratiques
    matric = option .eq. 'FULL_MECA' .or. option .eq. 'RIGI_MECA_TANG'
    vecteu = option .eq. 'FULL_MECA' .or. option .eq. 'RAPH_MECA'
!
!   parametres en sortie
    if (matric) then
        call jevech('PMATUUR', 'E', imatuu)
    endif
!
    if (vecteu) then
        call jevech('PVECTUR', 'E', ivectu)
        call jevech('PCONTPR', 'E', icontp)
        call jevech('PVARIPR', 'E', ivarip)
    endif
!
    call matrot(zr(iorien), pgl)
    xl = lonele()
    call poutre_modloc('CAGNPO', noms_cara, nb_cara, lvaleur=vale_cara)
!
    a      = vale_cara(1)
    xiy    = vale_cara(2)
    xiz    = vale_cara(3)
    alfay  = vale_cara(4)
    alfaz  = vale_cara(5)
    xjx    = vale_cara(8)
    a2     = vale_cara(9)
    xiy2   = vale_cara(10)
    xiz2   = vale_cara(11)
    alfay2 = vale_cara(12)
    alfaz2 = vale_cara(13)
    xjx2   = vale_cara(16)
    ey = (vale_cara(6) +vale_cara(14))/2.d0
    ez = (vale_cara(7) +vale_cara(15))/2.d0
    itype = nint(vale_cara(17))
!
    if (zk16(icompo+2) .ne. 'PETIT' .and. zk16(icompo+2) .ne. 'GROT_GDEP') then
        valk(1) = zk16(icompo+2)
        valk(2) = nomte
        call utmess('F', 'ELEMENTS3_40', nk=2, valk=valk)
    endif
    reactu = zk16(icompo+2) .eq. 'GROT_GDEP'
    if (reactu .and. (zk16(icompo).eq.'ELAS')) then
!       recuperation du 3eme angle nautique au temps t-
        call jevech('PSTRXMR', 'L', istrxm)
        gamma = zr(istrxm+3-1)
!       calcul de pgl,xl et angp
        call porea1(nno, nc, zr(ideplm), zr(ideplp), zr(igeom), gamma, vecteu, pgl, xl, angp)
!       sauvegarde des angles nautiques
        if (vecteu) then
            call jevech('PSTRXPR', 'E', istrxp)
            zr(istrxp+1-1) = angp(1)
            zr(istrxp+2-1) = angp(2)
            zr(istrxp+3-1) = angp(3)
        endif
!
    endif
!
!   recuperation des caracteristiques elastiques
    call moytem('RIGI', npg, 1, '+', tempp, iretp)
    call moytem('RIGI', npg, 1, '-', tempm, iretm)
    itemp = 0
    if ((iretp+iretm) .eq. 0) itemp=1
    call matela(zi(imate), ' ', itemp, tempp, e, nu)
    call matela(zi(imate), ' ', itemp, tempm, em, num)
    call verifm('RIGI', npg, 1, 'T', zi(imate), epsthe, iret)
!
    if (zk16(icompo) .eq. 'ELAS') then
!       calcul des matrices elementaires
        call porigi(nomte, e, nu, xl, klv)
!
        if (option .eq. 'RAPH_MECA' .or. option .eq. 'FULL_MECA') then
            if ((itemp.ne.0) .and. (nu.ne.num)) then
                call utmess('A', 'ELEMENTS3_59')
            endif
            call nmpoel(npg, klv, xl, nno, nc, pgl, zr(ideplp),&
                        epsthe, e, em, zr(icontm), fl, zr( icontp))
        endif
!
    else
        call utmess('F', 'ELEMENTS3_61', sk=zk16(icompo))
    endif
    if (matric) then
!       calcul de la matrice de rigidite geometrique
        if (reactu .and. (zk16(icompo).eq.'ELAS')) then
            if ( nomte.eq.'MECA_POU_D_E' ) then
                xfly = 1.0 ; xflz = 1.0
            else
                call tecach('ONN', 'PCAARPO', 'L', iret, iad=lrcou)
                if ( iret .eq. 0 ) then
                    xfly = zr(lrcou)
                    xflz = zr(lrcou+2)
                    if ( abs(xfly-1.0)+abs(xflz-1.0) .gt. 1.0E-8 ) then
                        call utmess('F', 'ELEMENTS3_64', nr=2, valr=[xfly,xflz])
                    endif
                endif
            endif
            if (option .eq. 'FULL_MECA') then
                ldep = icontp
            else
                ldep = icontm
            endif
            if (npg .eq. 2) then
                do i = 1, nc
                    sigma(i) = zr(ldep+i-1)
                    sigma(i+nc) = zr(ldep+nc+i-1)
                enddo
            else
                do i = 1, nc
                    sigma(i) = zr(ldep+i-1)
                    sigma(i+nc) = zr(ldep+nc+nc+i-1)
                enddo
            endif
            call r8inir(nk, 0.0d0, rgeom, 1)
            call ptkg00(sigma, a, a2, xiz, xiz2, xiy, xiy2, xl, ey, ez, rgeom)
            call lcsovn(nk, klv, rgeom, klv)
        endif
    endif
!
!   passage du repere local au repere global
    if (matric) then
        call utpslg(nno, nc, pgl, klv, zr(imatuu))
    endif
    if (vecteu) then
        call utpvlg(nno, nc, pgl, fl, zr(ivectu))
        call jevech('PCODRET', 'E', jcret)
        zi(jcret) = 0
    endif
!
end subroutine
