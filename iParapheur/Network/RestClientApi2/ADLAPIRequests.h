/*
 * Copyright 2012-2017, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */
#import "ADLRequester.h"
#import "ADLCollectivityDef.h"

#pragma mark - API Keys
/* Login / logout */
#define LOGIN_API               @"login"
#define LOGOUT_API              @"logout"

/* Data fetching */
#define GETLEVEL_API            @"getApiLevel"
#define GETBUREAUX_API          @"getBureaux"
#define GETDOSSIERSHEADERS_API  @"getDossiersHeaders"
#define GETDOSSIER_API          @"getDossier"
#define GETCIRCUIT_API          @"getCircuit"
#define GETANNOTATIONS_API      @"getAnnotations"
#define GETTYPOLOGIE_API        @"￼￼getTypologie"

/* editing api */
#define APPROVE_API             @"approve"

/* user details for display */
#define GETUSERDETAILS_API      @"getUserDetails"

#pragma mark - Commons

#define API_REQUEST(api, args) \
{ \
    ADLRequester *_requester = [ADLRequester sharedRequester]; \
    [_requester request:api andArgs:args delegate:self]; \
}

#define API_GET_REQUEST(api) \
{ \
ADLRequester *_requester = [ADLRequester sharedRequester]; \
[_requester request:api delegate:self]; \
}

#pragma mark - login

#define API_GETLEVEL() \
{ \
    API_GET_REQUEST(GETLEVEL_API); \
}

#define API_LOGIN(username, password) \
{ \
    NSDictionary *_args = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", password, @"password", nil]; \
    API_REQUEST(LOGIN_API, _args); \
}

#define API_LOGIN_GET_TICKET(answer) \
    [[answer objectForKey:@"data"] objectForKey:@"ticket"]

#pragma mark - getBureaux

#define API_GETBUREAUX() \
{ \
    API_GET_REQUEST(GETBUREAUX_API); \
}

#define API_GETLEVEL_GET_LEVEL(answer) \
    [answer objectForKey:@"level"]

#define API_GETBUREAUX_GET_BUREAUX(answer) \
    [answer objectForKey:@"bureaux"]

#pragma mark - getDossierHeaders

#define API_GETDOSSIERHEADERS(bureauCourant, page, pageSize) \
{ \
    NSDictionary *_args = [[NSDictionary alloc] initWithObjectsAndKeys:bureauCourant, @"bureauCourant", \
                            page, @"page", \
                            pageSize, @"pageSize", nil]; \
    API_REQUEST(GETDOSSIERSHEADERS_API, _args); \
}

#define API_GETDOSSIERHEADERS_FILTERED(bureauCourant, page, pageSize, banette, filters) \
    API_GETDOSSIER_GET_FILTER_REQUEST_BODY(bureauCourant, page, pageSize, banette, filters)\
    API_REQUEST(GETDOSSIERSHEADERS_API, _body);

#define API_GETDOSSIER_GET_FILTER_REQUEST_BODY(bureauCourant, page, pageSize, banette, filters) \
    NSDictionary *_body = [[NSDictionary alloc] initWithObjectsAndKeys: \
    bureauCourant, @"bureauCourant", \
    page, @"page", \
    filters, @"filters", \
    banette, @"parent", \
    pageSize, @"pageSize", nil];

#define API_GETDOSSIERHEADERS_GET_DOSSIERS(answer) \
    [answer objectForKey:@"dossiers"]

#pragma mark - getDossier

#define API_GETDOSSIER(dossier, bureauCourant) \
{ \
    NSDictionary *_args = [NSDictionary dictionaryWithObjectsAndKeys:dossier, @"dossier", \
                            bureauCourant, @"bureauCourant", nil]; \
    API_REQUEST(GETDOSSIER_API, _args); \
}

#define API_GETANNOTATIONS(dossier) \
{ \
    NSDictionary *_args = [NSDictionary dictionaryWithObjectsAndKeys:dossier, @"dossier", nil]; \
    API_REQUEST(GETANNOTATIONS_API, _args); \
}

#define API_GETCIRCUIT(dossier) \
{ \
NSDictionary *_args = [NSDictionary dictionaryWithObjectsAndKeys:dossierRef, @"dossier", nil]; \
API_REQUEST(GETCIRCUIT_API, _args); \
}
