# -*- tab-width: 2 -*-
"use strict"

angular.module('candidature.controllers', ['memoire.services', 'candidature.services'])


#
.controller('AccountCreationController',($rootScope, $http, $scope, $state, Registration, RestangularV2, Users) ->
      # inscription
      $rootScope.step.current = "04"
      $rootScope.current_display_screen = candidature_config.screen.account_create_user

      # init user form
      if(!$scope.user)
        $scope.user =
            last_name: ''
            first_name: ''
            email: ''

      # autogenerate username
      $scope.setUserName = (form, user) ->
        if (!user.first_name || !user.last_name)
          return
        user.username = slug(user.first_name).toLowerCase().substr(0,1) + slug(user.last_name).toLowerCase()
        form.uUserName.$setTouched()

      # create user
      $scope.create = (form, params) ->
        delete $http.defaults.headers.common.Authorization
        Registration.post(params).then((response) ->
          $state.go('candidature.account.user-created', {infos:params})
        , (response) ->
          form.error = response.data
        )


)
.controller('AccountConfirmCreationController',($rootScope, $http, $scope, $state, Registration, RestangularV2, Users, $stateParams) ->
    $rootScope.step.current = "05"
    $rootScope.current_display_screen = candidature_config.screen.account_confirm_creation
    $scope.edit_email = false
    $scope.send_email = 2

    if($stateParams.infos)
      $scope.user = $stateParams.infos

    $scope.update_infos = (form, params) ->
      delete $http.defaults.headers.common.Authorization
      form.$setSubmitted()
      RestangularV2.all('people/user/resend_activation_email').post(params).then((response) ->
        $scope.send_email--
      , (response) ->
        form.$error = response.data

      )
)


.controller('AccountCreatePasswordController', (
        $rootScope, $scope, $stateParams, $http,
        $state, jwtHelper, RestAuth, Restangular
) ->

  $rootScope.step.current = "06"
  $rootScope.current_display_screen = candidature_config.screen.account_create_password
  $scope.user_id = false

  if($stateParams.token)

    tokenDecode = []
    try tokenDecode = jwtHelper.decodeToken($stateParams.token)
    catch e then tokenDecode.user_id = false

    route = $stateParams.route
    $scope.user_id = tokenDecode.user_id
    $scope.username = tokenDecode.username

    $scope.submit = () ->
      # delete old headers
      delete $http.defaults.headers.common.Authorization

      password_infos =
        new_password1: $scope.new_password1
        new_password2: $scope.new_password2

      headers =
        Authorization: "JWT "+ $stateParams.token


      RestAuth.one().customPOST(password_infos, "password/change/", "", headers).then((response) ->
              $state.go(route)
            , (response) ->
              $scope.form.error = "Erreur de changement de mot de passe"

      )
)

.controller('AccountPasswordResetController', ($rootScope, $scope, RestAuth) ->

  $rootScope.step.current = "06"

  $scope.emailSended = false;
  $scope.submit = () ->
      RestAuth.one().customPOST({email: $scope.email}, "password/reset/").then((response) ->
        $scope.emailSended = true;
      , (response) ->
        $scope.form.error = "Erreur d'envoie de l'email"
  )
)

.controller('AccountLoginController', (
  $rootScope, $scope, RestangularV2, $state, $http, Login,
  Logout, authManager, jwtHelper
                                ) ->

    $rootScope.step.current = "07"
    $rootScope.current_display_screen = candidature_config.screen.account_login

    $scope.vm =
      username:""
      email:""
      password:""

    if($scope.isAuthenticated)
      console.log("logged : resume candidature")
      $state.go("candidature.options")

    $scope.login = (form, params) ->
      delete $http.defaults.headers.common.Authorization
      Login.post(params, [headers={}])
      .then((auth) ->
            localStorage.setItem('token', auth.token)
            # set header
            $http.defaults.headers.common.Authorization = "JWT "+ localStorage.getItem('token')
            authManager.authenticate()
            $state.go("candidature.options")
          , () ->
            console.log("error")
            params.error = "Error login"
            $scope.logout()
     )
)


.controller('ParentCandidatureController', ($rootScope, $scope, $state, jwtHelper, $q,
            Restangular, RestangularV2, Vimeo, Logout, $http, cfpLoadingBar, authManager, ISO3166,
            Users, Candidatures, ArtistsV2, Galleries, Media, Upload) ->

  # Media

  if(!$rootScope.current_display_screen)
    $rootScope.current_display_screen = candidature_config.screen.home

  # init step in parent controller
  $rootScope.step = []
  $rootScope.step.total = 24
  $rootScope.step.title = "Procédure d'inscription"
  $rootScope.candidature_config = candidature_config

  # navigation
  $rootScope.navigation_inter_page = 0
  $rootScope.display_help = false
  $rootScope.show_help = (bool) ->
    console.log("Please Help !" + bool)
    if(bool!=undefined)
      return $rootScope.display_help = bool
    $rootScope.display_help = !$rootScope.display_help

  # Dates
  $rootScope.current_year = new Date().getFullYear()
  $rootScope.age_min = 18
  $rootScope.age_max = 36

  # phone
  $rootScope.phone_pattern = /^\+?[0-9-]{2,5}[-. ]?\d{5,12}$/

  # ITW types
  $scope.INTERVIEW_TYPES = ["Skype"]


  # write data var
  $rootScope.writingData = false

  # lang
  if localStorage.getItem("language")
    $rootScope.language = localStorage.getItem("language")
  else
    localStorage.language = "fr"
    $rootScope.language = localStorage.getItem("language")

  $scope.setLang = (lang) ->
    localStorage.setItem("language", lang)
    $rootScope.language = localStorage.language

  # countries
  $rootScope.getCountrie = (code) ->
    return _.invert(ISO3166.countryToCode)[code]


  # logout
  $rootScope.logout = () ->
    Logout.post({},{},{}).then((auth) ->
        localStorage.removeItem("token")
        $rootScope.user = []
        delete $http.defaults.headers.common.Authorization
        authManager.unauthenticate()
        $state.go("candidature.account.login")
    )


  $rootScope.$on('data:write', (event, data) ->
    $rootScope.writingData = true

  )
  $rootScope.$on('data:read', (event, data) ->
    setTimeout ( ->
      $rootScope.writingData = false
    ), 100
  )


  createNewGallery = (scope, model, array_galleries_name, gallerie_label, gallerie_description, return_var) ->
      gallery_infos =
        label: gallerie_label
        description: gallerie_description
        # "Candidature's Gallery"
      Galleries.one().customPOST(gallery_infos).then((response_gallerie) ->
        # scope.candidature.administrative_galleries.push(response.url)
        if(model[array_galleries_name] instanceof Array)
          model[array_galleries_name].push(response_gallerie.url)
        else
          model[array_galleries_name] = response_gallerie.url
        return_var = response_gallerie
        infos = {}
        infos[array_galleries_name] =  model[array_galleries_name]

        model.patch(infos)
        # model.save()
      )

  getGalleryWithMedia = (gallery_url, return_var) ->
      RestangularV2.oneUrl('assets/gallery', gallery_url).get()
      .then((gall_response) ->
          return_var.url = gall_response.url
          for medium in gall_response.media
              RestangularV2.oneUrl('assets/medium', medium).get().then((response_medium) ->
                  find_medium = gall_response.media.indexOf(response_medium.url)
                  return_var.media[find_medium] = response_medium
              )

      )

  $rootScope.upload = (data, model, field) ->

      infos =
        url: model.url,
        data: {}
        method: 'PATCH',
        headers: { 'Authorization': 'JWT ' + localStorage.token },
        #withCredentials: true

      infos.data[field] = data
      Upload.upload(infos)
      .then((resp) ->
          model[field] = resp.data[field]
        ,(resp) ->
          console.log('Error status: ' + resp.status);
        ,(evt) ->
          $rootScope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
      )

  $scope.saveUserModel = (model) ->
    model_copy =  RestangularV2.copy(model)
    if model_copy.profile.photo
      delete model_copy.profile.photo
    model_copy.save()


  #load user infos
  $rootScope.loadInfos = (scope) ->

    scope.user = []
    scope.user.profile = []
    scope.artist = []
    scope.candidature = []

    scope.artworks = []
    # Admin
    scope.candidature.cursus_justifications = []
    scope.cursus_justifications = []
    scope.cursus_justifications.id = []
    scope.cursus_justifications.url = []
    scope.cursus_justifications.media = []

    # if(scope.candidature.length)
    if(!scope.isAuthenticated)
      $state.go("candidature.account.login")

    user_id = jwtHelper.decodeToken(localStorage.getItem('token')).user_id
    Users.one(user_id).get().then((user) ->
      scope.user = user

      Candidatures.getList().then((candidatures) ->
        console.log(candidatures.length)
        if (candidatures.length >= 2)
          $state.go("candidature.error_admin_user")

        candidature = candidatures[candidatures.length-1]
        scope.candidature = candidature
        if(candidature.application_completed)
          $state.go("candidature.confirmation")
          return

        if(scope.candidature.cursus_justifications)
          getGalleryWithMedia(scope.candidature.cursus_justifications, scope.cursus_justifications)
        else
          #
          createNewGallery(
            scope,
            scope.candidature,
            "cursus_justifications",
            "Cursus",
            "Candidatures de "+ user.last_name + " " + user.first_name + " | " + candidature.current_year_application_count,
            scope.cursus_justifications
          )
        # get Artist
        matches = candidature.artist.match(/\d+$/)
        if matches
          artist_id = matches[0]
          # console.log(scope.candidature.plain())
          ArtistsV2.one(artist_id).get().then((artist) ->
              scope.artist = artist
          )
      )
    , (userInfos_error) ->
      console.log("error user infos")
      $state.go("candidature.error")
    )
)


.controller('AdministrativeInformationsController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

  $rootScope.loadInfos($rootScope)
  $rootScope.step.current = "09"
  $rootScope.current_display_screen = candidature_config.screen.admin_infos

  $scope.birthdateMin = $filter('date')(new Date($rootScope.current_year-$rootScope.age_min,11,31), 'yyyy-MM-dd')
  $scope.birthdateMax = $filter('date')(new Date($rootScope.current_year-$rootScope.age_max+1,1,1), 'yyyy-MM-dd')

  # Gender
  $scope.gender =
    M: fr: "Homme", en: "Male"
    F: fr: "Femme", en: "Female"
    T: fr: "Transgenre", en: "Transgender"
    O: fr: "Autre", en: "Other"

  #country
  $scope.countries = ISO3166.countryToCode

  # nationality
  $scope.nationality = []
  $scope.splitChar = ", "

  $scope.$watch("user.profile.nationality", (newValue, oldValue) ->
    if(newValue)
      $scope.nationality = newValue.split($scope.splitChar)
  )



  # justif photo
  $scope.photo_justification_file = null

  $scope.uploadFile = (data, model, field, type) ->
    $rootScope.upload(data, model, field)


  # specific upload Photo

)

.controller('ContactInformationsController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "10"
    $rootScope.current_display_screen = candidature_config.screen.admin_infos

    #country
    $scope.countries = ISO3166.countryToCode

    $scope.$watch("user.profile.homeland_phone", (newValue, oldValue) ->
      if(newValue)
        $scope.phone_number = newValue.split(" ").pop()
        $scope.phone_country = newValue.split(" ").shift().substr(1)
        if($scope.form2.uHomelandPhone.$valid)
          $scope.saveUserModel($scope.user)
    )


)

.controller('LanguagesInformationsController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "11"
    $rootScope.current_display_screen = candidature_config.screen.languages_infos

    $scope.languageSelectOption =
      fr:"Sélectionner une langue"
      en:"Select a language"



    $scope.LANGUAGES_NAME = languageMappingList
    $scope.LANGUAGES = _.sortBy(_.pairs(languageMappingList), (o) -> return o[1].englishName)
    $scope.other_language = []
    $scope.splitChar = ", "

    $scope.$watch("user.profile.other_language", (newValue, oldValue) ->
      if(newValue)
        $scope.other_language =   newValue.split($scope.splitChar)
    )



)
.controller('UploadUserPhotoController', ($rootScope, $scope, $state, Upload) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "12"
    $rootScope.current_display_screen = candidature_config.screen.photo_info

    $scope.uploadPhoto = (data, model, form) ->
      infos =
        url: model.url,
        data: {
          'profile.photo' : data
        }
        method: 'PATCH',
        headers: { 'Authorization': 'JWT ' + localStorage.token },
        #withCredentials: true
      Upload.upload(infos)
      .then((resp) ->
          model.profile.photo = resp.data.profile.photo
        ,(resp) ->
          model.profile.photo = ""
        ,(evt) ->
          $rootScope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
      )


)


#cursus
.controller('CvController', ($rootScope, $scope, Media, Galleries, Upload) ->

      $rootScope.loadInfos($rootScope)
      $rootScope.step.current = "14"
      $rootScope.current_display_screen = candidature_config.screen.cv


      #patch Medium
      $scope.uploadFile = (data, model) ->

          field = "picture"
          if (data.type.match("image.*"))
            field = "picture"
          if (data.type.match("pdf"))
            field = "file"

          medium_infos =
            gallery: model.url
          Media.one().customPOST(medium_infos).then((response_media) ->
            model.media.push(response_media)
            $rootScope.upload(data, response_media, field)
          )

      $scope.removeItem = (media, index) ->
        item = media[index]
        item.remove().then((response) ->
            media.splice(index,1)
        )

)

.controller('PreviousAppController', ($rootScope, $scope, Media, Galleries, Upload) ->

        $rootScope.loadInfos($rootScope)
        $rootScope.step.current = "16"

        #cursus
        year = new Date().getFullYear()
        $scope.years = []
        $scope.years.push (year-i) for i in [1..35]

        $scope.last_applications_years = []
        $scope.splitChar = ", "

        $scope.$watch("candidature.last_applications_years", (newValue, oldValue) ->
          if(newValue)
            $scope.last_applications_years = newValue.split($scope.splitChar)
        )

)

# media
.controller('MediaVideoController', (
        $rootScope, $scope, $q, $state, $filter, $sce, $http,
        Users, ArtistsV2, Restangular, RestangularV2, Candidatures, Media, Galleries,
        ISO3166, Upload, VimeoToken, Vimeo
      ) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "20"

    $scope.trustSrc = (src) ->
      return $sce.trustAsResourceUrl(src);

    $scope.honor = false

    $scope.$watch("candidature.presentation_video", (newValue, oldValue) ->
      if(newValue)
        $scope.isAvailableVideo(newValue)

    )

    $scope._isAvailableVideo = false
    $scope.isAvailableVideo = (videoUri) ->
      if(!videoUri)
        $scope._isAvailableVideo = false
        return
      if(videoUri.indexOf('player.vimeo.com/video')>0)
          idVimeo = videoUri.split("/").pop()
          VimeoToken.one().get().then((settings) ->
              Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
              video_uri = "videos/"+idVimeo
              Vimeo.one(video_uri).get().then((video_infos) ->
                if(video_infos.data.status == "available")
                  $scope._isAvailableVideo = true
                else
                  $scope._isAvailableVideo = false
              , (error) ->
                $scope._isAvailableVideo = false
              )
          , (error) ->
            $scope._isAvailableVideo = false
          )
      else
        $scope._isAvailableVideo = true

    $scope.deleteVimeoVideo = (idVimeo, model, field) ->
      # get Vimeo token api
      VimeoToken.one().get().then((settings) ->
          Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
          video_uri = "videos/"+idVimeo
          Vimeo.one(video_uri).remove().then((video_infos) ->
            model[field] = ""
            patch_infos = {}
            model[field] = ""
            patch_infos[field] = model[field]
            model.patch(patch_infos)
          )
      )


    $scope.uploadVimeo = (data, model, field) ->

      if (!data)
        return

      # get Vimeo token api
      VimeoToken.one().get().then((settings) ->
          # localStorage.setItem('vimeo_upload_token',settings.token)
          Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
          # connect to vimeo api
          Vimeo.one("me").get().then((account_infos) ->
              # console.log(account_infos)
              console.log((account_infos.data.upload_quota.space.free / 1073741824).toFixed(3) + " GB")
              upload_settings =
                type: "streaming"
              # get an upload ticket
              account_infos.data.customPOST(upload_settings,"videos").then((ticket) ->
                    # http method because Vimeo crash when multipart upload
                    #  send no Authorization
                    upload_config =
                      url: ticket.data.upload_link_secure
                      headers:
                        'Content-Type': data.type
                        Authorization : undefined
                      data: data
                      method: 'PUT'
                      skipAuthorization: true,
                      # transformRequest: (data, headers) ->
                      #   delete headers()['Authorization']
                      #   return data;

                    Upload.http(upload_config)
                    .then((resp) ->
                        # Complete the upload : complete_uri remove
                        Vimeo.one(ticket.data.complete_uri).remove().then((remove) ->
                          # get video id
                          location = remove.headers('Location')
                          video_id = location.split('/')[2]
                          # save the media link
                          patch_infos = {}
                          model[field] = "https://player.vimeo.com/video/"+video_id
                          patch_infos[field] = model[field]
                          model.patch(patch_infos)
                          # rename the video
                          video_info =
                            name: data.name
                            description: "Inscription - " + $scope.candidature.current_year_application_count + " | " + $scope.user.last_name + " - " + $scope.user.first_name

                          Vimeo.one(location).patch(video_info).then((patch_response) ->
                            # console.log("Video set Title and description")
                            # put video in album 4370111 (candidature 2017)
                            album_id = 4370111
                            Vimeo.one(account_infos.data.uri).customPUT({}, "albums/"+album_id+"/videos/"+video_id).then((response_album) ->
                                # console.log("Video in specific album : " + album_id)
                            )
                          )
                        )
                      , (error)->
                        console.log("ERROR  upload VIMEO")
                        console.log(error.headers('Authorization'))
                      , (evt) ->
                        $rootScope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total)

                    )
                  )
            )

        , ->
          # error
          console.log("vimeoUploadError")
      )

    $scope.uploadFile = (data, model, field) ->
      $rootScope.upload(data, model, field)

)
