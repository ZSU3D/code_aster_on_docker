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
!
subroutine nmetca(modele, noma, ds_material, sddisc, sdcriq,&
                  numins, valinc)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/calcul.h"
#include "asterfort/cetule.h"
#include "asterfort/dbgcal.h"
#include "asterfort/detrsd.h"
#include "asterfort/diinst.h"
#include "asterfort/exisd.h"
#include "asterfort/infdbg.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mecact.h"
#include "asterfort/mechti.h"
#include "asterfort/megeom.h"
#include "asterfort/mesomm.h"
#include "asterfort/nmchex.h"
#include "asterfort/utmess.h"
!
character(len=8) :: noma
character(len=24) :: modele, sdcriq
type(NL_DS_Material), intent(in) :: ds_material
character(len=19) :: valinc(*)
integer :: numins
character(len=19) :: sddisc
!
! ----------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (ALGORITHME)
!
! CALCUL DE L'INDICATEUR D'ERREUR TEMPORELLE POUR LES MODELISATIONS
! HM SATUREES AVEC COMPORTEMENT MECANIQUE ELASTIQUE
!
! ----------------------------------------------------------------------
!
! IN  MODELE : NOM DU MODELE
! In  ds_material      : datastructure for material parameters
! IN  SDDISC : SD DISCRETISATION TEMPORELLE
! IN  SDERRO : SD ERREUR
! IN  NUMINS : NUMERO INSTANT COURANT
! IN  NOMA   : MAILLAGE SOUS-TENDU PAR LE MAILLAGE
! IN  VALINC : VARIABLE CHAPEAU POUR INCREMENTS VARIABLES
! IN  SDCRIQ : SD CRITERE QUALITE
!
! ----------------------------------------------------------------------
!
    integer :: nbout, nbin
    parameter    (nbout=1, nbin=6)
    character(len=8) :: lpaout(nbout), lpain(nbin)
    character(len=19) :: lchout(nbout), lchin(nbin)
!
    integer :: npara
    parameter  ( npara = 2 )
    character(len=8) :: licmp(npara)
    real(kind=8) :: rcmp(npara)
!
    integer :: codret, iret
    character(len=1) :: base
    character(len=24) :: ligrmo, chgeom
    character(len=24) :: chtime
    character(len=24) :: cartca
    character(len=19) :: sigmam, sigmap, chelem
    real(kind=8) :: somme(1)
    real(kind=8) :: instap, instam, deltat
    real(kind=8) :: longc, presc
    character(len=24) :: errthm
    integer :: jerrt
    real(kind=8) :: r8bid
    real(kind=8) :: taberr(2), tbgrca(3)
    character(len=16) :: option
    aster_logical :: debug
    integer :: ifmdbg, nivdbg
!
! ----------------------------------------------------------------------
!
    call jemarq()
    call infdbg('PRE_CALCUL', ifmdbg, nivdbg)
!
! --- INITIALISATIONS
!
    option = 'ERRE_TEMPS_THM'
    ligrmo = modele(1:8)//'.MODELE'
    if (nivdbg .ge. 2) then
        debug = .true.
    else
        debug = .false.
    endif
    base = 'V'
    cartca = '&&NMETCA.GRDCA'
    chelem = '&&NMETCA_ERRE_TEMPS'
!
! --- INSTANTS
!
    instap = diinst(sddisc,numins)
    instam = diinst(sddisc,numins-1)
    deltat = instap-instam
!
! --- RECUPERATION TABLEAU GRANDEURS
!
    call cetule(modele, tbgrca, codret)
    longc = tbgrca(1)
    presc = tbgrca(2)
!
! --- ERREUR PRECEDENTE
!
    errthm = sdcriq(1:19)//'.ERRT'
    call jeveuo(errthm, 'E', jerrt)
    taberr(1) = zr(jerrt-1+1)
    taberr(2) = zr(jerrt-1+2)
!
! --- CONTRAINTES
!
    call nmchex(valinc, 'VALINC', 'SIGMOI', sigmam)
    call nmchex(valinc, 'VALINC', 'SIGPLU', sigmap)
!
! --- CARTE GEOMETRIE
!
    call megeom(modele, chgeom)
!
! --- CARTE DES PARAMETRES TEMPORELS
!
    call mechti(noma, instap, r8bid, r8bid, chtime)
!
! --- CARTE DES PARAMETRES
!
    licmp(1) = 'X1'
    licmp(2) = 'X2'
    rcmp(1) = longc
    rcmp(2) = presc
!
    call mecact(base, cartca, 'MODELE', ligrmo, 'NEUT_R',&
                ncmp=npara, lnomcmp=licmp, vr=rcmp)
!
! --- CALCUL DES INDICATEURS LOCAUX PAR ELEMENT
!
    lpain(1) = 'PGEOMER'
    lchin(1) = chgeom(1:19)
    lpain(2) = 'PMATERC'
    lchin(2) = ds_material%field_mate(1:19)
    lpain(3) = 'PCONTGP'
    lchin(3) = sigmap(1:19)
    lpain(4) = 'PCONTGM'
    lchin(4) = sigmam(1:19)
    lpain(5) = 'PTEMPSR'
    lchin(5) = chtime(1:19)
    lpain(6) = 'PGRDCA'
    lchin(6) = cartca(1:19)
!
    lpaout(1) = 'PERREUR'
    lchout(1) = chelem
!
! --- APPEL A CALCUL
!
    if (debug) then
        call dbgcal(option, ifmdbg, nbin, lpain, lchin,&
                    nbout, lpaout, lchout)
    endif
    call calcul('C', option, ligrmo, nbin, lchin,&
                lpain, nbout, lchout, lpaout, base,&
                'OUI')
!
    call exisd('CHAMP_GD', lchout(1), iret)
    if (iret .eq. 0) then
        call utmess('F', 'CALCULEL2_88', sk=option)
        goto 999
    endif
!
! --- PASSAGE A UNE VALEUR GLOBALE EN ESPACE
!
    call mesomm(lchout(1), 1, vr=somme)
!
! --- INDICATEUR D'ERREUR LOCAL EN TEMPS / GLOBAL EN ESPACE
!
    taberr(1) = sqrt(deltat*somme(1))
!
! --- INDICATEUR D'ERREUR GLOBAL EN TEMPS / GLOBAL EN ESPACE
!
    taberr(2) = sqrt(taberr(2)**2 + taberr(1)**2)
!
! --- SAUVEGARDE
!
    zr(jerrt-1+1) = taberr(1)
    zr(jerrt-1+2) = taberr(2)
!
999 continue
!
! --- MENAGE
!
    call detrsd('CARTE', '&&NMETCA.GRDCA')
    call detrsd('CHAMP_GD', '&&NMETCA_ERRE_TEMPS_THM')
!
    call jedema()
!
end subroutine
