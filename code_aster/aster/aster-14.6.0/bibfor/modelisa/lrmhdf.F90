! --------------------------------------------------------------------
! Copyright (C) 1991 - 2019 - EDF R&D - www.code-aster.org
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
! person_in_charge: nicolas.sellenet at edf.fr
!
subroutine lrmhdf(nomamd, nomu, ifm, nrofic, niv,&
                  infmed, nbnoeu, nbmail, nbcoor)
!
    use as_med_module, only: as_med_open
    implicit none
!
#include "asterf_types.h"
#include "MeshTypes_type.h"
#include "asterc/utflsh.h"
#include "asterfort/as_mficlo.h"
#include "asterfort/as_mficom.h"
#include "asterfort/as_mfinvr.h"
#include "asterfort/as_mlbnuv.h"
#include "asterfort/codent.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetc.h"
#include "asterfort/jemarq.h"
#include "asterfort/lrmdes.h"
#include "asterfort/lrmmdi.h"
#include "asterfort/lrmmeq.h"
#include "asterfort/lrmmfa.h"
#include "asterfort/lrmmma.h"
#include "asterfort/lrmmno.h"
#include "asterfort/lrmtyp.h"
#include "asterfort/mdexma.h"
#include "asterfort/mdexpm.h"
#include "asterfort/sdmail.h"
#include "asterfort/ulisog.h"
#include "asterfort/utmess.h"
!
integer :: ifm, niv
integer :: nrofic, infmed
character(len=*) :: nomamd
character(len=8) :: nomu
integer :: nbnoeu, nbmail, nbcoor
!
! --------------------------------------------------------------------------------------------------
!
!     LECTURE DU MAILLAGE - FORMAT MED/HDF
!
! --------------------------------------------------------------------------------------------------
!
!     ENTREES :
!        NOMAMD : NOM MED DU MAILLAGE A LIRE
!                 SI ' ' : ON LIT LE PREMIER MAILLAGE DU FICHIER
!        NOMU   : NOM ASTER SOUS LEQUEL LE MAILLAGE SERA STOCKE
! ...
!     SORTIES:
!        NBNOEU : NOMBRE DE NOEUDS
!
! --------------------------------------------------------------------------------------------------
!
    character(len=6), parameter :: nompro = 'LRMHDF'
    integer, parameter :: edlect=0
    integer :: iaux 
    integer :: nmatyp(MT_NTYMAX)
    integer :: nnotyp(MT_NTYMAX), typgeo(MT_NTYMAX), nuanom(MT_NTYMAX, MT_NNOMAX)
    integer :: renumd(MT_NTYMAX), modnum(MT_NTYMAX), numnoa(MT_NTYMAX, MT_NNOMAX)
    integer :: nbtyp
    integer :: ndim, codret, nbnoma
    med_idt :: fid, ifimed
    integer :: nbltit, nbgrno, nbgrma
    integer :: vlib(3), vfic(3), iret
    integer :: vali(3), hdfok, medok
    character(len=1) :: saux01
    character(len=6) :: saux06
    character(len=8) :: nomtyp(MT_NTYMAX)
    character(len=8) :: saux08
    character(len=24) :: cooval, coodsc, cooref, grpnoe, grpmai, connex
    character(len=24) :: titre, nommai, nomnoe, typmai, adapma, gpptnn, gpptnm
    character(len=64) :: valk(2)
    character(len=200) :: nofimd, descfi
    character(len=255) :: kfic
    aster_logical :: existm
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
    call sdmail(nomu, nommai, nomnoe, cooval, coodsc,&
                cooref, grpnoe, gpptnn, grpmai, gpptnm,&
                connex, titre, typmai, adapma)
!
    descfi=' '
!
!====
! 1. PREALABLES
!====
!
    if (niv .gt. 1) then
        call utflsh(codret)
        write (ifm,101) 'DEBUT DE '//nompro
    endif
101 format(/,10('='),a,10('='),/)
!
! 1.1. ==> NOM DU FICHIER MED
!
    call ulisog(nrofic, kfic, saux01)
    if (kfic(1:1) .eq. ' ') then
        call codent(nrofic, 'G', saux08)
        nofimd = 'fort.'//saux08
    else
        nofimd = kfic(1:200)
    endif
!
    if (niv .gt. 1) then
        write (ifm,*) '<',nompro,'> NOM DU FICHIER MED : ',nofimd
    endif
!
! 1.2. ==> VERIFICATION DU FICHIER MED
!
! 1.2.1. ==> VERIFICATION DE LA VERSION HDF
!
    call as_mficom(nofimd, hdfok, medok, codret)
    if (hdfok .eq. 0) then
        valk (1) = nofimd(1:32)
        valk (2) = nomamd
        vali (1) = codret
        call utmess('A', 'MODELISA9_44', nk=2, valk=valk, si=vali(1))
        call utmess('F', 'PREPOST3_10')
    endif
!
! 1.2.2. ==> VERIFICATION DE LA VERSION MED
!
    if (medok .eq. 0) then
        vali (1) = codret
        call utmess('A+', 'MED_24', si=vali(1))
        call as_mlbnuv(vlib(1), vlib(2), vlib(3), iret)
        if (iret .eq. 0) then
            vali (1) = vlib(1)
            vali (2) = vlib(2)
            vali (3) = vlib(3)
            call utmess('A+', 'MED_25', ni=3, vali=vali)
        endif
        call as_med_open(fid, nofimd, edlect, codret)
        call as_mfinvr(fid, vfic(1), vfic(2), vfic(3), iret)
        if (iret .eq. 0) then
            if (vfic(2) .eq. -1 .or. vfic(3) .eq. -1) then
                call utmess('A+', 'MED_26')
            else
                vali (1) = vfic(1)
                vali (2) = vfic(2)
                vali (3) = vfic(3)
                call utmess('A+', 'MED_27', ni=3, vali=vali)
            endif
            if (vfic(1) .lt. vlib(1) .or. ( vfic(1).eq.vlib(1) .and. vfic(2).lt.vlib(2) )&
                .or.&
                (&
                vfic(1) .eq. vlib(1) .and. vfic( 2) .eq. vlib(2) .and. vfic(3) .eq. vlib(3)&
                )) then
                call utmess('A+', 'MED_28')
            endif
        endif
        call as_mficlo(fid, codret)
        call utmess('A', 'MED_41')
    endif
!
! 1.3. ==> VERIFICATION DE L'EXISTENCE DU MAILLAGE A LIRE
!
! 1.3.1. ==> C'EST LE PREMIER MAILLAGE DU FICHIER
!            ON RECUPERE SON NOM ET SA DIMENSION.
!
    if (nomamd .eq. ' ') then
!
        ifimed = 0
        call mdexpm(nofimd, ifimed, nomamd, existm, ndim,&
                    codret)
        if (.not.existm) then
            call utmess('F', 'MED_50', sk=nofimd)
        endif
!
! 1.3.2. ==> C'EST UN MAILLAGE DESIGNE PAR UN NOM
!            ON RECUPERE SA DIMENSION.
!
    else
!
        iaux = 1
        ifimed = 0
        call mdexma(nofimd, ifimed, nomamd, iaux, existm,&
                    ndim, codret)
        if (.not.existm) then
            valk(1) = nomamd
            valk(2) = nofimd(1:32)
            call utmess('F', 'MED_51', nk=2, valk=valk)
        endif
!
    endif
!
    nbcoor = ndim
    if (ndim .eq. 1) nbcoor = 2
!
!====
! 2. DEMARRAGE
!====
!
! 2.1. ==> OUVERTURE FICHIER MED EN LECTURE
!
    call as_med_open(fid, nofimd, edlect, codret)
    if (codret .ne. 0) then
        valk (1) = nofimd(1:32)
        valk (2) = nomamd
        vali (1) = codret
        call utmess('A', 'MODELISA9_51', nk=2, valk=valk, si=vali(1))
        call utmess('F', 'PREPOST_69')
    endif
!
!
! 2.2. ==> . RECUPERATION DES NB/NOMS/NBNO/NBITEM DES TYPES DE MAILLES
!            DANS CATALOGUE
!          . RECUPERATION DES TYPES GEOMETRIE CORRESPONDANT POUR MED
!          . VERIF COHERENCE AVEC LE CATALOGUE
!
    call lrmtyp(nbtyp, nomtyp, nnotyp, typgeo, renumd,&
                modnum, nuanom, numnoa)
!
!====
! 3. DESCRIPTION
!====
!
    call lrmdes(fid, nbltit, descfi, titre)
!
!====
! 4. DIMENSIONNEMENT
!====
!
    call lrmmdi(fid, nomamd, typgeo, nomtyp, nnotyp,&
                nmatyp, nbnoeu, nbmail, nbnoma, descfi,&
                adapma)
!
!====
! 5. LES NOEUDS
!====
!
    call lrmmno(fid, nomamd, ndim, nbnoeu, nomu,&
                nomnoe, cooval, coodsc, cooref, ifm,&
                infmed)
!
!====
! 6. LES MAILLES
!====
!
    saux06 = nompro
!
    call lrmmma(fid, nomamd, nbmail, nbnoma, nbtyp,&
                typgeo, nomtyp, nnotyp, renumd, nmatyp,&
                nommai, connex, typmai, saux06, infmed,&
                modnum, numnoa)
!
!====
! 7. LES FAMILLES
!====
!
    saux06 = nompro
!
    call lrmmfa(fid, nomamd, nbnoeu, grpnoe,&
                gpptnn, grpmai, gpptnm, nbgrno, nbgrma,&
                typgeo, nomtyp, nmatyp, saux06, infmed)
!
!====
! 8. LES EQUIVALENCES
!====
!
    call lrmmeq(fid, nomamd, infmed)
!
!====
! 9. FIN
!====
!
! 9.1. ==> FERMETURE FICHIER
!
    call as_mficlo(fid, codret)
    if (codret .ne. 0) then
        valk (1) = nofimd(1:32)
        valk (2) = nomamd
        vali (1) = codret
        call utmess('A', 'MODELISA9_52', nk=2, valk=valk, si=vali(1))
        call utmess('F', 'PREPOST_70')
    endif
!
! 9.2. ==> MENAGE
!
    call jedetc('V', '&&'//nompro, 1)
!
    call jedema()
!
    if (niv .gt. 1) then
        write (ifm,101) 'FIN DE '//nompro
        call utflsh(codret)
    endif
!
end subroutine
