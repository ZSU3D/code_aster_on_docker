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

subroutine gcharg(modele, lischa, chvolu, ch1d2d, ch2d3d,&
                  chpres, chepsi, chpesa, chrota, lfonc,&
                  time, iord)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/gcchar.h"
#include "asterfort/gcfonc.h"
#include "asterfort/gcsele.h"
#include "asterfort/isdeco.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jemarq.h"
#include "asterfort/lisccc.h"
#include "asterfort/lisdef.h"
#include "asterfort/lislch.h"
#include "asterfort/lislcm.h"
#include "asterfort/lislnf.h"
#include "asterfort/lisltc.h"
#include "asterfort/lisltf.h"
#include "asterfort/lisnnb.h"
#include "asterfort/lisnnl.h"
#include "asterfort/mefor0.h"
#include "asterfort/mepres.h"
#include "asterfort/wkvect.h"
    integer :: iord
    character(len=8) :: modele
    character(len=19) :: lischa
    character(len=19) :: chvolu, ch1d2d, ch2d3d, chpres
    character(len=19) :: chepsi, chpesa, chrota
    aster_logical :: lfonc
    real(kind=8) :: time
!
! OPERATEUR CALC_G
!
! CREATION DES CHAMPS PROVENANT DES CHARGEMENTS
!
! ----------------------------------------------------------------------
!
! IN  LISCHA : LISTE DES CHARGES
! IN  MODELE : NOM DU MODELE
! IN  TIME   : INSTANT
! IN  IORD   : NUMERO D'ORDRE CORRESPONDANT A TIME
! OUT CHVOLU : CARTE MODIFIEE POUR CHARGEMENT FORCE_INTERNE
! OUT CH1D2D : CARTE MODIFIEE POUR CHARGEMENT FORCE_CONTOUR
! OUT CH2D3D : CARTE MODIFIEE POUR CHARGEMENT FORCE_FACE
! OUT CHPRES : CARTE MODIFIEE POUR CHARGEMENT PRES_REP
! OUT CHEPSI : CARTE MODIFIEE POUR CHARGEMENT EPSI_INIT
! OUT CHPESA : CARTE MODIFIEE POUR CHARGEMENT PESANTEUR
! OUT CHROTA : CARTE MODIFIEE POUR CHARGEMENT ROTATION
! OUT LFONC  : .TRUE. AU MOINS UNE CHARGE EST DE TYPE FONCTION
!
! ----------------------------------------------------------------------
!
    integer :: znbenc
    parameter (znbenc=60)
    integer :: tabaut(znbenc)
!
    character(len=24) :: k24bid
    character(len=24) :: oldfon
    integer :: jfonci
    integer :: ichar, nbchar
    character(len=8) :: charge, typech, nomfct, newfct
    character(len=6) :: nomobj
    character(len=16) :: typfct, motcle, nomcmd, phenom
    character(len=13) :: prefob
    integer :: motclc(2)
    aster_logical :: lfchar, lfmult, lformu, lccomb, lpchar
    integer :: nbauth, nbnaut, mclaut(2), iposit
    integer :: iprec, ibid, itypob(2), ibid2(2)
    character(len=19) :: carteo, cartei
    aster_logical :: lvolu, l1d2d, l2d3d, lpres
    aster_logical :: lepsi, lpesa, lrota
    aster_logical :: lfvolu, lf1d2d, lf2d3d, lfpres
    aster_logical :: lfepsi, lfpesa, lfrota
!
! ----------------------------------------------------------------------
!
    call jemarq()
!
! - INITIALISATIONS
!
    lfonc = .false.
    nomcmd = 'CALC_G'
    phenom = 'MECANIQUE'
    lvolu = .false.
    l1d2d = .false.
    l2d3d = .false.
    lpres = .false.
    lepsi = .false.
    lpesa = .false.
    lrota = .false.
    lfvolu = .false.
    lf1d2d = .false.
    lf2d3d = .false.
    lfpres = .false.
    lfepsi = .false.
    lfpesa = .false.
    lfrota = .false.
    lformu = .false.
    lpchar = .false.
    lccomb = .false.
    call lisnnb(lischa, nbchar)
!
! - STOCKAGE DES TYPES DE CHARGE (FONCTION OU PAS)
!
    oldfon = '&&GCHARG.FONCI'
    if (nbchar .gt. 0) call wkvect(oldfon, 'V V L', nbchar, jfonci)
!
    do 10 ichar = 1, nbchar
!
! ----- NOM DE LA CHARGE
!
        call lislch(lischa, ichar, charge)
!
! ----- ENTIERS CODES POUR LES MOTS-CLEFS DE LA CHARGE
!
        call lislcm(lischa, ichar, motclc)
!
! ----- TYPE DE LA CHARGE (REELLE OU FONCTION)
!
        call lisltc(lischa, ichar, typech)
        if (typech(1:4) .eq. 'FONC') then
            lfonc = .true.
            lfchar = .true.
        else
            lfchar = .false.
        endif
!
! ----- CE CHARGEMENT EST FONCTION
!
        zl(jfonci+ichar-1) = lfchar
!
! ----- FONCTION MULTIPLICATRICE
!
        call lisltf(lischa, ichar, typfct)
        call lislnf(lischa, ichar, nomfct)
        lfmult = .false.
        if (typfct(1:5) .eq. 'FONCT') then
            lfmult = .true.
        endif
!
! ----- CHARGEMENTS UTILISES OU NON DANS CALC_G
!
        call lisccc(nomcmd, motclc, nbauth, nbnaut, mclaut)
!
        if (nbauth .ne. 0) then
!
! --------- DECODAGE
!
            call isdeco(mclaut, tabaut, znbenc)
!
! --------- BOUCLE SUR LES MOTS-CLEFS
!
            do 15 iposit = 1, znbenc
                if (tabaut(iposit) .eq. 1) then
!
! ----------------- MOT-CLEF DE LA CHARGE
!
                    call lisdef('MOTC', k24bid, iposit, motcle, ibid2)
                    if (motcle .eq. 'DIRI_DUAL') goto 12
!
! ----------------- PREFIXE DE L'OBJET DE LA CHARGE
!
                    call lisnnl(phenom, charge, prefob)
!
! ----------------- CARTE D'ENTREE
!
                    call lisdef('CART', motcle, ibid, nomobj, itypob)
                    ASSERT(itypob(1).eq.1)
                    cartei = prefob(1:13)//nomobj(1:6)
!
! ----------------- SELECTION SUIVANT TYPE
!
                    call gcsele(motcle, chvolu, ch1d2d, ch2d3d, chpres,&
                                chepsi, chpesa, chrota, lvolu, l1d2d,&
                                l2d3d, lpres, lepsi, lpesa, lrota,&
                                lfvolu, lf1d2d, lf2d3d, lfpres, lfepsi,&
                                lfpesa, lfrota, carteo, lformu, lpchar,&
                                lccomb)
!
! ----------------- PREPARATION NOM DE LA FONCTION RESULTANTE
!
                    call gcfonc(ichar, iord, cartei, lfchar, lfmult,&
                                newfct, lformu)
!
! ----------------- CONSTRUIT LA CARTE A PARTIR DU CHARGEMENT
!
                    call gcchar(ichar, iprec, time, carteo, lfchar,&
                                lpchar, lformu, lfmult, lccomb, cartei,&
                                nomfct, newfct, oldfon)
!
 12                 continue
                endif
 15         continue
        endif
 10 continue
!
! - SI ABSENCE D'UN CHAMP DE FORCES, CREATION D'UN CHAMP NUL
!
    if (.not.lvolu) then
        call mefor0(modele, chvolu, lfonc)
    endif
    if (.not.l1d2d) then
        call mefor0(modele, ch1d2d, lfonc)
    endif
    if (.not.l2d3d) then
        call mefor0(modele, ch2d3d, lfonc)
    endif
    if (.not.lpres) then
        call mepres(modele, chpres, lfonc)
    endif
!
    call jedetr(oldfon)
    call jedema()
end subroutine
