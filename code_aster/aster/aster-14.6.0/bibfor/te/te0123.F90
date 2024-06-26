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

subroutine te0123(option, nomte)
!  TE0123
!    - FONCTION REALISEE:  CALCUL DES OPTIONS NON-LINEAIRES MECANIQUES
!                          EN 2D
!                          POUR ELEMENTS NON LOCAUX  A GRAD. DE SIG.
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! ----------------------------------------------------------------------
!
use calcul_module, only : ca_jelvoi_, ca_jptvoi_, ca_jrepe_
implicit none
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/elref2.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/massup.h"
#include "asterfort/nmplgs.h"
#include "asterfort/rcangm.h"
#include "asterfort/tecach.h"
#include "asterfort/tecael.h"
#include "asterfort/utmess.h"
#include "asterfort/voiuti.h"
#include "blas/dcopy.h"
    character(len=16) :: option, nomte
!
    integer :: dlns
    integer :: nno, nnob, nnos, npg, imatuu, lgpg, lgpg1, lgpg2
    integer :: ipoids, ivf, idfde, igeom, imate
    integer :: ivfb, idfdeb, jgano
    integer :: icontm, ivarim
    integer :: iinstm, iinstp, idplgm, iddplg, icompo, icarcr
    integer :: ivectu, icontp, ivarip
    integer :: ivarix
    integer :: jtab(7), iadzi, iazk24, jcret, codret
    integer :: ndim, iret, ntrou, idim, i, vali(2)
!
    real(kind=8) :: trav1(3*8), angmas(7), bary(3)
    character(len=16) :: codvoi
    integer :: nvoima, nscoma, nbvois
    parameter(nvoima=12,nscoma=4)
    integer :: livois(1:nvoima), tyvois(1:nvoima), nbnovo(1:nvoima)
    integer :: nbsoco(1:nvoima), lisoco(1:nvoima, 1:nscoma, 1:2)
    integer :: numa
!
    integer :: icodr1(1)
    character(len=8) :: typmod(2), lielrf(10), nomail
    character(len=16) :: phenom
!
!
!
    icontp=1
    ivarip=1
    imatuu=1
    ivectu=1
!
!
! - FONCTIONS DE FORME
    call elref2(nomte, 10, lielrf, ntrou)
    ASSERT(ntrou.ge.2)
!
    if (option(1:9) .eq. 'MASS_MECA') then
        call elrefe_info(elrefe=lielrf(1),fami='MASS',ndim=ndim,nno=nno,nnos=nnos,&
  npg=npg,jpoids=ipoids,jvf=ivf,jdfde=idfde,jgano=jgano)
    else
        call elrefe_info(elrefe=lielrf(1),fami='RIGI',ndim=ndim,nno=nno,nnos=nnos,&
  npg=npg,jpoids=ipoids,jvf=ivf,jdfde=idfde,jgano=jgano)
        call elrefe_info(elrefe=lielrf(2),fami='RIGI',ndim=ndim,nno=nnob,nnos=nnos,&
  npg=npg,jpoids=ipoids,jvf=ivfb,jdfde=idfdeb,jgano=jgano)
    endif
!
! - TYPE DE MODELISATION
    if (ndim .eq. 2 .and. lteatt('C_PLAN','OUI')) then
        typmod(1) = 'C_PLAN  '
    else if (ndim.eq.2 .and. lteatt('D_PLAN','OUI')) then
        typmod(1) = 'D_PLAN  '
    else if (ndim .eq. 3) then
        typmod(1) = '3D'
    else
!       NOM D'ELEMENT ILLICITE
        ASSERT(ndim .eq. 3)
    endif
!
    typmod(2) = 'GRADSIGM'
    codret = 0
!
! - PARAMETRES EN ENTREE
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
!
    if (option(1:9) .eq. 'MASS_MECA') then
!---------------- CALCUL MATRICE DE MASSE ------------------------
!
        call jevech('PMATUUR', 'E', imatuu)
!
        if (ndim .eq. 2) then
! - 2 DEPLACEMENTS + 4 DEF
            dlns = 6
        else if (ndim.eq.3) then
! - 3 DEPLACEMENTS + 6 DEF
            dlns = 9
        else
            ASSERT(ndim .eq. 3)
        endif
!
        call massup(option, ndim, dlns, nno, nnos,&
                    zi(imate), phenom, npg, ipoids, idfde,&
                    zr(igeom), zr(ivf), imatuu, icodr1, igeom,&
                    ivf)
!
!--------------- FIN CALCUL MATRICE DE MASSE -----------------------
    else
!---------------- CALCUL OPTION DE RIGIDITE ------------------------
        call jevech('PCONTMR', 'L', icontm)
        call jevech('PVARIMR', 'L', ivarim)
        call jevech('PDEPLMR', 'L', idplgm)
        call jevech('PDEPLPR', 'L', iddplg)
        call jevech('PCOMPOR', 'L', icompo)
        call jevech('PCARCRI', 'L', icarcr)
!
! - ON INTERDIT UNE LOI DIFFERENTE DE ENDO_HETEROGENE
        if (zk16(icompo) .ne. 'ENDO_HETEROGENE') then
            call utmess('F', 'COMPOR2_13')
        endif
!
! - ON VERIFIE QUE PVARIMR ET PVARIPR ONT LE MEME NOMBRE DE V.I. :
!
        call tecach('OOO', 'PVARIMR', 'L', iret, nval=7,&
                    itab=jtab)
        ASSERT(jtab(1).eq.ivarim)
        lgpg1 = max(jtab(6),1)*jtab(7)
!
        if ((option.eq.'RAPH_MECA') .or. (option(1:9).eq.'FULL_MECA')) then
            call tecach('OOO', 'PVARIPR', 'E', iret, nval=7,&
                        itab=jtab)
            lgpg2 = max(jtab(6),1)*jtab(7)
            if (lgpg1 .ne. lgpg2) then
                call tecael(iadzi, iazk24)
                nomail = zk24(iazk24-1+3) (1:8)
                vali(1)=lgpg1
                vali(2)=lgpg2
                call utmess('F', 'CALCULEL6_64', sk=nomail, ni=2, vali=vali)
            endif
        endif
        lgpg = lgpg1
!
! --- ORIENTATION DU MASSIF
!     COORDONNEES DU BARYCENTRE ( POUR LE REPRE CYLINDRIQUE )
!
        bary(1) = 0.d0
        bary(2) = 0.d0
        bary(3) = 0.d0
        do 150 i = 1, nno
            do 140 idim = 1, ndim
                bary(idim) = bary(idim)+zr(igeom+idim+ndim*(i-1)-1)/ nno
140          continue
150      continue
        call rcangm(ndim, bary, angmas)
!
! - VARIABLES DE COMMANDE
!
        call jevech('PINSTMR', 'L', iinstm)
        call jevech('PINSTPR', 'L', iinstp)
!
! PARAMETRES EN SORTIE
!
        if (option(1:14) .eq. 'RIGI_MECA_TANG' .or. option(1:14) .eq. 'RIGI_MECA_ELAS' .or.&
            option(1:9) .eq. 'FULL_MECA') then
            call jevech('PMATUNS', 'E', imatuu)
        endif
!
        if (option(1:9) .eq. 'RAPH_MECA' .or. option(1:9) .eq. 'FULL_MECA') then
            call jevech('PVECTUR', 'E', ivectu)
            call jevech('PCONTPR', 'E', icontp)
            call jevech('PVARIPR', 'E', ivarip)
!
!      ESTIMATION VARIABLES INTERNES A L'ITERATION PRECEDENTE
            call jevech('PVARIMP', 'L', ivarix)
            call dcopy(npg*lgpg, zr(ivarix), 1, zr(ivarip), 1)
        endif
!
! - HYPO-ELASTICITE
!
        call tecael(iadzi, iazk24)
        numa=zi(iadzi-1+1)
        codvoi='A2'
!
        call voiuti(numa, codvoi, nvoima, nscoma, ca_jrepe_,&
                    ca_jptvoi_, ca_jelvoi_, nbvois, livois, tyvois,&
                    nbnovo, nbsoco, lisoco)
!
        if (zk16(icompo+2) .ne. 'PETIT') then
            call utmess('F', 'ELEMENTS3_16', sk=zk16(icompo+2))
        endif
!
!
        call nmplgs(ndim, nno, zr(ivf), idfde, nnob,&
                    zr(ivfb), idfdeb, npg, ipoids, zr(igeom),&
                    typmod, option, zi(imate), zk16(icompo), zr(icarcr),&
                    zr(iinstm), zr(iinstp), angmas, zr(idplgm), zr(iddplg),&
                    zr(icontm), lgpg, zr(ivarim), zr(icontp), zr(ivarip),&
                    zr(imatuu), zr(ivectu), codret, trav1, livois,&
                    nbvois, numa, lisoco, nbsoco)
!
        if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
            call jevech('PCODRET', 'E', jcret)
            zi(jcret) = codret
        endif
!---------------- FIN CALCUL OPTION DE RIGIDITE ------------------------
    endif
end subroutine
