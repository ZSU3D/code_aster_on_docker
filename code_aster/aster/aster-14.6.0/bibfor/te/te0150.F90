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

subroutine te0150(option, nomte)
!
!
! --------------------------------------------------------------------------------------------------
!     CALCULE LE CHARGEMENT INDUIT PAR UNE ELEVATION UNIFORME DE
!     TEMPERATURE DANS LES POUTRES D'EULER ET DE TIMOSHENKO
!
! --------------------------------------------------------------------------------------------------
!
! IN  OPTION : K16 : NOM DE L'OPTION A CALCULER
!       'FC1D1D_MECA'       : FORCES LINEIQUES (COMP)
!       'FR1D1D_MECA'       : FORCES LINEIQUES (REEL)
!       'FF1D1D_MECA'       : FORCES LINEIQUES (FONCTION)
!       'SR1D1D_MECA'       : FORCES LINEIQUES SUIVEUSES (REEL)
!       'SF1D1D_MECA'       : FORCES LINEIQUES SUIVEUSES (FONCTION)
!       'CHAR_MECA_PESA_R'  : CHARGES DE PESANTEUR
!       'CHAR_MECA_ROTA_R'  : CHARGES DE ROTATION
!       'CHAR_MECA_TEMP_R'  : DEFORMATIONS THERMIQUES
!       'CHAR_MECA_SECH_R'  : DEFORMATIONS DUES AU SECHAGE
!       'CHAR_MECA_HYDR_R'  : DEFORMATIONS HYDRIQUES
! IN  NOMTE  : K16 : NOM DU TYPE ELEMENT
!       'MECA_POU_D_E'  : POUTRE DROITE D'EULER       (SECTION VARIABLE)
!       'MECA_POU_D_T'  : POUTRE DROITE DE TIMOSHENKO (SECTION VARIABLE)
!       'MECA_POU_D_EM' : POUTRE DROITE MULTIFIBRE D EULER (SECT. CONST)
!       'MECA_POU_D_TG' : POUTRE DROITE DE TIMOSHENKO (GAUCHISSEMENT)
!       'MECA_POU_D_TGM': POUTRE DROITE DE TIMOSHENKO (GAUCHISSEMENT)
!                         MULTI-FIBRES SECTION CONSTANTE
!
! --------------------------------------------------------------------------------------------------
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lonele.h"
#include "asterfort/matrot.h"
#include "asterfort/moytem.h"
#include "asterfort/pmfrig.h"
#include "asterfort/porigi.h"
#include "asterfort/poutre_modloc.h"
#include "asterfort/ptfocp.h"
#include "asterfort/ptforp.h"
#include "asterfort/rcvalb.h"
#include "asterfort/utmess.h"
#include "asterfort/utpvlg.h"
#include "asterfort/verifm.h"
!
    character(len=*) :: option, nomte
!
! --------------------------------------------------------------------------------------------------
!
    integer :: nbpar, lmater, iret
    integer :: istruc, lorien, lvect
    integer :: itype, nc, ind, i, j
    integer :: ndim, nno, nnos, npg, ipoids
    integer :: ivf, idfdx, jgano
    real(kind=8) :: valpar(3)
    real(kind=8) :: e, nu, g
    real(kind=8) :: a, a2, xl
    real(kind=8) :: pgl(3, 3), de(14), ffe(14)
    real(kind=8) :: bsm(14, 14), matk(105)
    real(kind=8) :: epsith
    real(kind=8) :: fr(14), fi(14), fgr(14), fgi(14)
    real(kind=8) :: fer(12), fei(12)
!
    character(len=4) :: fami
    character(len=8) :: nompar(3), materi
    character(len=16) :: ch16
    aster_logical :: lrho
! --------------------------------------------------------------------------------------------------
    integer, parameter :: nbres=2
    integer :: codres(nbres)
    real(kind=8) :: valres(nbres)
    character(len=16) :: nomres(nbres)
    data nomres / 'E', 'NU' /
! --------------------------------------------------------------------------------------------------
    integer, parameter :: nb_cara = 3
    real(kind=8) :: vale_cara(nb_cara)
    character(len=8), parameter :: noms_cara(nb_cara) = (/'A1  ','A2  ','TVAR'/)
! --------------------------------------------------------------------------------------------------
!
    fami = 'RIGI'
    nno = 2
    nc = 6
    istruc = 1
!
    call elrefe_info(fami=fami, ndim=ndim, nno=nno, nnos=nnos, npg=npg,&
                     jpoids=ipoids, jvf=ivf, jdfde=idfdx, jgano=jgano)
!
!     -- POUR LA PESANTEUR ET LA ROTATION, ON N'A BESOIN QUE DE RHO
!        QUI EST FORCEMENT CONSTANT DANS LA MAILLE
    lrho=(option.eq.'CHAR_MECA_PESA_R'.or. option.eq.'CHAR_MECA_ROTA_R')
!
!     --- RECUPERATION DES CARACTERISTIQUES MATERIAUX (MOYENNE)
    if (option(13:16) .ne. '1D1D' .and. .not.lrho) then
        call jevech('PMATERC', 'L', lmater)
        call moytem(fami, npg, 1, '+', valpar(1), iret)
    endif
    valres(:) = 0.d0
!
    nbpar = 1
    nompar(1) = 'TEMP'
!
    e = 0.d0
!   -- RECUPERATION DES CARACTERISTIQUES GENERALES DES SECTIONS
    call jevech('PCAORIE', 'L', lorien)
    xl = lonele()
!
    call poutre_modloc('CAGNPO', noms_cara, nb_cara, lvaleur=vale_cara)
    a     = vale_cara(1)
    a2    = vale_cara(2)
    itype = nint(vale_cara(3))
    call matrot(zr(lorien), pgl)
!
    materi=' '
    if ((nomte.ne.'MECA_POU_D_EM') .and. (nomte.ne.'MECA_POU_D_TGM')) then
!       poutres classiques
        if (option(13:16) .ne. '1D1D' .and. .not.lrho) then
            call rcvalb(fami, 1, 1, '+', zi(lmater), materi, 'ELAS', nbpar, nompar, valpar,&
                        nbres, nomres, valres, codres, 1)
!
            e = valres(1)
            nu = valres(2)
            g = e / (2.d0*(1.d0+nu))
        endif
    endif
!
    if (nomte .eq. 'MECA_POU_D_EM') then
!       poutre multifibre droite d'euler a 6 DDL
        if (lrho) then
            itype=0
        else
            itype = 20
        endif
!
    else if (nomte .eq. 'MECA_POU_D_TG') then
!       poutre droite de timoskenko a 7 ddl (gauchissement)
        itype = 30
        nc = 7
    else if (nomte .eq. 'MECA_POU_D_TGM') then
!       poutre droite de timoskenko a 7 ddl (gauchissement, multifibres)
        itype = 30
        nc = 7
    endif
!   passage du repere local au repere global
    if (option .eq. 'CHAR_MECA_FC1D1D') then
        call jevech('PVECTUC', 'E', lvect)
        if (nomte .eq. 'MECA_POU_D_TG' .or. nomte .eq. 'MECA_POU_D_TGM') then
            call ptfocp(itype, option, xl, nno, 6, pgl, fr, fi)
            call utpvlg(nno, 6, pgl, fr, fgr)
            call utpvlg(nno, 6, pgl, fi, fgi)
            do i = 1, 6
                zc(lvect+i-1) = dcmplx(fgr(i),fgi(i))
                zc(lvect+i-1+7) = dcmplx(fgr(i+6),fgi(i+6))
            enddo
            zc(lvect+7-1) = dcmplx(0.d0,0.d0)
            zc(lvect+14-1) = dcmplx(0.d0,0.d0)
        else
            call ptfocp(itype, option, xl, nno, nc, pgl, fr, fi)
            call utpvlg(nno, nc, pgl, fr, fgr)
            call utpvlg(nno, nc, pgl, fi, fgi)
            do i = 1, 12
                zc(lvect+i-1) = dcmplx(fgr(i),fgi(i))
            enddo
        endif
        else if( option.eq.'CHAR_MECA_FR1D1D' .or.&
                 option.eq.'CHAR_MECA_FF1D1D' .or.&
                 option.eq.'CHAR_MECA_SR1D1D' .or.&
                 option.eq.'CHAR_MECA_SF1D1D' .or.&
                 option.eq.'CHAR_MECA_ROTA_R' .or.&
                 option.eq.'CHAR_MECA_PESA_R' ) then
        if (nomte .eq. 'MECA_POU_D_TG' .or. nomte .eq. 'MECA_POU_D_TGM') then
            call ptforp(0, option, nomte, a, a2, xl, 1, nno, 6, pgl, fer, fei)
        else
            call ptforp(itype, option, nomte, a, a2, xl, 1, nno, nc, pgl, fer, fei)
        endif
        do i = 1, 6
            ffe(i) = fer(i)
            ffe(i+nc) = fer(i+6)
        enddo
        if (nc .eq. 7) then
            ffe(7) = 0.d0
            ffe(14) = 0.d0
        endif
    else
        if (nomte .eq. 'MECA_POU_D_EM' .or. nomte .eq. 'MECA_POU_D_TGM') then
!           poutre droite multifibre a section constante
            call pmfrig(nomte, zi(lmater), matk)
        else
            call porigi(nomte, e, nu, xl, matk)
        endif
!       remplissage de la matrice carree
        ind = 0
        do i = 1, nc*2
            de(i) = 0.d0
            do j = 1, i-1
                ind = ind + 1
                bsm(i,j) = matk(ind)
                bsm(j,i) = matk(ind)
            enddo
            ind = ind + 1
            bsm(i,i) = matk(ind)
        enddo
!
        if (option .eq. 'CHAR_MECA_TEMP_R') then
!           calcul du deplacement local induit par l'elevation de temp.
            call verifm(fami, npg, 1, '+', zi(lmater), epsith, iret)
!
        else
            ch16 = option
            call utmess('F', 'ELEMENTS2_47', sk=ch16)
        endif
!
        if (itype .eq.30) then
            de(1) = -epsith * xl
            de(8) = -de(1)
        else
            de(1) = -epsith * xl
            de(7) = -de(1)
        endif
!       calcul des forces induites
        do i = 1, nc
            ffe(i) = 0.d0
            ffe(i+nc) = 0.d0
            do j = 1, nc
                ffe(i) = ffe(i) + bsm(i,j) * de(j)
                ffe(i+nc) = ffe(i+nc) + bsm(i+nc,j+nc) * de(j+nc)
            enddo
        enddo
    endif
!
    if (option .ne. 'CHAR_MECA_FC1D1D') then
        call jevech('PVECTUR', 'E', lvect)
!       matrice de passage du repere global au repere local : PGL
        call utpvlg(nno, nc, pgl, ffe, zr(lvect))
    endif
!
end subroutine
