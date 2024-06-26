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
! person_in_charge: daniele.colombo at ifpen.fr
!
subroutine te0588(option, nomte)
!
use THM_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/eulnau.h"
#include "asterc/r8dgrd.h"
#include "asterfort/elref1.h"
#include "asterfort/iselli.h"
#include "asterc/ismaem.h"
#include "asterfort/jevech.h"
#include "asterfort/naueul.h"
#include "asterfort/rcangm.h"
#include "asterfort/rccoma.h"
#include "asterfort/rcvalb.h"
#include "asterfort/teattr.h"
#include "asterfort/tecach.h"
#include "asterfort/vecini.h"
#include "asterfort/xasshm.h"
#include "asterfort/xcaehm.h"
#include "asterfort/xfnohm.h"
#include "asterfort/xhmddl.h"
#include "asterfort/xhmini.h"
#include "asterfort/xpeshm.h"
#include "asterfort/utmess.h"
#include "jeveux.h"
#include "asterfort/thmGetElemModel.h"
#include "asterfort/Behaviour_type.h"
    character(len=16) :: option, nomte
!     ------------------------------------------------------------------
! =====================================================================
!
!    - FONCTION REALISEE:  CALCUL DES OPTIONS NON-LINEAIRES MECANIQUES
!                          ELEMENTS THHM, HM ET HH
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! =====================================================================
    integer :: nno, imatuu, ndim, imate, iinstm, jcret
    integer :: dimmat, npi, npg, li, ibid, yaenrm
    integer :: retloi, iretp, iretm, icodre(1)
    integer :: ipoids, ivf, idfde, igeom, idim
    integer :: iinstp, ideplm, ideplp, icompo, icarcr, ipesa
    integer :: icontm, ivarip, ivarim, ivectu, icontp
    integer :: mecani(5), press1(7), press2(7), tempe(5), dimuel
    integer :: dimdef, dimcon, nbvari, nddls, nddlm
    integer :: nmec, np1, np2, i, nnos
    integer :: nnom
    real(kind=8) :: defgep(13), defgem(13)
    real(kind=8) :: dfdi(20, 3), dfdi2(20, 3), b(25, 52*20)
    real(kind=8) :: drds(25, 11+5), drdsr(25, 11+5), dsde(11+5, 25)
    real(kind=8) :: r(25), sigbar(25), c(25), ck(25), cs(25)
    real(kind=8) :: angmas(7), coor(3), angnau(3), angleu(3)
    real(kind=8) :: work1(11+5, 52*20), work2(25, 52*20)
    character(len=3) :: modint
    character(len=8) :: typmod(2)
    character(len=16) :: phenom, elref
    real(kind=8) :: rho(1), rbid(1)
    aster_logical :: axi, perman, fnoevo
    type(THM_DS) :: ds_thm
! =====================================================================
!  CETTE ROUTINE FAIT UN CALCUL EN HM AVEC XFEM
!  25 = (9 DEF MECA) + (9 DEF HEAV MECA) + 4 POUR P1 + 3 pour P1 HEAV
!  16 = 12 MECA + 4 POUR P1
! =====================================================================
!  POUR LES TABLEAUX DEFGEP ET DEFGEM ON A DANS L'ORDRE :
!                                      (PARTIE CLASSIQUE)
!                                      DX DY DZ
!                                      EPXX EPYY EPZZ EPXY EPXZ EPYZ
!                                      PRE1 P1DX P1DY P1DZ
!                                      (PARTIE ENRICHIE)
!                                      H1X  H1Y H1Z  H2X  H2Y  H2Z
!                                      H3X  H3Y H3Z
!                                      H1PRE1  H2PRE1  H3PRE1
!            EPSXY = RAC2/2*(DU/DY+DV/DX)
! =====================================================================
!    POUR LES CHAMPS DE CONTRAINTE
!                                      SIXX SIYY SIZZ SIXY SIXZ SIYZ
!                                      SIPXX SIPYY SIPZZ SIPXY SIPXZ SIPYZ
!                                      M11 FH11X FH11Y FH11Z
!
!        SIXY EST LE VRAI DE LA MECANIQUE DES MILIEUX CONTINUS
!        DANS EQUTHM ON LE MULITPLIERA PAR RAC2
! =====================================================================
!   POUR L'OPTION FORCNODA
!  SI LES TEMPS PLUS ET MOINS SONT PRESENTS
!  C'EST QUE L'ON APPELLE DEPUIS STAT NON LINE  : FNOEVO = VRAI
!  ET ALORS LES TERMES DEPENDANT DE DT SONT EVALUES
!  SI LES TEMPS PLUS ET MOINS NE SONT PAS PRESENTS
!  C'EST QUE L'ON APPELLE DEPUIS CALCNO  : FNOEVO = FAUX
!  ET ALORS LES TERMES DEPENDANT DE DT NE SONT PAS EVALUES
! =====================================================================
! AXI       AXISYMETRIQUE?
! TYPMOD    MODELISATION (D_PLAN, AXI, 3D ?)
! MODINT    METHODE D'INTEGRATION (CLASSIQUE,LUMPEE(D),REDUITE(R) ?)
! NNO       NB DE NOEUDS DE L'ELEMENT
! NNOS      NB DE NOEUDS SOMMETS DE L'ELEMENT
! NNOM      NB DE NOEUDS MILIEUX DE L'ELEMENT
! NDDLS     NB DE DDL SUR LES SOMMETS
! NDDLM     NB DE DDL SUR LES MILIEUX
! NPI       NB DE POINTS D'INTEGRATION DE L'ELEMENT
! NPG       NB DE POINTS DE GAUSS     POUR CLASSIQUE(=NPI)
!                 SOMMETS             POUR LUMPEE   (=NPI=NNOS)
!                 POINTS DE GAUSS     POUR REDUITE  (<NPI)
! NDIM      DIMENSION DE L'ESPACE
! DIMUEL    NB DE DDL TOTAL DE L'ELEMENT
! DIMCON    DIMENSION DES CONTRAINTES GENERALISEES ELEMENTAIRES
! DIMDEF    DIMENSION DES DEFORMATIONS GENERALISEES ELEMENTAIRES
! IVF       FONCTIONS DE FORMES QUADRATIQUES
! =====================================================================
    real(kind=8) :: dt
! =====================================================================
! DECLARATION POUR XFEM
!
    integer :: nfh, nfiss, jfisno, ddlc, contac
    integer :: ddld, ddlm, ddlp, nnop, nnops, nnopm
    integer :: enrmec(3), nenr, dimenr, enrhyd(3)
    integer :: jpintt, jcnset, jheavt, jpmilt, jheavn
    integer :: jlonch, jlst, jstno
    character(len=8) :: enr
! =====================================================================
! --- 1. INITIALISATIONS ----------------------------------------------
! --- SUIVANT ELEMENT, DEFINITION DES CARACTERISTIQUES : --------------
! --- CHOIX DU TYPE D'INTEGRATION -------------------------------------
! --- RECUPERATION DE LA GEOMETRIE ET POIDS DES POINTS D'INTEGRATION --
! --- RECUPERATION DES FONCTIONS DE FORME -----------------------------
! =====================================================================

!
! - Get model of finite element
!
    call thmGetElemModel(ds_thm)
    if (ds_thm%ds_elem%l_weak_coupling) then
        call utmess('F', 'CHAINAGE_12')
    endif
! INITIALISATION POUR XFEM
!
    call xhmini(nomte, nfh, ddld, ddlm, ddlp, nfiss, ddlc, contac)
    call xcaehm(ds_thm, nomte, axi, perman, typmod, modint,&
                mecani, press1, press2, tempe, dimdef,&
                dimcon, nmec, np1, np2, ndim,&
                nno, nnos, nnom, npi, npg,&
                nddls, nddlm, dimuel, ipoids, ivf,&
                idfde, ddld, ddlm, ddlp, enrmec, nenr,&
                dimenr, nnop, nnops, nnopm, enrhyd, ddlc, nfh)
! =====================================================================
! --- PARAMETRES PROPRES A XFEM ---------------------------------------
! =====================================================================
    call jevech('PPINTTO', 'L', jpintt)
    call jevech('PCNSETO', 'L', jcnset)
    call jevech('PHEAVTO', 'L', jheavt)
    call jevech('PLONCHA', 'L', jlonch)
    call jevech('PLST', 'L', jlst)
    call jevech('PSTANO', 'L', jstno)
    call elref1(elref)
    call teattr('S', 'XFEM', enr, ibid)
    ASSERT(enr(1:2).eq. 'XH')
    call jevech('PHEA_NO', 'L', jheavn)
!
! PARAMÈTRES PROPRES AUX ÉLÉMENTS 1D ET 2D QUADRATIQUES
!
    if ((ibid.eq.0) .and. (enr(1:2).eq.'XH') .and. .not. iselli(elref)) then
        call jevech('PPMILTO', 'L',jpmilt)
    endif
! PARAMETRE PROPRE AU MULTI-HEAVISIDE
    if (nfiss .gt. 1) then
        call jevech('PFISNO', 'L', jfisno)
    endif
! =====================================================================
! --- DEBUT DES DIFFERENTES OPTIONS -----------------------------------
! =====================================================================
! --- 2. OPTIONS : RIGI_MECA_TANG , FULL_MECA , RAPH_MECA -------------
! =====================================================================
    if ((option(1:9).eq.'RIGI_MECA' ) .or. (option(1:9).eq.'RAPH_MECA' ) .or.&
        (option(1:9).eq.'FULL_MECA' )) then
! =====================================================================
! --- PARAMETRES EN ENTREE --------------------------------------------
! =====================================================================
        call jevech('PGEOMER', 'L', igeom)
        call jevech('PMATERC', 'L', imate)
        call jevech('PINSTMR', 'L', iinstm)
        call jevech('PINSTPR', 'L', iinstp)
        call jevech('PDEPLMR', 'L', ideplm)
        call jevech('PDEPLPR', 'L', ideplp)
        call jevech('PCOMPOR', 'L', icompo)
        call jevech('PCARCRI', 'L', icarcr)
        call jevech('PVARIMR', 'L', ivarim)
        call jevech('PCONTMR', 'L', icontm)
        read (zk16(icompo-1+NVAR),'(I16)') nbvari
! =====================================================================
! ----RECUPERATION DES ANGLES NAUTIQUES/EULER DEFINIS PAR AFFE_CARA_ELEM
! --- ORIENTATION DU MASSIF
! --- COORDONNEES DU BARYCENTRE ( POUR LE REPRE CYLINDRIQUE )
! --- CONVERSION DES ANGLES NAUTIQUES EN ANGLES D'EULER
! =====================================================================
        call vecini(7, 0.d0, angmas)
        call vecini(3, 0.d0, coor)
        call vecini(3, 0.d0, angleu)
        call vecini(3, 0.d0, angnau)
!
        do i = 1, nno
            do idim = 1, ndim
                coor(idim) = coor(idim)+zr(igeom+idim+ndim*(i-1)-1)/ nno
            end do
        end do
        call rcangm(ndim, coor, angmas)
!# ANGMAS : donne par affe_cara_elem en degre et ici en fourni en radian
!# CAS OU AFFE_CARA_ELEM EST EN ANGLE D EULER => On CONVERTIT EN NAUTIQUE
        if (abs(angmas(4)-2.d0) .lt. 1.d-3) then
            if (ndim .eq. 3) then
                angleu(1) = angmas(5)
                angleu(2) = angmas(6)
                angleu(3) = angmas(7)
            else
                angleu(1) = angmas(5)
            endif
            call eulnau(angleu/r8dgrd(), angnau/r8dgrd())
!
!# CAS OU AFFE_CARA_ELEM EST EN ANGLE NAUTIQUE (OK PAS DE CONVERSION)
        else
            if (ndim .eq. 3) then
                angnau(1) = angmas(1)
                angnau(2) = angmas(2)
                angnau(3) = angmas(3)
            else
                angnau(1) = angmas(1)
            endif
        endif
! =====================================================================
! --- PARAMETRES EN SORTIE ISMAEM? ------------------------------------
! =====================================================================
        if (option(1:9) .eq. 'RIGI_MECA' .or. option(1:9) .eq. 'FULL_MECA') then
            call jevech('PMATUNS', 'E', imatuu)
        else
            imatuu = ismaem()
        endif
        if (option(1:9) .eq. 'RAPH_MECA' .or. option(1:9) .eq. 'FULL_MECA') then
            call jevech('PVECTUR', 'E', ivectu)
            call jevech('PCONTPR', 'E', icontp)
            call jevech('PVARIPR', 'E', ivarip)
            call jevech('PCODRET', 'E', jcret)
            zi(jcret) = 0
        else
            ivectu = ismaem()
            icontp = ismaem()
            ivarip = ismaem()
        endif
        retloi = 0
        dimmat = nddls*nnop
        if (option(1:9) .eq. 'RIGI_MECA') then
            call xasshm(ds_thm,&
                        nno, npg, npi, ipoids, ivf,&
                        idfde, igeom, zr(igeom), zr(icarcr), zr(ideplm),&
                        zr(ideplm), zr(icontm), zr(icontm), zr(ivarim), zr(ivarim),&
                        defgem, defgep, drds, drdsr, dsde,&
                        b, dfdi, dfdi2, r, sigbar,&
                        c, ck, cs, zr(imatuu), zr( ivectu),&
                        zr(iinstm), zr(iinstp), option, zi(imate), mecani,&
                        press1, press2, tempe, dimdef, dimcon,&
                        dimuel, nbvari, nddls, nddlm, nmec,&
                        np1, ndim, zk16(icompo), axi, modint,&
                        retloi, nnop, nnops, nnopm, enrmec,&
                        dimenr, zi(jheavt), zi( jlonch), zi(jcnset), jpintt,&
                        jpmilt, jheavn, angnau,dimmat, enrhyd, nfiss, nfh, jfisno,&
                        work1, work2)
        else
            do li = 1, dimuel
                zr(ideplp+li-1) = zr(ideplm+li-1) + zr(ideplp+li-1)
            end do
            call xasshm(ds_thm,&
                        nno, npg, npi, ipoids, ivf,&
                        idfde, igeom, zr(igeom), zr(icarcr), zr(ideplm),&
                        zr(ideplp), zr(icontm), zr(icontp), zr(ivarim), zr(ivarip),&
                        defgem, defgep, drds, drdsr, dsde,&
                        b, dfdi, dfdi2, r, sigbar,&
                        c, ck, cs, zr(imatuu), zr( ivectu),&
                        zr(iinstm), zr(iinstp), option, zi(imate), mecani,&
                        press1, press2, tempe, dimdef, dimcon,&
                        dimuel, nbvari, nddls, nddlm, nmec,&
                        np1, ndim, zk16(icompo), axi, modint,&
                        retloi, nnop, nnops, nnopm, enrmec,&
                        dimenr, zi(jheavt), zi( jlonch), zi(jcnset), jpintt,&
                        jpmilt, jheavn, angnau,dimmat, enrhyd, nfiss, nfh, jfisno,&
                        work1, work2)
            zi(jcret) = retloi
        endif
! =====================================================================
! --- SUPRESSION DES DDLS HEAVISIDE SUPERFLUS -------------------------
! =====================================================================
        call xhmddl(ndim, nfh, nddls, dimuel, nnop, nnops,&
                    zi(jstno), .false._1, option, nomte, zr(imatuu),&
                    zr(ivectu), nddlm, nfiss, jfisno, .false._1, contac)
    endif
! =====================================================================
! --- 3. OPTION : CHAR_MECA_PESA_R ------------------------------------
! =====================================================================
    if (option .eq. 'CHAR_MECA_PESA_R') then
        call jevech('PGEOMER', 'L', igeom)
        call jevech('PMATERC', 'L', imate)
        call jevech('PPESANR', 'L', ipesa)
        call jevech('PVECTUR', 'E', ivectu)
        call rccoma(zi(imate), 'THM_DIFFU', 1, phenom, icodre(1))
        call rcvalb('FPG1', 1, 1, '+', zi(imate),&
                    ' ', phenom, 0, ' ', [0.d0],&
                    1, 'RHO', rho(1), icodre, 1)
!
!        INDICATEUR POUR SAVOIR SI ON A DE L'ENRICHISSEMENT
        yaenrm = enrmec(1)
!
        call xpeshm(nno, nnop, nnops, ndim, nddls,&
                    nddlm, npg, igeom, jpintt, jpmilt, jheavn,&
                    ivf, ipoids, idfde, ivectu, ipesa,&
                    zi(jheavt), zi( jlonch), zi(jcnset), rho(1), axi,&
                    yaenrm, nfiss, nfh, jfisno)
!
! =====================================================================
! --- SUPRESSION DES DDLS HEAVISIDE SUPERFLUS -------------------------
! =====================================================================
        call xhmddl(ndim, nfh, nddls, dimuel, nnop, nnops,&
                    zi(jstno), .false._1, option, nomte, rbid,&
                    zr(ivectu), nddlm, nfiss, jfisno, .false._1, contac)
    endif
! ======================================================================
! --- 4. OPTION : FORC_NODA --------------------------------------------
! ======================================================================
    if (option .eq. 'FORC_NODA') then
! ======================================================================
! --- PARAMETRES EN ENTREE ---------------------------------------------
! ======================================================================
        call jevech('PGEOMER', 'L', igeom)
        call jevech('PCONTMR', 'L', icontm)
        call jevech('PMATERC', 'L', imate)
! ======================================================================
! --- SI LES TEMPS PLUS ET MOINS SONT PRESENTS -------------------------
! --- C EST QUE L ON APPELLE DEPUIS STAT NON LINE ET -------------------
! --- ALORS LES TERMES DEPENDANT DE DT SONT EVALUES --------------------
! ======================================================================
        call tecach('ONO', 'PINSTMR', 'L', iretm, iad=iinstm)
        call tecach('ONO', 'PINSTPR', 'L', iretp, iad=iinstp)
        if (iretm .eq. 0 .and. iretp .eq. 0) then
            dt = zr(iinstp) - zr(iinstm)
            fnoevo = .true.
        else
            fnoevo = .false.
            dt = 0.d0
        endif
! ======================================================================
! --- PARAMETRES EN SORTIE ---------------------------------------------
! ======================================================================
        call jevech('PVECTUR', 'E', ivectu)
!
        call xfnohm(ds_thm,&
                    fnoevo, dt, nno, npg, ipoids,&
                    ivf, idfde, zr(igeom), zr(icontm), b,&
                    dfdi, dfdi2, r, zr(ivectu), zi(imate),&
                    mecani, press1, dimcon, nddls, nddlm,&
                    dimuel, nmec, np1, ndim, axi,&
                    dimenr, nnop, nnops, nnopm, igeom,&
                    jpintt, jpmilt, jheavn, zi(jlonch), zi( jcnset), zi(jheavt),&
                    enrmec, enrhyd, nfiss, nfh, jfisno)
!
! =====================================================================
! --- SUPRESSION DES DDLS HEAVISIDE SUPERFLUS -------------------------
! =====================================================================
        call xhmddl(ndim, nfh, nddls, dimuel, nnop, nnops,&
                    zi(jstno), .false._1, option, nomte, rbid,&
                    zr(ivectu), nddlm, nfiss, jfisno, .false._1, contac)
    endif
end subroutine
