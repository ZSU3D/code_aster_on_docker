/* -------------------------------------------------------------------- */
/* Copyright (C) 1991 - 2017 - EDF R&D - www.code-aster.org             */
/* This file is part of code_aster.                                     */
/*                                                                      */
/* code_aster is free software: you can redistribute it and/or modify   */
/* it under the terms of the GNU General Public License as published by */
/* the Free Software Foundation, either version 3 of the License, or    */
/* (at your option) any later version.                                  */
/*                                                                      */
/* code_aster is distributed in the hope that it will be useful,        */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of       */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        */
/* GNU General Public License for more details.                         */
/*                                                                      */
/* You should have received a copy of the GNU General Public License    */
/* along with code_aster.  If not, see <http://www.gnu.org/licenses/>.  */
/* -------------------------------------------------------------------- */

/* person_in_charge: j-pierre.lefebvre at edf.fr */
#include "aster.h"
#include "aster_fort.h"
/*-----------------------------------------------------------------------------/
/ Récupération du nombre de datasets et de groups contenus dans un groupe 
/ au sein d'un fichier HDF 
/  Paramètres :
/   - in  idfic : identificateur du fichier (hid_t)
/   - in  nomgr : nom du groupe (char *)
/  Résultats :
/     nombre de datasets et de groups
/-----------------------------------------------------------------------------*/
#ifndef _DISABLE_HDF5
#include <hdf5.h>
#endif

ASTERINTEGER DEFPS(HDFNBO, hdfnbo, hid_t *idf, char *nomgr, STRING_SIZE ln)
{
  ASTERINTEGER nbobj=0;
#ifndef _DISABLE_HDF5
  hid_t idfic, bidon=0;
  char *nomg;
  int k;
  int idx ;
  void *malloc(size_t size);
  
  herr_t indiceNbName(hid_t loc_id, const char *name, const H5L_info_t *info, void *opdata);

  idfic=(hid_t) *idf;

  nomg = (char *) malloc((ln+1) * sizeof(char));
  for (k=0;k<ln;k++) {
     nomg[k] = nomgr[k];
  }
  k=ln-1;
  while (nomg[k] == ' ') { k--;}
  nomg[k+1] = '\0';

  idx = H5Literate_by_name (idfic, nomg , H5_INDEX_NAME, H5_ITER_NATIVE, NULL, indiceNbName,
                            &nbobj, bidon);
  free(nomg);
#else
  CALL_UTMESS("F", "FERMETUR_3");
#endif
  return nbobj; 
}
/*  
    http://www.hdfgroup.org/HDF5/doc/RM/RM_H5L.html#Link-Visit
    
    The protoype of the callback function op is as follows (as defined in the source code
    file H5Lpublic.h):
    herr_t (*H5L_iterate_t)( hid_t g_id, const char *name, const H5L_info_t *info, void *op_data)

    The parameters of this callback function have the following values or meanings:
            g_id    Group that serves as root of the iteration; same value as the H5Lvisit
                    group_id parameter
            name    Name of link, relative to g_id, being examined at current step of the iteration
            info    H5L_info_t struct containing information regarding that link
            op_data User-defined pointer to data required by the application in processing
                    the link; a pass-through of the op_data pointer provided with the H5Lvisit
                    function call

    The possible return values from the callback function, and the effect of each, are as follows:

        * Zero causes the visit iterator to continue, returning zero when all group members have
          been processed.
        * A positive value causes the visit iterator to immediately return that positive value,
          indicating short-circuit success. The iterator can be restarted at the next group member.
        * A negative value causes the visit iterator to immediately return that value, indicating
          failure. The iterator can be restarted at the next group member. 
*/

#ifndef _DISABLE_HDF5
herr_t indiceNbName(hid_t id,const char *nom,  const H5L_info_t *info, void *opdata)
{
  int *compteur;
  herr_t      status;
  H5O_info_t      infobuf;

  compteur = (int *) opdata;
/*  status = H5Oget_info_by_name (id, nom, &infobuf, H5P_DEFAULT); */
  (*compteur)++;
  return 0;
}
#endif
