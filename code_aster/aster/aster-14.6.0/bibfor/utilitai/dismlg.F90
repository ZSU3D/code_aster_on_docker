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

subroutine dismlg(questi, nomobz, repi, repkz, ierd)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/dimge1.h"
#include "asterfort/dismma.h"
#include "asterfort/dismml.h"
#include "asterfort/dismte.h"
#include "asterfort/dismtm.h"
#include "asterfort/exisd.h"
#include "asterfort/ismali.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/lteatt.h"
#include "asterfort/teattr.h"
#include "asterfort/utmess.h"
!
    integer :: repi, ierd
    character(len=*) :: questi, repkz, nomobz
!     --     DISMOI(LIGREL)
!    IN:
!       QUESTI : TEXTE PRECISANT LA QUESTION POSEE
!       NOMOBZ : NOM D'UN OBJET DE TYPE LIGREL
!    OUT:
!       REPI   : REPONSE ( SI ENTIERE )
!       REPKZ  : REPONSE ( SI CHAINE DE CARACTERES )
!       IERD   : CODE RETOUR (0--> OK, 1 --> PB)
!
! ----------------------------------------------------------------------
!
    integer :: dimge(3)
    aster_logical :: melang
    character(len=8) :: calcri, mailla, nomacr, modele, typemail, k8bid, typmod2, typmod3
    character(len=16) :: nomte, phenom, nomodl, tyvois
    character(len=19) :: nomob
    character(len=32) :: repk
    integer :: jlgrf, iret, nbgrel, igrel, nel, itypel, jsssa, n1
    integer :: ige2, igr, jliel, ite, ige1, ige3, nbgr
    integer :: iexi, iexi2, ico
    integer :: jnomac, nbsm, ism, ibid
    aster_logical :: mail_quad, mail_line, lret
    integer :: ndime, nb_elem, i_typelem
    character(len=24) :: list_elem
    character(len=8), pointer :: typema(:) => null()
    integer, pointer :: nbno(:) => null()
    character(len=8), pointer :: partit(:) => null()
! DEB ------------------------------------------------------------------
!
    call jemarq()
    repk = ' '
    repi = 0
    ierd = 0
!
    nomob=nomobz

!   -- nomob est-il vraiment un ligrel ?
!   -----------------------------------
    call exisd('LIGREL', nomob, iexi)
    ASSERT(iexi.eq.1)

!
!   -----------------------------------
    if (questi .eq. 'NOM_MAILLA') then
!   -----------------------------------
        call jeveuo(nomob//'.LGRF', 'L', jlgrf)
        repk=zk8(jlgrf-1+1)
!
!     --------------------------------
    else if (questi.eq.'PARTITION') then
!     --------------------------------
        repk=' '
        call jeveuo(nomob//'.LGRF', 'L', jlgrf)
        modele=zk8(jlgrf-1+2)
        if (modele .ne. ' ') then
            call jeexin(modele//'.PARTIT', iexi)
            if (iexi .gt. 0) then
                call jeveuo(modele//'.PARTIT', 'L', vk8=partit)
                repk=partit(1)
            endif
        endif
!
!     -----------------------------------
    else if (questi.eq.'EXI_ELEM') then
!     -----------------------------------
        call jeexin(nomob//'.LIEL', iexi)
        repk='NON'
        if (iexi .gt. 0) repk='OUI'
!
!
!     -----------------------------------------------------------------
    else if ((questi.eq.'BESOIN_VOISIN')) then
!     -----------------------------------------------------------------
        repk='NON'
        call jeexin(nomob//'.LIEL', iexi)
        if (iexi .gt. 0) then
            call jelira(nomob//'.LIEL', 'NUTIOC', nbgrel)
            do igrel = 1, nbgrel
                call jeveuo(jexnum(nomob//'.LIEL', igrel), 'L', jliel)
                call jelira(jexnum(nomob//'.LIEL', igrel), 'LONMAX', nel)
                itypel=zi(jliel-1+nel)
                call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)
                call teattr('C', 'TYPE_VOISIN', tyvois, iret, typel=nomte)
                if (iret .eq. 0) then
                    repk='OUI'
                    exit
                endif
            end do
        endif
!
!
!
!     -----------------------------------------------------------------
    elseif ((questi.eq.'EXI_RDM') .or. (questi.eq.'EXI_POUX') .or.&
            (questi(1:7).eq.'EXI_THM') .or. (questi.eq.'EXI_TUYAU') .or. &
            (questi.eq.'EXI_COQ3D') .or. (questi.eq.'EXI_COQ1D') .or.&
            (questi.eq.'EXI_GRILLE') .or. (questi.eq.'EXI_PLAQUE') .or.&
            (questi.eq.'EXI_COQUE') .or. (questi.eq.'CALC_RIGI') .or.&
            (questi.eq.'EXI_STRX') .or. (questi.eq.'EXI_STR2') ) then
!
!     -----------------------------------------------------------------
        call jeexin(nomob//'.LIEL', iexi)
        if (iexi .gt. 0) then
            call jelira(nomob//'.LIEL', 'NUTIOC', nbgrel)
            repk='NON'
            do igrel = 1, nbgrel
                call jeveuo(jexnum(nomob//'.LIEL', igrel), 'L', jliel)
                call jelira(jexnum(nomob//'.LIEL', igrel), 'LONMAX', nel)
                itypel=zi(jliel-1+nel)
                call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)
!
                if (questi .eq. 'EXI_RDM') then
                    if (lteatt('COQUE','OUI', typel=nomte)) repk='OUI'
                    if (lteatt('POUTRE','OUI', typel=nomte)) repk='OUI'
                    if (lteatt('DISCRET','OUI', typel=nomte)) repk='OUI'
                    if (repk.eq.'OUI') exit
!
                else if (questi.eq.'CALC_RIGI') then
                    repk='NON'
                    call dismte(questi, nomte, repi, calcri, ierd)
                    if (calcri .eq. 'OUI') then
                        repk='OUI'
                        exit
!
                    endif
!
                else if (questi.eq.'EXI_COQUE') then
                    call dismte('MODELISATION', nomte, repi, nomodl, ierd)
                    if (nomodl(1:5) .eq. 'COQUE') then
                        repk='OUI'
                        exit
!
                    endif
!
                else if (questi.eq.'EXI_GRILLE') then
                    call dismte('MODELISATION', nomte, repi, nomodl, ierd)
                    repk='NON'
                    if (nomodl(1:6) .eq. 'GRILLE') then
                        repk='OUI'
                        exit
!
                    endif
!
                    elseif ((questi.eq.'EXI_COQ3D') .or. (&
                questi.eq.'EXI_COQ1D')) then
                    call dismte('MODELISATION', nomte, repi, nomodl, ierd)
                    if (nomodl(1:8) .eq. 'COQUE_3D') then
                        repk='OUI'
                        exit
!
                    endif
!
                else if (questi.eq.'EXI_PLAQUE') then
                    call dismte('MODELISATION', nomte, repi, nomodl, ierd)
                    if ((nomodl(1:3).eq.'DKT') .or. (nomodl(1:3) .eq.'DST') .or.&
                        (nomodl(1:3).eq.'Q4G')) then
                        repk='OUI'
                        exit
!
                    endif
!
                else if (questi.eq.'EXI_TUYAU') then
                    if ((nomte.eq.'MET3SEG3') .or. ( nomte.eq.'MET3SEG4') .or.&
                        (nomte.eq.'MET6SEG3')) then
                        repk='OUI'
                        exit
!
                    endif
!
                else if (questi.eq.'EXI_POUX') then
                    if ((nomte.eq.'MECA_POU_D_E') .or. ( nomte.eq.'MECA_POU_D_EM') .or.&
                        ( nomte.eq.'MECA_POU_D_T') .or. ( nomte.eq.'MECA_POU_D_TG') .or.&
                        ( nomte.eq.'MECA_POU_D_TGM')) then
                        repk='OUI'
                        exit
!
                    endif
!
                else if (questi.eq.'EXI_STRX') then
                    if ((nomte(1:10).eq.'MECA_POU_D') .and. ( nomte.ne.'MECA_POU_D_T_GD')) then
                        repk='OUI'
                        exit
!
                    endif
!
                else if (questi.eq.'EXI_STR2') then
                    if (nomte .eq. 'MECA_POU_D_EM') then
                        repk='OUI'
                        exit
!
                    endif
!
!
                else if (questi.eq.'EXI_THM') then
                    call teattr('C', 'TYPMOD2', typmod2, iret, typel=nomte)
                    if (typmod2 .eq. 'THM') then
                        repk='OUI'
                        call teattr('C', 'TYPMOD3', typmod3, iret, typel=nomte)
                        if (typmod3 .eq. 'STEADY') then
                            repk='OUI_P'
                        endif
                    endif
!
                else
                    ASSERT(.false.)
                endif
            end do
        else
            repk='NON'
        endif
!
!     ------------------------------------------
    elseif ((questi.eq.'NB_SM_MAILLA') .or.&
            (questi.eq.'NB_SS_ACTI') .or.&
            (questi.eq.'NB_NL_MAILLA')) then
!     ------------------------------------------
        call jeexin(nomob//'.SSSA', iexi)
        if (iexi .eq. 0) then
            repi=0
        else
            call jeveuo(nomob//'.SSSA', 'L', jsssa)
            call jelira(nomob//'.SSSA', 'LONMAX', n1)
            if (questi .eq. 'NB_SM_MAILLA') then
                repi=zi(jsssa-1+n1-2)
            else if (questi.eq.'NB_SS_ACTI') then
                repi=zi(jsssa-1+n1-1)
            else if (questi.eq.'NB_NL_MAILLA') then
                repi=zi(jsssa-1+n1)
            endif
        endif
!
!     ---------------------------------------
    else if (questi.eq.'NB_NO_MAILLA') then
!     ---------------------------------------
        call jeveuo(nomob//'.LGRF', 'L', jlgrf)
        call dismma(questi, zk8(jlgrf), repi, repk, ierd)
!
!     ---------------------------------------
    else if (questi.eq.'NB_MA_MAILLA') then
!     ---------------------------------------
        call jeveuo(nomob//'.LGRF', 'L', jlgrf)
        call dismma(questi, zk8(jlgrf), repi, repk, ierd)
!
!     -----------------------------------
    else if (questi.eq.'DIM_GEOM') then
!     -----------------------------------
        repi=0
        ige2=0
        call jeexin(nomob//'.LIEL', iexi)
        if (iexi .gt. 0) then
            call jelira(nomob//'.LIEL', 'NUTIOC', nbgr)
            dimge(1)=0
            dimge(2)=0
            dimge(3)=0
            melang=.false.
            do igr = 1, nbgr
                call jeveuo(jexnum(nomob//'.LIEL', igr), 'L', jliel)
                call jelira(jexnum(nomob//'.LIEL', igr), 'LONMAX', n1)
                ite=zi(jliel-1+n1)
                call jenuno(jexnum('&CATA.TE.NOMTE', ite), nomte)
                call dismte(questi, nomte, ige1, repk, ierd)
                ASSERT((ige1.ge.0) .and. (ige1.le.3))
                if ((ige2.eq.0) .and. (ige1.ne.0)) ige2=ige1
                if ((ige1*ige2.gt.0) .and. (ige1.ne.ige2)) melang= .true.
                if (ige1 .gt. 0) dimge(ige1)=1
            end do
            if (melang) then
                ige3=+100*dimge(1)
                ige3=ige3+10*2*dimge(2)
                ige3=ige3+1*3*dimge(3)
                ige2=ige3
            endif
        endif
!        -- SI IL EXISTE DES MACRO-ELEMENTS, IL FAUT EN TENIR COMPTE :
        call jeexin(nomob//'.SSSA', iexi2)
        if (iexi2 .gt. 0) then
            call jelira(nomob//'.SSSA', 'LONMAX', n1)
            call jeveuo(nomob//'.SSSA', 'L', jsssa)
            call jeveuo(nomob//'.LGRF', 'L', jlgrf)
            mailla=zk8(jlgrf-1+1)
            call jeveuo(mailla//'.NOMACR', 'L', jnomac)
            nbsm=n1-3
            do ism = 1, nbsm
                if (zi(jsssa-1+ism) .eq. 1) then
                    nomacr=zk8(jnomac-1+ism)
                    call dismml(questi, nomacr, ige1, repk, ierd)
                    ASSERT(ige1.ge.0 .and. ige1.le.123)
                    if (ige2 .ne. ige1) then
                        ige2=dimge1(ige2,ige1)
                    endif
                endif
            end do
        endif
        repi=ige2
!
!
!     ----------------------------------
    else if (questi.eq.'NB_GREL') then
!     ----------------------------------
        call jeexin(nomob//'.LIEL', iexi)
        if (iexi .gt. 0) then
            call jelira(nomob//'.LIEL', 'NUTIOC', repi)
        else
            repi=0
        endif
!
!     ------------------------------------
    else if (questi.eq.'NB_MA_SUP') then
!     ------------------------------------
        call jeexin(nomob//'.NEMA', iexi)
        if (iexi .gt. 0) then
            call jelira(nomob//'.NEMA', 'NUTIOC', repi)
        else
            repi=0
        endif
!
!     -----------------------------------------
    else if (questi.eq.'NB_NO_SUP') then
!     -----------------------------------------
        call jeveuo(nomob//'.NBNO', 'L', vi=nbno)
        repi=nbno(1)
!
!     -------------------------------------
    else if (questi.eq.'NOM_MODELE') then
!     -------------------------------------
        call jeveuo(nomob//'.LGRF', 'L', jlgrf)
        repk=zk8(jlgrf-1+2)
!
!     ------------------------------------
    else if (questi.eq.'PHENOMENE') then
!     ------------------------------------
        call jelira(nomob//'.LGRF', 'DOCU', cval=phenom)
        if (phenom(1:4) .eq. 'MECA') then
            repk='MECANIQUE'
        else if (phenom(1:4).eq.'THER') then
            repk='THERMIQUE'
        else if (phenom(1:4).eq.'ACOU') then
            repk='ACOUSTIQUE'
        else
            call utmess('F', 'UTILITAI_63', sk=phenom)
        endif
!
!
!     -----------------------------------------------------------------
    else if ((questi.eq.'EXI_AXIS'.or.questi.eq.'AXIS')) then
!     -----------------------------------------------------------------
        repk='NON'
        call jeexin(nomob//'.LIEL', iexi)
        ico=0
        if (iexi .gt. 0) then
            call jelira(nomob//'.LIEL', 'NUTIOC', nbgrel)
            do igrel = 1, nbgrel
                call jeveuo(jexnum(nomob//'.LIEL', igrel), 'L', jliel)
                call jelira(jexnum(nomob//'.LIEL', igrel), 'LONMAX', nel)
                itypel=zi(jliel-1+nel)
                call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)
                if (lteatt('AXIS','OUI', typel=nomte)) then
                    ico=ico+1
                endif
            end do
            if (questi .eq. 'EXI_AXIS' .and. ico .gt. 0) repk='OUI'
            if (questi .eq. 'AXIS' .and. ico .eq. nbgrel) repk='OUI'
        endif
!
!
!     ------------------------------------
    else if (questi.eq.'EXI_AMOR') then
!     ------------------------------------
        repk='NON'
!        -- SI IL EXISTE DES ELEMENTS "ABSORBANT" :
        call jelira(nomob//'.LIEL', 'NUTIOC', nbgrel)
        do igrel = 1, nbgrel
            call jeveuo(jexnum(nomob//'.LIEL', igrel), 'L', jliel)
            call jelira(jexnum(nomob//'.LIEL', igrel), 'LONMAX', nel)
            itypel=zi(jliel-1+nel)
            call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)
            if ((nomte(1:9).eq.'MEAB_FACE') .or. (nomte(1:6) .eq.'MEPASE')) then
                repk='OUI'
                goto 80
!
            endif
        end do
 80     continue
!        -- SI IL EXISTE DES MACRO-ELEMENTS, IL FAUT LES EXAMINER :
        if (repk .eq. 'NON') then
            call jeexin(nomob//'.SSSA', iexi2)
            if (iexi2 .gt. 0) then
                call jelira(nomob//'.SSSA', 'LONMAX', n1)
                call jeveuo(nomob//'.SSSA', 'L', jsssa)
                call jeveuo(nomob//'.LGRF', 'L', jlgrf)
                mailla=zk8(jlgrf-1+1)
                call jeveuo(mailla//'.NOMACR', 'L', jnomac)
                nbsm=n1-3
                do ism = 1, nbsm
                    if (zi(jsssa-1+ism) .eq. 1) then
                        nomacr=zk8(jnomac-1+ism)
                        call dismml(questi, nomacr, ibid, repk, ierd)
                        if (repk .eq. 'OUI') goto 100
                    endif
                end do
            endif
        endif
100     continue
!     -------------------------------------
    else if (questi.eq.'LINE_QUAD') then
!     -------------------------------------
        list_elem = nomob//'.LIEL'
        call jelira(list_elem, 'NUTIOC', nbgrel)
        call jeveuo('&CATA.TE.TYPEMA', 'L', vk8=typema)
        mail_quad = .false.
        mail_line = .false.
        do igrel = 1, nbgrel
            call jeveuo(jexnum(list_elem, igrel), 'L', jliel)
            call jelira(jexnum(list_elem, igrel), 'LONMAX', nb_elem)
            i_typelem = zi(jliel-1+nb_elem)
            typemail = typema(i_typelem)
            call dismtm('DIM_TOPO', typemail, ndime, k8bid, ibid)
            if (ndime .ne. 0) then
                lret = ismali(typemail)
                if (lret) mail_line = .true.
                if (.not.lret) mail_quad = .true.
            endif
        end do
        if (mail_line .and. mail_quad) then
            repk = 'LINE_QUAD'
        else if (mail_line) then
            repk = 'LINE'
        else if (mail_quad) then
            repk = 'QUAD'
        else
            ierd = 1
        endif
!
!     ----
    else
!     ----
        ierd=1
    endif
!
    repkz=repk
    call jedema()
end subroutine
