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

subroutine te0239(option, nomte)
! ......................................................................
!    - FONCTION REALISEE:  CALCUL DES OPTIONS NON LINEAIRES
!                          COQUE 1D
!                          OPTION : 'RIGI_MECA_TANG ',
!                                   'FULL_MECA      ','RAPH_MECA      '
!                          ELEMENT: MECXSE3 (COQUE_AXIS)
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! ......................................................................
! person_in_charge: ayaovi-dzifa.kudawoo at edf.fr
    implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/r8nnem.h"
#include "asterfort/comcq1.h"
#include "asterfort/defgen.h"
#include "asterfort/dfdm1d.h"
#include "asterfort/effi.h"
#include "asterfort/elref1.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/matdtd.h"
#include "asterfort/mattge.h"
#include "asterfort/moytpg.h"
#include "asterfort/r8inir.h"
#include "asterfort/rcvalb.h"
#include "asterfort/tecach.h"
#include "asterfort/utmess.h"
#include "blas/dcopy.h"
    integer :: icompo, nbcou, npge, icontm, ideplm, ivectu, icou, inte, icontp
    integer :: kpki, k1, k2, kompt, ivarim, ivarip, iinstm, iinstp, lgpg, ideplp
    integer :: icarcr, nbvari, jcret, codret
    real(kind=8) :: cisail, zic, coef, rhos, rhot, epsx3, gsx3, sgmsx3
    real(kind=8) :: zmin, hic, depsx3
    integer :: nbres, itab(8), jnbspi
    parameter (nbres=2)
    character(len=16) :: nomres(nbres), option, nomte
    character(len=8) ::  nompar, elrefe
    integer :: valret(nbres)
    real(kind=8) :: valres(nbres), tempm
    real(kind=8) :: dfdx(3), zero, un, deux
    real(kind=8) :: test, test2, eps, nu, h, cosa, sina, cour, r
    real(kind=8) :: jacp, kappa, correc
    real(kind=8) :: eps2d(4), deps2d(4), sigtdi(5), sigmtd(5)
    real(kind=8) :: x3
    real(kind=8) :: dtild(5, 5), dtildi(5, 5), dsidep(6, 6)
    real(kind=8) :: rtangi(9, 9), rtange(9, 9), sigm2d(4), sigp2d(4)
    real(kind=8) :: angmas(3)
    integer :: nno, nnos, jgano, ndim, kp, npg, i, j, k, imatuu, icaco, ndimv
    integer :: ivarix
    integer :: ipoids, ivf, idfdk, igeom, imate
    integer :: nbpar, cod, iret, ksp
    aster_logical :: vecteu, matric, testl1, testl2
!
    parameter (npge=3)
!
    data zero,un,deux/0.d0,1.d0,2.d0/
!
    ivarip=1
!
    eps = 1.d-3
    codret = 0
!
!     ANGLE DU MOT_CLEF MASSIF (AFFE_CARA_ELEM)
!     INITIALISE A R8NNEM (ON NE S'EN SERT PAS)
    angmas(1) = r8nnem()
    angmas(2) = r8nnem()
    angmas(3) = r8nnem()
!
!
    vecteu = ((option.eq.'FULL_MECA') .or. (option.eq.'RAPH_MECA'))
    matric = ((option.eq.'FULL_MECA') .or. (option.eq.'RIGI_MECA_TANG'))
!
    call elref1(elrefe)
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nno, nnos=nnos, npg=npg,&
                     jpoids=ipoids, jvf=ivf, jdfde=idfdk, jgano=jgano)
!
!       TYPMOD(1) = 'C_PLAN  '
!       TYPMOD(2) = '        '
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PCACOQU', 'L', icaco)
    h = zr(icaco)
    kappa = zr(icaco+1)
    correc = zr(icaco+2)
!
!---- COTE MINIMALE SUR L'EPAISSEUR
    zmin = -h/2.d0
!
    call jevech('PMATERC', 'L', imate)
    nomres(1) = 'E'
    nomres(2) = 'NU'
!
    call jevech('PVARIMR', 'L', ivarim)
    call jevech('PINSTMR', 'L', iinstm)
    call jevech('PDEPLMR', 'L', ideplm)
    call jevech('PCONTMR', 'L', icontm)
    call jevech('PINSTPR', 'L', iinstp)
    call jevech('PDEPLPR', 'L', ideplp)
    call jevech('PCOMPOR', 'L', icompo)
    call jevech('PCARCRI', 'L', icarcr)
!
    if (zk16(icompo+3) .eq. 'COMP_ELAS') then
        if (zk16(icompo) .ne. 'ELAS') then
            call utmess('F', 'ELEMENTS2_90')
        endif
    endif
!
    if (zk16(icompo+2) (6:10) .eq. '_REAC') then
        call utmess('A', 'ELEMENTS3_54')
    endif
!
!--- LECTURE DU NBRE DE VAR. INTERNES, DE COUCHES ET LONG. MAX DU
!--- POINT D'INTEGRATION
    read (zk16(icompo-1+2),'(I16)') nbvari
    call tecach('OOO', 'PVARIMR', 'L', iret, nval=7,&
                itab=itab)
!      LGPG = MAX(ITAB(6),1)*ITAB(7) resultats faux sur Bull avec ifort
    if (itab(6) .le. 1) then
        lgpg=itab(7)
    else
        lgpg = itab(6)*itab(7)
    endif
    call jevech('PNBSP_I', 'L', jnbspi)
    nbcou = zi(jnbspi-1+1)
!---- MESSAGES LIMITATION NBRE DE COUCHES
    if (nbcou .le. 0) then
        call utmess('F', 'ELEMENTS_12')
    endif
    if (nbcou .gt. 10) then
        call utmess('F', 'ELEMENTS3_55')
    endif
!---- EPAISSEUR DE CHAQUE COUCHE
    hic = h/nbcou
    if (vecteu) then
        call jevech('PVECTUR', 'E', ivectu)
        call jevech('PCONTPR', 'E', icontp)
        call jevech('PVARIPR', 'E', ivarip)
    endif
    if (vecteu) then
        ndimv = npg*npge*nbcou*nbvari
        call jevech('PVARIMP', 'L', ivarix)
        call dcopy(ndimv, zr(ivarix), 1, zr(ivarip), 1)
    endif
    if (matric) then
        call jevech('PMATUUR', 'E', imatuu)
!        IVARIP=IVARIM
    endif
!
    call r8inir(81, 0.d0, rtange, 1)
    kpki = 0
!-- DEBUT DE BOUCLE D'INTEGRATION SUR LA SURFACE NEUTRE
    do  kp = 1, npg
        k = (kp-1)*nno
        call dfdm1d(nno, zr(ipoids+kp-1), zr(idfdk+k), zr(igeom), dfdx,&
                    cour, jacp, cosa, sina)
        r = zero
!
        call r8inir(5, 0.d0, sigmtd, 1)
        call r8inir(25, 0.d0, dtild, 1)
!
!-- BOUCLE SUR LES POINTS D'INTEGRATION SUR LA SURFACE
!
        do  i = 1, nno
            r = r + zr(igeom+2*i-2)*zr(ivf+k+i-1)
        enddo
!
!===============================================================
!     -- RECUPERATION DE LA TEMPERATURE POUR LE MATERIAU:
!     -- SI LA TEMPERATURE EST CONNUE AUX NOEUDS :
        call moytpg('RIGI', kp, 3, '-', tempm,&
                    iret)
        nbpar = 1
        nompar = 'TEMP'
        call rcvalb('RIGI', kp, 1, '-', zi(imate),&
                    ' ', 'ELAS', nbpar, nompar, [tempm],&
                    2, nomres, valres, valret, 1)
!
        nu = valres(2)
        cisail = valres(1)/ (un+nu)
!
!       ON EST EN AXIS:
        jacp = jacp*r
!
        test = abs(h*cour/deux)
        if (test .ge. un) correc = zero
        test2 = abs(h*cosa/ (deux*r))
        if (test2 .ge. un) correc = zero
!
        testl1 = (test.le.eps .or. correc.eq.zero)
        testl2 = (&
                 test2 .le. eps .or. correc .eq. zero .or. abs(cosa) .le. eps .or. abs(cour*r)&
                 .le. eps .or. abs(cosa-cour*r) .le. eps&
                 )
!
!-- DEBUT DE BOUCLE D'INTEGRATION DANS L'EPAISSEUR
!
        do  icou = 1, nbcou
            do  inte = 1, npge
                if (inte .eq. 1) then
                    zic = zmin + (icou-1)*hic
                    coef = 1.d0/3.d0
                else if (inte.eq.2) then
                    zic = zmin + hic/2.d0 + (icou-1)*hic
                    coef = 4.d0/3.d0
                else
                    zic = zmin + hic + (icou-1)*hic
                    coef = 1.d0/3.d0
                endif
!
                x3 = zic
!
                if (testl1) then
                    rhos = 1.d0
                else
                    rhos = 1.d0 + x3*cour
                endif
                if (testl2) then
                    rhot = 1.d0
                else
                    rhot = 1.d0 + x3*cosa/r
                endif
!
!           CALCULS DES COMPOSANTES DE DEFORMATIONS TRIDIMENSIONNELLES :
!           EPSSS, EPSTT, EPSSX3 (EN FONCTION DES DEFORMATIONS
!           GENERALISEES :ESS,KSS,ETT,KTT,GS)
!           DE L'INSTANT PRECEDANT ET DES DEFORMATIONS INCREMENTALES
!           DE L'INSTANT PRESENT
!
                call defgen(testl1, testl2, nno, r, x3,&
                            sina, cosa, cour, zr( ivf+k), dfdx,&
                            zr(ideplm), eps2d, epsx3)
                call defgen(testl1, testl2, nno, r, x3,&
                            sina, cosa, cour, zr( ivf+k), dfdx,&
                            zr(ideplp), deps2d, depsx3)
!
!
!           CONSTRUCTION DE LA DEFORMATION GSX3
!           ET DE LA CONTRAINTE SGMSX3
                gsx3 = 2.d0* (epsx3+depsx3)
                sgmsx3 = cisail*kappa*gsx3/2.d0
!
!           CALCUL DU NUMERO DU POINT D'INTEGRATION COURANT
                kpki = kpki + 1
                k1 = 4* (kpki-1)
                k2 = lgpg* (kp-1) + (npge* (icou-1)+inte-1)*nbvari
                ksp=(icou-1)*npge + inte
!
                do  i = 1, 4
                    sigm2d(i)=zr(icontm+k1+i-1)
              enddo
!
!  APPEL AU COMPORTEMENT
                call comcq1('RIGI', kp, ksp, zi(imate),&
                            zk16(icompo), zr(icarcr), zr(iinstm), zr(iinstp), eps2d,&
                            deps2d,  sigm2d, zr(ivarim+k2),&
                            option, angmas, sigp2d, zr( ivarip+k2), dsidep,&
                            cod)
                if (vecteu) then
                    do  i = 1, 4
                        zr(icontp+k1+i-1)=sigp2d(i)
                  enddo
                endif
!
!           COD=1 : ECHEC INTEGRATION LOI DE COMPORTEMENT
!           COD=3 : C_PLAN DEBORST SIGZZ NON NUL
                if (cod .ne. 0) then
                    if (codret .ne. 1) then
                        codret = cod
                    endif
                endif
!
!
                if (matric) then
!-- CALCULS DE LA MATRICE TANGENTE : BOUCLE SUR L'EPAISSEUR
!-- CONSTRUCTION DE LA MATRICE DTD (DTILD)
                    call matdtd(nomte, testl1, testl2, dsidep, cisail,&
                                x3, cour, r, cosa, kappa,&
                                dtildi)
                    do  i = 1, 5
                        do  j = 1, 5
                            dtild(i,j) = dtild(i,j) + dtildi(i,j)* 0.5d0*hic*coef
                      enddo
                  enddo
                endif
!
                if (vecteu) then
!-- CALCULS DES EFFORTS INTERIEURS : BOUCLE SUR L'EPAISSEUR
!
                    sigtdi(1) = zr(icontp-1+k1+1)/rhos
                    sigtdi(2) = x3*zr(icontp-1+k1+1)/rhos
                    sigtdi(3) = zr(icontp-1+k1+2)/rhot
                    sigtdi(4) = x3*zr(icontp-1+k1+2)/rhot
                    sigtdi(5) = sgmsx3/rhos
!
                    do  i = 1, 5
                        sigmtd(i) = sigmtd(i) + sigtdi(i)*0.5d0*hic* coef
                  enddo
                endif
!-- FIN DE BOUCLE SUR LES POINTS D'INTEGRATION DANS L'EPAISSEUR
         enddo
     enddo
!
        if (vecteu) then
!-- CALCUL DES EFFORTS INTERIEURS
            call effi(nomte, sigmtd, zr(ivf+k), dfdx, jacp,&
                      sina, cosa, r, zr(ivectu))
        endif
        if (matric) then
!-- CONSTRUCTION DE LA MATRICE TANGENTE
            call mattge(nomte, dtild, sina, cosa, r,&
                        jacp, zr(ivf+k), dfdx, rtangi)
            do  i = 1, 9
                do  j = 1, 9
                    rtange(i,j) = rtange(i,j) + rtangi(i,j)
             enddo
         enddo
        endif
!-- FIN DE BOUCLE SUR LES POINTS D'INTEGRATION DE LA SURFACE NEUTRE
 end do
    if (matric) then
!-- STOCKAGE DE LA MATRICE TANGENTE
        kompt = 0
        do  j = 1, 9
            do i = 1, j
                kompt = kompt + 1
                zr(imatuu-1+kompt) = rtange(i,j)
         end do 
       end do
    endif
    if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
        call jevech('PCODRET', 'E', jcret)
        zi(jcret) = codret
    endif
end subroutine
