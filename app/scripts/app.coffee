###
Copyright (c) 2015 "Fuzzy Frequency, Le Fresnoy"

This file is part of Kartel.

Kartel is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
###

# https://github.com/CommonsDev/map/blob/master/scripts/app.js

angular.module('candidature', ['candidature.application'])
angular.module('memoire', ['memoire.controllers', 'memoire.directives'])

angular.module('kartel',
              [
                  'memoire', 'candidature', 'ui.router',
                  'restangular', 'angular-jwt',
                  'ngAnimate', 'chieffancypants.loadingBar', 'ui.bootstrap', 'ngMessages',
                  'ngSanitize', 'markdown', '720kb.datepicker',
                  'iso-3166-country-codes', 'ngFileUpload', 'ngPlacesAutocomplete',
              ])

# CORS
.config(['$httpProvider', ($httpProvider) ->
        $httpProvider.defaults.useXDomain = true

        delete $httpProvider.defaults.headers.common['X-Requested-With']
])

# Tastypie
.config((RestangularProvider) ->
        RestangularProvider.setBaseUrl(config.rest_uri)
        # RestangularProvider.setRequestSuffix('?format=json');
        # RestangularProvider.setDefaultHeaders({"Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787"});
        # Tastypie patch
        RestangularProvider.setResponseExtractor((response, operation, what, url) ->
                newResponse = null;
                if operation is "getList"
                        if(response.objects)
                          newResponse = response.objects
                          newResponse.metadata = response.meta
                        else
                          newResponse = response
                        # V2
                        # newResponse = response
                        # V1
                        # newResponse = response.objects
                        # newResponse.metadata = response.meta
                else
                        newResponse = response

                return newResponse
        )
)

# token
 .config(($httpProvider, jwtOptionsProvider, RestangularProvider, jwtInterceptorProvider) ->

    jwtOptionsProvider.config({
      tokenGetter: ['options', (options) ->
        console.log(options)
        return localStorage.getItem('token')
      ],
      authHeader: "Authorization"
      authPrefix: "JWT"
      # unauthenticatedRedirectPath: '/login',
      unauthenticatedRedirector: ['$state', ($state) ->
        console.log("unauthenticatedRedirector")
        # $state.go('candidature.login');

      ],
      whiteListedDomains: ['api.lefresnoy.net', 'localhost', 'vimeo.com']

    })

    # jwtInterceptorProvider.tokenGetter = () ->
    #   return localStorage.getItem('token')


    $httpProvider.interceptors.push('jwtInterceptor')

    if localStorage.getItem('token')
        $httpProvider.defaults.headers.common.Authorization = "JWT "+ localStorage.getItem('token')

)
.run((authManager) ->

    authManager.checkAuthOnRefresh()
    authManager.redirectWhenUnauthenticated()

)


.filter("isFresnoyUrl", ->
  return (input, str = "/media/") ->
    if typeof input isnt 'string'
      return false
    return input.indexOf(str) > -1

)

.filter('time', ->
    return (value, unit, format, isPadded) ->
      time = value.split(":")
      hh = time[0]
      mm = time[1]
      ss = time[2]

      if(hh!="0")
        return format.replace(/hh/, hh).replace(/mm/, mm).replace(/ss/, ss);
      if(hh=="0" && mm!="0")
        # regex  hh[^mm] mm cible l'heure (hh) jusqu'au prochain 'mm' sans le prendre en compte : [^mm]
        return format.replace(/\hh[^mm]+\h/, '').replace(/mm/, mm).replace(/ss/, ss);
      if(hh=="0" && mm=="0" && ss!="0")
        return format.replace(/ss/, ss);
)

.filter('ageFilter', ->
    return (birthday) ->
      console.log(birthday)
      ageDifMs = Date.now() - new Date(birthday).getTime();
      ageDate = new Date(ageDifMs); # miliseconds from epoch
      return Math.abs(ageDate.getUTCFullYear() - 1970)
)

# catch write data
.factory('httpInterceptor', ['$q', '$rootScope', '$state', ($q, $rootScope, $state) ->
        return {
            request: (response) ->
                # disable html cache
                if(response.url.match(".html") && !response.url.match("uib") && !response.htmlnocache)
                  response.url +="?"+new Date().getTime().toString().slice(-2)
                  response.htmlnocache = true
                # broadcast message on save model
                if(response.method == "PUT" || response.method == "PATCH")
                    $rootScope.$broadcast('data:write')
                #
                $rootScope.$broadcast('loading:start')
                return response
            response: (response)  ->
                $rootScope.$broadcast('data:read')
                return response || $q.when(response)
            responseError: (response)  ->
                $rootScope.$broadcast('data:read')
                # candidature expired
                if(response.data && response.data.candidature)
                  if (response.data.candidature == "expired")
                    $state.go("candidature.expired")
                return $q.reject(response);
        }
])
.config(['$httpProvider', ($httpProvider) ->
    $httpProvider.interceptors.push('httpInterceptor')
])



# URI config
.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider,
                                                                      $stateProvider,
                                                                      $urlRouterProvider) ->

        $locationProvider.html5Mode(config.useHtml5Mode)
        $urlRouterProvider.otherwise("/school")

        # SCHOOL
        $stateProvider.state('school',
            url: '/school',
            views:
              'main_view':
                templateUrl: 'kartel.html'
                controller: 'NavController'
              'main_view.main_content_view':
                  templateUrl: 'views/school.html'
                  controller: 'SchoolController'
        )

        $stateProvider.state('school.promotion',
              url: '/promotion/:id'
              views:
                'content_school_view':
                    templateUrl: 'views/promotion.html'
                    controller: 'PromotionController'
        )

        $stateProvider.state('school.student',
              url: '/student/:id'
              views:
                'content_school_view':
                    templateUrl: 'views/student.html'
                    controller: 'StudentController'

        )

        # ARTIST
        $stateProvider.state('artist',
                url: '/artist?letter'
                views:
                  'main_view':
                      templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                    templateUrl: 'views/artists.html'
                    controller: 'ArtistListingController'
        )

        $stateProvider.state('artist.detail',
                url: '/:id',
                views:
                  'school_content_view':
                    templateUrl: 'views/student.html'
                    controller: 'ArtistController'
        )

        # ARTWORK

        $stateProvider.state('genre',
                url: '/artwork/?genre'
                views:
                  'main_view':
                    templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                      templateUrl: 'views/artworks.html'
                      controller: 'ArtworkGenreListingController'
        )

        $stateProvider.state('artwork',
                url: '/artwork?letter&offset'
                views:
                  'main_view':
                      templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                      templateUrl: 'views/artworks.html'
                      controller: 'ArtworkListingController'
        )

        $stateProvider.state('artwork-detail',
                url: '/artwork/:id'
                views:
                  'main_view':
                    templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                      templateUrl: 'views/artwork.html'
                      controller: 'ArtworkController'
        )

        # - Candidatures LISTS

        $stateProvider.state('candidatures',
                url: '/candidatures'
                views:
                  'main_view':
                    templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                      templateUrl: 'views/candidatures.html'
                      controller: 'CandidaturesController'
        )

        $stateProvider.state('candidatures.candidat',
                url: '/:id'
                views:
                  'main_content_view':
                      templateUrl: 'views/candidat.html'
                      controller: 'CandidatController'
        )




])

.run(['$rootScope', '$state', '$stateParams', ($rootScope, $state, $stateParams) ->
        $rootScope.homeStateName = 'apps' # Should be moved to loginServiceProvider

        $rootScope.config = config
        $rootScope.$state = $state
        $rootScope.$stateParams = $stateParams
        # $rootScope.loginService = loginService



])



.run(['AmeRestangular', (AmeRestangular) ->
  AmeRestangular.setErrorInterceptor((response) ->
    console.log(response)
    if (response.status == 401)
        console.log("Login required... ")
    else if (response.status == 404)
        console.log("Resource not available...")
    else
        console.log("Ame service not available : " + response.status )
    return response # stop the promise chain
  )
])

# Ugly Fix for autofill on forms
.directive('formAutofillFix', ->
        (scope, elem, attrs) ->
        # Fixes Chrome bug: https://groups.google.com/forum/#!topic/angular/6NlucSskQjY
        elem.prop 'method', 'POST'

        # Fix autofill issues where Angular doesn't know about autofilled inputs
        if attrs.ngSubmit
                setTimeout ->
                        elem.unbind('submit').submit (e) ->
                                e.preventDefault()
                                elem.find('input, textarea, select').trigger('input').trigger('change').trigger('keydown', ->
                                        scope.$apply(attrs.ngSubmit)
                                , 0)
)
