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

subroutine te0478(option, nomte)
!
! aslint: disable=W0104
!
! --------------------------------------------------------------------------------------------------
!
!     CALCUL DES COORDONNEES DES POINTS DE GAUSS + POIDS
!     POUR LES ELEMENTS 0D ET 1D (POI ET SEG)
!
!     TRAITEMENT SPECIFIQUE POUR LES ELEMENTS A SOUS POINTS
!     (PMF, TUYAU, COQUE(2D))
!
! --------------------------------------------------------------------------------------------------
!
    implicit none
    character(len=16) :: option, nomte
!
#include "jeveux.h"
#include "asterc/r8pi.h"
#include "asterfort/assert.h"
#include "asterfort/dfdm1d.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/matrot.h"
#include "asterfort/pmfinfo.h"
#include "asterfort/poutre_modloc.h"
#include "asterfort/ppga1d.h"
#include "asterfort/tecach.h"
#include "asterfort/utpvlg.h"
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ndim, nno, nnos, npg, jgano, icopg, idfde, ipoids, ivf, igeom
    integer :: tab(2), iret, ndim1
    integer :: inbf, jacf, iorien, nbsp, nbcou, nbsec, nbptcou, nbptsec
    integer :: isec, icou, isp, icoq, ig, ifi, kk, ii, jadr
    real(kind=8) :: copg(4, 4), copg2(3, 4), pgl(3, 3), gm1(3), gm2(3), airesp
    real(kind=8) :: epcou, alpha, rayon, ep, yy, zz, hh, rr, rayonsp, wspicou,wspisec
    real(kind=8) :: dfdx(3), cour, jacp, cosa, sina, spoid
!
    integer :: nbfibr, nbgrfi, tygrfi, nbcarm, nug(10)
! --------------------------------------------------------------------------------------------------
    integer, parameter :: nb_cara1 = 2
    real(kind=8) :: vale_cara1(nb_cara1)
    character(len=8) :: noms_cara1(nb_cara1)
    data noms_cara1 /'R1','EP1'/
! --------------------------------------------------------------------------------------------------
!
    call elrefe_info(fami='RIGI',ndim=ndim1,nno=nno,nnos=nnos,&
                     npg=npg,jpoids=ipoids,jvf=ivf,jdfde=idfde,jgano=jgano)
    ASSERT(npg.le.4)
!
!   ndim1 est la dimension topologique. il faut calculer la dimension de l'espace ndim (2 ou 3)
    call tecach('OOO', 'PGEOMER', 'L', iret, nval=2, itab=tab)
    ndim  = tab(2)/nno
    igeom = tab(1)
!   zr(icopg) : coordonnees points de gauss + poids
    call jevech('PCOORPG', 'E', icopg)
!
! --------------------------------------------------------------------------------------------------
!   POUTRES MULTIFIBRES
    if (nomte .eq. 'MECA_POU_D_EM' .or. nomte .eq. 'MECA_POU_D_TGM') then
!       Récupération des caractéristiques des fibres
        call pmfinfo(nbfibr,nbgrfi,tygrfi,nbcarm,nug,jacf=jacf)
        call jevech('PCAORIE', 'L', iorien)
        call matrot(zr(iorien), pgl)
!       position et poids des points de gauss, dans l'espace utilisateur
        call ppga1d(ndim, nno, npg, zr(ipoids), zr(ivf), zr(idfde), zr(igeom), copg)
        gm1(1)=0.d0
!       boucle sur les fibres/sous-points
!           données   : nbcarm valeurs par fibre <yf,zf,Aire> + <yp,zp,Numgr>
!           résultats : 4 valeurs par fibre  <x,y,z,w>
        do ifi = 1, nbfibr
            gm1(2)=zr(jacf+(ifi-1)*nbcarm)
            gm1(3)=zr(jacf+(ifi-1)*nbcarm+1)
            call utpvlg(1, 3, pgl, gm1, gm2)
            airesp=zr(jacf+(ifi-1)*nbcarm+2)
            do ig = 1, npg
                jadr = icopg+(nbfibr*(ig-1)+(ifi-1))*4
                zr(jadr+0)=copg(1,ig)+gm2(1)
                zr(jadr+1)=copg(2,ig)+gm2(2)
                zr(jadr+2)=copg(3,ig)+gm2(3)
!               pour le poids, on multiplie par l'aire des fibres
                zr(jadr+3) = copg(4,ig)*airesp
            enddo
        enddo
!
! --------------------------------------------------------------------------------------------------
!   TUYAUX
    else if((nomte.eq.'MET3SEG3').or.(nomte.eq.'MET3SEG4').or.(nomte.eq.'MET6SEG3')) then
!       nombre de couches et nombre de sections
        call jevech('PNBSP_I', 'L', inbf)
        nbcou = zi(inbf)
        nbsec = zi(inbf+1)
!       Nombre de points sur toutes les couches, tous les secteurs
        nbptcou = 2*nbcou+1
        nbptsec = 2*nbsec+1
!       nombre de sous points par point de gauss
        nbsp= nbptsec*nbptcou
!       rayon et epaisseur du tuyau
        call poutre_modloc('CAGEP1', noms_cara1, nb_cara1, lvaleur=vale_cara1)
        rayon = vale_cara1(1)
        ep    = vale_cara1(2)
!
        call jevech('PCAORIE', 'L', iorien)
!       position et poids des points de gauss
        call ppga1d(ndim, nno, npg, zr(ipoids), zr(ivf), zr(idfde), zr(igeom), copg)
!
        gm1(1)=0.d0
        alpha = r8pi()/(nbsec)
        epcou = ep/(2.0d0*nbcou)
        do ig = 1, npg
!           L'orientation change en fct du point de Gauss dans le cas courbe
            call matrot(zr(iorien+3*(ig-1)), pgl)
!           Calcul des coordonnees et stockage. Les sous points sont stockes niveau par niveau.
!           Il y a plusieurs niveaux par couche, en commencant par la section z local = 0 et y >0
            do icou = 1, nbptcou
!               Poids du sous-point en fonction de la couche
                if ( (icou.eq.1).or.(icou.eq.nbptcou)) then
                    wspicou = 1.0d0/3.0d0
                else
                    if (mod(icou,2).eq.0) then
                        wspicou = 4.0d0/3.0d0
                    else
                        wspicou = 2.0d0/3.0d0
                    endif
                endif
!               Section concernant le sous-point
                rayonsp = rayon-ep+(icou-1)*epcou
                airesp  = rayonsp * epcou * alpha
                do isec = 1, nbptsec
!                   SUPER IMPORTANT SUPER IMPORTANT SUPER IMPORTANT
!                   La convention des angles de vrilles entre les poutres et tuyaux est différente
!                   Il y a un repère indirect pour les tuyaux ==> c'est pas bien
!                       - On décale les angles de 90°.
!                       - Quand tout sera dans l'ordre, il faudra calculer correctement yy et zz
!
!                   A FAIRE DANS : te0478  irmase
!
                    yy=cos(-(isec-1)*alpha - 0.5*r8pi() )
                    zz=sin(-(isec-1)*alpha - 0.5*r8pi() )
!                   Poids du sous-point en fonction du secteur
                    if ( (isec.eq.1).or.(isec.eq.nbptsec)) then
                        wspisec = 1.0d0/3.0d0
                    else
                        if (mod(isec,2).eq.0) then
                            wspisec = 4.0d0/3.0d0
                        else
                            wspisec = 2.0d0/3.0d0
                        endif
                    endif
!                   Position de SP dans la section
                    gm1(2)=rayonsp*yy
                    gm1(3)=rayonsp*zz
                    call utpvlg(1, 3, pgl, gm1, gm2)
                    jadr = icopg+((ig-1)*nbsp+(icou-1)*nbptsec+(isec-1))*4
                    zr(jadr+0)= copg(1,ig)+gm2(1)
                    zr(jadr+1)= copg(2,ig)+gm2(2)
                    zr(jadr+2)= copg(3,ig)+gm2(3)
!                   Pour le poids
                    zr(jadr+3)= copg(4,ig)*wspisec*wspicou*airesp
                enddo
            enddo
        enddo
!
! --------------------------------------------------------------------------------------------------
!   COQUE(2D)
    else if(nomte.eq.'MECXSE3') then
        ASSERT(ndim.eq.2)
        call jevech('PNBSP_I', 'L', inbf)
        nbcou=zi(inbf)
        call jevech('PCACOQU', 'L', icoq)
        ep=zr(icoq)
        epcou=ep/nbcou
        call ppga1d(ndim, nno, npg, zr(ipoids), zr(ivf), zr(idfde), zr(igeom), copg2)
!
!       Nombre de point par couche
        nbptcou = 3
!       Nombre de sous-points par point de gauss
        nbsp= nbptcou*nbcou
!
        do ig = 1, npg
!           CALCUL DU VECTEUR NORMAL UNITAIRE AU POINT DE GAUSS
            kk = (ig-1)*nno
            call dfdm1d(nno, zr(ipoids+ig-1), zr(idfde+kk), zr(igeom), dfdx,&
                        cour, jacp, cosa, sina)
            rr = 0.d0
            do ii = 1, nno
                rr = rr + zr(igeom+2*(ii-1))*zr(ivf+kk+ii-1)
            enddo
            jacp = jacp*rr
            gm2(1)=cosa
            gm2(2)=sina
!
            do icou = 1, nbcou
                do isp = 1, nbptcou
                    hh=-ep/2+(icou-1+0.5d0*(isp-1))*epcou
                    jadr = icopg+((ig-1)*nbsp+(icou-1)*nbptcou+(isp-1))*3
                    zr(jadr+0) = copg2(1,ig)+hh*gm2(1)
                    zr(jadr+1) = copg2(2,ig)+hh*gm2(2)
                    if (isp .eq. 2) then
                        spoid=2.0d0/3.0d0
                    else
                        spoid=1.0d0/6.0d0
                    endif
!                   pour le poids, on multiplie par l'epaisseur par couche
                    zr(jadr+2)= jacp*spoid*epcou
                enddo
            enddo
        enddo
!
! --------------------------------------------------------------------------------------------------
!   autres elements
    else
        call ppga1d(ndim, nno, npg, zr(ipoids), zr(ivf), zr(idfde), zr( igeom), zr(icopg))
    endif
!
end subroutine
