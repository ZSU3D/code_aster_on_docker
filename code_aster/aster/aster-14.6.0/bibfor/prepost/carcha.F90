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

subroutine carcha(noch, nomgd, typcha, option, param)
    implicit none
#include "asterfort/assert.h"
#include "asterfort/utmess.h"
    character(len=8) :: nomgd, typcha, param
    character(len=16) :: noch
    character(len=24) :: option
!
!     BUT:
!       RECUPERER DES CARACTERISTIQUES LIEES A UN NOM DE CHAMP
!
!
!     ARGUMENTS:
!     ----------
!
!      ENTREE :
!-------------
! IN   NOCH     : NOM DU CHAMP
!
!      SORTIE :
!-------------
! OUT  NOMGD    : NOM DE LA GRANDEUR ASSOCIEE
! OUT  TYPCHA   : TYPE DU CHAMP
! OUT  OPTION   : OPTION CALCULANT CE CHAMP
! OUT  PARA     : NOM D'UN MODE LOCAL ASSOCIE
!
! ......................................................................
!
    if (noch .eq. 'TEMP') then
        nomgd = 'TEMP_R  '
        typcha = 'NOEU'
    else if (noch.eq.'PRES') then
        nomgd = 'PRES_R  '
        typcha = 'ELEM'
    else if (noch.eq.'IRRA') then
        nomgd = 'IRRA_R  '
        typcha = 'NOEU'
!
!     CHAMP DE GRANDEUR "DEPL_R"
    else if (noch.eq.'DEPL') then
        nomgd = 'DEPL_R  '
        typcha = 'NOEU'
    else if (noch.eq.'PTOT') then
        nomgd = 'DEPL_R  '
        typcha = 'NOEU'
    else if (noch.eq.'VITE') then
        nomgd = 'DEPL_R  '
        typcha = 'NOEU'
    else if (noch.eq.'ACCE') then
        nomgd = 'DEPL_R  '
        typcha = 'NOEU'
    else if (noch.eq.'FORC_NODA') then
        nomgd = 'DEPL_R  '
        typcha = 'NOEU'
    else if (noch.eq.'REAC_NODA') then
        nomgd = 'DEPL_R  '
        typcha = 'NOEU'
!
!     CHAMP DE GRANDEUR "SIEF_R"
    else if (noch.eq.'SIEF_ELGA') then
        nomgd = 'SIEF_R'
        typcha = 'ELGA'
        option = 'RAPH_MECA'
        param = 'PCONTPR'
    else if (noch.eq.'SIEF_ELGA') then
        nomgd = 'SIEF_R'
        typcha = 'ELGA'
        option = 'SIEF_ELGA'
        param = 'PCONTPR'
    else if (noch.eq.'SIEQ_ELGA') then
        nomgd = 'SIEF_R'
        typcha = 'ELGA'
        option = 'SIEQ_ELGA'
        param = 'PCONTEQ'
    else if (noch.eq.'SIEF_ELNO') then
        nomgd = 'SIEF_R'
        typcha = 'ELNO'
        option = 'SIEF_ELNO'
        param = 'PSIEFNOR'
    else if (noch.eq.'SIEQ_ELNO') then
        nomgd = 'SIEF_R'
        typcha = 'ELNO'
        option = 'SIEQ_ELNO'
    else if (noch.eq.'SIEF_NOEU') then
        nomgd = 'SIEF_R'
        typcha = 'NOEU'
    else if (noch.eq.'SIGM_ELNO') then
        nomgd = 'SIEF_R'
        typcha = 'ELNO'
    else if (noch.eq.'SIGM_NOEU') then
        nomgd = 'SIEF_R'
        typcha = 'NOEU'
    else if (noch.eq.'SIEQ_NOEU') then
        nomgd = 'SIEF_R'
        typcha = 'NOEU'
        option = 'SIEQ_NOEU'
    else if (noch.eq.'EFGE_ELNO') then
        nomgd = 'SIEF_R'
        typcha = 'ELNO'
        option = 'EFGE_ELNO'
!
!
!     CHAMP DE GRANDEUR "EPSI_R"
    else if (noch.eq.'EPSI_ELGA') then
        nomgd = 'EPSI_R'
        typcha = 'ELGA'
        option = 'EPSI_ELGA'
        param = 'PDEFOPG'
    else if (noch.eq.'EPMQ_ELGA') then
        nomgd = 'EPSI_R'
        typcha = 'ELGA'
        option = 'EPMQ_ELGA'
        param = 'PDEFOEQ'
    else if (noch.eq.'EPEQ_ELGA') then
        nomgd = 'EPSI_R'
        typcha = 'ELGA'
        option = 'EPEQ_ELGA'
        param = 'PDEFOEQ'
    else if (noch.eq.'EPSG_ELGA') then
        nomgd = 'EPSI_R'
        typcha = 'ELGA'
        option = 'EPSG_ELGA'
        param = 'PDEFOPG'
    else if (noch.eq.'EPSI_ELNO') then
        nomgd = 'EPSI_R'
        typcha = 'ELNO'
        option = 'EPSI_ELNO'
        param = 'PDEFONO'
    else if (noch.eq.'EPSA_ELNO') then
        nomgd = 'EPSI_R'
        typcha = 'ELNO'
        option = 'EPSI_ELNO'
        param = 'PDEFONO'
    else if (noch.eq.'EPSP_ELNO') then
        nomgd = 'EPSI_R'
        typcha = 'ELNO'
        option = 'EPSP_ELNO'
        param = 'PDEFONO'
    else if (noch.eq.'EPSP_ELGA') then
        nomgd = 'EPSI_R'
        typcha = 'ELGA'
        option = 'EPSP_ELGA'
        param = 'PDEFOPG'
    else if (noch.eq.'EPSI_NOEU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
    else if (noch.eq.'DIVU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
    else if (noch.eq.'EPSA_NOEU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
    else if (noch.eq.'EPME_ELNO') then
        nomgd = 'EPSI_R'
        typcha = 'ELNO'
    else if (noch.eq.'EPME_NOEU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
!
!     CHAMP DE GRANDEUR "FLUX_R"
    else if (noch.eq.'FLUX_NOEU') then
        nomgd = 'FLUX_R'
        typcha = 'NOEU'
!
!     CHAMP DE GRANDEUR "VARI_R"
    else if (noch.eq.'VARI_ELGA') then
        nomgd = 'VARI_R'
        typcha = 'ELGA'
        option = 'RAPH_MECA'
        param = 'PVARIPR'
    else if (noch.eq.'VARI_ELNO') then
        nomgd = 'VARI_R'
        typcha = 'ELNO'
        option = 'VARI_ELNO'
        param = 'PVARINR'
    else if (noch.eq.'VARI_NOEU') then
        nomgd = 'VAR2_R'
        typcha = 'NOEU'
    else if (noch.eq.'HYDR_ELNO') then
        nomgd = 'HYDR_R'
        typcha = 'ELNO'
    else if (noch.eq.'META_ELNO') then
        nomgd = 'VAR2_R'
        typcha = 'ELNO'
    else if (noch.eq.'HYDR_NOEU') then
        nomgd = 'HYDR_R'
        typcha = 'NOEU'
    else if (noch.eq.'ERME_ELEM') then
        nomgd = 'ERRE_R'
        typcha = 'ELEM'
    else if (noch.eq.'FSUR_3D') then
        nomgd = 'FORC_R'
        typcha = 'ELEM'
    else if (noch.eq.'T_EXT') then
        nomgd = 'TEMP_R'
        typcha = 'ELEM'
        option = 'CHAR_THER_TEXT_R'
        param = 'PT_EXTR'
    else if (noch.eq.'COEF_H') then
        nomgd = 'COEH_R'
        typcha = 'ELEM'
        option = 'CHAR_THER_TEXT_R'
        param = 'PCOEFHR'
    else if (noch.eq.'EPSG_NOEU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
    else if (noch.eq.'EPVC_NOEU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
    else if (noch.eq.'EPFP_NOEU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
    else if (noch.eq.'EPFD_NOEU') then
        nomgd = 'EPSI_R'
        typcha = 'NOEU'
!
!     ERREUR
    else
        call utmess('F', 'UTILITAI2_94', sk=noch)
    endif
!
!     VERIFICATION DE LA PRESENCE DE 'PARAM' ET 'OPTION'
!     POUR LES CHAMPS ELGA
    if (noch(6:9) .eq. 'ELGA') then
        ASSERT(option.ne.' ')
        ASSERT(param .ne.' ')
    endif
!
end subroutine
