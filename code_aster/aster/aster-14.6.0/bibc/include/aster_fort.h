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

#ifndef ASTER_FORT_H
#define ASTER_FORT_H

#include "aster.h"
#include "aster_mpi.h"

/* *********************************************************************
 *
 * Définition des interfaces aux routines fortran appelées depuis le C.
 *
 * *********************************************************************/

/* routines UTILITAIRES */
#define CALL_R8VIDE() CALL0(R8VIDE,r8vide)
extern ASTERDOUBLE DEF0(R8VIDE,r8vide);

#define CALL_R8PI() CALL0(R8PI,r8pi)
extern ASTERDOUBLE DEF0(R8PI,r8pi);

#define CALL_ISNNEM() CALL0(ISNNEM,isnnem)
extern ASTERINTEGER DEF0(ISNNEM,isnnem);

#define CALL_ULOPEN(a,b,c,d,e) CALLPSSSS(ULOPEN,ulopen,a,b,c,d,e)
extern void DEFPSSSS(ULOPEN,ulopen,ASTERINTEGER *,char *,STRING_SIZE,char *,STRING_SIZE,
                     char *,STRING_SIZE,char *,STRING_SIZE);

#define CALL_FCLOSE(a) CALLP(FCLOSE,fclose,a)
extern void DEFP(FCLOSE,fclose,ASTERINTEGER *);

#define CALL_DISMOI(a,b,c,d,e,f,g) CALLSSSPSSP(DISMOI,dismoi,a,b,c,d,e,f,g)
extern void DEFSSSPSSP(DISMOI, dismoi, const char *,STRING_SIZE,
                       const char *,STRING_SIZE, const char *,STRING_SIZE, ASTERINTEGER *,
                       char *,STRING_SIZE, const char *,STRING_SIZE, ASTERINTEGER *);

#define CALL_POSTKUTIL(a,b,c,d) CALLSSSS(POSTKUTIL,postkutil,a,b,c,d)
extern void DEFSSSS(POSTKUTIL,postkutil,char *,STRING_SIZE,char *,STRING_SIZE,
                    char *,STRING_SIZE,char *,STRING_SIZE);

#define CALL_MATFPE(a) CALLP(MATFPE,matfpe,a)
extern void DEFP(MATFPE, matfpe, ASTERINTEGER *);

#define CALL_OPTDEP(a,b,c) CALLSSP(OPTDEP, optdep, a, b, c)
extern void DEFSSP(OPTDEP, optdep, char *,STRING_SIZE, char *,STRING_SIZE, ASTERINTEGER *);

#define CALL_UTTCSM(a) CALLP(UTTCSM,uttcsm,a)
extern void DEFP(UTTCSM, uttcsm, ASTERDOUBLE *);


/* routines SUPERVISEUR */
#define CALL_EXPASS(a)  CALLP(EXPASS,expass,a)
extern void DEFP(EXPASS,expass, ASTERINTEGER *);

#define CALL_OPSEXE(a)  CALLP(OPSEXE,opsexe,a)
extern void DEFP(OPSEXE,opsexe, ASTERINTEGER *) ;

#define CALL_IMPERS() CALL0(IMPERS,impers)
extern void DEF0(IMPERS,impers);

#define CALL_ONERRF(a,b,c) CALLSSP(ONERRF,onerrf,a,b,c)
extern void DEFSSP(ONERRF,onerrf,char *,STRING_SIZE, _OUT char *,STRING_SIZE, _OUT ASTERINTEGER *);

#define CALL_GCNCON(a,b) CALLSS(GCNCON,gcncon,a,b)
extern void DEFSS(GCNCON,gcncon,char *,STRING_SIZE,char *,STRING_SIZE);

#define CALL_DEBUT() CALL0(DEBUT,debut)
extern void DEF0(DEBUT,debut);

#define CALL_IBMAIN() CALL0(IBMAIN,ibmain)
extern void DEF0(IBMAIN,ibmain);

#define CALL_POURSU() CALL0(POURSU,poursu)
extern void DEF0(POURSU,poursu);

#define CALL_ASABRT(a) CALLP(ASABRT,asabrt,a)
extern void DEFP(ASABRT, asabrt, _IN ASTERINTEGER *);

#define CALL_SETTCO(a,b) CALLSS(SETTCO,settco,a,b)
extern void DEFSS(SETTCO,settco, char *,STRING_SIZE, char *,STRING_SIZE);

/* routines JEVEUX */
#define CALL_JEMARQ() CALL0(JEMARQ, jemarq)
extern void DEF0(JEMARQ,jemarq);

#define CALL_JEDEMA() CALL0(JEDEMA, jedema)
extern void DEF0(JEDEMA,jedema);

#define CALL_JEDETR(a) CALLS(JEDETR, jedetr, a)
extern void DEFS(JEDETR, jedetr, const char *, STRING_SIZE);

#define CALL_JEDETC(a, b, c) CALLSSP(JEDETC, jedetc, a, b, c)
extern void DEFSSP(JEDETC, jedetc, char *, STRING_SIZE, char *, STRING_SIZE, ASTERINTEGER *);

#define CALL_JELST3(a,b,c,d)  CALLSSPP(JELST3,jelst3,a,b,c,d)
extern void DEFSSPP(JELST3,jelst3, char*, STRING_SIZE,
                    char*, STRING_SIZE, ASTERINTEGER *, ASTERINTEGER *);

#define CALL_JELIRA(a,b,c,d)  CALLSSPS(JELIRA,jelira,a,b,c,d)
extern void DEFSSPS(JELIRA,jelira, const char*, STRING_SIZE,
                    const char*, STRING_SIZE, ASTERINTEGER *,
                    char*, STRING_SIZE );

#define CALL_JEEXIN(a,b)  CALLSP(JEEXIN,jeexin,a,b)
extern void DEFSP(JEEXIN,jeexin, const char*, STRING_SIZE, ASTERINTEGER * );


/* routines d'accès aux OBJETS JEVEUX (vecteurs, collections, champs) */
#define CALL_GETCON(nomsd,iob,ishf,ilng,ctype,lcon,iaddr,nomob) \
    CALLSPPPPPPS(GETCON,getcon,nomsd,iob,ishf,ilng,ctype,lcon,iaddr,nomob)
extern void DEFSPPPPPPS(GETCON,getcon,char *,STRING_SIZE,ASTERINTEGER *,
                        ASTERINTEGER *,ASTERINTEGER *,
                        ASTERINTEGER *,ASTERINTEGER *,char **,char *,STRING_SIZE);

#define CALL_PUTCON(nomsd,nbind,ind,valr,valc,num,iret) \
    CALLSPPPPPP(PUTCON,putcon,nomsd,nbind,ind,valr,valc,num,iret)
extern void DEFSPPPPPP(PUTCON,putcon,char *,STRING_SIZE,ASTERINTEGER *,
                       ASTERINTEGER *,ASTERDOUBLE *,
                       ASTERDOUBLE *,ASTERINTEGER *,ASTERINTEGER *);

#define CALL_TAILSD(nom, nomsd, val, nbval) CALLSSPP(TAILSD,tailsd,nom, nomsd, val, nbval)
extern void DEFSSPP(TAILSD,tailsd,char *,STRING_SIZE,char *,STRING_SIZE,
                    ASTERINTEGER *, ASTERINTEGER *);

#define CALL_PRCOCH(nomce,nomcs,nomcmp,ktype,itopo,nval,groups) \
    CALLSSSSPPS(PRCOCH,prcoch,nomce,nomcs,nomcmp,ktype,itopo,nval,groups)
extern void DEFSSSSPPS(PRCOCH,prcoch,char *,STRING_SIZE,
                       char *,STRING_SIZE,char *,STRING_SIZE,
                       char *,STRING_SIZE,ASTERINTEGER *,ASTERINTEGER *,
                       char *,STRING_SIZE);

/* routine d'acces aux parametres memoire */
#define CALL_UTGTME(a,b,c,d) CALLPSPP(UTGTME,utgtme,a,b,c,d)
extern void DEFPSPP(UTGTME, utgtme, ASTERINTEGER *, char *, STRING_SIZE,
                    ASTERDOUBLE *, ASTERINTEGER *);

#define CALL_UTPTME(a,b,c) CALLSPP(UTPTME,utptme,a,b,c)
extern void DEFSPP(UTPTME, utptme, char *,  STRING_SIZE,  ASTERDOUBLE *, ASTERINTEGER *);

/* routines de manipulation de la SD RESULTAT */
extern void DEFSPPSPPPSP(RSACPA,rsacpa,char *, STRING_SIZE, ASTERINTEGER *, ASTERINTEGER *,
          char *, STRING_SIZE, ASTERINTEGER *, ASTERINTEGER *, ASTERDOUBLE *,
          char *, STRING_SIZE, ASTERINTEGER *);
#define CALL_RSACPA(nomsd, numva, icode, nomva, ctype, ival, rval, kval, ier) \
    CALLSPPSPPPSP(RSACPA,rsacpa, nomsd, numva, icode, nomva, ctype, ival, rval, kval, ier)

/* particulier car on passe les longueurs des chaines en dur */
extern void DEFSPSPPPS(RSACCH,rsacch,char *, STRING_SIZE, ASTERINTEGER *, char *,STRING_SIZE,
    ASTERINTEGER *, ASTERINTEGER *, ASTERINTEGER *, char *,STRING_SIZE);
#ifdef _STRLEN_AT_END
#define CALL_RSACCH(nomsd, numch, nomch, nbord, liord, nbcmp, liscmp) \
          F_FUNC(RSACCH,rsacch)(nomsd,numch,nomch,nbord,liord,nbcmp,liscmp, strlen(nomsd),16,8)
#else
#define CALL_RSACCH(nomsd, numch, nomch, nbord, liord, nbcmp, liscmp) \
          F_FUNC(RSACCH,rsacch)(nomsd,strlen(nomsd),numch, nomch,16,nbord, liord, nbcmp, liscmp,8)
#endif

/* routines interface MPI */
#define CALL_ASMPI_CHECK(a) CALLP(ASMPI_CHECK,asmpi_check,a)
extern void DEFP(ASMPI_CHECK,asmpi_check,ASTERINTEGER *);

#define CALL_ASMPI_WARN(a) CALLP(ASMPI_WARN,asmpi_warn,a)
extern void DEFP(ASMPI_WARN,asmpi_warn,ASTERINTEGER *);

/* routines intrinseques fortran */
#define CALL_ABORTF() CALL0(ABORTF,abortf)
extern void DEF0(ABORTF,abortf);

/* routines de manipulation de la SD MATERIAU */
#define CALL_RCVALE_WRAP(a,b,c,d,e,f,g,h,i,j) \
        CALLSSPSPPSPPP(RCVALE_WRAP,rcvale_wrap,a,b,c,d,e,f,g,h,i,j)
extern void DEFSSPSPPSPPP(RCVALE_WRAP, rcvale_wrap, char *,STRING_SIZE, char *,STRING_SIZE,
    ASTERINTEGER *, char *,STRING_SIZE, ASTERDOUBLE *, ASTERINTEGER *,
    char *,STRING_SIZE, ASTERDOUBLE *, ASTERINTEGER *,
    ASTERINTEGER *);


/* routines d'impression des MESSAGES */
#define CALL_AFFICH(a,b) CALLSS(AFFICH,affich,a,b)
extern void DEFSS(AFFICH,affich,char *,STRING_SIZE,char *,STRING_SIZE);

#define CALL_UTMESS(cod, idmess) CALLSS(UTMESS_CWRAP, utmess_cwrap, cod, idmess)
extern void DEFSS(UTMESS_CWRAP, utmess_cwrap, char *, STRING_SIZE, char *, STRING_SIZE);

/* particulier car on fixe les longueurs des chaines valk */
#define VALK_SIZE 128
extern void DEFSSPSPPPPS(UTMESS_CORE, utmess_core, char *, STRING_SIZE, char *, STRING_SIZE,
                         ASTERINTEGER *, char *, STRING_SIZE, ASTERINTEGER *,
                         ASTERINTEGER *, ASTERINTEGER *, ASTERDOUBLE *,
                         char *, STRING_SIZE);
#ifdef _STRLEN_AT_END
#define CALL_UTMESS_CORE(cod, idmess, nk, valk, ni, vali, nr, valr, fname) \
    F_FUNC(UTMESS_CORE, utmess_core)(cod, idmess, nk, valk, ni, vali, nr, valr, fname, \
                                     strlen(cod), strlen(idmess), VALK_SIZE, strlen(fname))
#else
#define CALL_UTMESS_CORE(cod, idmess, nk, valk, ni, vali, nr, valr, fname) \
    F_FUNC(UTMESS_CORE, utmess_core)(cod, strlen(cod), idmess, strlen(idmess), nk, \
                                     valk, VALK_SIZE, ni, vali, nr, valr, fname, strlen(fname))
#endif


/* routines UTILITAIRES pour MED */
#define CALL_MDNOMA(a,b,c,d) CALLSPSP(MDNOMA,mdnoma,a,b,c,d)
extern void DEFSPSP(MDNOMA,mdnoma,char *,STRING_SIZE,ASTERINTEGER *,
                    char *,STRING_SIZE,ASTERINTEGER *);

#define CALL_MDNOCH(a,b,c,d,e,f,g) CALLSPPSSSP(MDNOCH,mdnoch,a,b,c,d,e,f,g)
extern void DEFSPPSSSP(MDNOCH,mdnoch,char *,STRING_SIZE,
                       ASTERINTEGER *,ASTERINTEGER *,char *,STRING_SIZE,
                       char *,STRING_SIZE,char *,STRING_SIZE,ASTERINTEGER *);


/* FIN ASTER_FORT_H */
#endif
