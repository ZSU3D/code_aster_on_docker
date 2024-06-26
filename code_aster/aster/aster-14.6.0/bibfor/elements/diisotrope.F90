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

subroutine diisotrope(option, nomte, ndim, nbt, nno,&
                  nc, ulm, dul, pgl, iret)
!
! person_in_charge: jean-luc.flejou at edf.fr
! --------------------------------------------------------------------------------------------------
!
!        COMPORTEMENT ISOTROPE
!
! --------------------------------------------------------------------------------------------------
!
!  IN
!     option   : option de calcul
!     nomte    : nom terme élémentaire
!     ndim     : dimension du problème
!     nbt      : nombre de terme dans la matrice de raideur
!     nno      : nombre de noeuds de l'élément
!     nc       : nombre de composante par noeud
!     ulm      : déplacement moins
!     dul      : incrément de déplacement
!     pgl      : matrice de passage de global à local
!
! --------------------------------------------------------------------------------------------------
!
    implicit none
    character(len=*) :: option, nomte
    integer :: ndim, nbt, nno, nc, iret
    real(kind=8) :: ulm(12), dul(12), pgl(3, 3)
!
#include "jeveux.h"
#include "asterc/r8miem.h"
#include "asterfort/assert.h"
#include "asterfort/diraidklv.h"
#include "asterfort/diklvraid.h"
#include "asterfort/infdis.h"
#include "asterfort/jevech.h"
#include "asterfort/pmavec.h"
#include "asterfort/rcvala.h"
#include "asterfort/rk5adp.h"
#include "asterfort/tecael.h"
#include "asterfort/ut2mlg.h"
#include "asterfort/ut2vlg.h"
#include "asterfort/utmess.h"
#include "asterfort/utpslg.h"
#include "asterfort/utpvlg.h"
#include "asterfort/vecma.h"
#include "asterfort/disc_isotr.h"
#include "blas/dcopy.h"
!
! --------------------------------------------------------------------------------------------------
!
    integer :: imat, ivarim, jdc, irep, jtp, jtm, ifono, icontp, ivarip, iadzi, iazk24, icompo
    integer :: icarcr, idf, ipi, imate, imater, jmat, nbmat, nbvale, jvale, jprol, tecro
    integer :: icontm, ii, neq, kk
    real(kind=8) :: r8bid, fl(12), klv(78), klc(144), raide(6)
    character(len=8) :: k8bid
    character(len=24) :: messak(6)
!   pour le matériau
    integer      :: codret(1)
    real(kind=8) :: valres(1)
!   pour la loi de comportement
    integer :: nbpara, nbfct, iloi
    parameter  (nbpara=2, nbfct=1*5)
    integer          :: ldcfct(nbfct)
    real(kind=8)     :: ldcpar(nbpara)
    real(kind=8)     :: temps0, temps1, dtemps
    character(len=8) :: ldccar(1)
!   Équations du système
    integer :: nbequa, nbdecp
    parameter  (nbequa=14)
    real(kind=8) :: y0(nbequa), dy0(nbequa), resu(nbequa*2), ynorme(nbequa)
    real(kind=8) :: errmax
!
    real(kind=8) :: precis
    parameter (precis=1.0e-08)
!
! --------------------------------------------------------------------------------------------------
!   Paramètres associés au matériau codé
    integer :: lmat, lfct
    parameter  ( lmat = 9 , lfct = 10 )
! --------------------------------------------------------------------------------------------------
!
!
    neq = nno*nc
!   Comportement
    call jevech('PCOMPOR', 'L', icompo)
!   Récupération du matériau
    call jevech('PMATERC', 'L', imater)
!   Variables internes a t- : Force  Up  Puiss  tangente
    call jevech('PVARIMR', 'L', ivarim)
!   Effort à t-
    call jevech('PCONTMR', 'L', icontm)
!   récupération des caractéristiques élastique
    call jevech('PCADISK', 'L', jdc)
    call infdis('REPK', irep, r8bid, k8bid)
!   Seulement en 3D
    if (nomte(1:10) .ne. 'MECA_DIS_T' ) then
        messak(1) = nomte
        messak(2) = option
        messak(3) = zk16(icompo+3)
        messak(4) = zk16(icompo)
        call tecael(iadzi, iazk24)
        messak(5) = zk24(iazk24-1+3)
        call utmess('F', 'DISCRETS_22', nk=5, valk=messak)
    endif
!   Seulement en repère local : irep = 2
    if (irep .ne. 2) then
        messak(1) = nomte
        messak(2) = option
        messak(3) = zk16(icompo+3)
        messak(4) = zk16(icompo)
        call tecael(iadzi, iazk24)
        messak(5) = zk24(iazk24-1+3)
        call utmess('F', 'DISCRETS_5', nk=5, valk=messak)
    endif
!   les caractéristiques sont toujours dans le repère local. on fait seulement une copie
    call dcopy(nbt, zr(jdc), 1, klv, 1)
!   Récupère les termes diagonaux de la matrice de raideur
    call diraidklv(nomte,raide,klv)
!
!   Adresse de la SD mater
    jmat = zi(imater)
!   Nombre de matériau sur la maille : 1 seul autorisé
    nbmat=zi(jmat)
    ASSERT(nbmat.eq.1)
!   Adresse du matériau codé
    imate = jmat+zi(jmat+nbmat+1)
!   Recherche du comportement dans la SD compor
    ipi = 0
    do kk = 1, zi(imate+1)
        if ( zk32(zi(imate)+kk-1)(1:16) .eq. zk16(icompo) ) then
            ipi = zi(imate+2+kk-1)
            goto 10
        endif
    enddo
    messak(1) = nomte
    messak(2) = option
    messak(3) = zk16(icompo+3)
    messak(4) = zk16(icompo)
    call tecael(iadzi, iazk24)
    messak(5) = zk24(iazk24-1+3)
    call utmess('F', 'DISCRETS_7', nk=5, valk=messak)
10  continue
!
    ldcfct(:) = -1
    iloi = -1
    idf = zi(ipi)+zi(ipi+1)
    do kk = 1, zi(ipi+2)
        if      ('FX  ' .eq. zk16(zi(ipi+3)+idf+kk-1)) then
            ldcfct(1) = ipi+lmat-1+lfct*(kk-1)
            iloi = 1
        else if ('FTAN ' .eq. zk16(zi(ipi+3)+idf+kk-1)) then
            ldcfct(1) = ipi+lmat-1+lfct*(kk-1)
            iloi = 2
        endif
    enddo
    ASSERT( ldcfct(1) .ne. -1 )
    ASSERT( iloi .ne. -1 )
!   Nombre de point de la fonction
    nbvale = zi(ldcfct(1))
!   Adresse des informations sur le type de fonction
    jprol  = zi(ldcfct(1)+1)
!   Adresse des valeurs de la fonction
    jvale  = zi(ldcfct(1)+2)
!   Type d'écrouissage
    tecro = 0
    if ( iloi == 2 ) then
        call rcvala(jmat, ' ', 'DIS_ECRO_TRAC', 0, ' ',&
                    [0.0d0], 1, ['ECRO'], valres, codret, 1)
        tecro = nint( valres(1) )
    endif
!   Pour l'intégration
    ldcfct(1) = nbvale
    ldcfct(2) = jprol
    ldcfct(3) = jvale
    ldcfct(4) = iloi
    ldcfct(5) = tecro
!   les incréments de déplacement sont nuls
!       ==> récupération de la matrice tangente précédente, si possible
!       ==> si pas possible, pente initiale de la courbe
    if (option .eq. 'RIGI_MECA_TANG') then
        if   ( iloi == 1 ) then
!           La tangente est donnée par la pente initiale
            raide(1)= zr(jvale+nbvale+1)/zr(jvale+1)
!           Tangente précédente
            if (abs(zr(ivarim-1+15)) .gt. r8miem()) then
                raide(1) = zr(ivarim-1+15)
            endif
        else
!           La tangente est donnée par la pente initiale
            raide(2)= zr(jvale+nbvale+1)/zr(jvale+1)
            raide(3)= raide(2)
!           Tangente précédente
            if (abs(zr(ivarim-1+16)) .gt. r8miem()) then
                raide(2) = zr(ivarim-1+16)
            endif
            if (abs(zr(ivarim-1+16)) .gt. r8miem()) then
                raide(3) = zr(ivarim-1+16)
            endif
        endif
        goto 800
    endif
!
!   loi de comportement non-linéaire : récupération du temps + et - , calcul de dt
    call jevech('PINSTPR', 'L', jtp)
    call jevech('PINSTMR', 'L', jtm)
    temps0 = zr(jtm)
    temps1 = zr(jtp)
    dtemps = temps1 - temps0
!   contrôle de rk5 : découpage successif, erreur maximale
    call jevech('PCARCRI', 'L', icarcr)
!   nombre d'itérations maxi (ITER_INTE_MAXI)
    nbdecp = int(zr(icarcr))
!   tolérance de convergence (RESI_INTE_RELA)
    errmax = zr(icarcr+2)
!   équations du système :
!                    1 2 3       4 5 6  7      8         9 10 11  12 13 14
!       y0   : force(x,y,z) depl(x,y,z) Dissip pcum deplp(x,y,z)  X(x,y,z)   15 16 17
!       vari : force(x,y,z) depl(x,y,z) Dissip pcum deplp(x,y,z) dX(x,y,z)  tangente(x,y,z)
    y0(:)  = 0.0
    dy0(:) = 0.0
    if ( iloi == 1) then
        ! Déplacements précédent + incréments
        if (nno == 1) then
            y0(4)  = ulm(1)
            dy0(4) = dul(1)/dtemps
        else
            y0(4)  = (ulm(1+nc) - ulm(1))
            dy0(4) = (dul(1+nc) - dul(1))/dtemps
        endif
        ! Efforts précédents
        y0(1) = zr(icontm)
    else
        ! Déplacements précédent + incréments
        if (nno == 1) then
            y0(5)  = ulm(2)
            dy0(5) = dul(2)/dtemps
            y0(6)  = ulm(3)
            dy0(6) = dul(3)/dtemps
        else
            y0(5)  = (ulm(2+nc) - ulm(2))
            dy0(5) = (dul(2+nc) - dul(2))/dtemps
            y0(6)  = (ulm(3+nc) - ulm(3))
            dy0(6) = (dul(3+nc) - dul(3))/dtemps
        endif
        ! Efforts précédents
        y0(2) = zr(icontm+1)
        y0(3) = zr(icontm+2)
    endif
!   Récupération des variables internes
    y0(7:14)  = zr(ivarim-1+7:ivarim-1+14)
!   Le seuil élastique et le déplacement correspondant
    ldcpar(1) = zr(jvale+nbvale+1)
    ldcpar(2) = zr(jvale+1)
!   Norme pour le critère d'erreur
    ynorme(1:3)   = ldcpar(1)/10.0
    ynorme(4:6)   = ldcpar(2)/10.0
    ynorme(7)     = ldcpar(1)*ldcpar(2)/100.0
    ynorme(8:11)  = ldcpar(2)/10.0
    ynorme(12:14) = ldcpar(1)/100.0
!
    call rk5adp(nbequa, ldcpar, ldcfct, ldccar, temps0, dtemps, nbdecp,&
                errmax, y0, dy0, disc_isotr, resu, iret, ynorme)
!   resu(1:nbeq)            : variables intégrées
!   resu(nbeq+1:2*nbeq)     : d(resu)/d(t) a t+dt
    if (iret .ne. 0) goto 999
!
!   calcul de la tangente au comportement
    if ( iloi == 1 ) then
        raide(1)=ldcpar(1)/ldcpar(2)
        if (abs(resu(nbequa+4)) .gt. precis) then
            raide(1) = resu(nbequa+1)/resu(nbequa+4)
        endif
    else
        raide(2) = ldcpar(1)/ldcpar(2)
        raide(3) = raide(2)
        if (abs(resu(nbequa+5)) .gt. precis) then
            raide(2) = resu(nbequa+2)/resu(nbequa+5)
        endif
        if (abs(resu(nbequa+6)) .gt. precis) then
            raide(3) = resu(nbequa+3)/resu(nbequa+6)
        endif
    endif
!   actualisation de la matrice quasi-tangente
800 continue
!
!   Actualisation des termes diagonaux
    call diklvraid(nomte, klv, raide)
!   Actualisation de la matrice quasi-tangente
    if (option .eq. 'FULL_MECA' .or. option .eq. 'RIGI_MECA_TANG') then
        call jevech('PMATUUR', 'E', imat)
        if (ndim .eq. 3) then
            call utpslg(nno, nc, pgl, klv, zr(imat))
        else if (ndim.eq.2) then
            call ut2mlg(nno, nc, pgl, klv, zr(imat))
        endif
    endif
!
    if (option .eq. 'FULL_MECA' .or. option .eq. 'RAPH_MECA') then
!       calcul des efforts généralisés, des forces nodales
        call jevech('PVECTUR', 'E', ifono)
        call jevech('PCONTPR', 'E', icontp)
!       demi-matrice klv transformée en matrice pleine klc
        call vecma(klv, nbt, klc, neq)
!       calcul de fl = klc.dul (incrément d'effort)
        call pmavec('ZERO', neq, klc, dul, fl)
!       efforts généralisés aux noeuds 1 et 2 (repère local)
!       on change le signe des efforts sur le premier noeud pour les MECA_DIS_TR_L et MECA_DIS_T_L
        if (nno .eq. 1) then
            do ii = 1, nc
                zr(icontp-1+ii) = fl(ii) + zr(icontm-1+ii)
                fl(ii)          = fl(ii) + zr(icontm-1+ii)
            enddo
            if ( iloi == 1 ) then
                zr(icontp-1+1) = resu(1)
                fl(1)          = resu(1)
            else
                zr(icontp-1+2) = resu(2)
                zr(icontp-1+3) = resu(3)
                fl(2)          = resu(2)
                fl(3)          = resu(3)
            endif
        else if (nno.eq.2) then
            do ii = 1, nc
                zr(icontp-1+ii)    = -fl(ii)    + zr(icontm-1+ii)
                zr(icontp-1+ii+nc) =  fl(ii+nc) + zr(icontm-1+ii+nc)
                fl(ii)             =  fl(ii)    - zr(icontm-1+ii)
                fl(ii+nc)          =  fl(ii+nc) + zr(icontm-1+ii+nc)
            enddo
            if ( iloi == 1 ) then
                zr(icontp-1+1)    =  resu(1)
                zr(icontp-1+1+nc) =  resu(1)
                fl(1)             = -resu(1)
                fl(1+nc)          =  resu(1)
            else
                zr(icontp-1+2)    =  resu(2)
                zr(icontp-1+3)    =  resu(3)
                zr(icontp-1+2+nc) =  resu(2)
                zr(icontp-1+3+nc) =  resu(3)
                fl(2)             = -resu(2)
                fl(3)             = -resu(3)
                fl(2+nc)          =  resu(2)
                fl(3+nc)          =  resu(3)
            endif
        endif
!       forces nodales aux noeuds 1 et 2 (repère global)
        if (nc .ne. 2) then
            call utpvlg(nno, nc, pgl, fl, zr(ifono))
        else
            call ut2vlg(nno, nc, pgl, fl, zr(ifono))
        endif
!       mise à jour des variables internes
        call jevech('PVARIPR', 'E', ivarip)
        zr(ivarip-1+1:ivarip-1+14) = resu(1:14)
        zr(ivarip-1+15)            = raide(1)
        zr(ivarip-1+16)            = raide(2)
        zr(ivarip-1+17)            = raide(3)
        if (nno .eq. 2) then
            zr(ivarip-1+18:ivarip-1+34) = zr(ivarip-1+1:ivarip-1+17)
        endif
    endif
999 continue
end subroutine
