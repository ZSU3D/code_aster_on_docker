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

subroutine verif_loi_mater(mater)
!
!
! --------------------------------------------------------------------------------------------------
!
!               VÉRIFICATION D'INFORMATIONS DONNÉES POUR LES LDC
!
!   Lois traitées
!       - DIS_CONTACT                responsable : jean-luc.flejou at edf.fr
!       - DIS_ECRO_TRAC              responsable : jean-luc.flejou at edf.fr
!
! --------------------------------------------------------------------------------------------------
!
    implicit none
    character(len=8) :: mater
!
#include "jeveux.h"
#include "asterc/r8prem.h"
#include "asterfort/assert.h"
#include "asterfort/jelira.h"
#include "asterfort/jeveuo.h"
#include "asterfort/rccome.h"
#include "asterfort/utmess.h"
#include "asterfort/indk16.h"
!
! --------------------------------------------------------------------------------------------------
!
    integer             :: cc, kk, nbcrme, iret, nbr, nbc, nbk2, nbk
    integer             :: jprol, jvale, nbvale
    real(kind=8)        :: dx, fx, dfx, raidex
    logical             :: OkFct
    character(len=19)   :: nomfon
!
    character(len=11) :: k11
    character(len=19) :: noobrc
    character(len=24) :: chprol, chvale, chpara
    character(len=32) :: valk(2)
    character(len=32) :: nomrc
!
    real(kind=8), pointer       :: matr(:)      => null()
    character(len=16), pointer  :: matk(:)      => null()
    character(len=32), pointer  :: vnomrc(:)    => null()
!
    integer :: icoulomb, ia_nor, ia_tan, iecro, ifx, ifyz, tecro
    logical :: alarme
!
    real(kind=8) :: precis
    parameter (precis=1.0e-08)
!
! --------------------------------------------------------------------------------------------------
!   Nombre de relations de comportement
    call jelira(mater//'.MATERIAU.NOMRC', 'LONMAX', nbcrme)
!
!   Tableau des relations de comportement
    call jeveuo(mater//'.MATERIAU.NOMRC', 'L', vk32=vnomrc)
!
!   Boucle sur les relations de comportement
    do cc = 1, nbcrme
        nomrc = vnomrc(cc)
        if ( nomrc .eq. 'DIS_CONTACT' ) then
            call rccome(mater, nomrc, iret, iarret=1, k11_ind_nomrc=k11)
            noobrc = mater//k11
!           Récupération des noms et valeurs des paramètres
            call jelira(noobrc//'.VALR', 'LONUTI', nbr)
            call jelira(noobrc//'.VALK', 'LONUTI', nbk)
            ASSERT( nbr.eq.nbk )
            call jeveuo(noobrc//'.VALR', 'L', vr  =matr)
            call jeveuo(noobrc//'.VALK', 'L', vk16=matk)
!           Vérifications
!               Si COULOMB et (AMOR_NOR ou AMOR_TAN) différents de 0 ==> <A>
            icoulomb = indk16(matk,'COULOMB',1,nbk)
            if (icoulomb .ne. 0) then
                if ( abs(matr(icoulomb)).gt.r8prem() ) then
                    ia_nor = indk16(matk,'AMOR_NOR',1,nbk)
                    ia_tan = indk16(matk,'AMOR_TAN',1,nbk)
                    alarme = .False.
                    if (ia_nor.ne.0) then
                        if ( abs(matr(ia_nor)).gt.r8prem() ) alarme = .True.
                    endif
                    if (ia_tan.ne.0) then
                        if ( abs(matr(ia_tan)).gt.r8prem() ) alarme = .True.
                    endif
                    if ( alarme ) then
                        call utmess('A', 'DISCRETS_52')
                    endif
                endif
            endif
        else if ( nomrc .eq. 'DIS_ECRO_TRAC' ) then
            call rccome(mater, vnomrc(cc), iret, iarret=1, k11_ind_nomrc=k11)
            noobrc = mater//k11
            ! Nombre de : réel, complexe , chaine de caractères
            call jelira(noobrc//'.VALR', 'LONUTI', nbr)
            call jelira(noobrc//'.VALC', 'LONUTI', nbc)
            call jelira(noobrc//'.VALK', 'LONUTI', nbk2)
            ASSERT( nbc .eq. 0 )
            ! Récupération des pointeurs sur les valeurs
            call jeveuo(noobrc//'.VALR', 'L', vr  =matr)
            call jeveuo(noobrc//'.VALK', 'L', vk16=matk)
            nbk=(nbk2-nbr-nbc)/2
            ifx  = indk16(matk,'FX', 1,nbk2)
            ifyz = indk16(matk,'FTAN',1,nbk2)
            ! Nom de la fonction
            if      (ifx.ne.0) then
                nomfon = matk(ifx+nbk)(1:8)
            else if (ifyz.ne.0) then
                nomfon = matk(ifyz+nbk)(1:8)
            else
                ASSERT( .false. )
            endif
            iecro  = indk16(matk,'ECRO', 1,nbk2)
            ASSERT( iecro .ne. 0 )
            tecro = nint(matr(iecro))
!           Quelques vérifications sur la fonction
!               interpolation LIN LIN
!               paramètre 'DX' ou 'DTAN'
!               prolongée à gauche ou à droite exclue
!               avoir 3 points minimum ou exactement
!               FX et DX sont positifs, point n°1:(DX=0, FX=0)
!               dFx >0 , dDx >0
            chprol = nomfon//'.PROL'
            chvale = nomfon//'.VALE'
            chpara = nomfon//'.PARA'
!           Adresses
            call jeveuo(chprol, 'L', jprol)
            call jeveuo(chvale, 'L', jvale)
            call jelira(chvale, 'LONMAX', nbvale)
            nbvale = nbvale/2
!           vérifications sur les valeurs de la fonction
            dx = zr(jvale)
            fx = zr(jvale+nbvale)
            OkFct = (zk24(jprol)(1:8) .eq. 'FONCTION')
            OkFct = OkFct .and. (zk24(jprol+1)(1:3) .eq. 'LIN')
            OkFct = OkFct .and. (zk24(jprol+1)(5:7) .eq. 'LIN')
            if (ifx.ne.0) then
                OkFct = OkFct .and. (zk24(jprol+2)(1:2) .eq. 'DX')
                OkFct = OkFct .and. (nbvale .ge. 3 )
            else if (ifyz.ne.0) then
                OkFct = OkFct .and. (zk24(jprol+2)(1:4) .eq. 'DTAN')
                if (tecro.eq.1) then
                    OkFct = OkFct .and. (nbvale .ge. 3 )
                else
                    OkFct = OkFct .and. (nbvale .eq. 3 )
                endif
            endif
            OkFct = OkFct .and. (zk24(jprol+4)(1:2) .eq. 'EE')
            OkFct = OkFct .and. (dx .ge. 0.0d0 ) .and. (dx .le. precis)
            OkFct = OkFct .and. (fx .ge. 0.0d0 ) .and. (fx .le. precis)
            if ( OkFct ) then
                cik1: do kk = 1, nbvale-1
                    if ( ( zr(jvale+kk) .le. dx ) .or. &
                         ( zr(jvale+nbvale+kk) .le. fx ) ) then
                        OkFct = .false.
                        exit cik1
                    endif
                    if ( kk .eq. 1 ) then
                        raidex = (zr(jvale+nbvale+kk) - fx)/(zr(jvale+kk) - dx)
                        dfx = raidex
                    else
                        dfx = (zr(jvale+nbvale+kk) - fx)/(zr(jvale+kk) - dx)
                        if ( dfx .gt. raidex ) then
                            OkFct = .false.
                            exit cik1
                        endif
                    endif
                    dx     = zr(jvale+kk)
                    fx     = zr(jvale+nbvale+kk)
                    raidex = dfx
                enddo cik1
            endif
            if ( .not. OkFct ) then
                valk(1) = 'DIS_ECRO_TRAC'
                valk(2) = 'FX=f(DX) | FTAN=f(DTAN)'
                call utmess('F', 'DISCRETS_62', nk=2, valk=valk)
            endif
        endif
    enddo

end subroutine
