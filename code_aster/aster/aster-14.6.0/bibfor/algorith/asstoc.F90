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

subroutine asstoc(mome, resu, nomsy, neq, repdir,&
                  ndir, comdir, typcdi, glob, prim)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterc/getres.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jedetr.h"
#include "asterfort/jelibe.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/refdaj.h"
#include "asterfort/rsadpa.h"
#include "asterfort/rscrsd.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsexis.h"
#include "asterfort/rsnoch.h"
#include "asterfort/rsorac.h"
#include "asterfort/utmess.h"
#include "asterfort/vtdefs.h"
    integer :: neq, ndir(*)
    real(kind=8) :: repdir(neq, *)
    aster_logical :: comdir, glob, prim
    character(len=16) :: nomsy
    character(len=*) :: mome, resu, typcdi
!     COMMANDE : COMB_SISM_MODAL
!        STOCKAGE DES CHAMPS CALCULES
!     ------------------------------------------------------------------
! IN  : MOME   : MODES MECANIQUES
! IN  : RESU   : NOM UTILISATEUR DE LA COMMANDE
! IN  : NOMSY  : OPTION DE CALCUL
! IN  : NEQ    : NOMBRE D'EQUATIONS
! IN  : REPDIR : VECTEUR DES RECOMBINAISONS
! IN  : NDIR   : VECTEUR DES DIRECTIONS
! IN  : COMDIR : =.TRUE.  , COMBINAISON DES DIRECTIONS
!                =.FALSE. , PAS DE COMBINAISON DES DIRECTIONS
! IN  : TYPCDI : TYPE DE COMBINAISON DES DIRECTIONS
!     ------------------------------------------------------------------
    integer :: ibid, i, id, ieq, ier, in, iordr, jdef, jdir, jval, lvale, nbmode
    integer :: nbtrou, jdrr, jdor, jmod, jcar, jchm, tordr(1), icole
    real(kind=8) :: r8b, r1, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19
    real(kind=8) :: r2, r20, r21, r22, r23, r24, r3, r4, r5, r6, r7, r8, r9, rx
    real(kind=8) :: ry, rz, xxx
    character(len=8) :: k8b, comp(5)
    character(len=16) :: noms2, concep, nomcmd, def
    character(len=19) :: moncha, champ, resu19
    character(len=24) :: vale
    character(len=24) :: valk(3)
    character(len=14) :: numedd
    character(len=24) :: matric(3)
    complex(kind=8) :: c16b
!     ------------------------------------------------------------------
    data  comp / 'X' , 'Y' , 'Z' , 'QUAD' , 'NEWMARK' /
    data  vale / '                   .VALE' /
!     ------------------------------------------------------------------
!
    call jemarq()
    call getres(k8b, concep, nomcmd)
    call getfac('DEPL_MULT_APPUI', nbmode)
!
    do 10 i = 1, 3
        if (ndir(i) .eq. 1) nbmode = nbmode + 1
 10 continue
    if (comdir) nbmode = nbmode + 1
!
!     --- CREATION DE LA STRUCTURE D'ACCUEIL ---
    call rsexis(resu, ier)
    if (ier .eq. 0) call rscrsd('G', resu, concep, nbmode)
    noms2 = nomsy
    if (nomsy(1:4) .eq. 'VITE') noms2 = 'DEPL'
    if (nomsy(1:4) .eq. 'ACCE') noms2 = 'DEPL'
    call rsorac(mome, 'TOUT_ORDRE', ibid, r8b, k8b,&
                c16b, r8b, k8b, tordr, 1,&
                nbtrou)
    iordr=tordr(1)            
    call rsexch('F', mome, noms2, iordr, moncha,&
                ier)
!
    iordr = 0
!
    if (glob) then
        def = 'GLOBALE'
    else if (prim) then
        def = 'PRIMAIRE'
    endif
    do 20 id = 1, 3
        if (ndir(id) .eq. 1) then
            iordr = iordr + 1
!
!           --- CHAMP RECOMBINE ---
            call rsexch(' ', resu, nomsy, iordr, champ,&
                        ier)
            if (ier .eq. 100) then
                call vtdefs(champ, moncha, 'G', 'R')
            else
                valk(1) = nomsy
                valk(2) = comp(id)
                valk(3) = champ
                call utmess('F', 'SEISME_26', nk=3, valk=valk)
            endif
            vale(1:19) = champ
            call jeexin(vale(1:19)//'.VALE', ibid)
            if (ibid .gt. 0) then
                vale(20:24)='.VALE'
            else
                vale(20:24)='.CELV'
            endif
            call jeveuo(vale, 'E', jval)
!
            do 30 in = 1, neq
                zr(jval+in-1) = sqrt( abs ( repdir(in,id) ) )
 30         continue
            call jelibe(vale)
            call rsnoch(resu, nomsy, iordr)
!
!           --- PARAMETRE ---
            call rsadpa(resu, 'E', 1, 'NOEUD_CMP', iordr,&
                        0, sjv=jdir, styp=k8b)
            zk16(jdir) = 'DIR     '//comp(id)
            call rsadpa(resu, 'E', 1, 'TYPE_DEFO', iordr,&
                        0, sjv=jdef, styp=k8b)
            zk16(jdef) = def
            call rsadpa(resu, 'E', 1, 'FREQ', iordr,&
                        0, sjv=jdrr, styp=k8b)
            zr(jdrr) = id
            call rsadpa(resu, 'E', 1, 'NUME_MODE', iordr,&
                        0, sjv=jdor, styp=k8b)
            zi(jdor) = iordr
            call rsadpa(mome, 'L', 1, 'MODELE', 1,&
                       0, sjv=jval, styp=k8b, istop=0)
            call rsadpa(resu, 'E', 1, 'MODELE', iordr,&
                       0, sjv=jmod, styp=k8b)
            zk8(jmod) = zk8(jval)
            call rsadpa(mome, 'L', 1, 'CARAELEM', 1,&
                       0, sjv=jval, styp=k8b, istop=0)
            call rsadpa(resu, 'E', 1, 'CARAELEM', iordr,&
                       0, sjv=jcar, styp=k8b)
            zk8(jcar) = zk8(jval)
            call rsadpa(mome, 'L', 1, 'CHAMPMAT', 1,&
                       0, sjv=jval, styp=k8b, istop=0)
            call rsadpa(resu, 'E', 1, 'CHAMPMAT', iordr,&
                       0, sjv=jchm, styp=k8b)
            zk8(jchm) = zk8(jval)
        endif
 20 continue
!
    if (comdir) then
        iordr = iordr + 1
!
!        --- CHAMP RECOMBINE ---
        call rsexch(' ', resu, nomsy, iordr, champ,&
                    ier)
        if (ier .eq. 100) then
            call vtdefs(champ, moncha, 'G', 'R')
        else
            valk(1) = nomsy
            valk(2) = comp(id)
            valk(3) = champ
            call utmess('F', 'SEISME_26', nk=3, valk=valk)
        endif
        vale(1:19) = champ
        call jeexin(vale(1:19)//'.VALE', ibid)
        if (ibid .gt. 0) then
            vale(20:24)='.VALE'
        else
            vale(20:24)='.CELV'
        endif
        call jeveuo(vale, 'E', lvale)
!
        if (typcdi(1:4) .eq. 'QUAD') then
            do 40 ieq = 1, neq
                xxx = abs ( repdir(ieq,1) ) + abs ( repdir(ieq,2) ) + abs ( repdir(ieq,3) )
                zr(lvale+ieq-1) = sqrt( xxx )
 40         continue
        else if (typcdi(1:4).eq.'NEWM') then
            do 42 ieq = 1, neq
                rx = sqrt( abs ( repdir(ieq,1) ) )
                ry = sqrt( abs ( repdir(ieq,2) ) )
                rz = sqrt( abs ( repdir(ieq,3) ) )
                r1 = rx + 0.4d0*ry + 0.4d0*rz
                r2 = 0.4d0*rx + ry + 0.4d0*rz
                r3 = 0.4d0*rx + 0.4d0*ry + rz
                r4 = rx - 0.4d0*ry + 0.4d0*rz
                r5 = 0.4d0*rx - ry + 0.4d0*rz
                r6 = 0.4d0*rx - 0.4d0*ry + rz
                r7 = rx - 0.4d0*ry - 0.4d0*rz
                r8 = 0.4d0*rx - ry - 0.4d0*rz
                r9 = 0.4d0*rx - 0.4d0*ry - rz
                r10 = rx + 0.4d0*ry - 0.4d0*rz
                r11 = 0.4d0*rx + ry - 0.4d0*rz
                r12 = 0.4d0*rx + 0.4d0*ry - rz
                r13 = -rx + 0.4d0*ry + 0.4d0*rz
                r14 = -0.4d0*rx + ry + 0.4d0*rz
                r15 = -0.4d0*rx + 0.4d0*ry + rz
                r16 = -rx - 0.4d0*ry + 0.4d0*rz
                r17 = -0.4d0*rx - ry + 0.4d0*rz
                r18 = -0.4d0*rx - 0.4d0*ry + rz
                r19 = -rx - 0.4d0*ry - 0.4d0*rz
                r20 = -0.4d0*rx - ry - 0.4d0*rz
                r21 = -0.4d0*rx - 0.4d0*ry - rz
                r22 = -rx + 0.4d0*ry - 0.4d0*rz
                r23 = -0.4d0*rx + ry - 0.4d0*rz
                r24 = -0.4d0*rx + 0.4d0*ry - rz
                xxx = max(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13, r14)
                xxx = max(xxx,r15,r16,r17,r18,r19,r20,r21,r22,r23,r24)
                zr(lvale+ieq-1) = xxx
 42         continue
        endif
        call jelibe(vale)
        call rsnoch(resu, nomsy, iordr)
!
!        --- PARAMETRE ---
        call rsadpa(resu, 'E', 1, 'NOEUD_CMP', iordr,&
                    0, sjv=jdir, styp=k8b)
        if (typcdi(1:4) .eq. 'QUAD') then
            zk16(jdir) = 'COMBI   '//comp(4)
        else if (typcdi(1:4).eq.'NEWM') then
            zk16(jdir) = 'COMBI   '//comp(5)
        endif
        call rsadpa(resu, 'E', 1, 'TYPE_DEFO', iordr,&
                    0, sjv=jdef, styp=k8b)
        zk16(jdef) = def
        call rsadpa(resu, 'E', 1, 'FREQ', iordr,&
                    0, sjv=jdrr, styp=k8b)
        zr(jdrr) = 4
        call rsadpa(resu, 'E', 1, 'NUME_MODE', iordr,&
                    0, sjv=jdor, styp=k8b)
        zi(jdor) = iordr
        call rsadpa(mome, 'L', 1, 'MODELE', 1,&
                    0, sjv=jval, styp=k8b, istop=0)
        call rsadpa(resu, 'E', 1, 'MODELE', iordr,&
                    0, sjv=jmod, styp=k8b)
        zk8(jmod) = zk8(jval)
        call rsadpa(mome, 'L', 1, 'CARAELEM', 1,&
                    0, sjv=jval, styp=k8b, istop=0)
        call rsadpa(resu, 'E', 1, 'CARAELEM', iordr,&
                    0, sjv=jcar, styp=k8b)
        zk8(jcar) = zk8(jval)
        call rsadpa(mome, 'L', 1, 'CHAMPMAT', 1,&
                    0, sjv=jval, styp=k8b, istop=0)
        call rsadpa(resu, 'E', 1, 'CHAMPMAT', iordr,&
                    0, sjv=jchm, styp=k8b)
        zk8(jchm) = zk8(jval)
    endif
    resu19 = resu(1:8)
    call jeveuo(jexnum(mome(1:8)//'           .REFD', 1), 'L', icole)
    numedd = zk24(icole+1)
    do 50 i = 1, 3
       matric(i) = zk24(icole+i+1)
 50 continue
    call refdaj('F', resu19, iordr, numedd, 'DYNAMIQUE', matric, ier)
!
    call jedema()
end subroutine
